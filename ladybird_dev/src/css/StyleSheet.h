#pragma once

#include <string>
#include <vector>
#include <map>

namespace css {

// A single CSS declaration: property + value
struct Declaration {
    std::string property;
    std::string value;
    bool        important { false };
};

// A CSS rule: selector list + declaration block
struct Rule {
    std::vector<std::string> selectors;
    std::vector<Declaration> declarations;
};

// A parsed stylesheet
struct StyleSheet {
    std::vector<Rule> rules;
};

// Computed style for a DOM node (subset of properties we care about)
struct ComputedStyle {
    std::string display       { "block" };
    std::string color         { "inherit" };
    std::string background    { "transparent" };
    std::string font_weight   { "normal" };
    std::string font_size     { "16px" };
    std::string margin_top    { "0" };
    std::string margin_bottom { "0" };
    std::string text_align    { "left" };
    bool        hidden        { false };

    [[nodiscard]] bool is_inline() const { return display == "inline" || display == "inline-block"; }
    [[nodiscard]] bool is_block()  const { return display == "block" || display == "flex" || display == "grid"; }
};

} // namespace css
