#include <print>
#include <string>
#include <string_view>
#include <iostream>
#include "ipv4_addr.hpp"
#include "ipv4_network.hpp"

using mcw::ipv4_addr;
using mcw::ipv4_network;

int main()
{
    std::println("==============================================");
    std::println("        subnetdrill v0.1 - IPv4 Trainer        ");
    std::println("==============================================");
    std::println("Enter IPv4/CIDR (e.g. 192.168.1.141/26)");
    std::println("Type 'q' or 'quit' to exit.\n");

    std::string input;

    while (true)
    {
        mcw::print_subnet_chart();
        std::print("> ");
        if (!std::getline(std::cin, input))
            break;

        // Trim whitespace
        if (input == "q" || input == "quit")
            break;
        if (input.empty())
            continue;

        auto net_opt = ipv4_network::from_string(input);
        if (!net_opt)
        {
            std::println("Invalid input. Example: 10.0.0.42/20");
            continue;
        }

        ipv4_network net = *net_opt;

        ipv4_addr ip        = net.address;
        ipv4_addr mask      = net.mask();
        ipv4_addr wildcard  = net.wildcard();
        ipv4_addr network   = net.network_address();
        ipv4_addr broadcast = net.broadcast_address();
        ipv4_addr first     = net.first_host();
        ipv4_addr last      = net.last_host();
        ipv4_network next   = net.next_subnet();

        uint32_t total      = net.total_addresses_safe();
        uint32_t usable     = net.usable_hosts();

        std::println("\n=== Results for {} ===", net.to_string());
        std::println("IP Address:      {}", ip);
        std::println("Binary (IP):     {}", ip.to_binary_string());
        std::println();

        std::println("Subnet Mask:     {} (/ {})", mask, net.prefix);
        std::println("Binary (Mask):   {}", mask.to_binary_string());

        // Compute block size from mask logic:
        uint32_t block_size = total; // same as "subnet size"
        std::println("Block Size:      {}", block_size);

        std::println();
        std::println("Network:         {}", network);
        std::println("Broadcast:       {}", broadcast);
        std::println("First Host:      {}", first);
        std::println("Last Host:       {}", last);

        std::println();
        std::println("Total Addrs:     {}", total);
        std::println("Usable Hosts:    {}", usable);

        std::println("Next Subnet:     {}", next);
        std::println("==============================================\n");
    }

    std::println("\nGood luck on those subnet drills!");
    return 0;
}
