// mcw_ipv4.hpp
#ifndef IPV4_ADDR_HPP
#define IPV4_ADDR_HPP
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <optional>
#include <format>   // C++20
#include <charconv> // for from_chars

namespace mcw {

struct ipv4_addr
{
    // Store the address as 4 octets in canonical order: a.b.c.d
    uint8_t oct[4]{};

    // ----- ctors -----

    constexpr ipv4_addr() noexcept = default;

    constexpr ipv4_addr(uint8_t a0, uint8_t a1,
                        uint8_t a2, uint8_t a3) noexcept
        : oct{a0, a1, a2, a3}
    {}

    // Construct from 32-bit value in *network order* (a.b.c.d packed)
    static constexpr ipv4_addr from_u32(uint32_t net32) noexcept
    {
        return ipv4_addr{
            static_cast<uint8_t>((net32 >> 24) & 0xFF),
            static_cast<uint8_t>((net32 >> 16) & 0xFF),
            static_cast<uint8_t>((net32 >>  8) & 0xFF),
            static_cast<uint8_t>( net32        & 0xFF)
        };
    }

    // Parse "a.b.c.d" → ipv4_addr
    static std::optional<ipv4_addr> from_string(std::string_view s) noexcept
    {
        uint8_t parts[4]{};
        int part_index = 0;

        std::size_t start = 0;
        while (start < s.size() && part_index < 4)
        {
            std::size_t dot = s.find('.', start);
            std::string_view token;
            if (dot == std::string_view::npos) {
                token = s.substr(start);
                start = s.size();
            } else {
                token = s.substr(start, dot - start);
                start = dot + 1;
            }

            // Empty or too long segment is invalid
            if (token.empty() || token.size() > 3) {
                return std::nullopt;
            }

            // Ensure all digits
            for (char c : token) {
                if (c < '0' || c > '9')
                    return std::nullopt;
            }

            // Convert to integer (0–255)
            int value = 0;
            auto* first = token.data();
            auto* last  = token.data() + token.size();

            auto res = std::from_chars(first, last, value);
            if (res.ec != std::errc{} || res.ptr != last)
                return std::nullopt;
            if (value < 0 || value > 255)
                return std::nullopt;

            parts[part_index++] = static_cast<uint8_t>(value);
        }

        // Need exactly 4 parts
        if (part_index != 4 || start < s.size()) {
            return std::nullopt;
        }

        return ipv4_addr{parts[0], parts[1], parts[2], parts[3]};
    }

    // ----- conversions -----

    // To 32-bit network-order integer (a.b.c.d packed)
    constexpr uint32_t to_u32() const noexcept
    {
        return (static_cast<uint32_t>(oct[0]) << 24) |
               (static_cast<uint32_t>(oct[1]) << 16) |
               (static_cast<uint32_t>(oct[2]) <<  8) |
               (static_cast<uint32_t>(oct[3]));
    }

    // "a.b.c.d"
    std::string to_string() const
    {
        return std::format("{}.{}.{}.{}",
                           oct[0], oct[1], oct[2], oct[3]);
    }

    // "xxxxxxxx.xxxxxxxx.xxxxxxxx.xxxxxxxx"
    std::string to_binary_string() const
    {
        auto byte_to_bits = [](uint8_t b) {
            std::string s(8, '0');
            for (int i = 0; i < 8; ++i) {
                // MSB first: bit 7 → index 0
                if (b & (1u << (7 - i))) {
                    s[i] = '1';
                }
            }
            return s;
        };

        return std::format("{}.{}.{}.{}",
                           byte_to_bits(oct[0]),
                           byte_to_bits(oct[1]),
                           byte_to_bits(oct[2]),
                           byte_to_bits(oct[3]));
    }

    // ----- comparisons -----

    friend constexpr bool operator==(ipv4_addr const& a,
                                     ipv4_addr const& b) noexcept
    {
        return a.oct[0] == b.oct[0] &&
               a.oct[1] == b.oct[1] &&
               a.oct[2] == b.oct[2] &&
               a.oct[3] == b.oct[3];
    }

    friend constexpr bool operator!=(ipv4_addr const& a,
                                     ipv4_addr const& b) noexcept
    {
        return !(a == b);
    }

    // Useful for sorting (lexicographic by octets)
    friend constexpr bool operator<(ipv4_addr const& a,
                                    ipv4_addr const& b) noexcept
    {
        if (a.oct[0] != b.oct[0]) return a.oct[0] < b.oct[0];
        if (a.oct[1] != b.oct[1]) return a.oct[1] < b.oct[1];
        if (a.oct[2] != b.oct[2]) return a.oct[2] < b.oct[2];
        return a.oct[3] < b.oct[3];
    }
};

} // namespace mcw

// ----- formatter support for std::format / std::print -----

template<>
struct std::formatter<mcw::ipv4_addr, char>
{
    // We don't support any custom format specifiers for now,
    // so parse() just returns the end iterator.
    template <class ParseContext>
    constexpr auto parse(ParseContext& ctx)
    {
        return ctx.begin();
    }

    template <class FormatContext>
    auto format(mcw::ipv4_addr const& ip, FormatContext& ctx) const
    {
        return std::format_to(ctx.out(),
                              "{}.{}.{}.{}",
                              ip.oct[0], ip.oct[1], ip.oct[2], ip.oct[3]);
    }
};

#endif // IPV4_HPP