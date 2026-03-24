#include "Parser.h"

#include <sstream>
#include <algorithm>
#include <cctype>

namespace css {

static std::string trim(std::string_view sv) {
    auto b = sv.find_first_not_of(" \t\r\n");
    if (b == std::string_view::npos) return {};
    auto e = sv.find_last_not_of(" \t\r\n");
    return std::string(sv.substr(b, e - b + 1));
}

static std::string to_lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c){ return static_cast<char>(std::tolower(c)); });
    return s;
}

// ── parse_inline_style ────────────────────────────────────────────────────────

std::vector<Declaration> Parser::parse_inline_style(std::string_view style) {
    std::vector<Declaration> decls;
    std::string str(style);
    std::istringstream ss(str);
    std::string decl;
    while (std::getline(ss, decl, ';')) {
        auto colon = decl.find(':');
        if (colon == std::string::npos) continue;
        Declaration d;
        d.property = to_lower(trim(decl.substr(0, colon)));
        std::string val = trim(decl.substr(colon + 1));
        // Check for !important
        auto imp = val.rfind("!important");
        if (imp != std::string::npos) {
            d.important = true;
            val = trim(val.substr(0, imp));
        }
        d.value = val;
        if (!d.property.empty() && !d.value.empty())
            decls.push_back(std::move(d));
    }
    return decls;
}

// ── parse_stylesheet ──────────────────────────────────────────────────────────

StyleSheet Parser::parse_stylesheet(std::string_view css) {
    StyleSheet sheet;
    std::string str(css);
    size_t i = 0;

    auto skip_whitespace = [&]() {
        while (i < str.size() && std::isspace(static_cast<unsigned char>(str[i]))) ++i;
    };

    auto skip_comment = [&]() -> bool {
        if (i + 1 < str.size() && str[i] == '/' && str[i+1] == '*') {
            i += 2;
            while (i + 1 < str.size() && !(str[i] == '*' && str[i+1] == '/'))
                ++i;
            i += 2;
            return true;
        }
        return false;
    };

    while (i < str.size()) {
        skip_whitespace();
        if (skip_comment()) continue;
        if (i >= str.size()) break;

        // Read selector(s) until '{'
        std::string selector_str;
        while (i < str.size() && str[i] != '{') {
            selector_str += str[i++];
        }
        if (i >= str.size()) break;
        ++i; // consume '{'

        // Read declaration block until '}'
        std::string block;
        while (i < str.size() && str[i] != '}') {
            block += str[i++];
        }
        if (i < str.size()) ++i; // consume '}'

        Rule rule;

        // Split selectors on ','
        std::istringstream sel_ss(selector_str);
        std::string sel;
        while (std::getline(sel_ss, sel, ',')) {
            std::string t = trim(sel);
            if (!t.empty()) rule.selectors.push_back(to_lower(t));
        }

        // Parse declarations
        rule.declarations = parse_inline_style(block);

        if (!rule.selectors.empty() && !rule.declarations.empty())
            sheet.rules.push_back(std::move(rule));
    }

    return sheet;
}

// ── selector_matches ──────────────────────────────────────────────────────────

bool Parser::selector_matches(std::string_view selector,
                                std::string_view tag_name,
                                const std::vector<std::string>& class_list,
                                std::string_view id) {
    if (selector == "*") return true;
    if (selector == tag_name) return true;

    // Class selector: .foo
    if (selector.starts_with('.')) {
        std::string cls(selector.substr(1));
        return std::find(class_list.begin(), class_list.end(), cls) != class_list.end();
    }

    // ID selector: #foo
    if (selector.starts_with('#')) {
        return selector.substr(1) == id;
    }

    // Tag.class: p.intro
    auto dot = selector.find('.');
    if (dot != std::string_view::npos) {
        std::string t(selector.substr(0, dot));
        std::string c(selector.substr(dot + 1));
        return t == tag_name &&
               std::find(class_list.begin(), class_list.end(), c) != class_list.end();
    }

    return false;
}

// ── User-agent defaults ───────────────────────────────────────────────────────

static ComputedStyle ua_defaults(std::string_view tag) {
    ComputedStyle s;
    if (tag == "b" || tag == "strong") { s.font_weight = "bold"; s.display = "inline"; }
    else if (tag == "i" || tag == "em") { s.display = "inline"; }
    else if (tag == "span" || tag == "a" || tag == "code" || tag == "small") s.display = "inline";
    else if (tag == "p")    { s.margin_top = "16px"; s.margin_bottom = "16px"; }
    else if (tag == "h1")   { s.font_size = "2em";  s.font_weight = "bold"; s.margin_top = "21px"; s.margin_bottom = "21px"; }
    else if (tag == "h2")   { s.font_size = "1.5em"; s.font_weight = "bold"; }
    else if (tag == "h3")   { s.font_size = "1.17em"; s.font_weight = "bold"; }
    else if (tag == "h4")   { s.font_size = "1em";  s.font_weight = "bold"; }
    else if (tag == "head" || tag == "style" || tag == "script" || tag == "meta" || tag == "link")
        s.hidden = true;
    else if (tag == "hr")   { s.display = "block"; }
    else if (tag == "ul" || tag == "ol") { s.margin_top = "16px"; s.margin_bottom = "16px"; }
    else if (tag == "li")   { s.display = "list-item"; }
    else if (tag == "table") { s.display = "table"; }
    else if (tag == "tr")    { s.display = "table-row"; }
    else if (tag == "td" || tag == "th") { s.display = "table-cell"; }
    return s;
}

// ── apply_declarations ────────────────────────────────────────────────────────

void Parser::apply_declarations(ComputedStyle& style,
                                  const std::vector<Declaration>& decls) {
    for (auto& d : decls) {
        if      (d.property == "display")          style.display       = d.value;
        else if (d.property == "color")             style.color         = d.value;
        else if (d.property == "background" ||
                 d.property == "background-color")  style.background    = d.value;
        else if (d.property == "font-weight")       style.font_weight   = d.value;
        else if (d.property == "font-size")         style.font_size     = d.value;
        else if (d.property == "margin-top")        style.margin_top    = d.value;
        else if (d.property == "margin-bottom")     style.margin_bottom = d.value;
        else if (d.property == "text-align")        style.text_align    = d.value;
        else if (d.property == "visibility" && d.value == "hidden") style.hidden = true;
    }
}

// ── compute_style ─────────────────────────────────────────────────────────────

ComputedStyle Parser::compute_style(const StyleSheet&           sheet,
                                      std::string_view             tag_name,
                                      const std::vector<std::string>& class_list,
                                      std::string_view             element_id,
                                      std::string_view             inline_style) {
    // 1. User-agent defaults
    ComputedStyle style = ua_defaults(tag_name);

    // 2. Stylesheet rules (in order — later rules win for same specificity)
    for (auto& rule : sheet.rules) {
        for (auto& sel : rule.selectors) {
            if (selector_matches(sel, tag_name, class_list, element_id)) {
                apply_declarations(style, rule.declarations);
                break;
            }
        }
    }

    // 3. Inline style (highest priority, except !important from sheet)
    if (!inline_style.empty()) {
        auto decls = parse_inline_style(inline_style);
        apply_declarations(style, decls);
    }

    return style;
}

} // namespace css
