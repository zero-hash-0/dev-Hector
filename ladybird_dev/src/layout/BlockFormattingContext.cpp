#include "BlockFormattingContext.h"
#include "dom/Element.h"
#include "dom/Text.h"

#include <algorithm>
#include <cctype>

namespace layout {

std::string BlockFormattingContext::normalise_whitespace(std::string_view text) {
    std::string result;
    bool last_space = true; // collapse leading whitespace
    for (char c : text) {
        if (std::isspace(static_cast<unsigned char>(c))) {
            if (!last_space) { result += ' '; last_space = true; }
        } else {
            result += c;
            last_space = false;
        }
    }
    // Trim trailing space
    if (!result.empty() && result.back() == ' ')
        result.pop_back();
    return result;
}

std::unique_ptr<LayoutBox> BlockFormattingContext::build(const dom::Document& document,
                                                           const css::StyleSheet& sheet) {
    auto root = std::make_unique<LayoutBox>(BoxType::Block, nullptr, css::ComputedStyle{});

    for (auto& child : document.children()) {
        if (auto box = build_for_node(*child, sheet))
            root->add_child(std::move(box));
    }

    return root;
}

std::unique_ptr<LayoutBox> BlockFormattingContext::build_for_node(const dom::Node& node,
                                                                    const css::StyleSheet& sheet) {
    if (node.is_text()) {
        auto& t = static_cast<const dom::Text&>(node);
        std::string text = normalise_whitespace(t.data());
        if (text.empty()) return nullptr;
        css::ComputedStyle style;
        style.display = "inline";
        auto box = std::make_unique<LayoutBox>(BoxType::Text, const_cast<dom::Node*>(&node), style);
        box->set_text(std::move(text));
        return box;
    }

    if (!node.is_element()) return nullptr;

    return build_for_element(static_cast<const dom::Element&>(node), sheet);
}

std::unique_ptr<LayoutBox> BlockFormattingContext::build_for_element(
    const dom::Element& el, const css::StyleSheet& sheet)
{
    auto classes = el.class_list();
    auto id      = el.get_attr("id");
    auto style   = css::Parser::compute_style(
        sheet, el.tag_name(), classes, id, el.get_attr("style"));

    if (style.hidden) return nullptr;

    BoxType btype = style.is_inline() ? BoxType::Inline : BoxType::Block;
    auto box = std::make_unique<LayoutBox>(btype, const_cast<dom::Element*>(&el), style);

    for (auto& child : el.children()) {
        if (auto child_box = build_for_node(*child, sheet))
            box->add_child(std::move(child_box));
    }

    return box;
}

} // namespace layout
