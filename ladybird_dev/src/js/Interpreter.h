#pragma once

#include "js/Value.h"
#include "js/AST.h"

#include <string>
#include <unordered_map>
#include <vector>
#include <functional>
#include <optional>
#include <stdexcept>
#include <ostream>

namespace js {

// ── Control-flow signals (thrown as exceptions, caught at boundaries) ─────────
struct ReturnSignal  { Value value; };
struct BreakSignal   {};
struct ContinueSignal{};

// ── Runtime error ─────────────────────────────────────────────────────────────
class RuntimeError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

// ── Scope / environment ───────────────────────────────────────────────────────
class Environment {
public:
    using NativeFn = std::function<Value(std::vector<Value>)>;

    struct FuncDef {
        std::vector<std::string> params;
        BlockStmt*               body;     // non-owning
        Environment*             closure;  // non-owning
    };

    explicit Environment(Environment* parent = nullptr);

    void  define(const std::string& name, Value val);
    void  set   (const std::string& name, Value val);
    Value get   (const std::string& name) const;

    void define_function(const std::string& name, FuncDef def);
    [[nodiscard]] std::optional<FuncDef> get_function(const std::string& name) const;

    void define_native(const std::string& name, NativeFn fn);
    [[nodiscard]] std::optional<NativeFn> get_native(const std::string& name) const;

private:
    std::unordered_map<std::string, Value>   m_vars;
    std::unordered_map<std::string, FuncDef> m_funcs;
    std::unordered_map<std::string, NativeFn>m_natives;
    Environment* m_parent { nullptr };
};

// ── Interpreter ───────────────────────────────────────────────────────────────
class Interpreter {
public:
    /// output_stream defaults to std::cout; override in tests.
    explicit Interpreter(std::ostream& out);

    /// Parse and execute JavaScript source.
    void run(std::string_view source);

private:
    void  exec_program(Program& prog, Environment& env);
    void  exec_stmt   (Stmt& stmt, Environment& env);
    void  exec_block  (BlockStmt& block, Environment& env);
    Value eval_expr   (Expr& expr, Environment& env);

    // Helpers
    Value call_function(const std::string& name,
                        Environment::FuncDef& def,
                        std::vector<Value> args,
                        Environment& caller_env);

    void install_globals(Environment& env);

    std::ostream& m_out;
};

} // namespace js
