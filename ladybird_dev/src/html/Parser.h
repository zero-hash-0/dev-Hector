#pragma once

#include "Token.h"
#include "dom/Document.h"
#include "dom/Element.h"

#include <memory>
#include <vector>
#include <string_view>

namespace html {

// HTML5 tree-construction parser.
// Takes a stream of Token objects and builds a dom::Document.
// Implements a subset of WHATWG HTML §13.2.6 (tree construction).
class Parser {
public:
    // Parse a full HTML document from a string
    static std::shared_ptr<dom::Document> parse(std::string_view html,
                                                  const net::URL& document_url = {});

private:
    explicit Parser(const net::URL& url);

    // Insertion modes (subset of spec)
    enum class InsertionMode {
        Initial,
        BeforeHTML,
        BeforeHead,
        InHead,
        AfterHead,
        InBody,
        InTable,
        InCaption,
        InTableBody,
        InRow,
        InCell,
        InSelect,
        AfterBody,
        AfterAfterBody,
    };

    // Process a token
    void process(Token t);

    void process_initial(Token& t);
    void process_before_html(Token& t);
    void process_before_head(Token& t);
    void process_in_head(Token& t);
    void process_after_head(Token& t);
    void process_in_body(Token& t);
    void process_after_body(Token& t);

    // Stack of open elements helpers
    void push(std::shared_ptr<dom::Element> el);
    void pop();
    [[nodiscard]] dom::Element* current_node() const;
    [[nodiscard]] bool          in_scope(std::string_view tag) const;
    void                        pop_until(std::string_view tag);

    // Insert helpers
    std::shared_ptr<dom::Element> insert_element(std::string tag_name,
                                                   const std::vector<Attribute>& attrs = {});
    void insert_character(char c);
    void insert_comment(const std::string& data);

    // Void elements (self-closing)
    static bool is_void_element(std::string_view tag);
    // Raw text elements (script/style)
    static bool is_raw_text_element(std::string_view tag);

    // Members
    std::shared_ptr<dom::Document>        m_document;
    std::vector<std::shared_ptr<dom::Element>> m_open_elements;
    InsertionMode                          m_mode { InsertionMode::Initial };
    std::shared_ptr<dom::Element>          m_head_element;
    std::string                            m_raw_text_element; // non-empty while inside script/style
};

} // namespace html
