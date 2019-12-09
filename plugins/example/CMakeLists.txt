file( GLOB example-SOURCES "*.cpp" )
file( GLOB example-HEADERS "*.h" )

add_library(example SHARED)
target_sources(example PRIVATE
    ${example-SOURCES})
target_include_directories(example PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}")

install(TARGETS example
        LIBRARY DESTINATION lib/PeerNodePlugins)
