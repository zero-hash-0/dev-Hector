#pragma once

#include "Node.h"

#include <string>
#include <map>
#include <vector>
#include <optional>
#include <functional>

namespace dom {

class Element : public Node {
public:
    explicit Element(std::string tag_name);

    [[nodiscard]] const std::string& tag_name() const noexcept { return m_tag_name; }

    // Attribute access
    [[nodiscard]] bool        has_attr(std::string_view name)  const;
    [[nodiscard]] std::string get_attr(std::string_view name)  const;
    void                      set_attr(std::string name, std::string value);
    void                      remove_attr(std::string_view name);

    const std::map<std::string, std::string, std::less<>>& attributes() const { return m_attributes; }

    // Queries
    [[nodiscard]] std::optional<std::string> id()        const;
    [[nodiscard]] std::vector<std::string>   class_list() const;

    // Tree queries
    [[nodiscard]] Element*        query_selector(std::string_view tag)  const;
    [[nodiscard]] std::vector<Element*> query_selector_all(std::string_view tag) const;

    // Text content helpers
    [[nodiscard]] std::string text_content() const override;
    [[nodiscard]] std::string inner_text()   const;

private:
    std::string                                      m_tag_name;
    std::map<std::string, std::string, std::less<>>  m_attributes;

    void collect_elements(std::string_view tag, std::vector<Element*>& out) const;
};

} // namespace dom
