#include "Node.h"
#include "Element.h"
#include "Text.h"

#include <stdexcept>
#include <algorithm>

namespace dom {

void Node::append_child(std::shared_ptr<Node> child) {
    if (!child) throw std::invalid_argument("append_child: null node");
    if (child->m_parent)
        child->m_parent->remove_child(child.get());
    child->m_parent = this;
    m_children.push_back(std::move(child));
}

void Node::remove_child(Node* child) {
    auto it = std::find_if(m_children.begin(), m_children.end(),
                            [child](const auto& p){ return p.get() == child; });
    if (it == m_children.end()) return;
    (*it)->m_parent = nullptr;
    m_children.erase(it);
}

Node* Node::first_child() const {
    return m_children.empty() ? nullptr : m_children.front().get();
}

Node* Node::last_child() const {
    return m_children.empty() ? nullptr : m_children.back().get();
}

Node* Node::next_sibling() const {
    if (!m_parent) return nullptr;
    auto& siblings = m_parent->m_children;
    for (size_t i = 0; i + 1 < siblings.size(); ++i) {
        if (siblings[i].get() == this)
            return siblings[i + 1].get();
    }
    return nullptr;
}

std::string Node::text_content() const {
    std::string result;
    for (auto& child : m_children)
        result += child->text_content();
    return result;
}

Element* Node::as_element() {
    if (m_type != NodeType::Element) return nullptr;
    return static_cast<Element*>(this);
}

const Element* Node::as_element() const {
    if (m_type != NodeType::Element) return nullptr;
    return static_cast<const Element*>(this);
}

} // namespace dom
