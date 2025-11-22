#pragma once

#include "mcw/config.hpp"

#if MCW_PLATFORM_WINDOWS
  #include <winsock2.h>
  #include <ws2tcpip.h>
  // TODO: initialize WSA, link with ws2_32.lib when targeting Windows
#else
  #include <sys/types.h>
  #include <sys/socket.h>
  #include <netinet/in.h>
  #include <arpa/inet.h>
  #include <unistd.h>
#endif

namespace mcw::net {
// Future cross-platform socket helpers will live here.
}
