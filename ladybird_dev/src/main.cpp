#include "net/URL.h"
#include "net/Request.h"
#include "net/Response.h"
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

    std::cout << BOLD << GREEN << "LadyBird" << RESET << " v0.1  |  fetching "
              << url.to_string() << '\n';

    // ── 2. Fetch ──────────────────────────────────────────────────────────────
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

    // ── 3. Content-Security-Policy ────────────────────────────────────────────
    auto csp_header = response.header("content-security-policy");
    auto csp = csp_header.empty()
             ? security::ContentSecurityPolicy::permissive()
             : security::ContentSecurityPolicy::parse(csp_header, url);

    if (csp.upgrade_insecure_requests() && !url.is_secure()) {
        std::cerr << YELLOW
                  << "Note: page requests upgrade-insecure-requests but was loaded over HTTP."
                  << RESET << '\n';
    }
    if (csp.block_all_mixed_content()) {
        std::cout << GREEN << "[CSP] block-all-mixed-content active." << RESET << '\n';
    }

    // ── 4. Parse HTML ─────────────────────────────────────────────────────────
    auto html  = response.body_as_string();
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

    // ── 7. Render ─────────────────────────────────────────────────────────────
    std::string title = doc->title();
    render::render_to_terminal(*layout, title.empty() ? url.to_string() : title);

    return 0;
}
