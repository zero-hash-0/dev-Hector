#pragma once

#include "LayoutBox.h"
#include "dom/Document.h"
#include "css/StyleSheet.h"
#include "css/Parser.h"

#include <memory>

namespace layout {

// Builds a layout tree from a DOM document.
// Strips hidden elements, flattens whitespace, and assigns BoxType.
class BlockFormattingContext {
public:
    static std::unique_ptr<LayoutBox> build(const dom::Document& document,
                                             const css::StyleSheet& sheet);

private:
    static std::unique_ptr<LayoutBox> build_for_node(const dom::Node& node,
                                                       const css::StyleSheet& sheet);
    static std::unique_ptr<LayoutBox> build_for_element(const dom::Element& el,
                                                          const css::StyleSheet& sheet);
    static std::string                 normalise_whitespace(std::string_view text);
};

} // namespace layout
