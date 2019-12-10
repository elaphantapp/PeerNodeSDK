
pkg_search_module(pkg-Elastos.SDK.Contact REQUIRED Elastos.SDK.Contact)
message(STATUS "Elastos.SDK.Contact include path: ${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")

file( GLOB SOURCES "*.cpp" )

add_library(Service SHARED ${SOURCES})

target_include_directories(Service PRIVATE
    "${PROJECT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/../"
    "${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")

target_link_libraries(Service PUBLIC PeerNode)
