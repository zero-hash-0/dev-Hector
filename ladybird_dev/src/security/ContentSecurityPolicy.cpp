#include "ContentSecurityPolicy.h"

#include <sstream>
#include <algorithm>
#include <cctype>

namespace security {

static std::string trim(std::string s) {
    auto b = s.find_first_not_of(" \t\r\n");
    if (b == std::string::npos) return {};
    auto e = s.find_last_not_of(" \t\r\n");
    return s.substr(b, e - b + 1);
}

static std::string to_lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c){ return static_cast<char>(std::tolower(c)); });
    return s;
}

ContentSecurityPolicy ContentSecurityPolicy::parse(const std::string& header_value,
                                                    const net::URL& document_url) {
    ContentSecurityPolicy csp;
    csp.m_document_url = document_url;

    // Split on ';'
    std::istringstream ss(header_value);
    std::string directive_str;
    while (std::getline(ss, directive_str, ';')) {
        directive_str = trim(directive_str);
        if (directive_str.empty()) continue;

        auto space = directive_str.find(' ');
        std::string name = to_lower(trim(
            space == std::string::npos ? directive_str : directive_str.substr(0, space)));
        std::string value = (space == std::string::npos)
                          ? ""
                          : trim(directive_str.substr(space + 1));

        // Parse source list
        SourceList sources;
        std::istringstream vs(value);
        std::string token;
        while (vs >> token) sources.push_back(to_lower(token));

        // Map name → Directive enum
        if      (name == "default-src")                 csp.m_directives[Directive::DefaultSrc]    = sources;
        else if (name == "script-src")                  csp.m_directives[Directive::ScriptSrc]     = sources;
        else if (name == "style-src")                   csp.m_directives[Directive::StyleSrc]      = sources;
        else if (name == "img-src")                     csp.m_directives[Directive::ImgSrc]        = sources;
        else if (name == "connect-src")                 csp.m_directives[Directive::ConnectSrc]    = sources;
        else if (name == "font-src")                    csp.m_directives[Directive::FontSrc]       = sources;
        else if (name == "frame-src")                   csp.m_directives[Directive::FrameSrc]      = sources;
        else if (name == "media-src")                   csp.m_directives[Directive::MediaSrc]      = sources;
        else if (name == "object-src")                  csp.m_directives[Directive::ObjectSrc]     = sources;
        else if (name == "base-uri")                    csp.m_directives[Directive::BaseUri]       = sources;
        else if (name == "form-action")                 csp.m_directives[Directive::FormAction]    = sources;
        else if (name == "frame-ancestors")             csp.m_directives[Directive::FrameAncestors]= sources;
        else if (name == "upgrade-insecure-requests")   csp.m_upgrade_insecure = true;
        else if (name == "block-all-mixed-content")     csp.m_block_mixed      = true;
    }

    return csp;
}

ContentSecurityPolicy ContentSecurityPolicy::permissive() {
    return {}; // empty = no restrictions
}

// Returns the effective source list for a directive, falling back to default-src
const ContentSecurityPolicy::SourceList&
ContentSecurityPolicy::effective_list(Directive d) const {
    if (auto it = m_directives.find(d); it != m_directives.end())
        return it->second;
    // Fall back to default-src
    if (auto it = m_directives.find(Directive::DefaultSrc); it != m_directives.end())
        return it->second;
    static const SourceList empty;
    return empty;
}

bool ContentSecurityPolicy::source_matches(const std::string& source,
                                            const net::URL& url) const {
    if (source == "*")          return true;
    if (source == "'none'")     return false;
    if (source == "'self'")
        return url.origin() == m_document_url.origin();

    // Scheme-only: "https:" or "http:"
    if (source.back() == ':') {
        std::string scheme = source.substr(0, source.size() - 1);
        if (url.scheme() == net::URL::Scheme::HTTPS && scheme == "https") return true;
        if (url.scheme() == net::URL::Scheme::HTTP  && scheme == "http")  return true;
        return false;
    }

    // Host source (potentially with wildcard prefix)
    auto url_opt = net::URL::parse_or_null("https://" + source);
    if (!url_opt) return false;

    // Simple host match (ignore port/path for now)
    std::string src_host = url_opt->host();
    std::string tgt_host = url.host();

    if (src_host.starts_with("*.")) {
        std::string suffix = src_host.substr(1); // ".example.com"
        if (tgt_host == src_host.substr(2))      return true; // exact base
        if (tgt_host.size() > suffix.size() &&
            tgt_host.substr(tgt_host.size() - suffix.size()) == suffix)
            return true;
        return false;
    }

    return src_host == tgt_host;
}

bool ContentSecurityPolicy::source_allowed(const SourceList& list,
                                            const net::URL& url) const {
    if (list.empty()) return true; // no restriction
    for (auto& src : list)
        if (source_matches(src, url)) return true;
    return false;
}

bool ContentSecurityPolicy::allows_script(const net::URL& r)  const { return source_allowed(effective_list(Directive::ScriptSrc),  r); }
bool ContentSecurityPolicy::allows_style(const net::URL& r)   const { return source_allowed(effective_list(Directive::StyleSrc),   r); }
bool ContentSecurityPolicy::allows_image(const net::URL& r)   const { return source_allowed(effective_list(Directive::ImgSrc),     r); }
bool ContentSecurityPolicy::allows_connect(const net::URL& r) const { return source_allowed(effective_list(Directive::ConnectSrc), r); }
bool ContentSecurityPolicy::allows_frame(const net::URL& r)   const { return source_allowed(effective_list(Directive::FrameSrc),   r); }
bool ContentSecurityPolicy::allows_font(const net::URL& r)    const { return source_allowed(effective_list(Directive::FontSrc),    r); }
bool ContentSecurityPolicy::upgrade_insecure_requests()        const { return m_upgrade_insecure; }
bool ContentSecurityPolicy::block_all_mixed_content()          const { return m_block_mixed; }

} // namespace security
