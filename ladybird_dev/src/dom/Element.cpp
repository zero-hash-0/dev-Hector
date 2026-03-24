#include "Element.h"
#include "Text.h"

#include <algorithm>
#include <sstream>
#include <cctype>

namespace dom {

Element::Element(std::string tag_name)
    : Node(NodeType::Element), m_tag_name(std::move(tag_name)) {}

bool Element::has_attr(std::string_view name) const {
    return m_attributes.find(name) != m_attributes.end();
}

std::string Element::get_attr(std::string_view name) const {
    if (auto it = m_attributes.find(name); it != m_attributes.end())
        return it->second;
    return {};
}

void Element::set_attr(std::string name, std::string value) {
    // Strip null bytes — prevent attribute injection
    std::erase(name,  '\0');
    std::erase(value, '\0');
    m_attributes[std::move(name)] = std::move(value);
}

void Element::remove_attr(std::string_view name) {
    m_attributes.erase(std::string(name));
}

std::optional<std::string> Element::id() const {
    if (has_attr("id")) return get_attr("id");
    return std::nullopt;
}

std::vector<std::string> Element::class_list() const {
    std::vector<std::string> classes;
    std::istringstream ss(get_attr("class"));
    std::string token;
    while (ss >> token)
        classes.push_back(std::move(token));
    return classes;
}

std::string Element::text_content() const {
    std::string result;
    for (auto& child : m_children)
        result += child->text_content();
    return result;
}

std::string Element::inner_text() const {
    // Simplified: same as text_content for now
    return text_content();
}

void Element::collect_elements(std::string_view tag, std::vector<Element*>& out) const {
    for (auto& child : m_children) {
        if (child->is_element()) {
            auto* el = child->as_element();
            if (tag == "*" || el->tag_name() == tag)
                out.push_back(el);
            el->collect_elements(tag, out);
        }
    }
}

Element* Element::query_selector(std::string_view tag) const {
    for (auto& child : m_children) {
        if (child->is_element()) {
            auto* el = child->as_element();
            if (tag == "*" || el->tag_name() == tag)
                return el;
            if (auto* found = el->query_selector(tag))
                return found;
        }
    }
    return nullptr;
}

std::vector<Element*> Element::query_selector_all(std::string_view tag) const {
    std::vector<Element*> result;
    collect_elements(tag, result);
    return result;
}

} // namespace dom
