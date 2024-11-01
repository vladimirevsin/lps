# CMakeLists for libyuv
# Originally created for "roxlu build system" to compile libyuv on windows
# Run with -DENABLE_TEST=ON to build unit tests

CMAKE_MINIMUM_REQUIRED( VERSION 3.1 )

PROJECT ( YUV LANGUAGES C CXX )	# "C" is required even for C++ projects
OPTION( ENABLE_TEST "Built unit tests" OFF )

if(NOT WIN32)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
endif()
# Explicitly setting CMAKE_POSITION_INDEPENDENT_CODE=FALSE disables PIC for all
# targets, which will cause the shared library builds to fail.  Thus, if shared
# libraries are enabled and CMAKE_POSITION_INDEPENDENT_CODE is explicitly set
# to FALSE, we need to unset it, thus restoring the default behavior
# (automatically using PIC for shared library targets.)
if(DEFINED CMAKE_POSITION_INDEPENDENT_CODE AND
  NOT CMAKE_POSITION_INDEPENDENT_CODE AND ENABLE_SHARED)
  unset(CMAKE_POSITION_INDEPENDENT_CODE CACHE)
endif()

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

SET ( ly_base_dir	${PROJECT_SOURCE_DIR} )
SET ( ly_src_dir	${ly_base_dir}/source )
SET ( ly_inc_dir	${ly_base_dir}/include )
SET ( ly_tst_dir	${ly_base_dir}/unit_test )
SET ( ly_lib_name	yuv )

FILE ( GLOB_RECURSE	ly_source_files ${ly_src_dir}/*.cc )
LIST ( SORT			ly_source_files )

FILE ( GLOB_RECURSE	ly_unittest_sources ${ly_tst_dir}/*.cc )
LIST ( SORT			ly_unittest_sources )

INCLUDE_DIRECTORIES( BEFORE ${ly_inc_dir} )
include(GNUInstallDirs)

ADD_LIBRARY				( ${ly_lib_name} ${ly_source_files} )
target_include_directories(${ly_lib_name} INTERFACE
  $<INSTALL_INTERFACE:include>
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
)
if(WIN32)
  target_compile_options(${ly_lib_name} PRIVATE "-DLIBYUV_BUILDING_SHARED_LIBRARY" INTERFACE "-DLIBYUV_USING_SHARED_LIBRARY")
endif()

# this creates the conversion tool
if(ENABLE_TOOL)
	ADD_EXECUTABLE			( yuvconvert ${ly_base_dir}/util/yuvconvert.cc )
	TARGET_LINK_LIBRARIES	( yuvconvert ${ly_lib_name} )
endif()

find_package(TurboJpeg)
if(NOT TurboJpeg_FOUND)
  INCLUDE ( FindJPEG )
  if (JPEG_FOUND)
    include_directories( ${JPEG_INCLUDE_DIR} )
  endif()
else()
  set(JPEG_LIBRARY ${TurboJpeg_TARGET})
endif()
if( TurboJpeg_FOUND OR JPEG_FOUND)
  if(ENABLE_TOOL)
    target_link_libraries( yuvconvert ${JPEG_LIBRARY} )
  endif()
  target_link_libraries( ${ly_lib_name} ${JPEG_LIBRARY} )
  add_definitions( -DHAVE_JPEG )
endif()

if(ENABLE_TEST)
  find_library(GTEST_LIBRARY gtest)
  if(GTEST_LIBRARY STREQUAL "GTEST_LIBRARY-NOTFOUND")
    set(GTEST_SRC_DIR /usr/src/gtest CACHE STRING "Location of gtest sources")
    if(EXISTS ${GTEST_SRC_DIR}/src/gtest-all.cc)
      message(STATUS "building gtest from sources in ${GTEST_SRC_DIR}")
      set(gtest_sources ${GTEST_SRC_DIR}/src/gtest-all.cc)
      add_library(gtest STATIC ${gtest_sources})
      include_directories(${GTEST_SRC_DIR})
      include_directories(${GTEST_SRC_DIR}/include)
      set(GTEST_LIBRARY gtest)
    else()
      message(FATAL_ERROR "TEST is set but unable to find gtest library")
    endif()
  endif()

  add_executable(libyuv_unittest ${ly_unittest_sources})
  target_link_libraries(libyuv_unittest ${ly_lib_name} ${GTEST_LIBRARY})
  find_library(PTHREAD_LIBRARY pthread)
  if(NOT PTHREAD_LIBRARY STREQUAL "PTHREAD_LIBRARY-NOTFOUND")
    target_link_libraries(libyuv_unittest pthread)
  endif()
  if( TurboJpeg_FOUND OR JPEG_FOUND)
    target_link_libraries(libyuv_unittest ${JPEG_LIBRARY})
  endif()

  if(NACL AND NACL_LIBC STREQUAL "newlib")
    target_link_libraries(libyuv_unittest glibc-compat)
  endif()

  find_library(GFLAGS_LIBRARY gflags)
  if(NOT GFLAGS_LIBRARY STREQUAL "GFLAGS_LIBRARY-NOTFOUND")
    target_link_libraries(libyuv_unittest gflags)
    add_definitions(-DLIBYUV_USE_GFLAGS)
  endif()
endif()


# install the conversion tool, .so, .a, and all the header files

if(ENABLE_TOOL)
	INSTALL ( PROGRAMS $<TARGET_FILE:yuvconvert>			DESTINATION ${CMAKE_INSTALL_BINDIR} )
endif()
INSTALL ( TARGETS ${ly_lib_name} EXPORT YUVTargets LIBRARY				DESTINATION ${CMAKE_INSTALL_LIBDIR} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} )
INSTALL ( DIRECTORY ${PROJECT_SOURCE_DIR}/include/		DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} )

# create the .deb and .rpm packages using cpack
INCLUDE ( CM_linux_packages.cmake )


install(EXPORT YUVTargets
	FILE "YUVTargets.cmake"
	DESTINATION "${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake"
)
