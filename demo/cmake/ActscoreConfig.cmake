# - Config file for the package
# It defines the following variables
#  XXXXX_INCLUDE_DIRS - include directories
#  XXXXX_LIBRARIES    - libraries to link against
#  XXXXX_EXECUTABLE   - the  executable

set(ACTSCORE_INCLUDE_DIRS "/uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/include;/uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo;/uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/performance_testing")

# Our library dependencies (contains definitions for IMPORTED targets)
if(NOT TARGET Actscore AND NOT ACTSCORE_EXECUTABLE_DIR)
  include(${CMAKE_CURRENT_LIST_DIR}/ActscoreTargets.cmake)
endif()

# These are IMPORTED targets created by FooBarTargets.cmake
set(ACTSCORE_LIBRARIES Actscore)
set(ACTSCORE_EXECUTABLE mytlu)
