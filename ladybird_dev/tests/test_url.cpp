#include "net/URL.h"

#include <cassert>
#include <iostream>
#include <string>

#define CHECK(cond) do { \
    if (!(cond)) { \
        std::cerr << "FAIL [line " << __LINE__ << "]: " #cond "\n"; \
        failures++; \
    } \
} while(0)

int main() {
    int failures = 0;

    // ── Basic HTTPS parse ─────────────────────────────────────────────────────
    {
        auto r = net::URL::parse("https://example.com/path?q=1#frag");
        assert(std::holds_alternative<net::URL>(r));
        auto& u = std::get<net::URL>(r);
        CHECK(u.scheme() == net::URL::Scheme::HTTPS);
        CHECK(u.host()   == "example.com");
        CHECK(u.port()   == 443);
        CHECK(u.path()   == "/path");
        CHECK(u.query()  == "q=1");
        CHECK(u.fragment()== "frag");
        CHECK(u.is_secure());
    }

    // ── HTTP with explicit port ───────────────────────────────────────────────
    {
        auto r = net::URL::parse("http://localhost:8080/");
        assert(std::holds_alternative<net::URL>(r));
        auto& u = std::get<net::URL>(r);
        CHECK(u.scheme() == net::URL::Scheme::HTTP);
        CHECK(u.host()   == "localhost");
        CHECK(u.port()   == 8080);
        CHECK(!u.is_secure());
    }

    // ── Host is lowercased ────────────────────────────────────────────────────
    {
        auto r = net::URL::parse("https://Example.COM/");
        assert(std::holds_alternative<net::URL>(r));
        CHECK(std::get<net::URL>(r).host() == "example.com");
    }

    // ── Userinfo rejected ─────────────────────────────────────────────────────
    {
        auto r = net::URL::parse("https://user:pass@example.com/");
        CHECK(std::holds_alternative<net::URL::ParseError>(r));
    }

    // ── Empty host rejected ───────────────────────────────────────────────────
    {
        auto r = net::URL::parse("https:///path");
        CHECK(std::holds_alternative<net::URL::ParseError>(r));
    }

    // ── Invalid port rejected ─────────────────────────────────────────────────
    {
        auto r = net::URL::parse("http://example.com:99999/");
        CHECK(std::holds_alternative<net::URL::ParseError>(r));
    }

    // ── Missing scheme rejected ───────────────────────────────────────────────
    {
        auto r = net::URL::parse("example.com/path");
        CHECK(std::holds_alternative<net::URL::ParseError>(r));
    }

    // ── origin() ─────────────────────────────────────────────────────────────
    {
        auto r = net::URL::parse("https://example.com:8443/foo");
        assert(std::holds_alternative<net::URL>(r));
        CHECK(std::get<net::URL>(r).origin() == "https://example.com:8443");
    }

    // ── resolve() — absolute ──────────────────────────────────────────────────
    {
        auto base = net::URL::parse_or_null("https://example.com/a/b/page.html");
        assert(base.has_value());
        auto abs = base->resolve("https://other.com/foo");
        assert(abs.has_value());
        CHECK(abs->host() == "other.com");
    }

    // ── resolve() — absolute path ─────────────────────────────────────────────
    {
        auto base = net::URL::parse_or_null("https://example.com/a/b/page.html");
        assert(base.has_value());
        auto resolved = base->resolve("/new/path");
        assert(resolved.has_value());
        CHECK(resolved->path() == "/new/path");
        CHECK(resolved->host() == "example.com");
    }

    // ── to_string() round-trip ────────────────────────────────────────────────
    {
        std::string raw = "https://example.com/path?q=1";
        auto r = net::URL::parse(raw);
        assert(std::holds_alternative<net::URL>(r));
        CHECK(std::get<net::URL>(r).to_string() == raw);
    }

    if (failures == 0)
        std::cout << "test_url: ALL PASSED\n";
    else
        std::cerr << "test_url: " << failures << " FAILURE(S)\n";

    return failures ? 1 : 0;
}
