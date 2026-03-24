#pragma once

#include "net/URL.h"
#include <string>
#include <vector>
#include <map>

namespace security {

// Parses and evaluates Content-Security-Policy headers.
// Spec: https://www.w3.org/TR/CSP3/
class ContentSecurityPolicy {
public:
    enum class Directive {
        DefaultSrc,
        ScriptSrc,
        StyleSrc,
        ImgSrc,
        ConnectSrc,
        FontSrc,
        FrameSrc,
        MediaSrc,
        ObjectSrc,
        BaseUri,
        FormAction,
        FrameAncestors,
        UpgradeInsecureRequests,
        BlockAllMixedContent,
    };

    // Parse from a Content-Security-Policy header value
    static ContentSecurityPolicy parse(const std::string& header_value,
                                       const net::URL&     document_url);

    // Returns true if loading |resource| as the given type is allowed
    [[nodiscard]] bool allows_script(const net::URL& resource)    const;
    [[nodiscard]] bool allows_style(const net::URL& resource)     const;
    [[nodiscard]] bool allows_image(const net::URL& resource)     const;
    [[nodiscard]] bool allows_connect(const net::URL& resource)   const;
    [[nodiscard]] bool allows_frame(const net::URL& resource)     const;
    [[nodiscard]] bool allows_font(const net::URL& resource)      const;
    [[nodiscard]] bool upgrade_insecure_requests()                 const;
    [[nodiscard]] bool block_all_mixed_content()                   const;

    // Returns an empty (allow-all) policy
    static ContentSecurityPolicy permissive();

private:
    using SourceList = std::vector<std::string>;

    bool source_allowed(const SourceList& list, const net::URL& url) const;
    bool source_matches(const std::string& source, const net::URL& url) const;

    const SourceList& effective_list(Directive d) const;

    std::map<Directive, SourceList> m_directives;
    net::URL                        m_document_url;
    bool                            m_upgrade_insecure { false };
    bool                            m_block_mixed      { false };
};

} // namespace security
