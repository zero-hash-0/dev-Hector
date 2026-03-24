#pragma once

#include "dom/Node.h"
#include "css/StyleSheet.h"

#include <memory>
#include <vector>
#include <string>

namespace layout {

enum class BoxType { Block, Inline, AnonymousBlock, Text };

struct Rect {
    float x { 0 }, y { 0 }, width { 0 }, height { 0 };
};

class LayoutBox {
public:
    LayoutBox(BoxType type, dom::Node* node, css::ComputedStyle style)
        : m_type(type), m_node(node), m_style(std::move(style)) {}

    [[nodiscard]] BoxType                type()       const noexcept { return m_type; }
    [[nodiscard]] dom::Node*             node()       const noexcept { return m_node; }
    [[nodiscard]] const css::ComputedStyle& style()   const noexcept { return m_style; }
    [[nodiscard]] const Rect&            geometry()   const noexcept { return m_geometry; }
    [[nodiscard]] Rect&                  geometry()         noexcept { return m_geometry; }

    [[nodiscard]] const std::vector<std::unique_ptr<LayoutBox>>& children() const { return m_children; }

    LayoutBox* add_child(std::unique_ptr<LayoutBox> child);

    // Text content (for Text nodes)
    [[nodiscard]] const std::string& text() const noexcept { return m_text; }
    void set_text(std::string t) { m_text = std::move(t); }

private:
    BoxType                                 m_type;
    dom::Node*                              m_node     { nullptr };
    css::ComputedStyle                      m_style    {};
    Rect                                    m_geometry {};
    std::vector<std::unique_ptr<LayoutBox>> m_children {};
    std::string                             m_text     {};
};

} // namespace layout
