#pragma once

#include <cstdint>
#include <string>

namespace security {

// Sandbox flags for iframe and browsing-context isolation.
// Matches the HTML spec's sandbox keyword set.
// https://html.spec.whatwg.org/multipage/iframe-embed-object.html#attr-iframe-sandbox
enum class SandboxFlag : uint32_t {
    None                        = 0,
    AllowForms                  = 1 << 0,
    AllowModals                 = 1 << 1,
    AllowOrientationLock        = 1 << 2,
    AllowPointerLock            = 1 << 3,
    AllowPopups                 = 1 << 4,
    AllowPopupsToEscapeSandbox  = 1 << 5,
    AllowPresentation           = 1 << 6,
    AllowSameOrigin             = 1 << 7,
    AllowScripts                = 1 << 8,
    AllowTopNavigation          = 1 << 9,
    AllowTopNavigationByUser    = 1 << 10,
    AllowDownloads              = 1 << 11,
};

using SandboxFlags = uint32_t;

// Parse the value of an iframe sandbox= attribute into a flags bitmask.
SandboxFlags parse_sandbox_attribute(const std::string& attr_value);

inline bool has_flag(SandboxFlags flags, SandboxFlag f) {
    return (flags & static_cast<uint32_t>(f)) != 0;
}

} // namespace security
