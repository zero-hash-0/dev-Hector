#include "Parser.h"
#include "Tokenizer.h"
#include "dom/Text.h"

#include <algorithm>
#include <stdexcept>

namespace html {

// ── Static helpers ────────────────────────────────────────────────────────────

bool Parser::is_void_element(std::string_view tag) {
    static const std::array<std::string_view, 14> VOID = {
        "area","base","br","col","embed","hr","img","input",
        "link","meta","param","source","track","wbr"
    };
    return std::find(VOID.begin(), VOID.end(), tag) != VOID.end();
}

bool Parser::is_raw_text_element(std::string_view tag) {
    return tag == "script" || tag == "style";
}

// ── Parser construction ───────────────────────────────────────────────────────

Parser::Parser(const net::URL& url) {
    m_document = std::make_shared<dom::Document>();
    m_document->set_url(url);
}

std::shared_ptr<dom::Document> Parser::parse(std::string_view html,
                                               const net::URL& document_url) {
    Parser parser(document_url);

    Tokenizer tokenizer(html, [&parser](Token t) {
        parser.process(std::move(t));
    });
    tokenizer.run();

    return parser.m_document;
}

// ── Stack helpers ─────────────────────────────────────────────────────────────

void Parser::push(std::shared_ptr<dom::Element> el) {
    m_open_elements.push_back(std::move(el));
}

void Parser::pop() {
    if (!m_open_elements.empty())
        m_open_elements.pop_back();
}

dom::Element* Parser::current_node() const {
    if (m_open_elements.empty()) return nullptr;
    return m_open_elements.back().get();
}

bool Parser::in_scope(std::string_view tag) const {
    for (auto it = m_open_elements.rbegin(); it != m_open_elements.rend(); ++it) {
        if ((*it)->tag_name() == tag) return true;
        // Scope boundary elements
        auto& tn = (*it)->tag_name();
        if (tn == "html" || tn == "table" || tn == "template") return false;
    }
    return false;
}

void Parser::pop_until(std::string_view tag) {
    while (!m_open_elements.empty()) {
        bool done = m_open_elements.back()->tag_name() == tag;
        pop();
        if (done) break;
    }
}

// ── Insert helpers ────────────────────────────────────────────────────────────

std::shared_ptr<dom::Element> Parser::insert_element(std::string tag_name,
                                                        const std::vector<Attribute>& attrs) {
    auto el = std::make_shared<dom::Element>(std::move(tag_name));
    for (auto& a : attrs)
        el->set_attr(a.name, a.value);

    if (auto* parent = current_node())
        parent->append_child(el);
    else
        m_document->append_child(el);

    if (!is_void_element(el->tag_name()))
        push(el);

    return el;
}

void Parser::insert_character(char c) {
    auto* parent = current_node();
    if (!parent) return;

    // Coalesce adjacent Text nodes
    auto& children = parent->children();
    if (!children.empty() && children.back()->is_text()) {
        auto* text = static_cast<dom::Text*>(children.back().get());
        text->append_data(std::string_view(&c, 1));
        return;
    }

    parent->append_child(std::make_shared<dom::Text>(std::string(1, c)));
}

void Parser::insert_comment(const std::string& data) {
    (void)data; // comments don't need to be in the DOM for our use case
}

// ── Token processing ──────────────────────────────────────────────────────────

void Parser::process(Token t) {
    switch (m_mode) {
    case InsertionMode::Initial:      process_initial(t);      break;
    case InsertionMode::BeforeHTML:   process_before_html(t);  break;
    case InsertionMode::BeforeHead:   process_before_head(t);  break;
    case InsertionMode::InHead:       process_in_head(t);      break;
    case InsertionMode::AfterHead:    process_after_head(t);   break;
    case InsertionMode::InBody:
    case InsertionMode::InTable:
    case InsertionMode::InTableBody:
    case InsertionMode::InRow:
    case InsertionMode::InCell:
    case InsertionMode::InSelect:     process_in_body(t);      break;
    case InsertionMode::AfterBody:    process_after_body(t);   break;
    case InsertionMode::AfterAfterBody: break;
    default:                          process_in_body(t);      break;
    }
}

void Parser::process_initial(Token& t) {
    if (t.type == TokenType::DOCTYPE) {
        if (t.doctype_name != "html" || t.force_quirks)
            m_document->set_quirks_mode(dom::Document::Mode::Quirks);
        m_mode = InsertionMode::BeforeHTML;
        return;
    }
    // No DOCTYPE — quirks mode
    m_document->set_quirks_mode(dom::Document::Mode::Quirks);
    m_mode = InsertionMode::BeforeHTML;
    process(std::move(t)); // reprocess
}

void Parser::process_before_html(Token& t) {
    if (t.is_start_tag("html")) {
        auto el = std::make_shared<dom::Element>("html");
        for (auto& a : t.attributes) el->set_attr(a.name, a.value);
        m_document->append_child(el);
        push(el);
        m_mode = InsertionMode::BeforeHead;
        return;
    }
    // Implied <html>
    auto el = std::make_shared<dom::Element>("html");
    m_document->append_child(el);
    push(el);
    m_mode = InsertionMode::BeforeHead;
    process(std::move(t));
}

void Parser::process_before_head(Token& t) {
    if (t.type == TokenType::Character && (t.data == " " || t.data == "\n" ||
        t.data == "\t" || t.data == "\r" || t.data == "\f"))
        return; // ignore whitespace

    if (t.is_start_tag("head")) {
        m_head_element = insert_element("head", t.attributes);
        m_mode = InsertionMode::InHead;
        return;
    }
    // Implied <head>
    m_head_element = insert_element("head");
    m_mode = InsertionMode::InHead;
    process(std::move(t));
}

void Parser::process_in_head(Token& t) {
    // Discard raw-text content (script/style) in head too
    if (!m_raw_text_element.empty()) {
        if (t.type == TokenType::EndTag && t.tag_name == m_raw_text_element) {
            if (in_scope(m_raw_text_element))
                pop_until(m_raw_text_element);
            m_raw_text_element.clear();
        }
        return;
    }

    if (t.type == TokenType::Character) {
        // Insert characters only for non-raw-text elements (e.g. <title>)
        if (!t.data.empty()) insert_character(t.data[0]);
        return;
    }
    if (t.type == TokenType::Comment) { insert_comment(t.data); return; }
    if (t.type == TokenType::EndOfFile) return;

    if (t.is_start_tag("meta")) {
        insert_element("meta", t.attributes);
        return;
    }
    if (t.is_start_tag("title") || t.is_start_tag("style") ||
        t.is_start_tag("script") || t.is_start_tag("link")) {
        insert_element(t.tag_name, t.attributes);
        if (is_raw_text_element(t.tag_name))
            m_raw_text_element = t.tag_name;
        return;
    }

    if (t.type == TokenType::EndTag) {
        auto& tag = t.tag_name;
        if (tag == "head") {
            pop(); // pop <head> itself
            m_mode = InsertionMode::AfterHead;
            return;
        }
        // End tags for elements nested inside <head> (title, style, script …)
        if (in_scope(tag))
            pop_until(tag);
        return; // stay in InHead
    }

    // Anything else — close head implicitly, popping everything through <head>
    if (in_scope("head"))
        pop_until("head");
    m_mode = InsertionMode::AfterHead;
    process(std::move(t));
}

void Parser::process_after_head(Token& t) {
    if (t.type == TokenType::Character &&
        (t.data == " " || t.data == "\n" || t.data == "\t")) {
        insert_character(t.data[0]);
        return;
    }
    if (t.is_start_tag("body")) {
        insert_element("body", t.attributes);
        m_mode = InsertionMode::InBody;
        return;
    }
    // Implied <body>
    insert_element("body");
    m_mode = InsertionMode::InBody;
    process(std::move(t));
}

void Parser::process_in_body(Token& t) {
    // While inside a raw-text element, discard all tokens until its closing tag
    if (!m_raw_text_element.empty()) {
        if (t.type == TokenType::EndTag && t.tag_name == m_raw_text_element) {
            if (in_scope(m_raw_text_element))
                pop_until(m_raw_text_element);
            m_raw_text_element.clear();
        }
        return; // discard everything else (characters, nested tags, etc.)
    }

    if (t.type == TokenType::Character) {
        if (!t.data.empty()) insert_character(t.data[0]);
        return;
    }

    if (t.type == TokenType::Comment) { insert_comment(t.data); return; }

    if (t.type == TokenType::EndOfFile) return;

    if (t.type == TokenType::StartTag) {
        auto& tag = t.tag_name;

        // Void elements
        if (is_void_element(tag)) {
            insert_element(tag, t.attributes);
            return;
        }

        insert_element(tag, t.attributes);

        // Enter raw-text mode for script/style so their content isn't parsed
        if (is_raw_text_element(tag))
            m_raw_text_element = tag;

        return;
    }

    if (t.type == TokenType::EndTag) {
        auto& tag = t.tag_name;

        if (tag == "body" || tag == "html") {
            m_mode = InsertionMode::AfterBody;
            return;
        }

        // Pop matching open element
        if (in_scope(tag)) {
            pop_until(tag);
        }
        return;
    }
}

void Parser::process_after_body(Token& t) {
    if (t.is_start_tag("html")) {
        process_in_body(t);
        return;
    }
    if (t.is_end_tag("html")) {
        m_mode = InsertionMode::AfterAfterBody;
        return;
    }
    if (t.type == TokenType::EndOfFile) return;

    // Anything else — back to in_body
    m_mode = InsertionMode::InBody;
    process(std::move(t));
}

} // namespace html
