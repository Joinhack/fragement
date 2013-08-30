file(GLOB_RECURSE SOURCE RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "test_tree.cc")

include_directories (
  ${PROJECT_SOURCE_DIR}/thirdparty/gtest/include
  ${PROJECT_SOURCE_DIR}/test
  ${PROJECT_SOURCE_DIR}/src
)

set(GTEST_LIBS
  gtest_main
  gtest
)

add_executable(
  test_btree
  ${SOURCE}
)

IF (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(LIBS
    rt
  )
ENDIF()

target_link_libraries (
  test_btree
  btree
  ${LIBS}
  ${GTEST_LIBS}
)

