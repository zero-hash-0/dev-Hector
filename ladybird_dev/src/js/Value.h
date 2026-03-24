#pragma once

#include <string>
#include <variant>
#include <limits>
#include <cmath>

namespace js {

/// JavaScript primitive value: undefined | null | boolean | number | string.
/// Functions are tracked separately in the Environment.
using Value = std::variant<
    std::monostate,   // undefined
    std::nullptr_t,   // null
    bool,             // boolean
    double,           // number
    std::string       // string
>;

[[nodiscard]] std::string value_to_string(const Value& v);
[[nodiscard]] double      value_to_number(const Value& v);
[[nodiscard]] bool        value_to_boolean(const Value& v);
[[nodiscard]] std::string value_typeof(const Value& v);
[[nodiscard]] bool        is_undefined(const Value& v);

/// Abstract equality (==) with type coercion.
[[nodiscard]] bool abstract_equal(const Value& a, const Value& b);
/// Strict equality (===) — no coercion.
[[nodiscard]] bool strict_equal(const Value& a, const Value& b);

} // namespace js
