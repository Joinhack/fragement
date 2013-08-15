file(GLOB_RECURSE SOURCE RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.cc")

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

target_link_libraries (
  test_btree
  ${GTEST_LIBS}
)

