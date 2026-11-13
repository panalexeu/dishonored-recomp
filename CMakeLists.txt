# dishonored - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(dishonored LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use the pinned, patched SDK submodule unless REXSDK_DIR is given (see tools/apply_patches.sh).
set(REXSDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/rexglue-sdk" CACHE PATH "Path to rexglue-sdk source tree")

include(generated/rexglue.cmake)

# Sources
set(DISHONORED_SOURCES
    src/main.cpp
)

if(WIN32)
    add_executable(dishonored WIN32 ${DISHONORED_SOURCES})
else()
    add_executable(dishonored ${DISHONORED_SOURCES})
endif()

rexglue_setup_target(dishonored)

# Copy the runtime configuration next to the executable (the runtime reads <exe dir>/dishonored.toml).
add_custom_command(TARGET dishonored POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_CURRENT_SOURCE_DIR}/config/dishonored.toml
            $<TARGET_FILE_DIR:dishonored>/dishonored.toml
    COMMENT "Copying config/dishonored.toml next to the executable")
