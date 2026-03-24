#include "js/Lexer.h"

#include <cctype>
#include <unordered_map>

namespace js {

static const std::unordered_map<std::string, TK> KEYWORDS = {
    {"var",      TK::KwVar},      {"let",      TK::KwLet},
    {"const",    TK::KwConst},    {"function", TK::KwFunction},
    {"return",   TK::KwReturn},   {"if",       TK::KwIf},
    {"else",     TK::KwElse},     {"while",    TK::KwWhile},
    {"for",      TK::KwFor},      {"break",    TK::KwBreak},
    {"continue", TK::KwContinue}, {"true",     TK::KwTrue},
    {"false",    TK::KwFalse},    {"null",     TK::KwNull},
    {"typeof",   TK::KwTypeof},   {"void",     TK::KwVoid},
};

Lexer::Lexer(std::string_view src) : m_src(src) {}

char Lexer::peek(size_t offset) const noexcept {
    size_t idx = m_pos + offset;
    return idx < m_src.size() ? m_src[idx] : '\0';
}

char Lexer::advance() noexcept {
    char c = m_src[m_pos++];
    if (c == '\n') ++m_line;
    return c;
}

bool Lexer::match(char c) noexcept {
    if (m_pos < m_src.size() && m_src[m_pos] == c) {
        ++m_pos;
        return true;
    }
    return false;
}

void Lexer::skip_whitespace_and_comments() {
    while (m_pos < m_src.size()) {
        char c = peek();
        if (std::isspace(static_cast<unsigned char>(c))) {
            advance();
        } else if (c == '/' && peek(1) == '/') {
            while (m_pos < m_src.size() && peek() != '\n') advance();
        } else if (c == '/' && peek(1) == '*') {
            advance(); advance();
            while (m_pos + 1 < m_src.size() && !(peek() == '*' && peek(1) == '/'))
                advance();
            if (m_pos + 1 < m_src.size()) { advance(); advance(); }
        } else {
            break;
        }
    }
}

Token Lexer::make(TK kind, std::string text) {
    return Token{ kind, std::move(text), m_line };
}

Token Lexer::lex_number() {
    size_t start = m_pos - 1;
    bool dot_seen = false;
    while (m_pos < m_src.size()) {
        char c = peek();
        if (std::isdigit(static_cast<unsigned char>(c))) { advance(); }
        else if (c == '.' && !dot_seen) { dot_seen = true; advance(); }
        else break;
    }
    return make(TK::Number, std::string(m_src.substr(start, m_pos - start)));
}

Token Lexer::lex_string(char q) {
    std::string result;
    while (m_pos < m_src.size() && peek() != q) {
        char c = advance();
        if (c == '\\') {
            char esc = (m_pos < m_src.size()) ? advance() : '\\';
            switch (esc) {
                case 'n': result += '\n'; break;
                case 't': result += '\t'; break;
                case 'r': result += '\r'; break;
                default:  result += esc;  break;
            }
        } else {
            result += c;
        }
    }
    if (m_pos < m_src.size()) advance(); // closing quote
    return make(TK::String, std::move(result));
}

Token Lexer::lex_ident_or_kw() {
    size_t start = m_pos - 1;
    while (m_pos < m_src.size()) {
        char c = peek();
        if (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$')
            advance();
        else
            break;
    }
    std::string name(m_src.substr(start, m_pos - start));
    auto it = KEYWORDS.find(name);
    if (it != KEYWORDS.end()) return make(it->second, name);
    return make(TK::Identifier, std::move(name));
}

std::vector<Token> Lexer::tokenize() {
    std::vector<Token> tokens;

    while (true) {
        skip_whitespace_and_comments();
        if (m_pos >= m_src.size()) {
            tokens.push_back(make(TK::Eof));
            break;
        }

        char c = advance();

        if (std::isdigit(static_cast<unsigned char>(c))) {
            tokens.push_back(lex_number());
            continue;
        }
        if (std::isalpha(static_cast<unsigned char>(c)) || c == '_' || c == '$') {
            tokens.push_back(lex_ident_or_kw());
            continue;
        }
        if (c == '"' || c == '\'' || c == '`') {
            tokens.push_back(lex_string(c));
            continue;
        }

        switch (c) {
            case '+':
                if      (match('+')) tokens.push_back(make(TK::PlusPlus,  "++"));
                else if (match('=')) tokens.push_back(make(TK::PlusEq,    "+="));
                else                 tokens.push_back(make(TK::Plus,       "+"));
                break;
            case '-':
                if      (match('-')) tokens.push_back(make(TK::MinusMinus,"--"));
                else if (match('=')) tokens.push_back(make(TK::MinusEq,   "-="));
                else                 tokens.push_back(make(TK::Minus,      "-"));
                break;
            case '*':
                if (match('=')) tokens.push_back(make(TK::StarEq,  "*="));
                else            tokens.push_back(make(TK::Star,     "*"));
                break;
            case '/':
                if (match('=')) tokens.push_back(make(TK::SlashEq, "/="));
                else            tokens.push_back(make(TK::Slash,    "/"));
                break;
            case '%': tokens.push_back(make(TK::Percent, "%")); break;
            case '=':
                if (match('=')) {
                    if (match('=')) tokens.push_back(make(TK::EqEqEq, "==="));
                    else            tokens.push_back(make(TK::EqEq,   "=="));
                } else              tokens.push_back(make(TK::Eq,     "="));
                break;
            case '!':
                if (match('=')) {
                    if (match('=')) tokens.push_back(make(TK::BangEqEq, "!=="));
                    else            tokens.push_back(make(TK::BangEq,   "!="));
                } else              tokens.push_back(make(TK::Bang,     "!"));
                break;
            case '<':
                if (match('=')) tokens.push_back(make(TK::LtEq, "<="));
                else            tokens.push_back(make(TK::Lt,   "<"));
                break;
            case '>':
                if (match('=')) tokens.push_back(make(TK::GtEq, ">="));
                else            tokens.push_back(make(TK::Gt,   ">"));
                break;
            case '&':
                if (match('&')) tokens.push_back(make(TK::AmpAmp,  "&&"));
                else throw LexError(std::string("unexpected '&' at line ") + std::to_string(m_line));
                break;
            case '|':
                if (match('|')) tokens.push_back(make(TK::PipePipe, "||"));
                else throw LexError(std::string("unexpected '|' at line ") + std::to_string(m_line));
                break;
            case '(': tokens.push_back(make(TK::LParen,   "(")); break;
            case ')': tokens.push_back(make(TK::RParen,   ")")); break;
            case '{': tokens.push_back(make(TK::LBrace,   "{")); break;
            case '}': tokens.push_back(make(TK::RBrace,   "}")); break;
            case '[': tokens.push_back(make(TK::LBracket, "[")); break;
            case ']': tokens.push_back(make(TK::RBracket, "]")); break;
            case ';': tokens.push_back(make(TK::Semi,     ";")); break;
            case ',': tokens.push_back(make(TK::Comma,    ",")); break;
            case '.': tokens.push_back(make(TK::Dot,      ".")); break;
            default:
                throw LexError(std::string("unexpected character '") + c +
                               "' at line " + std::to_string(m_line));
        }
    }

    return tokens;
}

} // namespace js
