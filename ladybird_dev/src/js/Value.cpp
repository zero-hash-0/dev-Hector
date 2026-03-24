#include "js/Value.h"

#include <sstream>

namespace js {

std::string value_to_string(const Value& v) {
    struct Visitor {
        std::string operator()(std::monostate)        const { return "undefined"; }
        std::string operator()(std::nullptr_t)         const { return "null"; }
        std::string operator()(bool b)                 const { return b ? "true" : "false"; }
        std::string operator()(double n)               const {
            if (std::isnan(n))  return "NaN";
            if (std::isinf(n))  return n > 0 ? "Infinity" : "-Infinity";
            if (n == 0.0)       return "0";
            if (n == std::trunc(n) && std::abs(n) < 1e15) {
                std::ostringstream oss;
                oss << static_cast<long long>(n);
                return oss.str();
            }
            std::ostringstream oss;
            oss << n;
            return oss.str();
        }
        std::string operator()(const std::string& s)  const { return s; }
    };
    return std::visit(Visitor{}, v);
}

double value_to_number(const Value& v) {
    struct Visitor {
        double operator()(std::monostate)        const { return std::numeric_limits<double>::quiet_NaN(); }
        double operator()(std::nullptr_t)         const { return 0.0; }
        double operator()(bool b)                 const { return b ? 1.0 : 0.0; }
        double operator()(double n)               const { return n; }
        double operator()(const std::string& s)   const {
            if (s.empty()) return 0.0;
            size_t i = 0, j = s.size();
            while (i < j && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
            while (j > i && std::isspace(static_cast<unsigned char>(s[j-1]))) --j;
            if (i == j) return 0.0;
            try { return std::stod(s.substr(i, j - i)); }
            catch (...) { return std::numeric_limits<double>::quiet_NaN(); }
        }
    };
    return std::visit(Visitor{}, v);
}

bool value_to_boolean(const Value& v) {
    struct Visitor {
        bool operator()(std::monostate)        const { return false; }
        bool operator()(std::nullptr_t)         const { return false; }
        bool operator()(bool b)                 const { return b; }
        bool operator()(double n)               const { return n != 0.0 && !std::isnan(n); }
        bool operator()(const std::string& s)   const { return !s.empty(); }
    };
    return std::visit(Visitor{}, v);
}

std::string value_typeof(const Value& v) {
    struct Visitor {
        std::string operator()(std::monostate)        const { return "undefined"; }
        std::string operator()(std::nullptr_t)         const { return "object"; }  // JS quirk
        std::string operator()(bool)                   const { return "boolean"; }
        std::string operator()(double)                 const { return "number"; }
        std::string operator()(const std::string&)     const { return "string"; }
    };
    return std::visit(Visitor{}, v);
}

bool is_undefined(const Value& v) {
    return std::holds_alternative<std::monostate>(v);
}

bool strict_equal(const Value& a, const Value& b) {
    if (a.index() != b.index()) return false;
    if (std::holds_alternative<double>(a) && std::isnan(std::get<double>(a))) return false;
    return a == b;
}

bool abstract_equal(const Value& a, const Value& b) {
    if (a.index() == b.index()) return strict_equal(a, b);
    // null == undefined
    if ((std::holds_alternative<std::monostate>(a) && std::holds_alternative<std::nullptr_t>(b)) ||
        (std::holds_alternative<std::nullptr_t>(a)  && std::holds_alternative<std::monostate>(b)))
        return true;
    // number + string/bool — coerce both to number
    if (std::holds_alternative<double>(a) || std::holds_alternative<double>(b))
        return value_to_number(a) == value_to_number(b);
    if (std::holds_alternative<bool>(a))
        return abstract_equal(Value{ value_to_number(a) }, b);
    if (std::holds_alternative<bool>(b))
        return abstract_equal(a, Value{ value_to_number(b) });
    return false;
}

} // namespace js
