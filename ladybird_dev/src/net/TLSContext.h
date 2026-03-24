#pragma once

#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/x509v3.h>
#include <string>
#include <memory>

namespace net {

// RAII wrapper around an OpenSSL SSL_CTX.
// Configured with sane, secure defaults:
//   - TLS 1.2 minimum
//   - Strong cipher suites only
//   - Certificate verification enforced
//   - OCSP stapling requested
class TLSContext {
public:
    static TLSContext& global();

    TLSContext(const TLSContext&)            = delete;
    TLSContext& operator=(const TLSContext&) = delete;

    SSL_CTX* ctx() const noexcept { return m_ctx.get(); }

    // Verify the server's certificate for the given hostname.
    // Returns empty string on success, error description on failure.
    static std::string verify_peer(SSL* ssl, const std::string& hostname);

private:
    TLSContext();

    struct CTXDeleter {
        void operator()(SSL_CTX* p) const noexcept { SSL_CTX_free(p); }
    };
    std::unique_ptr<SSL_CTX, CTXDeleter> m_ctx;
};

} // namespace net
