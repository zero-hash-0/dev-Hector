cmake_minimum_required(VERSION 3.20)
project(LadyBird VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ── Compiler hardening flags ──────────────────────────────────────────────────
add_compile_options(
    -Wall -Wextra -Wpedantic
    -Wformat=2 -Wformat-security
    -Wconversion -Wshadow
    -fstack-protector-strong
    -D_FORTIFY_SOURCE=2
)
if(NOT APPLE)
    add_compile_options(-fPIE)
endif()

if(NOT APPLE)
    add_link_options(-pie -Wl,-z,relro,-z,now)
endif()

# ── Dependencies ──────────────────────────────────────────────────────────────
find_package(OpenSSL REQUIRED)

# ── Sources ───────────────────────────────────────────────────────────────────
set(BROWSER_SOURCES
    src/main.cpp

    src/net/URL.cpp
    src/net/Request.cpp
    src/net/Response.cpp
    src/net/TLSContext.cpp

    src/html/Tokenizer.cpp
    src/html/Parser.cpp

    src/css/Lexer.cpp
    src/css/Parser.cpp
    src/css/StyleSheet.cpp

    src/dom/Node.cpp
    src/dom/Element.cpp
    src/dom/Document.cpp
    src/dom/Text.cpp

    src/layout/LayoutBox.cpp
    src/layout/BlockFormattingContext.cpp

    src/render/TerminalRenderer.cpp

    src/security/ContentSecurityPolicy.cpp
    src/security/SameOriginPolicy.cpp
    src/security/SandboxFlags.cpp

    src/js/Lexer.cpp
    src/js/Value.cpp
    src/js/Parser.cpp
    src/js/Interpreter.cpp
)

add_executable(ladybird ${BROWSER_SOURCES})

target_include_directories(ladybird PRIVATE src)

target_link_libraries(ladybird PRIVATE
    OpenSSL::SSL
    OpenSSL::Crypto
)

# ── Tests ─────────────────────────────────────────────────────────────────────
enable_testing()
add_subdirectory(tests)
