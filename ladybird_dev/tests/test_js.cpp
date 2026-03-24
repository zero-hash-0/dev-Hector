#include "js/Interpreter.h"

#include <iostream>
#include <sstream>
#include <string>

#define CHECK(cond) do { \
    if (!(cond)) { \
        std::cerr << "FAIL [line " << __LINE__ << "]: " #cond "\n"; \
        ++failures; \
    } \
} while(0)

#define CHECK_OUTPUT(src, expected) do { \
    std::ostringstream _oss; \
    js::Interpreter _interp(_oss); \
    _interp.run(src); \
    if (_oss.str() != (expected)) { \
        std::cerr << "FAIL [line " << __LINE__ << "]: run(\"" #src "\")\n" \
                  << "  expected: \"" << (expected) << "\"\n" \
                  << "  got:      \"" << _oss.str() << "\"\n"; \
        ++failures; \
    } \
} while(0)

int main() {
    int failures = 0;

    // ── Literals and console.log ──────────────────────────────────────────────
    CHECK_OUTPUT("console.log(42);",           "42\n");
    CHECK_OUTPUT("console.log(true);",         "true\n");
    CHECK_OUTPUT("console.log(false);",        "false\n");
    CHECK_OUTPUT("console.log(null);",         "null\n");
    CHECK_OUTPUT("console.log('hello');",      "hello\n");
    CHECK_OUTPUT("console.log(\"world\");",    "world\n");

    // ── Arithmetic ────────────────────────────────────────────────────────────
    CHECK_OUTPUT("console.log(1 + 2);",        "3\n");
    CHECK_OUTPUT("console.log(10 - 3);",       "7\n");
    CHECK_OUTPUT("console.log(4 * 5);",        "20\n");
    CHECK_OUTPUT("console.log(10 / 4);",       "2.5\n");
    CHECK_OUTPUT("console.log(10 % 3);",       "1\n");

    // ── String concatenation ──────────────────────────────────────────────────
    CHECK_OUTPUT("console.log('foo' + 'bar');","foobar\n");
    CHECK_OUTPUT("console.log('x=' + 42);",   "x=42\n");

    // ── Variables ─────────────────────────────────────────────────────────────
    CHECK_OUTPUT("var x = 7; console.log(x);",       "7\n");
    CHECK_OUTPUT("let y = 3; y = y + 1; console.log(y);", "4\n");
    CHECK_OUTPUT("const z = 'hi'; console.log(z);",  "hi\n");

    // ── Comparison ────────────────────────────────────────────────────────────
    CHECK_OUTPUT("console.log(1 < 2);",  "true\n");
    CHECK_OUTPUT("console.log(2 > 3);",  "false\n");
    CHECK_OUTPUT("console.log(2 <= 2);", "true\n");
    CHECK_OUTPUT("console.log(3 >= 4);", "false\n");
    CHECK_OUTPUT("console.log(1 == 1);", "true\n");
    CHECK_OUTPUT("console.log(1 != 2);", "true\n");
    CHECK_OUTPUT("console.log(1 === 1);","true\n");
    CHECK_OUTPUT("console.log(1 !== 2);","true\n");

    // ── Logical operators ─────────────────────────────────────────────────────
    CHECK_OUTPUT("console.log(true && false);", "false\n");
    CHECK_OUTPUT("console.log(false || true);", "true\n");
    CHECK_OUTPUT("console.log(!true);",         "false\n");

    // ── if / else ─────────────────────────────────────────────────────────────
    CHECK_OUTPUT("if (1 < 2) { console.log('yes'); } else { console.log('no'); }", "yes\n");
    CHECK_OUTPUT("if (1 > 2) { console.log('yes'); } else { console.log('no'); }", "no\n");

    // ── while loop ────────────────────────────────────────────────────────────
    CHECK_OUTPUT("var i = 0; while (i < 3) { console.log(i); i = i + 1; }", "0\n1\n2\n");

    // ── for loop ──────────────────────────────────────────────────────────────
    CHECK_OUTPUT("for (var i = 0; i < 3; i++) { console.log(i); }", "0\n1\n2\n");

    // ── break / continue ─────────────────────────────────────────────────────
    CHECK_OUTPUT("for (var i = 0; i < 5; i++) { if (i == 3) break; console.log(i); }", "0\n1\n2\n");
    CHECK_OUTPUT("for (var i = 0; i < 4; i++) { if (i == 2) continue; console.log(i); }", "0\n1\n3\n");

    // ── function declaration and call ─────────────────────────────────────────
    CHECK_OUTPUT("function add(a, b) { return a + b; } console.log(add(3, 4));", "7\n");
    CHECK_OUTPUT("function greet(name) { return 'Hello, ' + name; } console.log(greet('World'));", "Hello, World\n");

    // ── recursion ─────────────────────────────────────────────────────────────
    CHECK_OUTPUT(
        "function fact(n) { if (n <= 1) return 1; return n * fact(n - 1); }"
        "console.log(fact(5));",
        "120\n");

    // ── compound assignment ───────────────────────────────────────────────────
    CHECK_OUTPUT("var x = 10; x += 5; console.log(x);", "15\n");
    CHECK_OUTPUT("var x = 10; x -= 3; console.log(x);", "7\n");
    CHECK_OUTPUT("var x = 4; x *= 3;  console.log(x);", "12\n");
    CHECK_OUTPUT("var x = 10; x /= 4; console.log(x);", "2.5\n");

    // ── prefix / postfix ++ -- ────────────────────────────────────────────────
    CHECK_OUTPUT("var x = 5; console.log(x++); console.log(x);", "5\n6\n");
    CHECK_OUTPUT("var x = 5; console.log(++x); console.log(x);", "6\n6\n");
    CHECK_OUTPUT("var x = 5; console.log(x--); console.log(x);", "5\n4\n");

    // ── typeof ────────────────────────────────────────────────────────────────
    CHECK_OUTPUT("console.log(typeof 42);",        "number\n");
    CHECK_OUTPUT("console.log(typeof 'hi');",       "string\n");
    CHECK_OUTPUT("console.log(typeof true);",       "boolean\n");
    CHECK_OUTPUT("console.log(typeof undefined);",  "undefined\n");

    // ── built-in functions ────────────────────────────────────────────────────
    CHECK_OUTPUT("console.log(String(42));",        "42\n");
    CHECK_OUTPUT("console.log(Number('3.14'));",     "3.14\n");
    CHECK_OUTPUT("console.log(Boolean(0));",         "false\n");
    CHECK_OUTPUT("console.log(Boolean(1));",         "true\n");
    CHECK_OUTPUT("console.log(parseInt('42px'));",   "42\n");

    // ── Math ──────────────────────────────────────────────────────────────────
    CHECK_OUTPUT("console.log(Math.abs(-5));",       "5\n");
    CHECK_OUTPUT("console.log(Math.floor(3.9));",    "3\n");
    CHECK_OUTPUT("console.log(Math.ceil(3.1));",     "4\n");
    CHECK_OUTPUT("console.log(Math.max(1, 5, 3));",  "5\n");
    CHECK_OUTPUT("console.log(Math.min(1, 5, 3));",  "1\n");
    CHECK_OUTPUT("console.log(Math.pow(2, 8));",     "256\n");

    // ── multi-line programs ───────────────────────────────────────────────────
    {
        const char* src = R"js(
            function fib(n) {
                if (n <= 1) return n;
                return fib(n - 1) + fib(n - 2);
            }
            for (var i = 0; i <= 7; i++) {
                console.log(fib(i));
            }
        )js";
        std::ostringstream oss;
        js::Interpreter interp(oss);
        interp.run(src);
        CHECK(oss.str() == "0\n1\n1\n2\n3\n5\n8\n13\n");
    }

    if (failures == 0)
        std::cout << "test_js: ALL PASSED\n";
    else
        std::cerr << "test_js: " << failures << " FAILURE(S)\n";

    return failures ? 1 : 0;
}
