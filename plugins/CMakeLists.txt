MACRO(SUBDIRLIST result curdir)
  FILE(GLOB children RELATIVE ${curdir} ${curdir}/*)
  SET(dirlist "")
  FOREACH(child ${children})
    IF(IS_DIRECTORY ${curdir}/${child})
      LIST(APPEND dirlist ${child})
    ENDIF()
  ENDFOREACH()
  SET(${result} ${dirlist})
ENDMACRO()

SUBDIRLIST(DirList ${CMAKE_CURRENT_SOURCE_DIR})

FOREACH(subdir ${DirList})
  ADD_SUBDIRECTORY(${subdir})
ENDFOREACH()

include_directories("${CMAKE_INSTALL_PREFIX}/include")
