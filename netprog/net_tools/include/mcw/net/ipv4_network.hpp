#pragma once

#include <cstdint>
#include "mcw/net/ipv4_addr.hpp"

namespace mcw::net {

class ipv4_network {
public:
    ipv4_network(ipv4_addr network, std::uint8_t prefix_len) noexcept
      : network_{network}, prefix_len_{prefix_len} {}

    ipv4_addr network_address() const noexcept;
    ipv4_addr broadcast_address() const noexcept;
    ipv4_addr first_host() const noexcept;
    ipv4_addr last_host() const noexcept;
    std::uint32_t host_count() const noexcept;

    std::uint8_t prefix_length() const noexcept { return prefix_len_; }

private:
    ipv4_addr    network_;
    std::uint8_t prefix_len_{};
};

} // namespace mcw::net
