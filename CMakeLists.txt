cmake_minimum_required(VERSION 3.23)
project(hydrus-elo)

add_subdirectory(sakana)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(hydrus-elo src/main.cpp)

target_link_libraries(hydrus-elo
  PRIVATE
  sakana::unagi
)
