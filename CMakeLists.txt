cmake_minimum_required(VERSION 3.12)

include(./config/cmake/CMakeLists.txt)

project(PeerNodeSDK)

pkg_search_module(pkg-Elastos.SDK.Contact REQUIRED Elastos.SDK.Contact)
message(STATUS "Elastos.SDK.Contact include path: ${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")
message(STATUS "Elastos.SDK.Contact library path: ${pkg-Elastos.SDK.Contact_STATIC_LDFLAGS}")

include_directories("${CMAKE_INSTALL_PREFIX}/include")


file( GLOB PeerNode-SOURCES "*.cpp" )
file( GLOB PeerNode-HEADERS "*.h" )

add_library(PeerNode)
target_sources(PeerNode PRIVATE
    ${PeerNode-SOURCES})
target_include_directories(PeerNode PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")
target_link_libraries(PeerNode PUBLIC
    "${pkg-Elastos.SDK.Contact_STATIC_LDFLAGS}")

set_target_properties(PeerNode PROPERTIES PUBLIC_HEADER "${PeerNode-HEADERS}")
install(TARGETS PeerNode
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        PUBLIC_HEADER DESTINATION include/PeerNodeSDK)

configure_file( ${CMAKE_CURRENT_SOURCE_DIR}/PeerNodeSDK.pc.in
	${CMAKE_CURRENT_BINARY_DIR}/PeerNodeSDK.pc @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/PeerNodeSDK.pc DESTINATION lib/pkgconfig)

