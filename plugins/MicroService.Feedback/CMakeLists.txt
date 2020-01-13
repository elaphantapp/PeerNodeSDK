file( GLOB FeedbackService-SOURCES "*.cpp" )
file( GLOB FeedbackService-HEADERS "*.h" )

add_library(FeedbackService SHARED)
target_sources(FeedbackService PRIVATE
    ${FeedbackService-SOURCES})
target_include_directories(FeedbackService PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${pkg-Elastos.SDK.Contact_INCLUDE_DIRS}")
target_link_libraries(FeedbackService PeerNode)

install(TARGETS FeedbackService
        LIBRARY DESTINATION lib/PeerNodePlugins)
