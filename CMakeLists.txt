if(MSVC)
  cmake_minimum_required(VERSION 3.9)
else()
  cmake_minimum_required(VERSION 3.5)
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/ExtractMetaData.cmake)
project(${EXTRACTED_NAME} VERSION ${EXTRACTED_VERSION} LANGUAGES CXX)

#######################
## Find dependencies ##
#######################
##---------------------##
## Boost C++ Libraries ##
##---------------------##
find_package(Boost REQUIRED COMPONENTS regex system thread)

##-------------------------##
## Google Protocol Buffers ##
##-------------------------##
if(WIN32)
  # For a Chocolatey-based ROS/ROS2 installation, then it appears that the protobuf compiler is
  # by default installed at ${_CMAKE_INSTALL_DIR}/tools/protobuf, and find_package() doesn't
  # always seem to find the compiler without specifying a hint.
  find_package(Protobuf REQUIRED HINTS ${_CMAKE_INSTALL_DIR}/tools/protobuf)
else()
  find_package(Protobuf REQUIRED)
endif()

# Make sure protoc is present, as apparently the above find_package() doesn't check that.
if(NOT PROTOBUF_PROTOC_EXECUTABLE)
  message(FATAL_ERROR "Cannot find required 'protoc', cannot process Protobuf files without it. Aborting.")
endif()

# Generate C++ for protocol classes (headers and sources
# get written to the CMAKE_CURRENT_BINARY_DIR location).
set(EgmProtoFiles proto/egm.proto proto/egm_wrapper.proto proto/egm_wrapper_trajectory.proto)
if(NOT QUIET)
  message(STATUS "Generating protobuf C++ for: ${EgmProtoFiles}")
endif()
if(MSVC)
  protobuf_generate_cpp(EgmProtoSources EgmProtoHeaders EXPORT_MACRO ABB_LIBEGM_STATIC_DEFINE ${EgmProtoFiles})
else()
  protobuf_generate_cpp(EgmProtoSources EgmProtoHeaders ${EgmProtoFiles})
endif()

##---------##
## Threads ##
##---------##
find_package(Threads REQUIRED)

# Work around Protobuf exporting 'lpthread' as a library: we let the
# previous find_package(...) determine the system's thread library.
list(REMOVE_ITEM PROTOBUF_LIBRARIES "-lpthread")

###############
## Pre-build ##
###############
include(GNUInstallDirs)
include(GenerateExportHeader)

if(WIN32)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

if(NOT DEFINED BUILD_SHARED_LIBS)
  option(BUILD_SHARED_LIBS "Build dynamically-linked binaries" ON)
endif()

###########
## Build ##
###########
set(
  SRC_FILES
    src/egm_base_interface.cpp
    src/egm_common.cpp
    src/egm_common_auxiliary.cpp
    src/egm_controller_interface.cpp
    src/egm_interpolator.cpp
    src/egm_logger.cpp
    src/egm_udp_server.cpp
    src/egm_trajectory_interface.cpp
    ${EgmProtoSources}
)

add_library(${PROJECT_NAME} ${SRC_FILES})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

generate_export_header(${PROJECT_NAME})

target_include_directories(${PROJECT_NAME} PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
  $<INSTALL_INTERFACE:$<INSTALL_PREFIX>/include>
  ${PROTOBUF_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} PUBLIC
  Boost::regex
  Boost::system
  Boost::thread
  ${PROTOBUF_LIBRARIES}
  Threads::Threads
)

if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(${PROJECT_NAME} PUBLIC "ABB_LIBEGM_STATIC_DEFINE")
endif()

if(MSVC)
  target_compile_options(${PROJECT_NAME} PUBLIC "/FI${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_export.h")
endif()

################
## Post-build ##
################
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/PostBuild.cmake)
