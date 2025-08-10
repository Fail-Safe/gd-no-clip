cmake_minimum_required(VERSION 3.21)
project(gd-noclip VERSION 0.1.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)

# macOS universal by default when building locally
if(APPLE)
  set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "" FORCE)
endif()

## --- Geode SDK integration ---
# The SDK path may be provided either as a CMake cache variable GEODE_SDK (by Geode CLI)
# or as an environment variable $GEODE_SDK for manual builds. If neither is set,
# fall back to fetching the SDK via FetchContent.
set(_GEODE_SDK_PATH "")
if (DEFINED GEODE_SDK AND EXISTS "${GEODE_SDK}")
  set(_GEODE_SDK_PATH "${GEODE_SDK}")
elseif (DEFINED ENV{GEODE_SDK} AND EXISTS "$ENV{GEODE_SDK}")
  set(_GEODE_SDK_PATH "$ENV{GEODE_SDK}")
endif()

if (NOT _GEODE_SDK_PATH STREQUAL "")
  message(STATUS "Using Geode SDK from ${_GEODE_SDK_PATH}")
  add_subdirectory(${_GEODE_SDK_PATH} ${CMAKE_CURRENT_BINARY_DIR}/_geode)
else()
  message(STATUS "GEODE_SDK not provided; fetching Geode SDK with FetchContent (one-time download)")
  include(FetchContent)
  FetchContent_Declare(
    geode
    GIT_REPOSITORY https://github.com/geode-sdk/geode.git
    GIT_TAG v4.7.0 # TODO: keep in sync with your target loader version
  )
  FetchContent_MakeAvailable(geode)
endif()

# Sources
file(GLOB_RECURSE GD_NOCLIP_SOURCES CONFIGURE_DEPENDS src/*.cpp)
add_library(${PROJECT_NAME} SHARED ${GD_NOCLIP_SOURCES})

# Include directories
# Geode exposes include dirs from add_subdirectory; if building without SDK, this will fail to link, but
# users building via `geode build` won't hit this path as CLI wires it up.

# Platform-specific definitions
if (WIN32)
  target_compile_definitions(${PROJECT_NAME} PRIVATE GEODE_TARGET_WIN32)
elseif(APPLE)
  target_compile_definitions(${PROJECT_NAME} PRIVATE GEODE_TARGET_MACOS)
endif()

# Link with Geode and set up resources when SDK is available
if (COMMAND setup_geode_mod)
  setup_geode_mod(${PROJECT_NAME})
else()
  message(STATUS "Geode SDK CMake not loaded; ensure GEODE_SDK is set or let Geode CLI drive the build to package the .geode.")
endif()
