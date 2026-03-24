#include "Request.h"
#include "TLSContext.h"

#include <openssl/ssl.h>
#include <openssl/err.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <cerrno>
#include <cstring>
#include <sstream>
#include <algorithm>
#include <cctype>
#include <stdexcept>

namespace net {

// ── Socket helpers ────────────────────────────────────────────────────────────

static int connect_tcp(const std::string& host, uint16_t port, std::string& err) {
    addrinfo hints {};
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags    = AI_NUMERICSERV;

    addrinfo* res = nullptr;
    std::string port_str = std::to_string(port);

    int rc = getaddrinfo(host.c_str(), port_str.c_str(), &hints, &res);
    if (rc != 0) {
        err = gai_strerror(rc);
        return -1;
    }

    int fd = -1;
    for (addrinfo* rp = res; rp != nullptr; rp = rp->ai_next) {
        fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd < 0) continue;

        // Non-blocking connect with timeout
        fcntl(fd, F_SETFL, O_NONBLOCK);
        int cr = connect(fd, rp->ai_addr, rp->ai_addrlen);

        if (cr == 0) break; // connected immediately

        if (errno == EINPROGRESS) {
            pollfd pfd { fd, POLLOUT, 0 };
            int pr = poll(&pfd, 1, Request::CONNECT_TIMEOUT_S * 1000);
            if (pr == 1 && (pfd.revents & POLLOUT)) {
                int so_err = 0;
                socklen_t slen = sizeof(so_err);
                getsockopt(fd, SOL_SOCKET, SO_ERROR, &so_err, &slen);
                if (so_err == 0) break; // connected
            }
        }

        close(fd);
        fd = -1;
    }

    freeaddrinfo(res);

    if (fd < 0) {
        err = "Could not connect to " + host + ":" + port_str;
        return -1;
    }

    // Restore blocking mode
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);

    // Set read timeout
    timeval tv { Request::READ_TIMEOUT_S, 0 };
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    return fd;
}

// ── Request ───────────────────────────────────────────────────────────────────

Request::Request(URL url) : m_url(std::move(url)) {
    // Default headers — all browsers send these
    m_headers["user-agent"]      = "LadyBird/0.1";
    m_headers["accept"]          = "text/html,application/xhtml+xml,*/*;q=0.8";
    m_headers["accept-language"] = "en-US,en;q=0.9";
    m_headers["accept-encoding"] = "identity"; // keep it simple for now
    m_headers["connection"]      = "close";
}

Request& Request::set_header(std::string name, std::string value) {
    // Sanitise: strip CR/LF to prevent header injection
    std::erase(name,  '\r'); std::erase(name,  '\n');
    std::erase(value, '\r'); std::erase(value, '\n');
    m_headers[std::move(name)] = std::move(value);
    return *this;
}

Request& Request::set_method(std::string method) {
    // Whitelist safe methods
    if (method != "GET" && method != "HEAD")
        throw std::invalid_argument("Only GET and HEAD are supported");
    m_method = std::move(method);
    return *this;
}

std::variant<Response, NetworkError> Request::send() {
    return send_once(m_url);
}

std::variant<Response, NetworkError> Request::send_once(const URL& url) {
    if (m_redirect_count > MAX_REDIRECTS)
        return NetworkError{ "Too many redirects" };

    auto result = (url.scheme() == URL::Scheme::HTTPS)
                ? send_https(url)
                : send_http(url);

    if (std::holds_alternative<NetworkError>(result))
        return result;

    auto& resp = std::get<Response>(result);

    if (resp.is_redirect()) {
        std::string location = resp.header("location");
        if (location.empty())
            return NetworkError{ "Redirect with no Location header" };

        auto next_url = url.resolve(location);
        if (!next_url)
            return NetworkError{ "Invalid redirect URL: " + location };

        // Block HTTPS → HTTP downgrade
        if (!is_safe_redirect(url, *next_url))
            return NetworkError{ "Blocked HTTPS → HTTP redirect (security)" };

        ++m_redirect_count;
        return send_once(*next_url);
    }

    return result;
}

bool Request::is_safe_redirect(const URL& from, const URL& to) {
    // Never downgrade from HTTPS to HTTP
    if (from.is_secure() && !to.is_secure())
        return false;
    return true;
}

static std::string build_request_line(const std::string& method,
                                      const URL& url) {
    std::ostringstream ss;
    ss << method << ' ' << url.path();
    if (!url.query().empty()) ss << '?' << url.query();
    ss << " HTTP/1.1\r\n";
    ss << "Host: " << url.host();
    if ((url.scheme() == URL::Scheme::HTTPS && url.port() != 443) ||
        (url.scheme() == URL::Scheme::HTTP  && url.port() != 80))
        ss << ':' << url.port();
    ss << "\r\n";
    return ss.str();
}

Response Request::parse_http_response(const std::string& raw) {
    Response resp;

    auto header_end = raw.find("\r\n\r\n");
    if (header_end == std::string::npos)
        return resp;

    std::istringstream ss(raw.substr(0, header_end));
    std::string status_line;
    std::getline(ss, status_line);

    // Parse status line: HTTP/1.x NNN text
    auto sp1 = status_line.find(' ');
    if (sp1 != std::string::npos) {
        auto sp2 = status_line.find(' ', sp1 + 1);
        resp.status_code = static_cast<uint16_t>(
            std::stoi(status_line.substr(sp1 + 1, sp2 - sp1 - 1)));
        if (sp2 != std::string::npos)
            resp.status_text = status_line.substr(sp2 + 1);
    }

    // Parse headers
    std::string line;
    while (std::getline(ss, line)) {
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        if (line.empty()) break;
        auto colon = line.find(':');
        if (colon == std::string::npos) continue;
        std::string key = line.substr(0, colon);
        std::string val = line.substr(colon + 1);
        // Trim leading whitespace from value
        auto trim = val.find_first_not_of(" \t");
        if (trim != std::string::npos) val = val.substr(trim);
        // Lowercase key for case-insensitive lookup
        std::transform(key.begin(), key.end(), key.begin(),
                       [](unsigned char c){ return static_cast<char>(std::tolower(c)); });
        resp.headers[std::move(key)] = std::move(val);
    }

    // Body
    std::string body_str = raw.substr(header_end + 4);
    resp.body.assign(body_str.begin(), body_str.end());

    return resp;
}

std::variant<Response, NetworkError> Request::send_http(const URL& url) {
    std::string err;
    int fd = connect_tcp(url.host(), url.port(), err);
    if (fd < 0) return NetworkError{ err };

    // Build request
    std::ostringstream req;
    req << build_request_line(m_method, url);
    for (auto& [k, v] : m_headers) req << k << ": " << v << "\r\n";
    req << "\r\n";

    std::string req_str = req.str();
    if (::send(fd, req_str.data(), req_str.size(), MSG_NOSIGNAL) < 0) {
        close(fd);
        return NetworkError{ "send() failed: " + std::string(strerror(errno)) };
    }

    // Read response (bounded to MAX_BODY_BYTES)
    std::string raw;
    char buf[4096];
    ssize_t n;
    while ((n = ::recv(fd, buf, sizeof(buf), 0)) > 0) {
        raw.append(buf, static_cast<size_t>(n));
        if (raw.size() > MAX_BODY_BYTES) {
            close(fd);
            return NetworkError{ "Response exceeded size limit" };
        }
    }

    close(fd);
    return parse_http_response(raw);
}

std::variant<Response, NetworkError> Request::send_https(const URL& url) {
    std::string err;
    int fd = connect_tcp(url.host(), url.port(), err);
    if (fd < 0) return NetworkError{ err };

    SSL* ssl = SSL_new(TLSContext::global().ctx());
    if (!ssl) {
        close(fd);
        return NetworkError{ "SSL_new failed" };
    }

    SSL_set_fd(ssl, fd);
    SSL_set_tlsext_host_name(ssl, url.host().c_str()); // SNI

    // Enforce hostname verification before connecting
    SSL_set_hostflags(ssl, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
    SSL_set1_host(ssl, url.host().c_str());

    if (SSL_connect(ssl) != 1) {
        char ebuf[256];
        ERR_error_string_n(ERR_get_error(), ebuf, sizeof(ebuf));
        SSL_free(ssl);
        close(fd);
        return NetworkError{ std::string("TLS handshake failed: ") + ebuf };
    }

    // Verify certificate
    std::string verify_err = TLSContext::verify_peer(ssl, url.host());
    if (!verify_err.empty()) {
        SSL_free(ssl);
        close(fd);
        return NetworkError{ verify_err };
    }

    // Build and send request
    std::ostringstream req;
    req << build_request_line(m_method, url);
    for (auto& [k, v] : m_headers) req << k << ": " << v << "\r\n";
    req << "\r\n";

    std::string req_str = req.str();
    if (SSL_write(ssl, req_str.data(), static_cast<int>(req_str.size())) <= 0) {
        SSL_free(ssl);
        close(fd);
        return NetworkError{ "SSL_write failed" };
    }

    // Read response
    std::string raw;
    char buf[4096];
    int n;
    while ((n = SSL_read(ssl, buf, sizeof(buf))) > 0) {
        raw.append(buf, static_cast<size_t>(n));
        if (raw.size() > MAX_BODY_BYTES) {
            SSL_shutdown(ssl);
            SSL_free(ssl);
            close(fd);
            return NetworkError{ "Response exceeded size limit" };
        }
    }

    SSL_shutdown(ssl);
    SSL_free(ssl);
    close(fd);

    return parse_http_response(raw);
}

} // namespace net
