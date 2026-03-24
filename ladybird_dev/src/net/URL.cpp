#include "URL.h"

#include <sstream>
#include <algorithm>
#include <cctype>

namespace net {

static std::string to_lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return s;
}

static bool is_valid_host_char(char c) {
    return std::isalnum(static_cast<unsigned char>(c))
        || c == '-' || c == '.' || c == '[' || c == ']'; // IPv6 brackets
}

std::variant<URL, URL::ParseError> URL::parse(std::string_view raw) {
    URL url;

    if (raw.empty())
        return ParseError{ "empty URL" };

    // ── Scheme ──────────────────────────────────────────────────────────────
    auto scheme_end = raw.find("://");
    if (scheme_end == std::string_view::npos)
        return ParseError{ "missing scheme" };

    std::string scheme_str = to_lower(std::string(raw.substr(0, scheme_end)));
    if (scheme_str == "https")       url.m_scheme = Scheme::HTTPS;
    else if (scheme_str == "http")   url.m_scheme = Scheme::HTTP;
    else if (scheme_str == "file") {
        // file:///path/to/file — host is empty, path starts after ://
        url.m_scheme = Scheme::File;
        url.m_host   = {};
        url.m_port   = 0;
        // Everything after "file://" is the path
        std::string_view file_rest = raw.substr(scheme_end + 3);
        // Strip leading slash for file:///abs/path → /abs/path
        url.m_path = file_rest.empty() ? "/" : std::string(file_rest);
        // Override to_string for file:// so it serialises cleanly
        return url;
    }
    else                             return ParseError{ "unsupported scheme: " + scheme_str };

    // ── Authority (host:port) ────────────────────────────────────────────────
    std::string_view rest = raw.substr(scheme_end + 3);

    auto path_start  = rest.find('/');
    auto query_start = rest.find('?');
    auto auth_end    = std::min(path_start, query_start);

    std::string_view authority = rest.substr(0, auth_end);

    // Reject userinfo (user:pass@host) — security risk
    if (authority.find('@') != std::string_view::npos)
        return ParseError{ "userinfo in URL is not permitted" };

    // port
    auto colon = authority.rfind(':');
    if (colon != std::string_view::npos) {
        std::string port_str(authority.substr(colon + 1));
        if (port_str.empty() || !std::all_of(port_str.begin(), port_str.end(),
                                              [](char c){ return std::isdigit(static_cast<unsigned char>(c)); }))
            return ParseError{ "invalid port" };

        int port = std::stoi(port_str);
        if (port < 1 || port > 65535)
            return ParseError{ "port out of range" };

        url.m_port = static_cast<uint16_t>(port);
        url.m_host = to_lower(std::string(authority.substr(0, colon)));
    } else {
        url.m_host = to_lower(std::string(authority));
        url.m_port = (url.m_scheme == Scheme::HTTPS) ? 443 : 80;
    }

    if (url.m_host.empty())
        return ParseError{ "empty host" };

    for (char c : url.m_host) {
        if (!is_valid_host_char(c))
            return ParseError{ std::string("invalid character in host: ") + c };
    }

    // ── Path ────────────────────────────────────────────────────────────────
    if (auth_end == std::string_view::npos) {
        url.m_path = "/";
    } else {
        rest = rest.substr(auth_end);
        auto qpos = rest.find('?');
        auto fpos = rest.find('#');
        url.m_path = std::string(rest.substr(0, std::min(qpos, fpos)));
        if (url.m_path.empty()) url.m_path = "/";

        // ── Query ────────────────────────────────────────────────────────
        if (qpos != std::string_view::npos) {
            rest = rest.substr(qpos + 1);
            auto fp2 = rest.find('#');
            url.m_query = std::string(rest.substr(0, fp2));
            if (fp2 != std::string_view::npos)
                url.m_fragment = std::string(rest.substr(fp2 + 1));
        } else if (fpos != std::string_view::npos) {
            url.m_fragment = std::string(rest.substr(fpos + 1));
        }
    }

    return url;
}

std::optional<URL> URL::parse_or_null(std::string_view raw) {
    auto result = parse(raw);
    if (std::holds_alternative<URL>(result))
        return std::get<URL>(result);
    return std::nullopt;
}

std::string URL::to_string() const {
    if (m_scheme == Scheme::File)
        return "file://" + m_path;
    std::ostringstream ss;
    ss << (m_scheme == Scheme::HTTPS ? "https" : "http") << "://";
    ss << m_host;
    bool default_port = (m_scheme == Scheme::HTTPS && m_port == 443)
                     || (m_scheme == Scheme::HTTP  && m_port == 80);
    if (!default_port) ss << ':' << m_port;
    ss << m_path;
    if (!m_query.empty())    ss << '?' << m_query;
    if (!m_fragment.empty()) ss << '#' << m_fragment;
    return ss.str();
}

std::string URL::origin() const {
    if (m_scheme == Scheme::File) return "null"; // file:// has opaque origin
    std::ostringstream ss;
    ss << (m_scheme == Scheme::HTTPS ? "https" : "http") << "://";
    ss << m_host;
    bool default_port = (m_scheme == Scheme::HTTPS && m_port == 443)
                     || (m_scheme == Scheme::HTTP  && m_port == 80);
    if (!default_port) ss << ':' << m_port;
    return ss.str();
}

std::optional<URL> URL::resolve(std::string_view relative) const {
    if (relative.empty()) return *this;

    // Absolute URL — parse directly
    if (relative.find("://") != std::string_view::npos)
        return parse_or_null(relative);

    URL resolved = *this;
    resolved.m_fragment = {};

    if (relative.starts_with("//")) {
        // Protocol-relative
        std::string full = (m_scheme == Scheme::HTTPS ? "https:" : "http:");
        full += relative;
        return parse_or_null(full);
    }

    if (relative.starts_with('/')) {
        resolved.m_path  = std::string(relative);
        resolved.m_query = {};
        return resolved;
    }

    if (relative.starts_with('?')) {
        resolved.m_query    = std::string(relative.substr(1));
        resolved.m_fragment = {};
        return resolved;
    }

    if (relative.starts_with('#')) {
        resolved.m_fragment = std::string(relative.substr(1));
        return resolved;
    }

    // Relative path — merge with base path
    std::string base = m_path;
    auto last_slash = base.rfind('/');
    if (last_slash != std::string::npos)
        base = base.substr(0, last_slash + 1);
    else
        base = "/";

    resolved.m_path  = base + std::string(relative);
    resolved.m_query = {};
    return resolved;
}

} // namespace net
