cmake_minimum_required(VERSION 2.6)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

project(mst)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

set(mst_VERSION_MAJOR 1)
set(mst_VERSION_MINOR 0)
set(mst_VERSION_PATCH 0)

set(MST_VERSION ${mst_VERSION_MAJOR}.${mst_VERSION_MINOR}.${mst_VERSION_PATCH})

option(BUILD_COVERAGE                    "Compile with gcov"                                 OFF)

find_package(OpenMP)
if(OPENMP_FOUND)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
endif()

if (BUILD_COVERAGE)
  set(BUILD_SHARED_LIBS OFF)
  set(CMAKE_BUILD_TYPE DEBUG)
  IF (CMAKE_COMPILER_IS_GNUCC)
    SET(CMAKE_C_FLAGS "-g -O0 -Wall -fprofile-arcs -ftest-coverage")
    SET(CMAKE_CXX_FLAGS "-g -O0 -Wall -fprofile-arcs -ftest-coverage")
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fprofile-arcs -ftest-coverage -lgcov")
  ENDIF()
endif(BUILD_COVERAGE)

find_package(Boost REQUIRED)

if(WIN32)
  add_definitions(-D_USE_MATH_DEFINES)
  add_definitions(-DNOMINMAX)
endif(WIN32)

configure_file (
  "${mst_SOURCE_DIR}/include/cmake-config.h.in"
  "${mst_BINARY_DIR}/include/config.h"
)

include_directories(${Boost_INCLUDE_DIRS})

include_directories(${mst_BINARY_DIR}/include)

add_definitions(-DCMAKE_BUILD)

add_subdirectory(mst) 

include(CTest)

if(BUILD_TESTING)
  ENABLE_TESTING()
endif(BUILD_TESTING)
