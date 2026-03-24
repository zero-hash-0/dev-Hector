cmake_minimum_required(VERSION 3.20)

set(TEST_SOURCES
    test_url.cpp
    test_tokenizer.cpp
    test_parser.cpp
    test_csp.cpp
    test_js.cpp
)

foreach(src ${TEST_SOURCES})
    get_filename_component(name ${src} NAME_WE)
    add_executable(${name} ${src})
    target_include_directories(${name} PRIVATE ${CMAKE_SOURCE_DIR}/src)
    target_link_libraries(${name} PRIVATE OpenSSL::SSL OpenSSL::Crypto)
    target_sources(${name} PRIVATE
        ${CMAKE_SOURCE_DIR}/src/net/URL.cpp
        ${CMAKE_SOURCE_DIR}/src/net/Response.cpp
        ${CMAKE_SOURCE_DIR}/src/net/TLSContext.cpp
        ${CMAKE_SOURCE_DIR}/src/html/Tokenizer.cpp
        ${CMAKE_SOURCE_DIR}/src/html/Parser.cpp
        ${CMAKE_SOURCE_DIR}/src/css/Lexer.cpp
        ${CMAKE_SOURCE_DIR}/src/css/Parser.cpp
        ${CMAKE_SOURCE_DIR}/src/css/StyleSheet.cpp
        ${CMAKE_SOURCE_DIR}/src/dom/Node.cpp
        ${CMAKE_SOURCE_DIR}/src/dom/Element.cpp
        ${CMAKE_SOURCE_DIR}/src/dom/Document.cpp
        ${CMAKE_SOURCE_DIR}/src/dom/Text.cpp
        ${CMAKE_SOURCE_DIR}/src/security/ContentSecurityPolicy.cpp
        ${CMAKE_SOURCE_DIR}/src/security/SameOriginPolicy.cpp
        ${CMAKE_SOURCE_DIR}/src/security/SandboxFlags.cpp
        ${CMAKE_SOURCE_DIR}/src/js/Lexer.cpp
        ${CMAKE_SOURCE_DIR}/src/js/Value.cpp
        ${CMAKE_SOURCE_DIR}/src/js/Parser.cpp
        ${CMAKE_SOURCE_DIR}/src/js/Interpreter.cpp
    )
    add_test(NAME ${name} COMMAND ${name})
endforeach()
