#include "js/Interpreter.h"
#include "js/Lexer.h"
#include "js/Parser.h"

#include <cassert>
#include <cmath>
#include <iostream>
#include <sstream>

namespace js {

// ── Environment ───────────────────────────────────────────────────────────────

Environment::Environment(Environment* parent) : m_parent(parent) {}

void Environment::define(const std::string& name, Value val) {
    m_vars[name] = std::move(val);
}

void Environment::set(const std::string& name, Value val) {
    if (m_vars.count(name)) { m_vars[name] = std::move(val); return; }
    if (m_parent)           { m_parent->set(name, std::move(val)); return; }
    // Auto-define at global scope (var semantics)
    m_vars[name] = std::move(val);
}

Value Environment::get(const std::string& name) const {
    auto it = m_vars.find(name);
    if (it != m_vars.end()) return it->second;
    if (m_parent) return m_parent->get(name);
    return std::monostate{}; // undefined
}

void Environment::define_function(const std::string& name, FuncDef def) {
    m_funcs[name] = std::move(def);
}

std::optional<Environment::FuncDef> Environment::get_function(const std::string& name) const {
    auto it = m_funcs.find(name);
    if (it != m_funcs.end()) return it->second;
    if (m_parent) return m_parent->get_function(name);
    return std::nullopt;
}

void Environment::define_native(const std::string& name, NativeFn fn) {
    m_natives[name] = std::move(fn);
}

std::optional<Environment::NativeFn> Environment::get_native(const std::string& name) const {
    auto it = m_natives.find(name);
    if (it != m_natives.end()) return it->second;
    if (m_parent) return m_parent->get_native(name);
    return std::nullopt;
}

// ── Interpreter ───────────────────────────────────────────────────────────────

Interpreter::Interpreter(std::ostream& out) : m_out(out) {}

void Interpreter::install_globals(Environment& env) {
    // console object — accessed as console.log(...)
    // We handle "console" as a magic identifier; CallExpr on MemberExpr(console, log)
    // is intercepted in eval_expr. Here we just define console as a placeholder.
    env.define("console", std::monostate{});

    // Math helpers
    env.define("Infinity", Value{ std::numeric_limits<double>::infinity() });
    env.define("NaN",      Value{ std::numeric_limits<double>::quiet_NaN() });

    // String(x)
    env.define_native("String", [](std::vector<Value> args) -> Value {
        return args.empty() ? Value{std::string{}} : Value{value_to_string(args[0])};
    });
    // Number(x)
    env.define_native("Number", [](std::vector<Value> args) -> Value {
        return args.empty() ? Value{0.0} : Value{value_to_number(args[0])};
    });
    // Boolean(x)
    env.define_native("Boolean", [](std::vector<Value> args) -> Value {
        return args.empty() ? Value{false} : Value{value_to_boolean(args[0])};
    });
    // parseInt / parseFloat
    env.define_native("parseInt", [](std::vector<Value> args) -> Value {
        if (args.empty()) return Value{std::numeric_limits<double>::quiet_NaN()};
        std::string s = value_to_string(args[0]);
        try {
            size_t pos;
            long long n = std::stoll(s, &pos);
            return Value{static_cast<double>(n)};
        } catch (...) {
            return Value{std::numeric_limits<double>::quiet_NaN()};
        }
    });
    env.define_native("parseFloat", [](std::vector<Value> args) -> Value {
        if (args.empty()) return Value{std::numeric_limits<double>::quiet_NaN()};
        try { return Value{std::stod(value_to_string(args[0]))}; }
        catch (...) { return Value{std::numeric_limits<double>::quiet_NaN()}; }
    });
    // isNaN / isFinite
    env.define_native("isNaN", [](std::vector<Value> args) -> Value {
        return Value{args.empty() || std::isnan(value_to_number(args[0]))};
    });
    env.define_native("isFinite", [](std::vector<Value> args) -> Value {
        return Value{!args.empty() && std::isfinite(value_to_number(args[0]))};
    });
    // Math object: accessed via Math.xxx — handled as MemberExpr in eval_expr
    env.define("Math", std::monostate{});
}

void Interpreter::run(std::string_view source) {
    Lexer  lexer(source);
    auto   tokens = lexer.tokenize();
    Parser parser(std::move(tokens));
    auto   prog = parser.parse();

    Environment global_env;
    install_globals(global_env);
    exec_program(prog, global_env);
}

void Interpreter::exec_program(Program& prog, Environment& env) {
    // Hoist function declarations first
    for (auto& stmt : prog.body) {
        if (auto* fd = dynamic_cast<FuncDecl*>(stmt.get())) {
            env.define_function(fd->name, { fd->params, fd->body.get(), &env });
        }
    }
    for (auto& stmt : prog.body) {
        if (!dynamic_cast<FuncDecl*>(stmt.get()))
            exec_stmt(*stmt, env);
    }
}

void Interpreter::exec_stmt(Stmt& stmt, Environment& env) {
    if (auto* s = dynamic_cast<ExprStmt*>(&stmt)) {
        eval_expr(*s->expr, env);
        return;
    }
    if (auto* s = dynamic_cast<BlockStmt*>(&stmt)) {
        exec_block(*s, env);
        return;
    }
    if (auto* s = dynamic_cast<VarDecl*>(&stmt)) {
        Value init = s->init ? eval_expr(*s->init, env) : Value{std::monostate{}};
        env.define(s->name, std::move(init));
        return;
    }
    if (auto* s = dynamic_cast<FuncDecl*>(&stmt)) {
        // Already hoisted in exec_program; re-define for nested scopes
        env.define_function(s->name, { s->params, s->body.get(), &env });
        return;
    }
    if (auto* s = dynamic_cast<IfStmt*>(&stmt)) {
        if (value_to_boolean(eval_expr(*s->test, env)))
            exec_stmt(*s->then_branch, env);
        else if (s->else_branch)
            exec_stmt(*s->else_branch, env);
        return;
    }
    if (auto* s = dynamic_cast<WhileStmt*>(&stmt)) {
        while (value_to_boolean(eval_expr(*s->test, env))) {
            try { exec_stmt(*s->body, env); }
            catch (BreakSignal&)    { break; }
            catch (ContinueSignal&) { continue; }
        }
        return;
    }
    if (auto* s = dynamic_cast<ForStmt*>(&stmt)) {
        Environment loop_env(&env);
        if (s->init) exec_stmt(*s->init, loop_env);
        while (!s->test || value_to_boolean(eval_expr(*s->test, loop_env))) {
            try { exec_stmt(*s->body, loop_env); }
            catch (BreakSignal&)    { break; }
            catch (ContinueSignal&) { /* fall through to update */ }
            if (s->update) eval_expr(*s->update, loop_env);
        }
        return;
    }
    if (dynamic_cast<BreakStmt*>(&stmt))    throw BreakSignal{};
    if (dynamic_cast<ContinueStmt*>(&stmt)) throw ContinueSignal{};
    if (auto* s = dynamic_cast<ReturnStmt*>(&stmt)) {
        Value v = s->value ? eval_expr(*s->value, env) : Value{std::monostate{}};
        throw ReturnSignal{ std::move(v) };
    }
}

void Interpreter::exec_block(BlockStmt& block, Environment& parent) {
    Environment scope(&parent);
    // Hoist function declarations inside block
    for (auto& s : block.body)
        if (auto* fd = dynamic_cast<FuncDecl*>(s.get()))
            scope.define_function(fd->name, { fd->params, fd->body.get(), &scope });
    for (auto& s : block.body)
        if (!dynamic_cast<FuncDecl*>(s.get()))
            exec_stmt(*s, scope);
}

Value Interpreter::eval_expr(Expr& expr, Environment& env) {

    // ── Literals ──────────────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<NumLit*>(&expr))  return Value{e->value};
    if (auto* e = dynamic_cast<StrLit*>(&expr))  return Value{e->value};
    if (auto* e = dynamic_cast<BoolLit*>(&expr)) return Value{e->value};
    if (dynamic_cast<NullLit*>(&expr))           return Value{nullptr};

    // ── Identifier ────────────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<Ident*>(&expr)) {
        // Check native functions first (String, Number, etc.)
        if (auto fn = env.get_native(e->name)) return Value{std::monostate{}};
        return env.get(e->name);
    }

    // ── Member expression ─────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<MemberExpr*>(&expr)) {
        // Math.*
        if (auto* obj = dynamic_cast<Ident*>(e->obj.get())) {
            if (obj->name == "Math") {
                const std::string& prop = e->prop;
                if (prop == "PI")  return Value{ 3.141592653589793 };
                if (prop == "E")   return Value{ 2.718281828459045 };
                // Math methods are handled via CallExpr
                return Value{std::monostate{}};
            }
        }
        return Value{std::monostate{}}; // objects not yet supported
    }

    // ── Call expression ───────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<CallExpr*>(&expr)) {
        // Evaluate arguments
        std::vector<Value> args;
        args.reserve(e->args.size());
        for (auto& arg : e->args)
            args.push_back(eval_expr(*arg, env));

        // console.log(...)
        if (auto* mem = dynamic_cast<MemberExpr*>(e->callee.get())) {
            if (auto* obj = dynamic_cast<Ident*>(mem->obj.get())) {
                if (obj->name == "console" && mem->prop == "log") {
                    for (size_t i = 0; i < args.size(); ++i) {
                        if (i) m_out << ' ';
                        m_out << value_to_string(args[i]);
                    }
                    m_out << '\n';
                    return Value{std::monostate{}};
                }
                // Math.*()
                if (obj->name == "Math") {
                    const std::string& fn = mem->prop;
                    double x = args.empty() ? 0.0 : value_to_number(args[0]);
                    if (fn == "abs")   return Value{std::abs(x)};
                    if (fn == "sqrt")  return Value{std::sqrt(x)};
                    if (fn == "floor") return Value{std::floor(x)};
                    if (fn == "ceil")  return Value{std::ceil(x)};
                    if (fn == "round") return Value{std::round(x)};
                    if (fn == "pow")   {
                        double y = args.size() > 1 ? value_to_number(args[1]) : 1.0;
                        return Value{std::pow(x, y)};
                    }
                    if (fn == "max") {
                        double r = args.empty() ? -std::numeric_limits<double>::infinity()
                                                : value_to_number(args[0]);
                        for (size_t i = 1; i < args.size(); ++i) r = std::max(r, value_to_number(args[i]));
                        return Value{r};
                    }
                    if (fn == "min") {
                        double r = args.empty() ? std::numeric_limits<double>::infinity()
                                                : value_to_number(args[0]);
                        for (size_t i = 1; i < args.size(); ++i) r = std::min(r, value_to_number(args[i]));
                        return Value{r};
                    }
                    if (fn == "log")  return Value{std::log(x)};
                    if (fn == "log2") return Value{std::log2(x)};
                    if (fn == "sin")  return Value{std::sin(x)};
                    if (fn == "cos")  return Value{std::cos(x)};
                    if (fn == "tan")  return Value{std::tan(x)};
                    throw RuntimeError("Math." + fn + " is not implemented");
                }
            }
        }

        // Named function or native call
        if (auto* callee_ident = dynamic_cast<Ident*>(e->callee.get())) {
            const std::string& fname = callee_ident->name;

            // Native (built-in) functions
            if (auto native = env.get_native(fname))
                return (*native)(std::move(args));

            // User-defined function
            if (auto def = env.get_function(fname))
                return call_function(fname, *def, std::move(args), env);

            throw RuntimeError("'" + fname + "' is not a function");
        }

        throw RuntimeError("callee is not callable");
    }

    // ── Binary expression ─────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<BinExpr*>(&expr)) {
        // Short-circuit logical operators
        if (e->op == "&&") {
            auto lv = eval_expr(*e->lhs, env);
            return value_to_boolean(lv) ? eval_expr(*e->rhs, env) : lv;
        }
        if (e->op == "||") {
            auto lv = eval_expr(*e->lhs, env);
            return value_to_boolean(lv) ? lv : eval_expr(*e->rhs, env);
        }

        auto lv = eval_expr(*e->lhs, env);
        auto rv = eval_expr(*e->rhs, env);

        if (e->op == "+") {
            // String concatenation if either operand is a string
            if (std::holds_alternative<std::string>(lv) ||
                std::holds_alternative<std::string>(rv))
                return Value{ value_to_string(lv) + value_to_string(rv) };
            return Value{ value_to_number(lv) + value_to_number(rv) };
        }
        if (e->op == "-")  return Value{ value_to_number(lv) - value_to_number(rv) };
        if (e->op == "*")  return Value{ value_to_number(lv) * value_to_number(rv) };
        if (e->op == "/")  return Value{ value_to_number(lv) / value_to_number(rv) };
        if (e->op == "%") {
            double l = value_to_number(lv), r = value_to_number(rv);
            return Value{ std::fmod(l, r) };
        }
        if (e->op == "<")  return Value{ value_to_number(lv) <  value_to_number(rv) };
        if (e->op == ">")  return Value{ value_to_number(lv) >  value_to_number(rv) };
        if (e->op == "<=") return Value{ value_to_number(lv) <= value_to_number(rv) };
        if (e->op == ">=") return Value{ value_to_number(lv) >= value_to_number(rv) };
        if (e->op == "==")  return Value{ abstract_equal(lv, rv) };
        if (e->op == "!=")  return Value{ !abstract_equal(lv, rv) };
        if (e->op == "===") return Value{ strict_equal(lv, rv) };
        if (e->op == "!==") return Value{ !strict_equal(lv, rv) };

        throw RuntimeError("unknown binary operator: " + e->op);
    }

    // ── Unary expression ──────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<UnaryExpr*>(&expr)) {
        if (e->op == "typeof") {
            // typeof on undefined identifier should return "undefined" not throw
            if (auto* ident = dynamic_cast<Ident*>(e->operand.get()))
                return Value{ value_typeof(env.get(ident->name)) };
            return Value{ value_typeof(eval_expr(*e->operand, env)) };
        }

        // Prefix ++ / --
        if (e->prefix && (e->op == "++" || e->op == "--")) {
            if (auto* ident = dynamic_cast<Ident*>(e->operand.get())) {
                double n = value_to_number(env.get(ident->name));
                n += (e->op == "++") ? 1.0 : -1.0;
                env.set(ident->name, Value{n});
                return Value{n};
            }
            throw RuntimeError("prefix " + e->op + " requires an identifier");
        }
        // Postfix ++ / --
        if (!e->prefix && (e->op == "++" || e->op == "--")) {
            if (auto* ident = dynamic_cast<Ident*>(e->operand.get())) {
                double old = value_to_number(env.get(ident->name));
                double nv  = old + ((e->op == "++") ? 1.0 : -1.0);
                env.set(ident->name, Value{nv});
                return Value{old};
            }
            throw RuntimeError("postfix " + e->op + " requires an identifier");
        }

        auto val = eval_expr(*e->operand, env);
        if (e->op == "!")  return Value{ !value_to_boolean(val) };
        if (e->op == "-")  return Value{ -value_to_number(val) };
        if (e->op == "+")  return Value{  value_to_number(val) };

        throw RuntimeError("unknown unary operator: " + e->op);
    }

    // ── Assignment ────────────────────────────────────────────────────────────
    if (auto* e = dynamic_cast<AssignExpr*>(&expr)) {
        Value rhs = eval_expr(*e->value, env);

        if (auto* target = dynamic_cast<Ident*>(e->target.get())) {
            Value result = rhs;
            if (e->op != "=") {
                Value lv = env.get(target->name);
                if      (e->op == "+=") result = std::holds_alternative<std::string>(lv) || std::holds_alternative<std::string>(rhs)
                                                 ? Value{value_to_string(lv) + value_to_string(rhs)}
                                                 : Value{value_to_number(lv) + value_to_number(rhs)};
                else if (e->op == "-=") result = Value{value_to_number(lv) - value_to_number(rhs)};
                else if (e->op == "*=") result = Value{value_to_number(lv) * value_to_number(rhs)};
                else if (e->op == "/=") result = Value{value_to_number(lv) / value_to_number(rhs)};
            }
            env.set(target->name, result);
            return result;
        }
        throw RuntimeError("invalid assignment target");
    }

    throw RuntimeError("unknown expression type");
}

Value Interpreter::call_function(const std::string& /*name*/,
                                  Environment::FuncDef& def,
                                  std::vector<Value> args,
                                  Environment& /*caller_env*/) {
    Environment fn_env(def.closure);

    // Bind parameters
    for (size_t i = 0; i < def.params.size(); ++i)
        fn_env.define(def.params[i], i < args.size() ? args[i] : Value{std::monostate{}});

    // Hoist inner function declarations
    for (auto& s : def.body->body)
        if (auto* fd = dynamic_cast<FuncDecl*>(s.get()))
            fn_env.define_function(fd->name, { fd->params, fd->body.get(), &fn_env });

    try {
        for (auto& s : def.body->body)
            if (!dynamic_cast<FuncDecl*>(s.get()))
                exec_stmt(*s, fn_env);
    } catch (ReturnSignal& ret) {
        return std::move(ret.value);
    }
    return Value{std::monostate{}};
}

} // namespace js
