#pragma once

#include "Token.h"

#include <string>
#include <string_view>
#include <functional>
#include <optional>

namespace html {

// HTML5 tokenizer following WHATWG HTML Living Standard §13.2.5.
// Produces a stream of Token objects via a callback.
class Tokenizer {
public:
    using TokenCallback = std::function<void(Token)>;

    explicit Tokenizer(std::string_view input, TokenCallback callback);

    // Run tokenization to completion
    void run();

private:
    // ── State machine states ─────────────────────────────────────────────────
    enum class State {
        Data,
        RCDATA,
        RAWTEXT,
        ScriptData,
        PLAINTEXT,
        TagOpen,
        EndTagOpen,
        TagName,
        RCDATALessThanSign,
        RCDATAEndTagOpen,
        RCDATAEndTagName,
        RAWTEXTLessThanSign,
        RAWTEXTEndTagOpen,
        RAWTEXTEndTagName,
        BeforeAttributeName,
        AttributeName,
        AfterAttributeName,
        BeforeAttributeValue,
        AttributeValueDoubleQuoted,
        AttributeValueSingleQuoted,
        AttributeValueUnquoted,
        AfterAttributeValueQuoted,
        SelfClosingStartTag,
        BogusComment,
        MarkupDeclarationOpen,
        CommentStart,
        CommentStartDash,
        Comment,
        CommentEndDash,
        CommentEnd,
        CommentEndBang,
        DOCTYPE,
        BeforeDOCTYPEName,
        DOCTYPEName,
        AfterDOCTYPEName,
    };

    // ── Input helpers ────────────────────────────────────────────────────────
    [[nodiscard]] std::optional<char> current_char() const;
    [[nodiscard]] std::optional<char> peek(size_t offset = 1) const;
    void                              advance();
    void                              reconsume();
    bool                              consume_if(std::string_view s);

    // ── Emission ─────────────────────────────────────────────────────────────
    void emit(Token t);
    void emit_current_tag();
    void emit_character(char c);
    void emit_eof();

    // ── Per-state handlers ───────────────────────────────────────────────────
    void handle_data();
    void handle_tag_open();
    void handle_end_tag_open();
    void handle_tag_name();
    void handle_before_attribute_name();
    void handle_attribute_name();
    void handle_after_attribute_name();
    void handle_before_attribute_value();
    void handle_attribute_value_double_quoted();
    void handle_attribute_value_single_quoted();
    void handle_attribute_value_unquoted();
    void handle_after_attribute_value_quoted();
    void handle_self_closing_start_tag();
    void handle_bogus_comment();
    void handle_markup_declaration_open();
    void handle_comment_states();
    void handle_doctype_states();

    // ── Members ──────────────────────────────────────────────────────────────
    std::string_view m_input;
    // Initialised to SIZE_MAX so the first advance() wraps to 0 (unsigned overflow
    // is well-defined in C++) — this lets the run() loop uniformly advance before
    // each state handler without special-casing the very first character.
    size_t           m_pos       { static_cast<size_t>(-1) };
    bool             m_reconsume   { false };
    bool             m_eof_emitted { false };
    State            m_state     { State::Data };
    TokenCallback    m_callback;

    // Current token being built
    Token   m_current_token;
    // Temp buffer for end tag name matching in RCDATA/RAWTEXT
    std::string m_temp_buffer;
};

} // namespace html
