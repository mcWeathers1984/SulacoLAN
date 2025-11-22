#pragma once

#include <cstdint>
#include <string>

namespace mcw::net {

class ipv4_addr {
public:
    constexpr ipv4_addr() noexcept : value_{0} {}
    explicit constexpr ipv4_addr(std::uint32_t v) noexcept : value_{v} {}

    static ipv4_addr from_octets(std::uint8_t a, std::uint8_t b,
                                 std::uint8_t c, std::uint8_t d) noexcept;

    static ipv4_addr from_string(const std::string& s);

    std::string to_string() const;

    std::uint32_t value() const noexcept { return value_; }

private:
    std::uint32_t value_; // store in host order for now
};

} // namespace mcw::net
