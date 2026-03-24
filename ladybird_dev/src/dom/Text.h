#pragma once

#include "Node.h"

namespace dom {

class Text : public Node {
public:
    explicit Text(std::string data)
        : Node(NodeType::Text), m_data(std::move(data)) {}

    [[nodiscard]] const std::string& data() const noexcept { return m_data; }
    void append_data(std::string_view s) { m_data += s; }

    [[nodiscard]] std::string text_content() const override { return m_data; }

private:
    std::string m_data;
};

} // namespace dom
