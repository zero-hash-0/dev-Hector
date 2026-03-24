#pragma once

#include "StyleSheet.h"

#include <string>
#include <string_view>

namespace css {

class Parser {
public:
    // Parse a full stylesheet
    static StyleSheet parse_stylesheet(std::string_view css);

    // Parse an inline style attribute value into declarations
    static std::vector<Declaration> parse_inline_style(std::string_view style);

    // Compute a style for an element given tag name, class list, id, and inline style.
    // Cascades: user-agent defaults → stylesheet → inline
    static ComputedStyle compute_style(const StyleSheet&           sheet,
                                        std::string_view             tag_name,
                                        const std::vector<std::string>& class_list,
                                        std::string_view             element_id,
                                        std::string_view             inline_style);

private:
    static bool selector_matches(std::string_view selector,
                                   std::string_view tag_name,
                                   const std::vector<std::string>& class_list,
                                   std::string_view id);
    static void apply_declarations(ComputedStyle&              style,
                                    const std::vector<Declaration>& decls);
};

} // namespace css
