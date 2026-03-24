#include "html/Parser.h"
#include "dom/Document.h"
#include "dom/Element.h"

#include <cassert>
#include <iostream>

#define CHECK(cond) do { \
    if (!(cond)) { \
        std::cerr << "FAIL [line " << __LINE__ << "]: " #cond "\n"; \
        failures++; \
    } \
} while(0)

int main() {
    int failures = 0;

    // ── Full document ─────────────────────────────────────────────────────────
    {
        auto doc = html::Parser::parse(
            "<!DOCTYPE html><html><head><title>Test</title></head>"
            "<body><h1>Hello</h1><p>World</p></body></html>");

        CHECK(doc != nullptr);
        CHECK(doc->title() == "Test");

        auto* body = doc->body();
        CHECK(body != nullptr);

        auto* h1 = body->query_selector("h1");
        CHECK(h1 != nullptr);
        CHECK(h1->text_content() == "Hello");

        auto* p = body->query_selector("p");
        CHECK(p != nullptr);
        CHECK(p->text_content() == "World");
    }

    // ── get_element_by_id ─────────────────────────────────────────────────────
    {
        auto doc = html::Parser::parse(
            "<html><body><div id=\"main\">content</div></body></html>");
        auto* el = doc->get_element_by_id("main");
        CHECK(el != nullptr);
        CHECK(el->tag_name() == "div");
        CHECK(el->text_content() == "content");
    }

    // ── get_elements_by_tag ───────────────────────────────────────────────────
    {
        auto doc = html::Parser::parse(
            "<html><body><p>A</p><p>B</p><p>C</p></body></html>");
        auto ps = doc->get_elements_by_tag("p");
        CHECK(ps.size() == 3);
    }

    // ── Attributes ────────────────────────────────────────────────────────────
    {
        auto doc = html::Parser::parse(
            "<html><body><a href=\"/link\" class=\"nav active\">click</a></body></html>");
        auto* a = doc->body()->query_selector("a");
        CHECK(a != nullptr);
        CHECK(a->get_attr("href") == "/link");
        auto cls = a->class_list();
        CHECK(cls.size() == 2);
        CHECK(cls[0] == "nav");
        CHECK(cls[1] == "active");
    }

    // ── Quirks mode without DOCTYPE ───────────────────────────────────────────
    {
        auto doc = html::Parser::parse("<html><body>hi</body></html>");
        CHECK(doc->quirks_mode() == dom::Document::Mode::Quirks);
    }

    // ── No-quirks mode with DOCTYPE ───────────────────────────────────────────
    {
        auto doc = html::Parser::parse("<!DOCTYPE html><html><body>hi</body></html>");
        CHECK(doc->quirks_mode() == dom::Document::Mode::NoQuirks);
    }

    // ── Implied html/head/body ────────────────────────────────────────────────
    {
        auto doc = html::Parser::parse("<p>Hello</p>");
        CHECK(doc->body() != nullptr);
        CHECK(doc->head() != nullptr);
    }

    if (failures == 0)
        std::cout << "test_parser: ALL PASSED\n";
    else
        std::cerr << "test_parser: " << failures << " FAILURE(S)\n";

    return failures ? 1 : 0;
}
