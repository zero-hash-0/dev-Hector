#include "html/Tokenizer.h"

#include <cassert>
#include <iostream>
#include <vector>

#define CHECK(cond) do { \
    if (!(cond)) { \
        std::cerr << "FAIL [line " << __LINE__ << "]: " #cond "\n"; \
        failures++; \
    } \
} while(0)

using html::Token;
using html::TokenType;

static std::vector<Token> tokenize(std::string_view html) {
    std::vector<Token> tokens;
    html::Tokenizer t(html, [&](Token tok){ tokens.push_back(std::move(tok)); });
    t.run();
    return tokens;
}

int main() {
    int failures = 0;

    // ── Simple text ───────────────────────────────────────────────────────────
    {
        auto toks = tokenize("Hello");
        // Should get 5 Character tokens + EOF
        size_t chars = 0;
        for (auto& t : toks)
            if (t.type == TokenType::Character) ++chars;
        CHECK(chars == 5);
    }

    // ── Start tag ─────────────────────────────────────────────────────────────
    {
        auto toks = tokenize("<p>");
        bool found = false;
        for (auto& t : toks)
            if (t.type == TokenType::StartTag && t.tag_name == "p") found = true;
        CHECK(found);
    }

    // ── End tag ───────────────────────────────────────────────────────────────
    {
        auto toks = tokenize("</p>");
        bool found = false;
        for (auto& t : toks)
            if (t.type == TokenType::EndTag && t.tag_name == "p") found = true;
        CHECK(found);
    }

    // ── Tag with attribute ────────────────────────────────────────────────────
    {
        auto toks = tokenize("<a href=\"https://example.com\">");
        bool found = false;
        for (auto& t : toks) {
            if (t.type == TokenType::StartTag && t.tag_name == "a") {
                CHECK(t.attr("href") == "https://example.com");
                found = true;
            }
        }
        CHECK(found);
    }

    // ── Self-closing tag ──────────────────────────────────────────────────────
    {
        auto toks = tokenize("<br/>");
        bool found = false;
        for (auto& t : toks)
            if (t.type == TokenType::StartTag && t.tag_name == "br" && t.self_closing)
                found = true;
        CHECK(found);
    }

    // ── Comment ───────────────────────────────────────────────────────────────
    {
        auto toks = tokenize("<!-- hello -->");
        bool found = false;
        for (auto& t : toks)
            if (t.type == TokenType::Comment && t.data == " hello ") found = true;
        CHECK(found);
    }

    // ── DOCTYPE ───────────────────────────────────────────────────────────────
    {
        auto toks = tokenize("<!DOCTYPE html>");
        bool found = false;
        for (auto& t : toks)
            if (t.type == TokenType::DOCTYPE && t.doctype_name == "html") found = true;
        CHECK(found);
    }

    // ── Tag names are lowercased ──────────────────────────────────────────────
    {
        auto toks = tokenize("<DIV>");
        bool found = false;
        for (auto& t : toks)
            if (t.type == TokenType::StartTag && t.tag_name == "div") found = true;
        CHECK(found);
    }

    // ── Attribute names are lowercased ────────────────────────────────────────
    {
        auto toks = tokenize("<img SRC=\"x.png\">");
        for (auto& t : toks) {
            if (t.type == TokenType::StartTag && t.tag_name == "img") {
                CHECK(t.attr("src") == "x.png");
            }
        }
    }

    // ── EOF token always present ──────────────────────────────────────────────
    {
        auto toks = tokenize("<p>text</p>");
        CHECK(!toks.empty());
        CHECK(toks.back().type == TokenType::EndOfFile);
    }

    if (failures == 0)
        std::cout << "test_tokenizer: ALL PASSED\n";
    else
        std::cerr << "test_tokenizer: " << failures << " FAILURE(S)\n";

    return failures ? 1 : 0;
}
