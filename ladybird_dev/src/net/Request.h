#pragma once

#include "URL.h"
#include "Response.h"

#include <string>
#include <map>
#include <variant>
#include <cstdint>

namespace net {

struct NetworkError {
    std::string message;
};

class Request {
public:
    // Maximum allowed redirects before aborting
    static constexpr int MAX_REDIRECTS = 10;
    // Connect timeout in seconds
    static constexpr int CONNECT_TIMEOUT_S = 15;
    // Read timeout in seconds
    static constexpr int READ_TIMEOUT_S = 30;
    // Maximum response body size (10 MB)
    static constexpr size_t MAX_BODY_BYTES = 10 * 1024 * 1024;

    explicit Request(URL url);

    Request& set_header(std::string name, std::string value);
    Request& set_method(std::string method);

    // Perform the request synchronously. Follows redirects (same-origin only
    // for HTTPS → HTTP downgrades are blocked).
    std::variant<Response, NetworkError> send();

private:
    std::variant<Response, NetworkError> send_once(const URL& url);
    std::variant<Response, NetworkError> send_http(const URL& url);
    std::variant<Response, NetworkError> send_https(const URL& url);

    static Response parse_http_response(const std::string& raw);
    static bool     is_safe_redirect(const URL& from, const URL& to);

    URL         m_url;
    std::string m_method { "GET" };
    std::map<std::string, std::string, std::less<>> m_headers;
    int         m_redirect_count { 0 };
};

} // namespace net
