include_directories("${CMAKE_INSTALL_PREFIX}/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../sdk")

macro(SUBDIRLIST result curdir)
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
        if(IS_DIRECTORY ${curdir}/${child})
            list(APPEND dirlist "${curdir}/${child}")
        endif()
    endforeach()
    set(${result} ${dirlist})
endmacro()

subdirlist(DirList ${CMAKE_CURRENT_SOURCE_DIR})
foreach(subdir ${DirList})
    if(EXISTS "${subdir}/CMakeLists.txt")
        message(STATUS "Add subdirectory: ${subdir}")
        add_subdirectory(${subdir})
    else() # not find CMakeLists.txt, search subdirs
        subdirlist(PluginDirList ${subdir})
        foreach(plgsubdir ${PluginDirList})
            if(EXISTS "${plgsubdir}/CMakeLists.txt")
                message(STATUS "Add subdirectory: ${plgsubdir}")
                add_subdirectory(${plgsubdir})
            endif()
        endforeach()
    endif()
endforeach()
