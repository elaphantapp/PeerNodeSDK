file( GLOB ManagerService-SOURCES "*.cpp" "*/*.cpp")
file( GLOB ManagerService-HEADERS "*.h" )

add_library(ManagerService SHARED)
target_sources(ManagerService PRIVATE
    ${ManagerService-SOURCES})
target_include_directories(ManagerService PRIVATE
    ${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(ManagerService PRIVATE
    PeerNode)

install(TARGETS ManagerService
    LIBRARY DESTINATION lib/PeerNodePlugins)
