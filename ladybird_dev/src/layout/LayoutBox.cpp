#include "LayoutBox.h"

namespace layout {

LayoutBox* LayoutBox::add_child(std::unique_ptr<LayoutBox> child) {
    m_children.push_back(std::move(child));
    return m_children.back().get();
}

} // namespace layout
