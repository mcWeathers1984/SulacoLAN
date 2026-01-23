#include "mcw/tui/menu.hpp"
#include "mcw/print.hpp"

#include <iostream>
#include <limits>

namespace mcw::tui {

main_choice show_main_menu() {
    using mcw::println;

    println("==== Main Menu ====");
    println("  1) Subnet tools");
    println("  2) Ping tools"); 
    println("  0) Quit");
    println("-------------------");

    int choice = -1;
    while (true) {
        println("Enter choice (0-2): ");
        if (!(std::cin >> choice)) {
            std::cin.clear();
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            println("Invalid input. Please enter a number.");
            continue;
        }

        if (choice < 0 || choice > 2) {
            println("Invalid choice. Please enter 0, 1, or 2.");
            continue;
        }

        break;
    }

    switch (choice) {
        case 1: return main_choice::subnet_tools;
        case 2: return main_choice::ping_tools;
        case 0:
        default:
            return main_choice::quit;
    }
}

} // namespace mcw::tui
