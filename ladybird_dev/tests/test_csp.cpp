#include "security/ContentSecurityPolicy.h"
#include "security/SameOriginPolicy.h"
#include "security/SandboxFlags.h"
#include "net/URL.h"

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

    auto doc_url = net::URL::parse_or_null("https://example.com/page");
    assert(doc_url.has_value());

    // ── Permissive CSP allows everything ─────────────────────────────────────
    {
        auto csp = security::ContentSecurityPolicy::permissive();
        auto other = net::URL::parse_or_null("https://cdn.example.com/script.js");
        CHECK(csp.allows_script(*other));
        CHECK(csp.allows_image(*other));
    }

    // ── script-src 'self' blocks cross-origin scripts ─────────────────────────
    {
        auto csp = security::ContentSecurityPolicy::parse("script-src 'self'", *doc_url);
        auto same   = net::URL::parse_or_null("https://example.com/app.js");
        auto cross  = net::URL::parse_or_null("https://evil.com/malware.js");
        CHECK( csp.allows_script(*same));
        CHECK(!csp.allows_script(*cross));
    }

    // ── img-src * allows all images ───────────────────────────────────────────
    {
        auto csp  = security::ContentSecurityPolicy::parse("img-src *", *doc_url);
        auto img  = net::URL::parse_or_null("https://any-cdn.net/image.png");
        CHECK(csp.allows_image(*img));
    }

    // ── upgrade-insecure-requests ─────────────────────────────────────────────
    {
        auto csp = security::ContentSecurityPolicy::parse("upgrade-insecure-requests", *doc_url);
        CHECK(csp.upgrade_insecure_requests());
        CHECK(!csp.block_all_mixed_content());
    }

    // ── block-all-mixed-content ───────────────────────────────────────────────
    {
        auto csp = security::ContentSecurityPolicy::parse("block-all-mixed-content", *doc_url);
        CHECK(csp.block_all_mixed_content());
    }

    // ── SameOriginPolicy ─────────────────────────────────────────────────────
    {
        auto a = net::URL::parse_or_null("https://example.com/foo");
        auto b = net::URL::parse_or_null("https://example.com/bar");
        auto c = net::URL::parse_or_null("https://other.com/foo");
        auto d = net::URL::parse_or_null("http://example.com/foo");

        CHECK( security::SameOriginPolicy::same_origin(*a, *b));
        CHECK(!security::SameOriginPolicy::same_origin(*a, *c));
        CHECK(!security::SameOriginPolicy::same_origin(*a, *d)); // different scheme
    }

    // ── SandboxFlags ─────────────────────────────────────────────────────────
    {
        auto flags = security::parse_sandbox_attribute("allow-scripts allow-forms");
        CHECK( security::has_flag(flags, security::SandboxFlag::AllowScripts));
        CHECK( security::has_flag(flags, security::SandboxFlag::AllowForms));
        CHECK(!security::has_flag(flags, security::SandboxFlag::AllowSameOrigin));
        CHECK(!security::has_flag(flags, security::SandboxFlag::AllowPopups));
    }

    // ── Empty sandbox blocks everything ──────────────────────────────────────
    {
        auto flags = security::parse_sandbox_attribute("");
        CHECK(!security::has_flag(flags, security::SandboxFlag::AllowScripts));
        CHECK(!security::has_flag(flags, security::SandboxFlag::AllowForms));
    }

    if (failures == 0)
        std::cout << "test_csp: ALL PASSED\n";
    else
        std::cerr << "test_csp: " << failures << " FAILURE(S)\n";

    return failures ? 1 : 0;
}
