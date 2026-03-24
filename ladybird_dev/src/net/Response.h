#pragma once

#include <string>
#include <map>
#include <vector>
#include <cstdint>

namespace net {

class Response {
public:
    uint16_t                                   status_code  { 0 };
    std::string                                status_text  {};
    std::map<std::string, std::string, std::less<>> headers {};
    std::vector<uint8_t>                       body         {};

    // ── Helpers ──────────────────────────────────────────────────────────────
    [[nodiscard]] bool ok() const noexcept {
        return status_code >= 200 && status_code < 300;
    }

    [[nodiscard]] bool is_redirect() const noexcept {
        return status_code == 301 || status_code == 302
            || status_code == 303 || status_code == 307
            || status_code == 308;
    }

    [[nodiscard]] std::string header(std::string_view name) const;
    [[nodiscard]] std::string body_as_string() const;
    [[nodiscard]] std::string content_type() const;
    [[nodiscard]] std::string charset() const;
};

} // namespace net
