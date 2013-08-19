file(GLOB_RECURSE SOURCE RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.cc")

include_directories (
  ${PROJECT_SOURCE_DIR}/src
)

add_library(
  btree STATIC
  ${SOURCE}
)

