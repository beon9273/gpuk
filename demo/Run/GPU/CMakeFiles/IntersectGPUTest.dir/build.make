# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.15

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /uufs/chpc.utah.edu/sys/installdir/cmake/3.15.3/bin/cmake

# The command to remove a file.
RM = /uufs/chpc.utah.edu/sys/installdir/cmake/3.15.3/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo

# Include any dependencies generated for this target.
include Run/GPU/CMakeFiles/IntersectGPUTest.dir/depend.make

# Include the progress variables for this target.
include Run/GPU/CMakeFiles/IntersectGPUTest.dir/progress.make

# Include the compile flags for this target's objects.
include Run/GPU/CMakeFiles/IntersectGPUTest.dir/flags.make

Run/GPU/CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.o: Run/GPU/CMakeFiles/IntersectGPUTest.dir/flags.make
Run/GPU/CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.o: ../Run/GPU/IntersectGPUTest.cu
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CUDA object Run/GPU/CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.o"
	cd /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/Run/GPU && /uufs/chpc.utah.edu/sys/installdir/cuda/11.3.0/bin/nvcc  $(CUDA_DEFINES) $(CUDA_INCLUDES) $(CUDA_FLAGS) -x cu -c /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/Run/GPU/IntersectGPUTest.cu -o CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.o

Run/GPU/CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CUDA source to CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.i"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_PREPROCESSED_SOURCE

Run/GPU/CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CUDA source to assembly CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.s"
	$(CMAKE_COMMAND) -E cmake_unimplemented_variable CMAKE_CUDA_CREATE_ASSEMBLY_SOURCE

# Object files for target IntersectGPUTest
IntersectGPUTest_OBJECTS = \
"CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.o"

# External object files for target IntersectGPUTest
IntersectGPUTest_EXTERNAL_OBJECTS =

Run/GPU/IntersectGPUTest: Run/GPU/CMakeFiles/IntersectGPUTest.dir/IntersectGPUTest.cu.o
Run/GPU/IntersectGPUTest: Run/GPU/CMakeFiles/IntersectGPUTest.dir/build.make
Run/GPU/IntersectGPUTest: libActscore.a
Run/GPU/IntersectGPUTest: /uufs/chpc.utah.edu/sys/installdir/gcc/10.2.0/lib64/libgomp.so
Run/GPU/IntersectGPUTest: /lib64/libpthread.so
Run/GPU/IntersectGPUTest: Run/GPU/CMakeFiles/IntersectGPUTest.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable IntersectGPUTest"
	cd /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/Run/GPU && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/IntersectGPUTest.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
Run/GPU/CMakeFiles/IntersectGPUTest.dir/build: Run/GPU/IntersectGPUTest

.PHONY : Run/GPU/CMakeFiles/IntersectGPUTest.dir/build

Run/GPU/CMakeFiles/IntersectGPUTest.dir/clean:
	cd /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/Run/GPU && $(CMAKE_COMMAND) -P CMakeFiles/IntersectGPUTest.dir/cmake_clean.cmake
.PHONY : Run/GPU/CMakeFiles/IntersectGPUTest.dir/clean

Run/GPU/CMakeFiles/IntersectGPUTest.dir/depend:
	cd /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/Run/GPU /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/Run/GPU /uufs/chpc.utah.edu/common/home/u1305734/gpuKalmanFitter/demo/Run/GPU/CMakeFiles/IntersectGPUTest.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : Run/GPU/CMakeFiles/IntersectGPUTest.dir/depend

