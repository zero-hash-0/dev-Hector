#pragma once

#include <string>
#include <string_view>
#include <vector>
#include <stdexcept>

namespace js {

enum class TK {
    // Literals
    Number, String,
    // Identifier / keywords
    Identifier,
    KwVar, KwLet, KwConst,
    KwFunction, KwReturn,
    KwIf, KwElse,
    KwWhile, KwFor, KwBreak, KwContinue,
    KwTrue, KwFalse, KwNull,
    KwTypeof, KwVoid,
    // Operators
    Plus, Minus, Star, Slash, Percent,
    PlusPlus, MinusMinus,
    Eq,
    EqEq, EqEqEq,
    Bang, BangEq, BangEqEq,
    Lt, LtEq,
    Gt, GtEq,
    AmpAmp, PipePipe,
    PlusEq, MinusEq, StarEq, SlashEq,
    // Punctuation
    LParen, RParen,
    LBrace, RBrace,
    LBracket, RBracket,
    Semi, Comma, Dot,
    // End
    Eof,
};

struct Token {
    TK          kind;
    std::string text;
    size_t      line { 1 };
};

class LexError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

class Lexer {
public:
    explicit Lexer(std::string_view src);

    [[nodiscard]] std::vector<Token> tokenize();

private:
    [[nodiscard]] char peek(size_t offset = 0) const noexcept;
    char               advance() noexcept;
    bool               match(char c) noexcept;
    void               skip_whitespace_and_comments();
    Token              make(TK kind, std::string text = {});
    Token              lex_number();
    Token              lex_string(char quote);
    Token              lex_ident_or_kw();

    std::string_view m_src;
    size_t           m_pos  { 0 };
    size_t           m_line { 1 };
};

} // namespace js
