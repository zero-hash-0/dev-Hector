#pragma once

#include <string>
#include <string_view>
#include <optional>
#include <variant>
#include <cstdint>

namespace net {

// Represents a parsed URL following RFC 3986 / WHATWG URL Standard.
// Immutable after construction. Use URL::parse() to build instances.
class URL {
public:
    enum class Scheme { HTTP, HTTPS, Unknown };

    struct ParseError {
        std::string reason;
    };

    static std::variant<URL, ParseError> parse(std::string_view raw);
    static std::optional<URL>            parse_or_null(std::string_view raw);

    // Origin components
    [[nodiscard]] Scheme      scheme()   const noexcept { return m_scheme; }
    [[nodiscard]] std::string host()     const noexcept { return m_host; }
    [[nodiscard]] uint16_t    port()     const noexcept { return m_port; }
    [[nodiscard]] std::string path()     const noexcept { return m_path; }
    [[nodiscard]] std::string query()    const noexcept { return m_query; }
    [[nodiscard]] std::string fragment() const noexcept { return m_fragment; }

    // Serialise back to string
    [[nodiscard]] std::string to_string() const;

    // Returns "scheme://host:port" — used for same-origin checks
    [[nodiscard]] std::string origin() const;

    [[nodiscard]] bool is_secure() const noexcept { return m_scheme == Scheme::HTTPS; }

    // Resolve a relative URL against this base
    [[nodiscard]] std::optional<URL> resolve(std::string_view relative) const;

    bool operator==(const URL&) const = default;

    // Default-constructed URL is an empty/invalid placeholder.
    // Prefer URL::parse() or URL::parse_or_null() for validated URLs.
    URL() = default;

public:

    Scheme      m_scheme   { Scheme::Unknown };
    std::string m_host     {};
    uint16_t    m_port     { 0 };
    std::string m_path     { "/" };
    std::string m_query    {};
    std::string m_fragment {};
};

} // namespace net
