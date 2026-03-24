#pragma once

#include <string>
#include <vector>

namespace html {

struct Attribute {
    std::string name;
    std::string value;
};

enum class TokenType {
    DOCTYPE,
    StartTag,
    EndTag,
    Comment,
    Character,
    EndOfFile,
};

struct Token {
    TokenType type { TokenType::EndOfFile };

    // DOCTYPE
    std::string doctype_name;
    bool        force_quirks  { false };

    // Tag
    std::string            tag_name;
    bool                   self_closing { false };
    std::vector<Attribute> attributes;

    // Character / Comment
    std::string data;

    // Helpers
    [[nodiscard]] bool is_start_tag(std::string_view name) const {
        return type == TokenType::StartTag && tag_name == name;
    }
    [[nodiscard]] bool is_end_tag(std::string_view name) const {
        return type == TokenType::EndTag && tag_name == name;
    }

    [[nodiscard]] std::string attr(std::string_view name) const {
        for (auto& a : attributes)
            if (a.name == name) return a.value;
        return {};
    }
};

} // namespace html
