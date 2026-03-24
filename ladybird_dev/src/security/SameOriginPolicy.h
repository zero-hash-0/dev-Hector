#pragma once

#include "net/URL.h"
#include <string>

namespace security {

// Enforces the Same-Origin Policy (SOP).
// Two URLs share the same origin iff their scheme, host, and port all match.
// References: https://html.spec.whatwg.org/multipage/origin.html
class SameOriginPolicy {
public:
    // Returns true when |requestor| and |target| share the same origin.
    static bool same_origin(const net::URL& requestor, const net::URL& target);

    // Returns true when cross-origin access to |target| is permitted for the
    // given |resource_type|.  Currently conservative: only allows navigation
    // and subresources marked as CORS-safe.
    enum class ResourceType { Navigation, Image, Script, Stylesheet, Font, Fetch };
    static bool may_access(const net::URL& requestor,
                            const net::URL& target,
                            ResourceType    resource_type);
};

} // namespace security
