#include "Tokenizer.h"

#include <algorithm>
#include <cctype>
#include <cassert>

namespace html {

static bool is_ascii_alpha(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}
static bool is_ascii_upper(char c) { return c >= 'A' && c <= 'Z'; }
static char to_ascii_lower(char c) {
    return is_ascii_upper(c) ? static_cast<char>(c + 0x20) : c;
}
static bool is_whitespace(char c) {
    return c == '\t' || c == '\n' || c == '\f' || c == ' ';
}

// ── Construction ──────────────────────────────────────────────────────────────

Tokenizer::Tokenizer(std::string_view input, TokenCallback callback)
    : m_input(input), m_callback(std::move(callback)) {}

// ── Input helpers ─────────────────────────────────────────────────────────────

std::optional<char> Tokenizer::current_char() const {
    if (m_pos >= m_input.size()) return std::nullopt;
    return m_input[m_pos];
}

std::optional<char> Tokenizer::peek(size_t offset) const {
    size_t idx = m_pos + offset;
    if (idx >= m_input.size()) return std::nullopt;
    return m_input[idx];
}

void Tokenizer::advance() {
    ++m_pos; // unsigned: SIZE_MAX+1 wraps to 0 on first call
}

void Tokenizer::reconsume() {
    m_reconsume = true;
}

bool Tokenizer::consume_if(std::string_view s) {
    if (m_pos + s.size() > m_input.size()) return false;
    if (m_input.substr(m_pos, s.size()) == s) {
        m_pos += s.size();
        return true;
    }
    return false;
}

// ── Emission ──────────────────────────────────────────────────────────────────

void Tokenizer::emit(Token t) {
    m_callback(std::move(t));
}

void Tokenizer::emit_current_tag() {
    // Sanitise attribute values: strip null bytes
    for (auto& attr : m_current_token.attributes) {
        std::erase(attr.name,  '\0');
        std::erase(attr.value, '\0');
    }
    emit(std::move(m_current_token));
    m_current_token = {};
}

void Tokenizer::emit_character(char c) {
    Token t;
    t.type = TokenType::Character;
    t.data = std::string(1, c);
    emit(std::move(t));
}

void Tokenizer::emit_eof() {
    if (m_eof_emitted) return;
    m_eof_emitted = true;
    Token t;
    t.type = TokenType::EndOfFile;
    emit(std::move(t));
}

// ── Main loop ─────────────────────────────────────────────────────────────────

void Tokenizer::run() {
    while (true) {
        if (!m_reconsume) advance();
        m_reconsume = false;

        switch (m_state) {
        case State::Data:                     handle_data();                      break;
        case State::TagOpen:                  handle_tag_open();                  break;
        case State::EndTagOpen:               handle_end_tag_open();              break;
        case State::TagName:                  handle_tag_name();                  break;
        case State::BeforeAttributeName:      handle_before_attribute_name();     break;
        case State::AttributeName:            handle_attribute_name();            break;
        case State::AfterAttributeName:       handle_after_attribute_name();      break;
        case State::BeforeAttributeValue:     handle_before_attribute_value();    break;
        case State::AttributeValueDoubleQuoted: handle_attribute_value_double_quoted(); break;
        case State::AttributeValueSingleQuoted: handle_attribute_value_single_quoted(); break;
        case State::AttributeValueUnquoted:   handle_attribute_value_unquoted();  break;
        case State::AfterAttributeValueQuoted: handle_after_attribute_value_quoted(); break;
        case State::SelfClosingStartTag:      handle_self_closing_start_tag();    break;
        case State::BogusComment:             handle_bogus_comment();             break;
        case State::MarkupDeclarationOpen:    handle_markup_declaration_open();   break;
        case State::CommentStart:
        case State::CommentStartDash:
        case State::Comment:
        case State::CommentEndDash:
        case State::CommentEnd:
        case State::CommentEndBang:           handle_comment_states();            break;
        case State::DOCTYPE:
        case State::BeforeDOCTYPEName:
        case State::DOCTYPEName:
        case State::AfterDOCTYPEName:         handle_doctype_states();            break;
        default:
            // Unhandled state — treat remaining input as data
            handle_data();
            break;
        }

        if (!current_char().has_value() && !m_reconsume)
            break;
    }

    emit_eof();
}

// ── State handlers ────────────────────────────────────────────────────────────

void Tokenizer::handle_data() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (*c == '<') {
        m_state = State::TagOpen;
    } else if (*c == '\0') {
        // Parse error: null character — emit replacement
        emit_character(static_cast<char>(0xFD)); // replacement char (U+FFFD low byte)
    } else {
        emit_character(*c);
    }
}

void Tokenizer::handle_tag_open() {
    auto c = current_char();
    if (!c) {
        emit_character('<');
        reconsume();
        m_state = State::Data;
        return;
    }

    if (*c == '!') {
        m_state = State::MarkupDeclarationOpen;
    } else if (*c == '/') {
        m_state = State::EndTagOpen;
    } else if (is_ascii_alpha(*c)) {
        m_current_token       = {};
        m_current_token.type  = TokenType::StartTag;
        reconsume();
        m_state = State::TagName;
    } else if (*c == '?') {
        m_current_token       = {};
        m_current_token.type  = TokenType::Comment;
        reconsume();
        m_state = State::BogusComment;
    } else {
        emit_character('<');
        reconsume();
        m_state = State::Data;
    }
}

void Tokenizer::handle_end_tag_open() {
    auto c = current_char();
    if (!c) {
        emit_character('<');
        emit_character('/');
        m_state = State::Data;
        return;
    }

    if (is_ascii_alpha(*c)) {
        m_current_token      = {};
        m_current_token.type = TokenType::EndTag;
        reconsume();
        m_state = State::TagName;
    } else if (*c == '>') {
        m_state = State::Data; // parse error, ignore
    } else {
        m_current_token      = {};
        m_current_token.type = TokenType::Comment;
        reconsume();
        m_state = State::BogusComment;
    }
}

void Tokenizer::handle_tag_name() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (is_whitespace(*c)) {
        m_state = State::BeforeAttributeName;
    } else if (*c == '/') {
        m_state = State::SelfClosingStartTag;
    } else if (*c == '>') {
        m_state = State::Data;
        emit_current_tag();
    } else if (*c == '\0') {
        m_current_token.tag_name += '\xEF'; // replacement char (simplified)
    } else {
        m_current_token.tag_name += to_ascii_lower(*c);
    }
}

void Tokenizer::handle_before_attribute_name() {
    auto c = current_char();
    if (!c) { reconsume(); m_state = State::AfterAttributeName; return; }

    if (is_whitespace(*c)) {
        // ignore
    } else if (*c == '/' || *c == '>') {
        reconsume();
        m_state = State::AfterAttributeName;
    } else if (*c == '=') {
        // parse error — start new attr with "=" as name
        m_current_token.attributes.push_back({ "=", {} });
        m_state = State::AttributeName;
    } else {
        m_current_token.attributes.push_back({});
        reconsume();
        m_state = State::AttributeName;
    }
}

void Tokenizer::handle_attribute_name() {
    auto c = current_char();
    if (!c) { reconsume(); m_state = State::AfterAttributeName; return; }

    if (is_whitespace(*c) || *c == '/' || *c == '>') {
        reconsume();
        m_state = State::AfterAttributeName;
    } else if (*c == '=') {
        m_state = State::BeforeAttributeValue;
    } else if (*c == '\0') {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().name += '\xEF';
    } else {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().name += to_ascii_lower(*c);
    }
}

void Tokenizer::handle_after_attribute_name() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (is_whitespace(*c)) {
        // ignore
    } else if (*c == '/') {
        m_state = State::SelfClosingStartTag;
    } else if (*c == '=') {
        m_state = State::BeforeAttributeValue;
    } else if (*c == '>') {
        m_state = State::Data;
        emit_current_tag();
    } else {
        m_current_token.attributes.push_back({});
        reconsume();
        m_state = State::AttributeName;
    }
}

void Tokenizer::handle_before_attribute_value() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (is_whitespace(*c)) {
        // ignore
    } else if (*c == '"') {
        m_state = State::AttributeValueDoubleQuoted;
    } else if (*c == '\'') {
        m_state = State::AttributeValueSingleQuoted;
    } else if (*c == '>') {
        m_state = State::Data;
        emit_current_tag();
    } else {
        reconsume();
        m_state = State::AttributeValueUnquoted;
    }
}

void Tokenizer::handle_attribute_value_double_quoted() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (*c == '"') {
        m_state = State::AfterAttributeValueQuoted;
    } else if (*c == '\0') {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().value += '\xEF';
    } else {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().value += *c;
    }
}

void Tokenizer::handle_attribute_value_single_quoted() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (*c == '\'') {
        m_state = State::AfterAttributeValueQuoted;
    } else if (*c == '\0') {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().value += '\xEF';
    } else {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().value += *c;
    }
}

void Tokenizer::handle_attribute_value_unquoted() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (is_whitespace(*c)) {
        m_state = State::BeforeAttributeName;
    } else if (*c == '>') {
        m_state = State::Data;
        emit_current_tag();
    } else if (*c == '\0') {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().value += '\xEF';
    } else {
        if (!m_current_token.attributes.empty())
            m_current_token.attributes.back().value += *c;
    }
}

void Tokenizer::handle_after_attribute_value_quoted() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (is_whitespace(*c)) {
        m_state = State::BeforeAttributeName;
    } else if (*c == '/') {
        m_state = State::SelfClosingStartTag;
    } else if (*c == '>') {
        m_state = State::Data;
        emit_current_tag();
    } else {
        reconsume();
        m_state = State::BeforeAttributeName;
    }
}

void Tokenizer::handle_self_closing_start_tag() {
    auto c = current_char();
    if (!c) { emit_eof(); return; }

    if (*c == '>') {
        m_current_token.self_closing = true;
        m_state = State::Data;
        emit_current_tag();
    } else {
        reconsume();
        m_state = State::BeforeAttributeName;
    }
}

void Tokenizer::handle_bogus_comment() {
    auto c = current_char();
    if (!c) {
        emit(std::move(m_current_token));
        m_current_token = {};
        emit_eof();
        return;
    }

    if (*c == '>') {
        m_state = State::Data;
        emit(std::move(m_current_token));
        m_current_token = {};
    } else if (*c == '\0') {
        m_current_token.data += '\xEF';
    } else {
        m_current_token.data += *c;
    }
}

void Tokenizer::handle_markup_declaration_open() {
    // Peek ahead to determine DOCTYPE vs comment vs CDATA
    if (m_pos + 1 < m_input.size() && m_input[m_pos] == '-' && m_input[m_pos + 1] == '-') {
        // Consume only the second '-'; the loop's advance() at the end of this
        // iteration will move past it to the first comment content character.
        m_pos += 1;
        m_current_token      = {};
        m_current_token.type = TokenType::Comment;
        m_state = State::CommentStart;
    } else if (m_pos + 6 < m_input.size()) {
        std::string candidate(m_input.substr(m_pos, 7));
        std::transform(candidate.begin(), candidate.end(), candidate.begin(),
                       [](unsigned char c){ return static_cast<char>(std::tolower(c)); });
        if (candidate == "doctype") {
            m_pos += 7;
            m_current_token      = {};
            m_current_token.type = TokenType::DOCTYPE;
            m_state = State::DOCTYPE;
        } else {
            m_current_token      = {};
            m_current_token.type = TokenType::Comment;
            m_state = State::BogusComment;
        }
    } else {
        m_current_token      = {};
        m_current_token.type = TokenType::Comment;
        m_state = State::BogusComment;
    }
}

void Tokenizer::handle_comment_states() {
    auto c = current_char();
    if (!c) {
        emit(std::move(m_current_token));
        m_current_token = {};
        emit_eof();
        return;
    }

    switch (m_state) {
    case State::CommentStart:
        if (*c == '-')      m_state = State::CommentStartDash;
        else if (*c == '>') { m_state = State::Data; emit(std::move(m_current_token)); m_current_token = {}; }
        else                { reconsume(); m_state = State::Comment; }
        break;

    case State::CommentStartDash:
        if (*c == '-')      m_state = State::CommentEnd;
        else if (*c == '>') { m_state = State::Data; emit(std::move(m_current_token)); m_current_token = {}; }
        else                { m_current_token.data += '-'; reconsume(); m_state = State::Comment; }
        break;

    case State::Comment:
        if (*c == '<')      { m_current_token.data += *c; /* CommentLessThan — simplified */ }
        else if (*c == '-') m_state = State::CommentEndDash;
        else if (*c == '\0') m_current_token.data += '\xEF';
        else                m_current_token.data += *c;
        break;

    case State::CommentEndDash:
        if (*c == '-')      m_state = State::CommentEnd;
        else                { m_current_token.data += '-'; reconsume(); m_state = State::Comment; }
        break;

    case State::CommentEnd:
        if (*c == '>')      { m_state = State::Data; emit(std::move(m_current_token)); m_current_token = {}; }
        else if (*c == '!') m_state = State::CommentEndBang;
        else if (*c == '-') m_current_token.data += '-';
        else                { m_current_token.data += "--"; reconsume(); m_state = State::Comment; }
        break;

    case State::CommentEndBang:
        if (*c == '-')      { m_current_token.data += "--!"; m_state = State::CommentEndDash; }
        else if (*c == '>') { m_state = State::Data; emit(std::move(m_current_token)); m_current_token = {}; }
        else                { m_current_token.data += "--!"; reconsume(); m_state = State::Comment; }
        break;

    default: break;
    }
}

void Tokenizer::handle_doctype_states() {
    auto c = current_char();
    if (!c) {
        m_current_token.force_quirks = true;
        emit(std::move(m_current_token));
        m_current_token = {};
        emit_eof();
        return;
    }

    switch (m_state) {
    case State::DOCTYPE:
        if (is_whitespace(*c)) m_state = State::BeforeDOCTYPEName;
        else if (*c == '>')    { m_current_token.force_quirks = true; m_state = State::Data; emit(std::move(m_current_token)); m_current_token = {}; }
        else                   { reconsume(); m_state = State::BeforeDOCTYPEName; }
        break;

    case State::BeforeDOCTYPEName:
        if (is_whitespace(*c)) break;
        if (*c == '>') {
            m_current_token.force_quirks = true;
            m_state = State::Data;
            emit(std::move(m_current_token));
            m_current_token = {};
        } else {
            m_current_token.doctype_name += to_ascii_lower(*c);
            m_state = State::DOCTYPEName;
        }
        break;

    case State::DOCTYPEName:
        if (is_whitespace(*c))  m_state = State::AfterDOCTYPEName;
        else if (*c == '>')     { m_state = State::Data; emit(std::move(m_current_token)); m_current_token = {}; }
        else if (*c == '\0')    m_current_token.doctype_name += '\xEF';
        else                    m_current_token.doctype_name += to_ascii_lower(*c);
        break;

    case State::AfterDOCTYPEName:
        if (is_whitespace(*c)) break;
        if (*c == '>') {
            m_state = State::Data;
            emit(std::move(m_current_token));
            m_current_token = {};
        }
        // PUBLIC/SYSTEM identifiers — simplified: just skip to >
        break;

    default: break;
    }
}

} // namespace html
