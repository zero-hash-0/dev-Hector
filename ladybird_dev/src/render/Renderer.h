#pragma once

#include "layout/LayoutBox.h"
#include <string>

namespace render {

// Render a layout tree to stdout using ANSI escape codes.
void render_to_terminal(const layout::LayoutBox& root, const std::string& title = {});

} // namespace render
