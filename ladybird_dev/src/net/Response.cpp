#include "Response.h"

#include <algorithm>
#include <cctype>
#include <sstream>

namespace net {

static std::string header_lower(std::string_view name) {
    std::string s(name);
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c){ return static_cast<char>(std::tolower(c)); });
    return s;
}

std::string Response::header(std::string_view name) const {
    auto key = header_lower(name);
    if (auto it = headers.find(key); it != headers.end())
        return it->second;
    return {};
}

std::string Response::body_as_string() const {
    return { reinterpret_cast<const char*>(body.data()), body.size() };
}

std::string Response::content_type() const {
    auto ct = header("content-type");
    auto semi = ct.find(';');
    if (semi != std::string::npos)
        ct = ct.substr(0, semi);
    // Trim trailing whitespace
    while (!ct.empty() && std::isspace(static_cast<unsigned char>(ct.back())))
        ct.pop_back();
    return ct;
}

std::string Response::charset() const {
    auto ct = header("content-type");
    auto pos = ct.find("charset=");
    if (pos == std::string::npos) return "utf-8";
    auto start = pos + 8;
    auto end   = ct.find(';', start);
    std::string cs = ct.substr(start, end == std::string::npos ? std::string::npos : end - start);
    // Strip quotes
    if (cs.size() >= 2 && cs.front() == '"' && cs.back() == '"')
        cs = cs.substr(1, cs.size() - 2);
    return cs.empty() ? "utf-8" : cs;
}

} // namespace net
