#include "js/Parser.h"

#include <cassert>

namespace js {

Parser::Parser(std::vector<Token> tokens) : m_tokens(std::move(tokens)) {}

// ── Token helpers ─────────────────────────────────────────────────────────────

const Token& Parser::peek(size_t offset) const {
    size_t idx = m_pos + offset;
    return idx < m_tokens.size() ? m_tokens[idx] : m_tokens.back();
}

bool Parser::check(TK kind) const { return peek().kind == kind; }

Token Parser::consume() {
    return m_pos < m_tokens.size() ? m_tokens[m_pos++] : m_tokens.back();
}

Token Parser::expect(TK kind, std::string_view what) {
    if (!check(kind))
        throw ParseError("expected " + std::string(what) +
                         " but got '" + peek().text +
                         "' at line " + std::to_string(peek().line));
    return consume();
}

bool Parser::match(TK kind) {
    if (check(kind)) { consume(); return true; }
    return false;
}

// ── Program ───────────────────────────────────────────────────────────────────

Program Parser::parse() {
    Program prog;
    while (!check(TK::Eof))
        prog.body.push_back(parse_stmt());
    return prog;
}

// ── Statements ────────────────────────────────────────────────────────────────

StmtPtr Parser::parse_stmt() {
    auto k = peek().kind;

    if (k == TK::LBrace)    return parse_block_stmt();
    if (k == TK::KwVar  ||
        k == TK::KwLet  ||
        k == TK::KwConst)   return parse_var_decl(consume().text);
    if (k == TK::KwFunction) return parse_func_decl();
    if (k == TK::KwIf)      return parse_if();
    if (k == TK::KwWhile)   return parse_while();
    if (k == TK::KwFor)     return parse_for();
    if (k == TK::KwReturn)  return parse_return();
    if (k == TK::KwBreak)   { consume(); match(TK::Semi); return std::make_unique<BreakStmt>(); }
    if (k == TK::KwContinue){ consume(); match(TK::Semi); return std::make_unique<ContinueStmt>(); }

    // Expression statement
    auto expr = parse_expr();
    match(TK::Semi);
    auto stmt = std::make_unique<ExprStmt>();
    stmt->expr = std::move(expr);
    return stmt;
}

StmtPtr Parser::parse_block_stmt() {
    expect(TK::LBrace, "{");
    auto block = std::make_unique<BlockStmt>();
    while (!check(TK::RBrace) && !check(TK::Eof))
        block->body.push_back(parse_stmt());
    expect(TK::RBrace, "}");
    return block;
}

StmtPtr Parser::parse_var_decl(std::string keyword, bool consume_semi) {
    auto name_tok = expect(TK::Identifier, "variable name");
    ExprPtr init;
    if (match(TK::Eq))
        init = parse_expr();
    if (consume_semi) match(TK::Semi);
    auto decl = std::make_unique<VarDecl>();
    decl->keyword = std::move(keyword);
    decl->name    = name_tok.text;
    decl->init    = std::move(init);
    return decl;
}

StmtPtr Parser::parse_func_decl() {
    expect(TK::KwFunction, "function");
    auto name_tok = expect(TK::Identifier, "function name");

    expect(TK::LParen, "(");
    std::vector<std::string> params;
    if (!check(TK::RParen)) {
        do { params.push_back(expect(TK::Identifier, "parameter").text); }
        while (match(TK::Comma));
    }
    expect(TK::RParen, ")");

    auto body_stmt = parse_block_stmt();
    auto body = std::unique_ptr<BlockStmt>(static_cast<BlockStmt*>(body_stmt.release()));

    auto decl = std::make_unique<FuncDecl>();
    decl->name   = name_tok.text;
    decl->params = std::move(params);
    decl->body   = std::move(body);
    return decl;
}

StmtPtr Parser::parse_if() {
    expect(TK::KwIf, "if");
    expect(TK::LParen, "(");
    auto test = parse_expr();
    expect(TK::RParen, ")");

    auto then_branch = parse_stmt();
    StmtPtr else_branch;
    if (match(TK::KwElse)) else_branch = parse_stmt();

    auto stmt = std::make_unique<IfStmt>();
    stmt->test        = std::move(test);
    stmt->then_branch = std::move(then_branch);
    stmt->else_branch = std::move(else_branch);
    return stmt;
}

StmtPtr Parser::parse_while() {
    expect(TK::KwWhile, "while");
    expect(TK::LParen, "(");
    auto test = parse_expr();
    expect(TK::RParen, ")");
    auto body = parse_stmt();

    auto stmt = std::make_unique<WhileStmt>();
    stmt->test = std::move(test);
    stmt->body = std::move(body);
    return stmt;
}

StmtPtr Parser::parse_for() {
    expect(TK::KwFor, "for");
    expect(TK::LParen, "(");

    // Init clause (no trailing semicolon consumed by parse_var_decl)
    StmtPtr init;
    if (!check(TK::Semi)) {
        if (check(TK::KwVar) || check(TK::KwLet) || check(TK::KwConst)) {
            init = parse_var_decl(consume().text, /*consume_semi=*/false);
        } else {
            auto expr = parse_expr();
            auto es = std::make_unique<ExprStmt>();
            es->expr = std::move(expr);
            init = std::move(es);
        }
    }
    expect(TK::Semi, ";");

    ExprPtr test;
    if (!check(TK::Semi)) test = parse_expr();
    expect(TK::Semi, ";");

    ExprPtr update;
    if (!check(TK::RParen)) update = parse_expr();
    expect(TK::RParen, ")");

    auto body = parse_stmt();

    auto stmt = std::make_unique<ForStmt>();
    stmt->init   = std::move(init);
    stmt->test   = std::move(test);
    stmt->update = std::move(update);
    stmt->body   = std::move(body);
    return stmt;
}

StmtPtr Parser::parse_return() {
    expect(TK::KwReturn, "return");
    ExprPtr value;
    if (!check(TK::Semi) && !check(TK::RBrace) && !check(TK::Eof))
        value = parse_expr();
    match(TK::Semi);
    auto stmt = std::make_unique<ReturnStmt>();
    stmt->value = std::move(value);
    return stmt;
}

// ── Expressions ───────────────────────────────────────────────────────────────

ExprPtr Parser::parse_expr()  { return parse_assign(); }

ExprPtr Parser::parse_assign() {
    auto lhs = parse_logical_or();
    auto k = peek().kind;
    if (k == TK::Eq || k == TK::PlusEq || k == TK::MinusEq ||
        k == TK::StarEq || k == TK::SlashEq) {
        std::string op = consume().text;
        auto rhs = parse_assign();
        auto node = std::make_unique<AssignExpr>();
        node->op     = std::move(op);
        node->target = std::move(lhs);
        node->value  = std::move(rhs);
        return node;
    }
    return lhs;
}

ExprPtr Parser::parse_logical_or() {
    auto lhs = parse_logical_and();
    while (check(TK::PipePipe)) {
        consume();
        auto rhs = parse_logical_and();
        auto node = std::make_unique<BinExpr>();
        node->op  = "||";
        node->lhs = std::move(lhs);
        node->rhs = std::move(rhs);
        lhs = std::move(node);
    }
    return lhs;
}

ExprPtr Parser::parse_logical_and() {
    auto lhs = parse_equality();
    while (check(TK::AmpAmp)) {
        consume();
        auto rhs = parse_equality();
        auto node = std::make_unique<BinExpr>();
        node->op  = "&&";
        node->lhs = std::move(lhs);
        node->rhs = std::move(rhs);
        lhs = std::move(node);
    }
    return lhs;
}

ExprPtr Parser::parse_equality() {
    auto lhs = parse_relational();
    while (check(TK::EqEq) || check(TK::EqEqEq) ||
           check(TK::BangEq) || check(TK::BangEqEq)) {
        std::string op = consume().text;
        auto rhs = parse_relational();
        auto node = std::make_unique<BinExpr>();
        node->op  = std::move(op);
        node->lhs = std::move(lhs);
        node->rhs = std::move(rhs);
        lhs = std::move(node);
    }
    return lhs;
}

ExprPtr Parser::parse_relational() {
    auto lhs = parse_additive();
    while (check(TK::Lt) || check(TK::Gt) || check(TK::LtEq) || check(TK::GtEq)) {
        std::string op = consume().text;
        auto rhs = parse_additive();
        auto node = std::make_unique<BinExpr>();
        node->op  = std::move(op);
        node->lhs = std::move(lhs);
        node->rhs = std::move(rhs);
        lhs = std::move(node);
    }
    return lhs;
}

ExprPtr Parser::parse_additive() {
    auto lhs = parse_multiplicative();
    while (check(TK::Plus) || check(TK::Minus)) {
        std::string op = consume().text;
        auto rhs = parse_multiplicative();
        auto node = std::make_unique<BinExpr>();
        node->op  = std::move(op);
        node->lhs = std::move(lhs);
        node->rhs = std::move(rhs);
        lhs = std::move(node);
    }
    return lhs;
}

ExprPtr Parser::parse_multiplicative() {
    auto lhs = parse_unary();
    while (check(TK::Star) || check(TK::Slash) || check(TK::Percent)) {
        std::string op = consume().text;
        auto rhs = parse_unary();
        auto node = std::make_unique<BinExpr>();
        node->op  = std::move(op);
        node->lhs = std::move(lhs);
        node->rhs = std::move(rhs);
        lhs = std::move(node);
    }
    return lhs;
}

ExprPtr Parser::parse_unary() {
    if (check(TK::Bang) || check(TK::Minus) || check(TK::Plus)) {
        std::string op = consume().text;
        auto operand = parse_unary();
        auto node = std::make_unique<UnaryExpr>();
        node->op      = std::move(op);
        node->operand = std::move(operand);
        node->prefix  = true;
        return node;
    }
    if (check(TK::KwTypeof)) {
        consume();
        auto operand = parse_unary();
        auto node = std::make_unique<UnaryExpr>();
        node->op      = "typeof";
        node->operand = std::move(operand);
        node->prefix  = true;
        return node;
    }
    if (check(TK::PlusPlus) || check(TK::MinusMinus)) {
        std::string op = consume().text;
        auto operand = parse_unary();
        auto node = std::make_unique<UnaryExpr>();
        node->op      = std::move(op);
        node->operand = std::move(operand);
        node->prefix  = true;
        return node;
    }
    return parse_postfix();
}

ExprPtr Parser::parse_postfix() {
    auto expr = parse_primary();

    // Left-to-right: member access and function calls
    bool changed = true;
    while (changed) {
        changed = false;
        if (check(TK::Dot)) {
            consume();
            auto prop = expect(TK::Identifier, "property name");
            auto node = std::make_unique<MemberExpr>();
            node->obj  = std::move(expr);
            node->prop = prop.text;
            expr = std::move(node);
            changed = true;
        } else if (check(TK::LParen)) {
            consume();
            std::vector<ExprPtr> args;
            if (!check(TK::RParen)) {
                do { args.push_back(parse_expr()); } while (match(TK::Comma));
            }
            expect(TK::RParen, ")");
            auto call = std::make_unique<CallExpr>();
            call->callee = std::move(expr);
            call->args   = std::move(args);
            expr = std::move(call);
            changed = true;
        }
    }

    // Postfix ++ / --
    if (check(TK::PlusPlus) || check(TK::MinusMinus)) {
        std::string op = consume().text;
        auto node = std::make_unique<UnaryExpr>();
        node->op      = std::move(op);
        node->operand = std::move(expr);
        node->prefix  = false;
        return node;
    }
    return expr;
}

ExprPtr Parser::parse_primary() {
    auto tok = peek();

    if (tok.kind == TK::Number) {
        consume();
        auto node = std::make_unique<NumLit>();
        node->value = std::stod(tok.text);
        return node;
    }
    if (tok.kind == TK::String) {
        consume();
        auto node = std::make_unique<StrLit>();
        node->value = tok.text;
        return node;
    }
    if (tok.kind == TK::KwTrue) {
        consume();
        auto node = std::make_unique<BoolLit>();
        node->value = true;
        return node;
    }
    if (tok.kind == TK::KwFalse) {
        consume();
        auto node = std::make_unique<BoolLit>();
        node->value = false;
        return node;
    }
    if (tok.kind == TK::KwNull) {
        consume();
        return std::make_unique<NullLit>();
    }
    if (tok.kind == TK::Identifier) {
        consume();
        auto node = std::make_unique<Ident>();
        node->name = tok.text;
        return node;
    }
    if (tok.kind == TK::LParen) {
        consume();
        auto expr = parse_expr();
        expect(TK::RParen, ")");
        return expr;
    }

    throw ParseError("unexpected token '" + tok.text +
                     "' at line " + std::to_string(tok.line));
}

} // namespace js
