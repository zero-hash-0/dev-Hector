#pragma once

#include <string>
#include <vector>
#include <memory>

namespace js {

// ── Forward declarations ──────────────────────────────────────────────────────
struct Expr;
struct Stmt;
struct BlockStmt;

using ExprPtr = std::unique_ptr<Expr>;
using StmtPtr = std::unique_ptr<Stmt>;

// ── Expressions ───────────────────────────────────────────────────────────────
struct Expr { virtual ~Expr() = default; };

struct NumLit     : Expr { double value; };
struct StrLit     : Expr { std::string value; };
struct BoolLit    : Expr { bool value; };
struct NullLit    : Expr {};
struct Ident      : Expr { std::string name; };

struct BinExpr    : Expr {
    std::string op;
    ExprPtr     lhs;
    ExprPtr     rhs;
};

struct UnaryExpr  : Expr {
    std::string op;
    ExprPtr     operand;
    bool        prefix { true };
};

struct AssignExpr : Expr {
    std::string op;     // = += -= *= /=
    ExprPtr     target;
    ExprPtr     value;
};

struct CallExpr   : Expr {
    ExprPtr              callee;
    std::vector<ExprPtr> args;
};

struct MemberExpr : Expr {
    ExprPtr     obj;
    std::string prop;
};

// ── Statements ────────────────────────────────────────────────────────────────
struct Stmt { virtual ~Stmt() = default; };

struct BlockStmt    : Stmt { std::vector<StmtPtr> body; };
struct ExprStmt     : Stmt { ExprPtr expr; };

struct VarDecl      : Stmt {
    std::string keyword;    // var | let | const
    std::string name;
    ExprPtr     init;       // may be null
};

struct FuncDecl     : Stmt {
    std::string                name;
    std::vector<std::string>   params;
    std::unique_ptr<BlockStmt> body;
};

struct ReturnStmt   : Stmt { ExprPtr value; };   // value may be null

struct IfStmt       : Stmt {
    ExprPtr test;
    StmtPtr then_branch;
    StmtPtr else_branch;  // may be null
};

struct WhileStmt    : Stmt {
    ExprPtr test;
    StmtPtr body;
};

struct ForStmt      : Stmt {
    StmtPtr init;    // VarDecl or ExprStmt, may be null
    ExprPtr test;    // may be null
    ExprPtr update;  // may be null
    StmtPtr body;
};

struct BreakStmt    : Stmt {};
struct ContinueStmt : Stmt {};

// ── Program ───────────────────────────────────────────────────────────────────
struct Program { std::vector<StmtPtr> body; };

} // namespace js
