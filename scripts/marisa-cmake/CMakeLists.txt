cmake_minimum_required(VERSION 3.10)
project(marisa LANGUAGES CXX)
include(GNUInstallDirs)

# Upstream marisa-trie v0.2.6 uses Autotools and ships no CMakeLists.txt.
# Compile exactly the libmarisa sources listed in its Makefile.am hierarchy.
set(MARISA_SOURCE_DIR "" CACHE PATH "Path to the unpacked marisa-trie v0.2.6 source")
if(NOT EXISTS "${MARISA_SOURCE_DIR}/include/marisa.h")
  message(FATAL_ERROR "MARISA_SOURCE_DIR must point to the unpacked marisa-trie source")
endif()

set(marisa_sources
  lib/marisa/agent.cc
  lib/marisa/keyset.cc
  lib/marisa/trie.cc
  lib/marisa/grimoire/io/mapper.cc
  lib/marisa/grimoire/io/reader.cc
  lib/marisa/grimoire/io/writer.cc
  lib/marisa/grimoire/trie/louds-trie.cc
  lib/marisa/grimoire/trie/tail.cc
  lib/marisa/grimoire/vector/bit-vector.cc
)
list(TRANSFORM marisa_sources PREPEND "${MARISA_SOURCE_DIR}/")

add_library(marisa SHARED ${marisa_sources})
target_include_directories(marisa PRIVATE
  "${MARISA_SOURCE_DIR}/include"
  "${MARISA_SOURCE_DIR}/lib"
)
set_target_properties(marisa PROPERTIES VERSION 0.2.6 SOVERSION 0)

install(TARGETS marisa LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
install(FILES "${MARISA_SOURCE_DIR}/include/marisa.h"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
install(DIRECTORY "${MARISA_SOURCE_DIR}/include/marisa"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  FILES_MATCHING PATTERN "*.h")
