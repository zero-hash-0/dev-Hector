#pragma once

#include "Node.h"
#include "net/URL.h"

#include <string>
#include <optional>

namespace dom {

class Element;

class Document : public Node {
public:
    Document();

    // The URL this document was loaded from
    [[nodiscard]] const net::URL& url()             const noexcept { return m_url; }
    void                          set_url(net::URL u)              { m_url = std::move(u); }

    [[nodiscard]] std::string     title()           const;
    [[nodiscard]] std::string     charset()         const noexcept { return m_charset; }
    void                          set_charset(std::string cs)      { m_charset = std::move(cs); }

    // Root <html> element
    [[nodiscard]] Element*        document_element() const;
    [[nodiscard]] Element*        head()             const;
    [[nodiscard]] Element*        body()             const;

    // Convenience queries
    [[nodiscard]] Element*        get_element_by_id(std::string_view id) const;
    [[nodiscard]] std::vector<Element*> get_elements_by_tag(std::string_view tag) const;

    // Quirks mode (set when DOCTYPE is missing or invalid)
    enum class Mode { NoQuirks, Quirks, LimitedQuirks };
    [[nodiscard]] Mode    quirks_mode() const noexcept { return m_quirks_mode; }
    void                  set_quirks_mode(Mode m)      { m_quirks_mode = m; }

private:
    Element* find_first(std::string_view tag) const;
    void     collect_by_id(const Node* n, std::string_view id, Element*& out) const;

    net::URL    m_url         {};
    std::string m_charset     { "utf-8" };
    Mode        m_quirks_mode { Mode::NoQuirks };
};

} // namespace dom
