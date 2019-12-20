
pkg_search_module(pkg-Elastos.SDK.Contact REQUIRED Elastos.SDK.Contact)
message(STATUS "Elastos.SDK.Contact include path: ${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")

file( GLOB SOURCES "*.cpp" )

add_executable(PeerNodeLauncher ${SOURCES})

target_include_directories(PeerNodeLauncher PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../"
    "${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")

target_link_libraries(PeerNodeLauncher PUBLIC PeerNode)

if(DEFINED CFG_WITH_TEST)
    add_subdirectory(Service)
endif()

install(TARGETS PeerNodeLauncher
        RUNTIME DESTINATION bin)
install(PROGRAMS ${CMAKE_CURRENT_SOURCE_DIR}/PeerNodeLauncher.sh
        DESTINATION bin)
