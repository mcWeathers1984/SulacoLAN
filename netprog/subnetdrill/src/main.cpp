#include <print>
#include "ipv4_addr.hpp"

int main() 
{
    using mcw::ipv4_addr;

    ipv4_addr ip{192, 168, 1, 141};

    std::println("ip: {}", ip);                        // uses formatter
    std::println("ip string: {}", ip.to_string());
    std::println("ip binary: {}", ip.to_binary_string());
    std::println("ip as u32: {}", ip.to_u32());

    if (auto parsed = ipv4_addr::from_string("10.0.0.42")) {
        std::println("parsed ok: {}", *parsed);
    } else {
        std::println("parse failed");
    }

    return 0;
}
