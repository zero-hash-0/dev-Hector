#include "net/URL.h"
#include "net/Request.h"
#include "net/Response.h"

#include <fstream>
#include <sstream>
#include "html/Parser.h"
#include "html/Tokenizer.h"
#include "css/Parser.h"
#include "css/StyleSheet.h"
#include "dom/Document.h"
#include "dom/Element.h"
#include "layout/BlockFormattingContext.h"
#include "render/Renderer.h"
#include "security/ContentSecurityPolicy.h"
#include "security/SameOriginPolicy.h"
#include "js/Interpreter.h"

#include <iostream>
#include <string>
#include <variant>

// ── ANSI colours ──────────────────────────────────────────────────────────────
static const char* RESET  = "\033[0m";
static const char* RED    = "\033[31m";
static const char* YELLOW = "\033[33m";
static const char* GREEN  = "\033[32m";
static const char* BOLD   = "\033[1m";

static void print_usage(const char* argv0) {
    std::cerr << "Usage: " << argv0 << " <url>\n"
              << "  Supported schemes: http://, https://\n";
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    std::string raw_url = argv[1];

    // ── 1. Parse URL ──────────────────────────────────────────────────────────
    auto url_result = net::URL::parse(raw_url);
    if (std::holds_alternative<net::URL::ParseError>(url_result)) {
        std::cerr << RED << "URL parse error: "
                  << std::get<net::URL::ParseError>(url_result).reason
                  << RESET << '\n';
        return 1;
    }
    const auto& url = std::get<net::URL>(url_result);

    std::cout << BOLD << GREEN << "LadyBird" << RESET << " v0.1  |  loading "
              << url.to_string() << '\n';

    std::string html;
    auto csp = security::ContentSecurityPolicy::permissive();

    // ── 2. Fetch or read ──────────────────────────────────────────────────────
    if (url.is_file()) {
        // file:// — read directly from disk
        std::string path = url.path();
        std::ifstream fs(path);
        if (!fs) {
            std::cerr << RED << "Cannot open file: " << path << RESET << '\n';
            return 1;
        }
        std::ostringstream ss;
        ss << fs.rdbuf();
        html = ss.str();
        std::cout << YELLOW << "file " << path << RESET << '\n';
    } else {
        net::Request request(url);
        auto fetch_result = request.send();

        if (std::holds_alternative<net::NetworkError>(fetch_result)) {
            std::cerr << RED << "Network error: "
                      << std::get<net::NetworkError>(fetch_result).message
                      << RESET << '\n';
            return 1;
        }

        const auto& response = std::get<net::Response>(fetch_result);
        std::cout << YELLOW << "HTTP " << response.status_code
                  << " " << response.status_text << RESET << '\n';

        if (!response.ok()) {
            std::cerr << RED << "Server returned non-2xx status." << RESET << '\n';
            return 1;
        }

        auto csp_header = response.header("content-security-policy");
        if (!csp_header.empty())
            csp = security::ContentSecurityPolicy::parse(csp_header, url);

        if (csp.upgrade_insecure_requests() && !url.is_secure())
            std::cerr << YELLOW << "Note: page sets upgrade-insecure-requests." << RESET << '\n';
        if (csp.block_all_mixed_content())
            std::cout << GREEN << "[CSP] block-all-mixed-content active." << RESET << '\n';

        html = response.body_as_string();
    }

    // ── 3b. Strip raw-text element content before parsing ─────────────────────
    // Removes content between <script>…</script> and <style>…</style> so that
    // inline JS/CSS payloads (e.g. Next.js RSC flight data) never reach the DOM.
    auto strip_raw_text = [](std::string& src,
                              std::string_view open_tag,
                              std::string_view close_tag) {
        std::string out;
        out.reserve(src.size());
        size_t i = 0;
        while (i < src.size()) {
            // Case-insensitive search for open_tag
            if (src.size() - i >= open_tag.size()) {
                bool match = true;
                for (size_t k = 0; k < open_tag.size() && match; ++k)
                    match = (std::tolower(static_cast<unsigned char>(src[i+k]))
                             == static_cast<unsigned char>(open_tag[k]));
                if (match) {
                    // Copy through to end of opening tag (find '>'), then skip content
                    size_t tag_end = src.find('>', i);
                    if (tag_end == std::string::npos) { out += src[i++]; continue; }
                    out.append(src, i, tag_end - i + 1); // keep the open tag
                    i = tag_end + 1;
                    // Find close tag (case-insensitive)
                    size_t close = std::string::npos;
                    for (size_t j = i; j + close_tag.size() <= src.size(); ++j) {
                        bool cm = true;
                        for (size_t k = 0; k < close_tag.size() && cm; ++k)
                            cm = (std::tolower(static_cast<unsigned char>(src[j+k]))
                                  == static_cast<unsigned char>(close_tag[k]));
                        if (cm) { close = j; break; }
                    }
                    if (close != std::string::npos) i = close; // skip content; close tag copied below
                    continue;
                }
            }
            out += src[i++];
        }
        src = std::move(out);
    };
    strip_raw_text(html, "<script", "</script>");
    strip_raw_text(html, "<style",  "</style>");

    // ── 4. Parse HTML ─────────────────────────────────────────────────────────
    auto doc   = html::Parser::parse(html, url);

    // ── 5. Extract and parse stylesheets ──────────────────────────────────────
    css::StyleSheet sheet;
    if (auto* head = doc->head()) {
        for (auto* style_el : head->query_selector_all("style")) {
            sheet = css::Parser::parse_stylesheet(style_el->text_content());
        }
    }

    // ── 6. Build layout tree ──────────────────────────────────────────────────
    auto layout = layout::BlockFormattingContext::build(*doc, sheet);

    // ── 7. Execute inline scripts ─────────────────────────────────────────────
    js::Interpreter js_engine(std::cerr); // JS output goes to stderr, not the rendered page
    auto script_elements = doc->get_elements_by_tag("script");
    for (auto* script : script_elements) {
        std::string src = script->text_content();
        if (src.empty()) continue;
        try {
            js_engine.run(src);
        } catch (const std::exception& ex) {
            std::cerr << YELLOW << "[JS] " << ex.what() << RESET << '\n';
        }
    }

    // ── 8. Render ─────────────────────────────────────────────────────────────
    std::string title = doc->title();
    render::render_to_terminal(*layout, title.empty() ? url.to_string() : title);

    return 0;
}
