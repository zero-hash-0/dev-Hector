#pragma once

#include <string>
#include <vector>
#include <memory>
#include <string_view>

namespace dom {

enum class NodeType {
    Document    = 9,
    Element     = 1,
    Text        = 3,
    Comment     = 8,
    DocumentType= 10,
};

class Document;
class Element;

class Node {
public:
    explicit Node(NodeType type) : m_type(type) {}
    virtual ~Node() = default;

    // Non-copyable — DOM nodes are reference-counted
    Node(const Node&)            = delete;
    Node& operator=(const Node&) = delete;

    [[nodiscard]] NodeType type()   const noexcept { return m_type; }
    [[nodiscard]] Node*    parent() const noexcept { return m_parent; }

    // Tree navigation
    [[nodiscard]] const std::vector<std::shared_ptr<Node>>& children() const { return m_children; }
    [[nodiscard]] Node* first_child() const;
    [[nodiscard]] Node* last_child()  const;
    [[nodiscard]] Node* next_sibling() const;

    // Tree mutation
    void append_child(std::shared_ptr<Node> child);
    void remove_child(Node* child);

    // Serialise subtree to text (used by renderer)
    [[nodiscard]] virtual std::string text_content() const;

    // Type checks
    [[nodiscard]] bool is_element()  const noexcept { return m_type == NodeType::Element; }
    [[nodiscard]] bool is_text()     const noexcept { return m_type == NodeType::Text; }
    [[nodiscard]] bool is_document() const noexcept { return m_type == NodeType::Document; }

    // Downcasts — safe, checked at runtime
    [[nodiscard]] Element*        as_element();
    [[nodiscard]] const Element*  as_element() const;

protected:
    NodeType                           m_type;
    Node*                              m_parent   { nullptr };
    std::vector<std::shared_ptr<Node>> m_children {};
};

} // namespace dom
