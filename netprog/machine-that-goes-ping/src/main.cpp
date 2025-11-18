#include "common.hpp"
#include "sstring.hpp"

void MainMenu() {
 std::println("Main Menu");
 std::println("(1)\tset ip address");
 std::println("(2)\tping");
 std::println("(0)\texit");
}

void Usage() {
 std::println("Usage: Ping an ip address, run trace route or set an ip address.\nPress \'0\' to go back or exit.");
}

int main(int argc, char** argc) {
 std::print("The Machine That Goes PING!\n");
 return 0;
}
