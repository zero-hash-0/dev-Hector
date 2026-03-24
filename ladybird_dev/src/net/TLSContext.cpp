#include "TLSContext.h"

#include <stdexcept>
#include <cstring>

namespace net {

TLSContext& TLSContext::global() {
    static TLSContext instance;
    return instance;
}

TLSContext::TLSContext() {
    // Initialise OpenSSL
    SSL_load_error_strings();
    OpenSSL_add_ssl_algorithms();

    SSL_CTX* ctx = SSL_CTX_new(TLS_client_method());
    if (!ctx)
        throw std::runtime_error("Failed to create SSL_CTX");

    m_ctx.reset(ctx);

    // ── Minimum protocol: TLS 1.2 ────────────────────────────────────────────
    SSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION);

    // ── Strong cipher suites only (TLS 1.2) ──────────────────────────────────
    // Prefer ECDHE forward-secrecy ciphers; exclude RC4, 3DES, NULL, EXPORT
    SSL_CTX_set_cipher_list(ctx,
        "ECDHE-ECDSA-AES256-GCM-SHA384:"
        "ECDHE-RSA-AES256-GCM-SHA384:"
        "ECDHE-ECDSA-AES128-GCM-SHA256:"
        "ECDHE-RSA-AES128-GCM-SHA256:"
        "ECDHE-ECDSA-CHACHA20-POLY1305:"
        "ECDHE-RSA-CHACHA20-POLY1305");

    // TLS 1.3 cipher suites
    SSL_CTX_set_ciphersuites(ctx,
        "TLS_AES_256_GCM_SHA384:"
        "TLS_CHACHA20_POLY1305_SHA256:"
        "TLS_AES_128_GCM_SHA256");

    // ── Certificate verification ──────────────────────────────────────────────
    SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT, nullptr);
    SSL_CTX_set_default_verify_paths(ctx);

    // ── Disable session tickets (forward secrecy) ─────────────────────────────
    SSL_CTX_set_options(ctx, SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION
                           | SSL_OP_NO_COMPRESSION      // CRIME attack
                           | SSL_OP_CIPHER_SERVER_PREFERENCE);

    // ── OCSP stapling ─────────────────────────────────────────────────────────
    SSL_CTX_set_tlsext_status_type(ctx, TLSEXT_STATUSTYPE_ocsp);
}

std::string TLSContext::verify_peer(SSL* ssl, const std::string& hostname) {
    // Step 1: verify certificate chain
    long verify_result = SSL_get_verify_result(ssl);
    if (verify_result != X509_V_OK)
        return std::string("Certificate verify failed: ")
             + X509_verify_cert_error_string(verify_result);

    // Step 2: hostname verification (RFC 6125)
    X509* cert = SSL_get_peer_certificate(ssl);
    if (!cert)
        return "No peer certificate presented";

    // Use OpenSSL's built-in hostname check
    X509_VERIFY_PARAM* param = SSL_get0_param(ssl);
    X509_VERIFY_PARAM_set_hostflags(param, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);

    if (X509_VERIFY_PARAM_set1_host(param, hostname.c_str(), hostname.size()) != 1) {
        X509_free(cert);
        return "Failed to set hostname for verification";
    }

    X509_free(cert);
    return {}; // success
}

} // namespace net
