#pragma once

#include "js/Lexer.h"
#include "js/AST.h"

#include <stdexcept>
#include <string_view>

namespace js {

class ParseError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

class Parser {
public:
    explicit Parser(std::vector<Token> tokens);

    [[nodiscard]] Program parse();

private:
    // ── Statements ────────────────────────────────────────────────────────────
    StmtPtr parse_stmt();
    StmtPtr parse_block_stmt();
    StmtPtr parse_var_decl(std::string keyword, bool consume_semi = true);
    StmtPtr parse_func_decl();
    StmtPtr parse_if();
    StmtPtr parse_while();
    StmtPtr parse_for();
    StmtPtr parse_return();

    // ── Expressions (recursive descent / Pratt) ───────────────────────────────
    ExprPtr parse_expr();
    ExprPtr parse_assign();
    ExprPtr parse_logical_or();
    ExprPtr parse_logical_and();
    ExprPtr parse_equality();
    ExprPtr parse_relational();
    ExprPtr parse_additive();
    ExprPtr parse_multiplicative();
    ExprPtr parse_unary();
    ExprPtr parse_postfix();
    ExprPtr parse_primary();

    // ── Token helpers ─────────────────────────────────────────────────────────
    [[nodiscard]] const Token& peek(size_t offset = 0) const;
    [[nodiscard]] bool         check(TK kind) const;
    Token                      consume();
    Token                      expect(TK kind, std::string_view what);
    bool                       match(TK kind);

    std::vector<Token> m_tokens;
    size_t             m_pos { 0 };
};

} // namespace js
