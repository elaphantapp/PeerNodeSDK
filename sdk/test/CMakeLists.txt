pkg_search_module(pkg-Elastos.SDK.Contact REQUIRED Elastos.SDK.Contact)
message(STATUS "Elastos.SDK.Contact include path: ${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")

file( GLOB SOURCES "*.cpp" )

add_executable(test ${SOURCES})

include_directories("${CMAKE_INSTALL_PREFIX}/include")

target_include_directories(test PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../"
    "${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")

target_link_libraries(test PUBLIC PeerNode)
