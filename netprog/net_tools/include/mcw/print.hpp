#pragma once
#include "mcw/config.hpp"

#include <string_view>
#include <utility>

#if MCW_HAS_STD_FORMAT
  #include <format>
  #include <iostream>
#else
  #include <iostream>
#endif

namespace mcw {

namespace detail {

#if MCW_HAS_STD_FORMAT

template <typename... Args>
inline void print_impl(std::string_view fmt, Args&&... args) {
    // Use std::format / std::vformat when available
    std::cout << std::vformat(fmt, std::make_format_args(args...));
}

#else

template <typename... Args>
inline void print_impl(std::string_view fmt, Args&&...) {
    // Fallback: ignore arguments, just print the format string
    std::cout << fmt;
}

#endif // MCW_HAS_STD_FORMAT

} // namespace detail

template <typename... Args>
inline void print(std::string_view fmt, Args&&... args) {
    detail::print_impl(fmt, std::forward<Args>(args)...);
}

template <typename... Args>
inline void println(std::string_view fmt, Args&&... args) {
    detail::print_impl(fmt, std::forward<Args>(args)...);
    std::cout << '\n';
}

inline void println() {
    std::cout << '\n';
}

} // namespace mcw

