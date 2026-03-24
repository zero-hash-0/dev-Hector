#include "Document.h"
#include "Element.h"
#include "Text.h"

namespace dom {

Document::Document() : Node(NodeType::Document) {}

Element* Document::document_element() const {
    return find_first("html");
}

Element* Document::head() const {
    auto* html = document_element();
    if (!html) return nullptr;
    return html->query_selector("head");
}

Element* Document::body() const {
    auto* html = document_element();
    if (!html) return nullptr;
    return html->query_selector("body");
}

std::string Document::title() const {
    auto* h = head();
    if (!h) return {};
    auto* title = h->query_selector("title");
    if (!title) return {};
    return title->text_content();
}

Element* Document::find_first(std::string_view tag) const {
    for (auto& child : m_children) {
        if (child->is_element()) {
            auto* el = child->as_element();
            if (el->tag_name() == tag) return el;
        }
    }
    return nullptr;
}

void Document::collect_by_id(const Node* n, std::string_view id, Element*& out) const {
    if (out) return;
    for (auto& child : n->children()) {
        if (child->is_element()) {
            auto* el = child->as_element();
            if (el->get_attr("id") == id) { out = el; return; }
            collect_by_id(el, id, out);
        }
    }
}

Element* Document::get_element_by_id(std::string_view id) const {
    Element* result = nullptr;
    collect_by_id(this, id, result);
    return result;
}

std::vector<Element*> Document::get_elements_by_tag(std::string_view tag) const {
    std::vector<Element*> result;
    auto* html = document_element();
    if (html) {
        if (tag == "*" || html->tag_name() == tag) result.push_back(html);
        for (auto* el : html->query_selector_all(tag)) result.push_back(el);
    }
    return result;
}

} // namespace dom
