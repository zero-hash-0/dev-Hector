#include "SameOriginPolicy.h"

namespace security {

bool SameOriginPolicy::same_origin(const net::URL& a, const net::URL& b) {
    return a.scheme() == b.scheme()
        && a.host()   == b.host()
        && a.port()   == b.port();
}

bool SameOriginPolicy::may_access(const net::URL& requestor,
                                   const net::URL& target,
                                   ResourceType    resource_type) {
    if (same_origin(requestor, target))
        return true;

    // Cross-origin rules
    switch (resource_type) {
        case ResourceType::Navigation:
            // Navigation to cross-origin is permitted (links, redirects)
            return true;

        case ResourceType::Image:
            // Images are embeddable cross-origin (tainted canvas rules apply)
            return true;

        case ResourceType::Script:
        case ResourceType::Stylesheet:
        case ResourceType::Font:
            // Classical cross-origin subresource loads allowed by embedding
            // CORS headers on the server are handled separately
            return true;

        case ResourceType::Fetch:
            // Fetch API requires CORS — deny by default without header check
            return false;
    }

    return false;
}

} // namespace security
