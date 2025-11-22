#include "mcw/print.hpp"
#include "mcw/tui/menu.hpp"

int main() {
    using mcw::println;
    using mcw::tui::main_choice;

    println("Welcome to the net TUI.\n");

    for (;;) {
        auto choice = mcw::tui::show_main_menu();
        switch (choice) {
            case main_choice::subnet_tools:
                println("[TODO] Subnet tools not implemented yet.");
                break;
            case main_choice::ping_tools:
                println("[TODO] Ping tools not implemented yet.");
                break;
            case main_choice::quit:
            default:
                println("Goodbye.");
                return 0;
        }
    }
}
