cmake_minimum_required(VERSION 3.9)
include (utils.cmake)
disallow_intree_builds()

project(RedServer VERSION 0.0.0 DESCRIPTION "Server for the Red Text Editor")

SET(CMAKE_CXX_FLAGS_DEBUG "-g -O0")
SET(CMAKE_C_FLAGS_DEBUG "-g -O0")

set_property(SOURCE src/module.modulemap
    PROPERTY MACOSX_PACKAGE_LOCATION "Modules")

add_library(RedServer SHARED
    ${CMAKE_CURRENT_BINARY_DIR}/server.c
    src/server.h
    src/RedServer.h
    src/module.modulemap
)

find_library(ZMQ_NAME NAMES libzmq.5.dylib libzmq.dylib)
find_path(ZMQ_INCLUDE_NAME NAMES zmq.h)

message("Zmq at ${ZMQ_NAME} ${ZMQ_INCLUDE_NAME}")

add_library(zmq SHARED IMPORTED)
set_target_properties(zmq PROPERTIES
    IMPORTED_LOCATION "${ZMQ_NAME}"
    INTERFACE_INCLUDE_DIRECTORIES "${ZMQ_INCLUDE_NAME}"
)

target_link_libraries(RedServer zmq)

set_target_properties(RedServer PROPERTIES
    SOVERSION 0
    VERSION ${PROJECT_VERSION}
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.manicmind.RedServer
    #MACOSX_FRAMEWORK_INFO_PLIST Info.plist
    PUBLIC_HEADER RedServer.h
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "None"
    PUBLIC_HEADER "src/RedServer.h;src/server.h"
)

add_custom_command(TARGET RedServer POST_BUILD
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/RedServer.framework"
    COMMAND "/bin/ln" "-sf" "Versions/Current/Modules"
    COMMENT "Linking RedServer Modules"
)


install(TARGETS RedServer
    FRAMEWORK DESTINATION lib
)

target_include_directories(RedServer PRIVATE src)
target_include_directories(RedServer PRIVATE "/Applications/Racket\ v7.7/include")

target_link_directories(RedServer PRIVATE "/Applications/Racket\ v7.7/lib")
target_link_libraries(RedServer "-framework Racket")
target_link_options(RedServer PRIVATE "-F" "${CMAKE_CURRENT_SOURCE_DIR}/../../third-party")

configure_file("src/server.c" "${CMAKE_CURRENT_BINARY_DIR}/server.c" COPYONLY)