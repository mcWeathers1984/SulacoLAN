#pragma once

namespace mcw::tui {

enum class main_choice {
    quit = 0,
    subnet_tools,
    ping_tools
    // extend later
};

main_choice show_main_menu();

} // namespace mcw::tui
