#include <print>
#include "ipv4_addr.hpp"
#include "ipv4_network.hpp"

int main()
{
    using mcw::ipv4_addr;
    using mcw::ipv4_network;

    ipv4_addr ip{192, 168, 1, 141};

    std::println("=== ipv4_addr tests ===");
    std::println("ip:          {}", ip);
    std::println("ip string:   {}", ip.to_string());
    std::println("ip binary:   {}", ip.to_binary_string());
    std::println("ip as u32:   {}", ip.to_u32());

    if (auto parsed = ipv4_addr::from_string("10.0.0.42")) {
        std::println("parsed ok:  {}", *parsed);
    } else {
        std::println("parse failed");
    }

    std::println("\n=== ipv4_network tests ===");

    // Example: 192.168.1.141/26
    ipv4_network net{ip, 26};

    std::println("network:      {}", net);
    std::println("mask:         {}", net.mask());
    std::println("mask (bin):   {}", net.mask().to_binary_string());
    std::println("wildcard:     {}", net.wildcard());
    std::println("ip (bin):     {}", ip.to_binary_string());
    std::println("net addr:     {}", net.network_address());
    std::println("bcast addr:   {}", net.broadcast_address());
    std::println("first host:   {}", net.first_host());
    std::println("last host:    {}", net.last_host());
    std::println("total addrs:  {}", net.total_addresses_safe());
    std::println("usable hosts: {}", net.usable_hosts());
    std::println("next subnet:  {}", net.next_subnet());

    // Quick parse test: "10.0.0.42/20"
    if (auto net2 = ipv4_network::from_string("10.0.0.42/20")) {
        std::println("\nparsed net:  {}", *net2);
        std::println("mask:         {}", net2->mask());
        std::println("network addr: {}", net2->network_address());
        std::println("broadcast:    {}", net2->broadcast_address());
    }

    return 0;
}
