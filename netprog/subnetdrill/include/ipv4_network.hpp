#ifndef IPV4_NETWORK_HPP
#define IPV4_NETWORK_HPP
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <format>
#include <charconv>
#include <system_error>

#include "ipv4_addr.hpp"

namespace mcw {

struct ipv4_network
{
    ipv4_addr address{}; // some IP in the subnet
    uint8_t   prefix{};  // CIDR prefix length: 0–32

    // ----- ctors -----

    constexpr ipv4_network() noexcept = default;

    constexpr ipv4_network(ipv4_addr addr_, uint8_t pfx) noexcept
        : address{addr_}, prefix{pfx}
    {}

    // Parse "a.b.c.d/n"
    static std::optional<ipv4_network> from_string(std::string_view s) noexcept
    {
        // Split at '/'
        std::size_t slash = s.find('/');
        if (slash == std::string_view::npos) {
            return std::nullopt;
        }

        std::string_view ip_part   = s.substr(0, slash);
        std::string_view pfx_part  = s.substr(slash + 1);

        if (ip_part.empty() || pfx_part.empty()) {
            return std::nullopt;
        }

        auto ip_opt = ipv4_addr::from_string(ip_part);
        if (!ip_opt) return std::nullopt;

        // parse prefix
        int pfx_val = 0;
        const char* first = pfx_part.data();
        const char* last  = pfx_part.data() + pfx_part.size();

        auto res = std::from_chars(first, last, pfx_val);
        if (res.ec != std::errc{} || res.ptr != last) {
            return std::nullopt;
        }
        if (pfx_val < 0 || pfx_val > 32) {
            return std::nullopt;
        }

        return ipv4_network{*ip_opt, static_cast<uint8_t>(pfx_val)};
    }

    // String form "a.b.c.d/n"
    std::string to_string() const
    {
        return std::format("{}/{}", address, prefix);
    }

    // ----- core helpers -----

    // 32-bit subnet mask, network-order
    constexpr uint32_t mask_u32() const noexcept
    {
        if (prefix == 0)  return 0u;
        if (prefix >= 32) return 0xFFFFFFFFu;
        // 32 - prefix in [1,31] here
        return 0xFFFFFFFFu << (32 - prefix);
    }

    // 32-bit wildcard mask (inverse of mask)
    constexpr uint32_t wildcard_u32() const noexcept
    {
        return ~mask_u32();
    }

    ipv4_addr mask() const noexcept
    {
        return ipv4_addr::from_u32(mask_u32());
    }

    ipv4_addr wildcard() const noexcept
    {
        return ipv4_addr::from_u32(wildcard_u32());
    }

    // Network address (all host bits zero)
    ipv4_addr network_address() const noexcept
    {
        uint32_t ip32  = address.to_u32();
        uint32_t m32   = mask_u32();
        uint32_t net32 = ip32 & m32;
        return ipv4_addr::from_u32(net32);
    }

    // Broadcast address (all host bits one)
    ipv4_addr broadcast_address() const noexcept
    {
        uint32_t net32 = network_address().to_u32();
        uint32_t b32   = net32 | wildcard_u32();
        return ipv4_addr::from_u32(b32);
    }

    // Total addresses in this prefix (2^(32 - prefix))
    uint32_t total_addresses() const noexcept
    {
        if (prefix >= 32) return 1u;
        uint8_t host_bits = static_cast<uint8_t>(32 - prefix);
        // host_bits in [1,32]; but prefix>=32 handled above
        return (host_bits >= 31)
            ? (1u << 31) * 2u // this is slightly overkill; practically only /31, /32 edge cases
            : (1u << host_bits);
    }

    // More conservative version (no UB, reasonable for exam ranges /0.. /30)
    uint32_t total_addresses_safe() const noexcept
    {
        if (prefix >= 32) return 1u;
        uint8_t host_bits = static_cast<uint8_t>(32 - prefix);
        // For /0 host_bits=32 → this caps at max uint32_t
        if (host_bits >= 31) return 0xFFFFFFFFu;
        return (1u << host_bits);
    }

    // Usable hosts (Network+ style: subtract 2, except /31 /32)
    uint32_t usable_hosts() const noexcept
    {
        if (prefix >= 31) return 0; // /31 and /32 treated as "no usable hosts" for classic exam logic
        uint32_t total = total_addresses_safe();
        if (total <= 2) return 0;
        return total - 2;
    }

    // First usable host
    ipv4_addr first_host() const noexcept
    {
        if (prefix >= 31) {
            // Degenerate case: just return the network address
            return network_address();
        }
        uint32_t net32   = network_address().to_u32();
        uint32_t first32 = net32 + 1;
        return ipv4_addr::from_u32(first32);
    }

    // Last usable host
    ipv4_addr last_host() const noexcept
    {
        if (prefix >= 31) {
            // Degenerate case: just return the broadcast address
            return broadcast_address();
        }
        uint32_t bc32   = broadcast_address().to_u32();
        uint32_t last32 = bc32 - 1;
        return ipv4_addr::from_u32(last32);
    }

    // Next subnet with the same prefix (may wrap if near end of space)
    ipv4_network next_subnet() const noexcept
    {
        uint32_t net32   = network_address().to_u32();
        uint32_t block   = total_addresses_safe();
        uint32_t next32  = net32 + block;
        return ipv4_network{ipv4_addr::from_u32(next32), prefix};
    }
};

} // namespace mcw

// ----- formatter support for std::format / std::print -----

template<>
struct std::formatter<mcw::ipv4_network, char>
{
    template <class ParseContext>
    constexpr auto parse(ParseContext& ctx)
    {
        return ctx.begin();
    }

    template <class FormatContext>
    auto format(mcw::ipv4_network const& net, FormatContext& ctx) const
    {
        return std::format_to(ctx.out(), "{}/{}", net.address, net.prefix);
    }
};

#endif
