#include "Renderer.h"

#include "layout/LayoutBox.h"
#include "dom/Element.h"

#include <iostream>
#include <string>
#include <algorithm>

namespace render {

// ANSI escape helpers
static const char* RESET    = "\033[0m";
static const char* BOLD     = "\033[1m";
static const char* DIM      = "\033[2m";
static const char* UNDERLINE= "\033[4m";
static const char* CYAN     = "\033[36m";
static const char* GREEN    = "\033[32m";
static const char* YELLOW   = "\033[33m";
static const char* BLUE     = "\033[34m";
[[maybe_unused]] static const char* RED = "\033[31m";

static void hr(int width = 72) {
    std::cout << std::string(static_cast<size_t>(width), '-') << '\n';
}

// Returns true if the text looks like human-readable content.
// Human text almost always contains letters outside [a-fA-F] (g-z) or spaces.
// Strings ≥8 chars with neither are binary/encoded data (RSC payloads, hashes, etc.).
static bool is_readable_text(const std::string& text) {
    if (text.size() < 8) return true;
    for (unsigned char c : text) {
        if (c == ' ' || c == '\n' || c == '\t') return true; // has whitespace → human text
        if ((c >= 'g' && c <= 'z') || (c >= 'G' && c <= 'Z')) return true; // has non-hex letter
    }
    return false; // ≥8 chars, no spaces, no g-z letters → encoded data
}

static void render_box(const layout::LayoutBox& box, int indent, bool& last_was_block) {
    if (box.type() == layout::BoxType::Text) {
        const auto& t = box.text();
        if (!t.empty()) {
            bool ok = is_readable_text(t);
            std::cerr << (ok ? "[TEXT-PASS  " : "[TEXT-BLOCK ")
                      << t.size() << "] "
                      << t.substr(0, 72) << '\n';
            if (ok) {
                std::cout << t;
                last_was_block = false;
            }
        }
        return;
    }

    auto* node = box.node();
    if (!node || !node->is_element()) {
        // Anonymous block — just render children
        for (auto& child : box.children())
            render_box(*child, indent, last_was_block);
        return;
    }

    auto* el  = node->as_element();
    auto& tag = el->tag_name();
    [[maybe_unused]] auto& style = box.style();

    // ── Tags whose content must never be rendered as text ────────────────────
    static const std::initializer_list<std::string_view> skip_tags = {
        "script", "style", "noscript", "svg", "canvas",
        "meta", "link", "head", "template", "iframe"
    };
    for (auto s : skip_tags)
        if (tag == s) return;

    // ── Block-level elements ─────────────────────────────────────────────────
    if (box.type() == layout::BoxType::Block || box.type() == layout::BoxType::AnonymousBlock) {
        if (!last_was_block) std::cout << '\n';

        std::string pad(static_cast<size_t>(indent * 2), ' ');

        if (tag == "html" || tag == "body" || tag == "div" || tag == "main" ||
            tag == "article" || tag == "section" || tag == "aside" || tag == "nav" ||
            tag == "header" || tag == "footer") {
            for (auto& child : box.children())
                render_box(*child, indent + 1, last_was_block);
            if (!last_was_block) std::cout << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "h1") {
            hr();
            std::cout << BOLD << CYAN;
            for (auto& child : box.children()) render_box(*child, 0, last_was_block);
            std::cout << RESET << '\n';
            hr();
            std::cout << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "h2") {
            std::cout << '\n' << BOLD << CYAN;
            for (auto& child : box.children()) render_box(*child, 0, last_was_block);
            std::cout << RESET << '\n';
            std::cout << std::string(40, '=') << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "h3" || tag == "h4" || tag == "h5" || tag == "h6") {
            std::cout << '\n' << BOLD;
            for (auto& child : box.children()) render_box(*child, 0, last_was_block);
            std::cout << RESET << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "p") {
            std::cout << '\n' << pad;
            for (auto& child : box.children()) render_box(*child, 0, last_was_block);
            std::cout << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "hr") {
            hr();
            last_was_block = true;
            return;
        }

        if (tag == "pre" || tag == "code") {
            std::cout << '\n' << DIM;
            for (auto& child : box.children()) render_box(*child, 0, last_was_block);
            std::cout << RESET << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "blockquote") {
            std::cout << '\n' << DIM << "  | ";
            for (auto& child : box.children()) render_box(*child, 0, last_was_block);
            std::cout << RESET << '\n';
            last_was_block = true;
            return;
        }

        if (tag == "ul") {
            std::cout << '\n';
            for (auto& child : box.children()) {
                if (child->node() && child->node()->is_element() &&
                    child->node()->as_element()->tag_name() == "li") {
                    std::cout << pad << "  • ";
                    bool b = false;
                    for (auto& c2 : child->children()) render_box(*c2, 0, b);
                    std::cout << '\n';
                }
            }
            last_was_block = true;
            return;
        }

        if (tag == "ol") {
            std::cout << '\n';
            int n = 1;
            for (auto& child : box.children()) {
                if (child->node() && child->node()->is_element() &&
                    child->node()->as_element()->tag_name() == "li") {
                    std::cout << pad << "  " << n++ << ". ";
                    bool b = false;
                    for (auto& c2 : child->children()) render_box(*c2, 0, b);
                    std::cout << '\n';
                }
            }
            last_was_block = true;
            return;
        }

        if (tag == "table") {
            std::cout << '\n';
            for (auto& tbody : box.children()) {
                for (auto& row : tbody->children()) {
                    if (!row->node() || !row->node()->is_element()) continue;
                    std::cout << "| ";
                    bool b = false;
                    for (auto& cell : row->children()) {
                        for (auto& c2 : cell->children()) render_box(*c2, 0, b);
                        std::cout << " | ";
                    }
                    std::cout << '\n';
                }
            }
            last_was_block = true;
            return;
        }

        if (tag == "form") {
            std::cout << '\n' << YELLOW << "[FORM]" << RESET << '\n';
            for (auto& child : box.children()) render_box(*child, indent, last_was_block);
            last_was_block = true;
            return;
        }

        if (tag == "input") {
            std::string type = el->get_attr("type");
            std::string name = el->get_attr("name");
            std::string ph   = el->get_attr("placeholder");
            std::cout << YELLOW;
            if (type == "submit" || type == "button")
                std::cout << "[BUTTON: " << el->get_attr("value") << "]";
            else
                std::cout << "[INPUT " << (type.empty() ? "text" : type)
                           << (name.empty() ? "" : " name=" + name)
                           << (ph.empty()   ? "" : " placeholder=\"" + ph + "\"") << "]";
            std::cout << RESET << '\n';
            last_was_block = true;
            return;
        }

        // Generic block
        for (auto& child : box.children())
            render_box(*child, indent, last_was_block);
        if (!last_was_block) std::cout << '\n';
        last_was_block = true;
        return;
    }

    // ── Inline elements ───────────────────────────────────────────────────────
    if (tag == "a") {
        std::string href = el->get_attr("href");
        std::cout << BLUE << UNDERLINE;
        for (auto& child : box.children()) render_box(*child, 0, last_was_block);
        std::cout << RESET;
        if (!href.empty()) std::cout << GREEN << " [" << href << "]" << RESET;
        last_was_block = false;
        return;
    }

    if (tag == "strong" || tag == "b") {
        std::cout << BOLD;
        for (auto& child : box.children()) render_box(*child, 0, last_was_block);
        std::cout << RESET;
        last_was_block = false;
        return;
    }

    if (tag == "em" || tag == "i") {
        std::cout << DIM;
        for (auto& child : box.children()) render_box(*child, 0, last_was_block);
        std::cout << RESET;
        last_was_block = false;
        return;
    }

    if (tag == "code") {
        std::cout << DIM << "`";
        for (auto& child : box.children()) render_box(*child, 0, last_was_block);
        std::cout << "`" << RESET;
        last_was_block = false;
        return;
    }

    if (tag == "br") {
        std::cout << '\n';
        last_was_block = true;
        return;
    }

    if (tag == "img") {
        std::string alt = el->get_attr("alt");
        std::string src = el->get_attr("src");
        std::cout << YELLOW << "[IMG" << (alt.empty() ? "" : ": " + alt) << "]" << RESET;
        last_was_block = false;
        return;
    }

    // Fallback: render children
    for (auto& child : box.children())
        render_box(*child, indent, last_was_block);
}

void render_to_terminal(const layout::LayoutBox& root, const std::string& title) {
    if (!title.empty()) {
        std::cout << BOLD << CYAN;
        hr();
        std::cout << "  " << title << '\n';
        hr();
        std::cout << RESET << '\n';
    }

    bool last_was_block = true;
    for (auto& child : root.children())
        render_box(*child, 0, last_was_block);

    std::cout << '\n' << DIM;
    hr();
    std::cout << "  End of document." << RESET << '\n';
}

} // namespace render
