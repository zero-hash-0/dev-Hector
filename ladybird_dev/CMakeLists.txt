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
    -fPIE
    -D_FORTIFY_SOURCE=2
)

add_link_options(-pie -Wl,-z,relro,-z,now)

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
