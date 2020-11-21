cmake_minimum_required(VERSION 3.9)
include (utils.cmake)
disallow_intree_builds()

project(RedLib VERSION 0.0.0 DESCRIPTION "Server for the Red Text Editor")

SET(CMAKE_CXX_FLAGS_DEBUG "-g -O0")
SET(CMAKE_C_FLAGS_DEBUG "-g -O0")

set_property(SOURCE src/module.modulemap
    PROPERTY MACOSX_PACKAGE_LOCATION "Modules")

add_library(RedLib SHARED
    src/main.c
    src/main.h
    src/client.c
    src/client.h
    src/work_queue.c
    src/work_queue.h
    src/libred_macos.c
    src/libred_macos.h
    src/RedLib.h
    src/module.modulemap
)

set_property(TARGET RedLib PROPERTY C_STANDARD 11)

SET(THIRD_PARTY_INSTALL "${CMAKE_CURRENT_SOURCE_DIR}/../../build/install/")
SET(THIRD_PARTY_INCLUDE "${THIRD_PARTY_INSTALL}include/")
SET(THIRD_PARTY_LIB "${THIRD_PARTY_INSTALL}lib/")
SET(THIRD_PARTY_FRAMEWORKS "${THIRD_PARTY_INSTALL}Frameworks/")
target_include_directories(RedLib PRIVATE "${THIRD_PARTY_INCLUDE}")
target_link_directories(RedLib PRIVATE "${THIRD_PARTY_LIB}")

find_library(ZMQ_NAME NAMES libzmq.5.dylib libzmq.dylib)
find_path(ZMQ_INCLUDE_NAME NAMES zmq.h)

message("Zmq at ${ZMQ_NAME} ${ZMQ_INCLUDE_NAME}")

add_library(zmq SHARED IMPORTED)
set_target_properties(zmq PROPERTIES
    IMPORTED_LOCATION "${ZMQ_NAME}"
    INTERFACE_INCLUDE_DIRECTORIES "${ZMQ_INCLUDE_NAME}"
)
target_link_libraries(RedLib zmq)

find_library(MSGPACK_NAME NAMES libmsgpackc.dylib)
find_path(MSGPACK_INCLUDE_NAME NAMES msgpack.h)

add_library(msgpack SHARED IMPORTED)
set_target_properties(msgpack PROPERTIES
    IMPORTED_LOCATION "${MSGPACK_NAME}"
    INTERFACE_INCLUDE_DIRECTORIES "${MSGPACK_INCLUDE_NAME}"
)
target_link_libraries(RedLib msgpack)

set_target_properties(RedLib PROPERTIES
    SOVERSION 0
    VERSION ${PROJECT_VERSION}
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.manicmind.RedLib
    PUBLIC_HEADER RedLib.h
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "None"
    PUBLIC_HEADER "src/RedLib.h;src/main.h"
)

add_custom_command(TARGET RedLib POST_BUILD
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/RedLib.framework"
    COMMAND "/bin/ln" "-sf" "Versions/Current/Modules"
    COMMENT "Linking RedLib Modules"
)


install(TARGETS RedLib
    FRAMEWORK DESTINATION lib
)

target_include_directories(RedLib PRIVATE src)

target_link_libraries(RedLib "-framework Racket" "-framework Foundation" "-framework CoreServices")
target_link_options(RedLib PRIVATE "-F" "${THIRD_PARTY_FRAMEWORKS}")
target_compile_options(RedLib PRIVATE "-F" "${THIRD_PARTY_FRAMEWORKS}" -Wall -Wextra -pedantic -Werror)
