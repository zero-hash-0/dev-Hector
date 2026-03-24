#include "SandboxFlags.h"

#include <sstream>
#include <algorithm>
#include <cctype>

namespace security {

SandboxFlags parse_sandbox_attribute(const std::string& attr_value) {
    SandboxFlags flags = static_cast<uint32_t>(SandboxFlag::None);

    std::istringstream ss(attr_value);
    std::string token;
    while (ss >> token) {
        std::transform(token.begin(), token.end(), token.begin(),
                       [](unsigned char c){ return static_cast<char>(std::tolower(c)); });

        if      (token == "allow-forms")                     flags |= static_cast<uint32_t>(SandboxFlag::AllowForms);
        else if (token == "allow-modals")                    flags |= static_cast<uint32_t>(SandboxFlag::AllowModals);
        else if (token == "allow-orientation-lock")          flags |= static_cast<uint32_t>(SandboxFlag::AllowOrientationLock);
        else if (token == "allow-pointer-lock")              flags |= static_cast<uint32_t>(SandboxFlag::AllowPointerLock);
        else if (token == "allow-popups")                    flags |= static_cast<uint32_t>(SandboxFlag::AllowPopups);
        else if (token == "allow-popups-to-escape-sandbox")  flags |= static_cast<uint32_t>(SandboxFlag::AllowPopupsToEscapeSandbox);
        else if (token == "allow-presentation")              flags |= static_cast<uint32_t>(SandboxFlag::AllowPresentation);
        else if (token == "allow-same-origin")               flags |= static_cast<uint32_t>(SandboxFlag::AllowSameOrigin);
        else if (token == "allow-scripts")                   flags |= static_cast<uint32_t>(SandboxFlag::AllowScripts);
        else if (token == "allow-top-navigation")            flags |= static_cast<uint32_t>(SandboxFlag::AllowTopNavigation);
        else if (token == "allow-top-navigation-by-user-activation")
                                                             flags |= static_cast<uint32_t>(SandboxFlag::AllowTopNavigationByUser);
        else if (token == "allow-downloads")                 flags |= static_cast<uint32_t>(SandboxFlag::AllowDownloads);
    }

    return flags;
}

} // namespace security
