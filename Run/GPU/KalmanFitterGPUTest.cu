#include "FitData.hpp"
#include "Processor.hpp"
#include "Writer.hpp"

#include "Geometry/GeometryID.hpp"
#include "Material/HomogeneousSurfaceMaterial.hpp"
#include "Utilities/CudaHelper.hpp"
#include "Utilities/Profiling.hpp"

#include "ActsExamples/MultiplicityGenerators.hpp"
#include "ActsExamples/ParametricParticleGenerator.hpp"
#include "ActsExamples/VertexGenerators.hpp"

#include "Test/Helper.hpp"
#include "Test/Logger.hpp"

#include "DataSizeCalculator.cu"
#include "Kernels.cu"

#include <chrono>
#include <cmath>
#include <fstream>
#include <iostream>
#include <random>
#include <string>
#include <type_traits>
#include <vector>

// This executable is used to run the KalmanFitter fit test on GPU with
// parallelism on the track-level. It contains mainly two parts: 1) Explicit
// calling of the propagation to create measurements on tracks 2) Running the
// Kalmanfitter using the created measurements in 1) as one of the inputs. In
// princinple, both 1) and 2) could on offloaded to GPU. Right now, only 2) is
// put into a kernel

static void show_usage(std::string name) {
  std::cerr << "Usage: <option(s)> VALUES"
            << "Options:\n"
            << "\t-h,--help\t\tShow this help message\n"
            << "\t-t,--tracks \tSpecify the number of tracks\n"
            << "\t-e,--streams \tSpecify number of streams\n"
            << "\t-r,--threads \tSpecify the number of threads\n"
            << "\t-u,--multiple-devices \tIndicator for running on multiple "
               "GPUs (if available)\n"
            << "\t-o,--output \tIndicator for writing propagation results\n"
            << "\t-d,--device \tSpecify the device: 'gpu' or 'cpu'\n"
            << "\t-g,--grid-size \tSpecify GPU grid size: 'x*y'\n"
            << "\t-b,--block-size \tSpecify GPU block size: 'x*y*z'\n"
            << "\t-s,--shared-memory \tIndicator for using shared memory for "
               "one track or not\n"
            << "\t-m,--smoothing \tIndicator for running smoothing\n"
            << "\t-a,--machine \tThe name of the machine, e.g. V100\n"
            << std::endl;
}

void logGPUInfo() {}

int main(int argc, char *argv[]) {
  Size nTracks = 10000;
  Size nStreams = 1;
  Size nThreads = 250;
  Size nDevices = 1;
  // The number of navigation surfaces
  const Size nSurfaces = 10;
  bool output = false;
  bool useSharedMemory = false;
  bool smoothing = true;
  bool multiGpu = false;
  std::string device = "cpu";
  std::string machine;
  std::string bFieldFileName;
  dim3 grid(100000), block(8, 8);
  // This should always be included
  for (Size i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if ((arg == "-h") or (arg == "--help")) {
      show_usage(argv[0]);
      return 0;
    } else if (i + 1 < argc) {
      if ((arg == "-t") or (arg == "--tracks")) {
        nTracks = atoi(argv[++i]);
      } else if ((arg == "-e") or (arg == "--streams")) {
        nStreams = atoi(argv[++i]);
        if (multiGpu && nStreams > 1) {
          std::cerr << "--multiple-devices and --streams options are "
                       "incompatible. Choose only one for now!"
                    << std::endl;
          return 1;
        }
      } else if ((arg == "-r") or (arg == "--threads")) {
        nThreads = atoi(argv[++i]);
      } else if ((arg == "-u") or (arg == "--multiple-devices")) {
        multiGpu = (atoi(argv[++i]) == 1);
        if (multiGpu) {
          if (nStreams > 1) {
            std::cerr << "--multiple-devices and --streams options are "
                         "incompatible. Choose only one for now!"
                      << std::endl;
            return 1;
          } else {
            int nDev;
            GPUERRCHK(cudaGetDeviceCount(&nDev));
            nDevices = (Size)nDev;
            nStreams = nDevices;
          }
        }
      } else if ((arg == "-o") or (arg == "--output")) {
        output = (atoi(argv[++i]) == 1);
      } else if ((arg == "-d") or (arg == "--device")) {
        device = argv[++i];
      } else if ((arg == "-a") or (arg == "--machine")) {
        machine = argv[++i];
      } else if ((arg == "-g") or (arg == "--grid-size")) {
        grid = stringToDim3(argv[++i]);
      } else if ((arg == "-b") or (arg == "--block-size")) {
        block = stringToDim3(argv[++i]);
      } else if ((arg == "-s") or (arg == "--shared-memory")) {
        useSharedMemory = (atoi(argv[++i]) == 1);
      } else if ((arg == "-m") or (arg == "--smoothing")) {
        smoothing = (atoi(argv[++i]) == 1);
      } else {
        std::cerr << "Unknown argument." << std::endl;
        return 1;
      }
    }
  }

  if (device == "gpu" and (grid.z != 1 or block.z != 1)) {
    std::cout
        << "ERROR: 3D grid or block is not supported at the moment! Good luck!"
        << std::endl;
    return 1;
  }

  bool doublePrecision = std::is_same<ActsScalar, double>::value;
  std::cout << "INFO: " << (doublePrecision ? "double" : "float")
            << " precision operand used." << std::endl;

  cudaDeviceProp prop;

  if (device == "gpu") {
    for (Size devId = 0; devId < nDevices; devId++) {
      GPUERRCHK(cudaSetDevice(devId));
      // https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__DEVICE.html
      GPUERRCHK(cudaGetDeviceProperties(&prop, devId));
      printf("\nDevice : %s\n", prop.name);
      printf("maxThreadsPerMultiProcessor : %i\n",
             prop.maxThreadsPerMultiProcessor);
      printf("maxGridSize : (%i, %i, %i)\n", prop.maxGridSize[0],
             prop.maxGridSize[1], prop.maxGridSize[2]);
      printf("maxThreadsPerBlock : %i\n", prop.maxThreadsPerBlock);
      printf("maxThreadsDim : (%i, %i, %i)\n", prop.maxThreadsDim[0],
             prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
      printf("regsPerMultiprocessor : %i\n", prop.regsPerMultiprocessor);
      printf("regsPerBlock : %i\n", prop.regsPerBlock);
      int driverVersion, rtVersion;
      GPUERRCHK(cudaDriverGetVersion(&driverVersion));
      printf("Cuda driver version: %i\n", driverVersion);
      GPUERRCHK(cudaRuntimeGetVersion(&rtVersion));
      printf("Cuda rt version: %i\n", rtVersion);

      // Print out the warp occupancy
      int OccupancyInNumBlocks;
      int blockSize = block.x * block.y;
      cudaOccupancyMaxActiveBlocksPerMultiprocessor(
          &OccupancyInNumBlocks, fitKernelThreadPerTrack, blockSize, 0);
      int activeWarps = OccupancyInNumBlocks * blockSize / prop.warpSize;
      int maxWarps = prop.maxThreadsPerMultiProcessor / prop.warpSize;
      std::cout << "INFO: Warp Occupancy with block size " << blockSize << " : "
                << (double)activeWarps / maxWarps * 100 << "%" << std::endl;

      // Print out the desirable block size
      int maxOccupancyBlockSize;
      int minGridSize;
      cudaOccupancyMaxPotentialBlockSize(&minGridSize, &maxOccupancyBlockSize,
                                         (void *)fitKernelThreadPerTrack, 0,
                                         nTracks);
      std::cout << "INFO: Estimated max occupancy with block size =  "
                << maxOccupancyBlockSize << ", min grid size = " << minGridSize
                << std::endl;
      std::cout << std::endl;
    }
  }

  if (machine.empty()) {
    if (device == "gpu") {
      machine = prop.name;
      std::replace(machine.begin(), machine.end(), ' ', '_');
      if (multiGpu)
        machine.append("x").append(std::to_string(nDevices));
    } else {
      std::cout << "ERROR: The name of the CPU being tested must be provided, "
                   "like e.g. "
                   "-a Intel_i7-8559U."
                << std::endl;
      return 1;
    }
  }

  Size tracksPerBlock = block.x * block.y;

  // Use 8*8 block if using one block for one track
  if (useSharedMemory) {
    std::cout << "WARNING: Shared memory used. Block size is set to 8 x 8!"
              << std::endl;
    block = dim3(8, 8);
    tracksPerBlock = 1;
  }

  // The navigation surfaces
  const Size navigationSurfaceBytes = sizeof(PlaneSurfaceType) * nSurfaces;
  // The track-specific objects
  const auto dataBytes = FitDataSizeCalculator::totalBytes(nSurfaces, nTracks);
  // The last stream could could less tracks
  const auto dataBytesPerStream =
      FitDataSizeCalculator::streamBytes(nSurfaces, nTracks, nStreams, 0);
  const auto dataBytesLastStream = FitDataSizeCalculator::streamBytes(
      nSurfaces, nTracks, nStreams, nStreams - 1);
  const Size tracksPerStream = dataBytesPerStream[7];
  const Size tracksLastStream = dataBytesLastStream[7];

  // The grid size
  const Size blocksPerGrid =
      (tracksPerStream + tracksPerBlock - 1) / tracksPerBlock;
  if (grid.x * grid.y < blocksPerGrid) {
    std::cout << "WARNING: Grid size too small. It's set to the minimum size: "
              << blocksPerGrid << std::endl;
    grid = blocksPerGrid;
  }

  if (device == "gpu") {
    std::cout << "INFO: grid size = " << grid.x << " x " << grid.y
              << ", block size =  " << block.x << " x " << block.y << std::endl;
  }

  // Create a test context
  Acts::GeometryContext gctx(0);
  Acts::MagneticFieldContext mctx(0);

  // Create a random number service
  ActsExamples::RandomNumbers::Config config;
  auto randomNumbers = std::make_shared<ActsExamples::RandomNumbers>(config);
  auto rng = randomNumbers->spawnGenerator(0);

  // Create the geometry
  // Set translation vectors
  std::vector<Acts::Vector3D> translations;
  for (Size isur = 0; isur < nSurfaces; isur++) {
    Acts::Vector3D translation(isur * 30. + 20., 0., 0.);
    translations.emplace_back(translation);
  }
  // The silicon material
  Acts::MaterialSlab matProp(Test::makeSilicon(), 0.5 * Acts::units::_mm);
  Acts::HomogeneousSurfaceMaterial surfaceMaterial(matProp);
  // Create plane surfaces without boundaries
  PlaneSurfaceType *surfaces;
  GPUERRCHK(cudaMallocHost(&surfaces, navigationSurfaceBytes));
  for (Size isur = 0; isur < nSurfaces; isur++) {
    surfaces[isur] = PlaneSurfaceType(translations[isur],
                                      Acts::Vector3D(1, 0, 0), surfaceMaterial);
  }
  // Assign the geometry ID
  for (Size isur = 0; isur < nSurfaces; isur++) {
    auto geoID =
        Acts::GeometryID().setVolume(0u).setLayer(isur).setSensitive(isur);
    surfaces[isur].assignGeoID(geoID);
  }
  const Acts::Surface *surfacePtrs = surfaces;
  std::cout << "INFO: Creating " << nSurfaces << " boundless plane surfaces"
            << std::endl;

  // Pinned memory for data objects
  Acts::PixelSourceLink *sourcelinks;
  BoundState *boundStates;
  Acts::LineSurface *targetSurfaces;
  FitOptionsType *fitOptions;
  TSType *fitStates;
  Acts::BoundParameters<Acts::LineSurface> *fitPars;
  bool *fitStatus;
  GPUERRCHK(
      cudaMallocHost((void **)&sourcelinks, dataBytes[FitData::SourceLinks]));
  GPUERRCHK(
      cudaMallocHost((void **)&boundStates, dataBytes[FitData::StartState]));
  GPUERRCHK(cudaMallocHost((void **)&targetSurfaces,
                           dataBytes[FitData::TargetSurface]));
  GPUERRCHK(
      cudaMallocHost((void **)&fitOptions, dataBytes[FitData::FitOptions]));
  GPUERRCHK(cudaMallocHost((void **)&fitStates, dataBytes[FitData::FitStates]));
  GPUERRCHK(cudaMallocHost((void **)&fitPars, dataBytes[FitData::FitParams]));
  GPUERRCHK(cudaMallocHost((void **)&fitStatus, dataBytes[FitData::FitStatus]));

  // Prepare to run the particles generation
  ActsExamples::GaussianVertexGenerator vertexGen;
  vertexGen.stddev[Acts::eFreePos0] = 20.0 * Acts::units::_um;
  vertexGen.stddev[Acts::eFreePos1] = 20.0 * Acts::units::_um;
  vertexGen.stddev[Acts::eFreePos2] = 50.0 * Acts::units::_um;
  vertexGen.stddev[Acts::eFreeTime] = 1.0 * Acts::units::_ns;
  ActsExamples::ParametricParticleGenerator::Config pgCfg;
  // @note We are generating 20% more particles to make sure we could get enough
  // valid particles
  size_t nGeneratedParticles = nTracks * 1.2;
  ActsExamples::Generator generator = ActsExamples::Generator{
      ActsExamples::FixedMultiplicityGenerator{nGeneratedParticles},
      std::move(vertexGen), ActsExamples::ParametricParticleGenerator(pgCfg)};
  // Run the generation to generate particles
  std::vector<ActsFatras::Particle> generatedParticles;
  runParticleGeneration(rng, generator, generatedParticles);

  // Prepare to run the simulation
  Stepper stepper;
  PropagatorType propagator(stepper);
  auto start_propagate = std::chrono::high_resolution_clock::now();
  // Run the simulation to generate sim hits
  // @note We will pick up the valid particles
  std::vector<Simulator::result_type> simResult(nTracks);
  std::vector<ActsFatras::Particle> validParticles(nTracks);
  runSimulation(gctx, mctx, rng, propagator, generatedParticles, validParticles,
                simResult, surfacePtrs, nSurfaces);
  auto end_propagate = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double> elapsed_seconds =
      end_propagate - start_propagate;
  std::cout << std::endl;
  std::cout << "INFO: Time (ms) to run simulation: "
            << elapsed_seconds.count() * 1000 << std::endl;
  if (output) {
    std::string simFileName =
        "sim_hits_for_" + std::to_string(nTracks) + "_particles.obj";
    std::cout << "INFO: Writing simulation results to " << simFileName
              << std::endl;
    writeSimHitsObj(simResult, simFileName);
  }

  // Build the target surfaces based on the truth particle position
  buildTargetSurfaces(validParticles, targetSurfaces);

  // The hit smearing resolution
  std::array<ActsScalar, 2> hitResolution = {50. * Acts::units::_um,
                                             50. * Acts::units::_um};
  // Run hit smearing to create source links
  // @note pass the concreate PlaneSurfaceType pointer here
  runHitSmearing(gctx, rng, simResult, hitResolution, sourcelinks, surfaces,
                 nSurfaces);

  // The particle smearing resolution
  ParticleSmearingParameters seedResolution;
  // Run truth seed smearing to create starting parameters with provided
  // reference surface
  auto startParsCollection = runParticleSmearing(
      rng, gctx, validParticles, seedResolution, targetSurfaces, nTracks);
  // Initialize the boundState
  for (Size it = 0; it < nTracks; it++) {
    boundStates[it].boundParams = startParsCollection[it].parameters();
    boundStates[it].boundCov = *startParsCollection[it].covariance();
  }

  // Prepare to perform fit to the created tracks
  KalmanFitterType kFitter(propagator);
  // Initialize the fitOptions and fit status
  for (Size it = 0; it < nTracks; it++) {
    fitOptions[it] = FitOptionsType(gctx, mctx, smoothing);
    fitStatus[it] = false;
  }

  float sec; // elapsed time in seconds

  // Running directly on host or offloading to GPU
  bool useGPU = (device == "gpu");
  if (useGPU) {
    // Record time
    struct stat_t {
      double startDeviceTime = 0.0;
      double stopDeviceTime = 0.0;
    } stats[nDevices];

    // The same number of streams is available, but used either:
    // a. in parallel on the same device, OR
    // b. one per device, in parallel for all devices;
    cudaStream_t stream[nStreams];
    Size max = std::max(nDevices, nStreams);

    // The recorded starting time
    auto startFitTime = omp_get_wtime();

    for (Size i = 0; i < max; ++i) {
      GPUERRCHK(cudaSetDevice(multiGpu ? i : 0));
      GPUERRCHK(cudaStreamCreate(&stream[i]));
    }


#pragma omp parallel for num_threads(nDevices) proc_bind(master) if (multiGpu)   	
    for (Size devId = 0; devId < nDevices; ++devId) {
      stats[devId].startDeviceTime = omp_get_wtime();
      // Set the corresponding device
      GPUERRCHK(cudaSetDevice(devId));

      // Allocate memory on the device
      PlaneSurfaceType *d_surfaces;
      KalmanFitterType *d_kFitter;
      Acts::PixelSourceLink *d_sourcelinks;
      BoundState *d_boundStates;
      Acts::LineSurface *d_targetSurfaces;
      FitOptionsType *d_fitOptions;
      TSType *d_fitStates;
      Acts::BoundParameters<Acts::LineSurface> *d_fitPars;
      bool *d_fitStatus;
      GPUERRCHK(cudaMalloc(&d_surfaces, navigationSurfaceBytes));
      GPUERRCHK(cudaMalloc(&d_kFitter, sizeof(KalmanFitterType)));
      GPUERRCHK(cudaMalloc(&d_sourcelinks, dataBytes[FitData::SourceLinks]));
      GPUERRCHK(cudaMalloc(&d_boundStates, dataBytes[FitData::StartState]));
      GPUERRCHK(
          cudaMalloc(&d_targetSurfaces, dataBytes[FitData::TargetSurface]));
      GPUERRCHK(cudaMalloc(&d_fitOptions, dataBytes[FitData::FitOptions]));
      GPUERRCHK(cudaMalloc(&d_fitStates, dataBytes[FitData::FitStates]));
      GPUERRCHK(cudaMalloc(&d_fitPars, dataBytes[FitData::FitParams]));
      GPUERRCHK(cudaMalloc(&d_fitStatus, dataBytes[FitData::FitStatus]));

      // Copy the KalmanFitter and surfaces from host to device (shared between
      // all tracks)
      GPUERRCHK(cudaMemcpy(d_surfaces, surfaces, navigationSurfaceBytes,
                           cudaMemcpyHostToDevice));
      GPUERRCHK(cudaMemcpy(d_kFitter, &kFitter, sizeof(KalmanFitterType),
                           cudaMemcpyHostToDevice));

      // If more devices are available, then there is only 1 stream per device;
      // If only 1 device is available, then there are nStreams streams used;
      Size streamStartIdx = multiGpu ? devId : 0;
      Size streamEndIdx = multiGpu ? (devId + 1) : nStreams;

      for (Size i = streamStartIdx; i < streamEndIdx; ++i) {
        GPUERRCHK(cudaSetDevice(devId));
        Size offset = i * tracksPerStream;
        const auto streamTracks =
            (i < nStreams - 1) ? tracksPerStream : tracksLastStream;
        const auto streamDataBytes =
            (i < nStreams - 1) ? dataBytesPerStream : dataBytesLastStream;

        // Copy the objects  from host to device
        GPUERRCHK(cudaMemcpyAsync(&d_sourcelinks[offset * nSurfaces],
                                  &sourcelinks[offset * nSurfaces],
                                  streamDataBytes[FitData::SourceLinks],
                                  cudaMemcpyHostToDevice, stream[i]));
        GPUERRCHK(cudaMemcpyAsync(&d_boundStates[offset], &boundStates[offset],
                                  streamDataBytes[FitData::StartState],
                                  cudaMemcpyHostToDevice, stream[i]));
        GPUERRCHK(cudaMemcpyAsync(&d_targetSurfaces[offset],
                                  &targetSurfaces[offset],
                                  streamDataBytes[FitData::TargetSurface],
                                  cudaMemcpyHostToDevice, stream[i]));
        GPUERRCHK(cudaMemcpyAsync(&d_fitOptions[offset], &fitOptions[offset],
                                  streamDataBytes[FitData::FitOptions],
                                  cudaMemcpyHostToDevice, stream[i]));
        GPUERRCHK(cudaMemcpyAsync(&d_fitStates[offset * nSurfaces],
                                  &fitStates[offset * nSurfaces],
                                  streamDataBytes[FitData::FitStates],
                                  cudaMemcpyHostToDevice, stream[i]));
        GPUERRCHK(cudaMemcpyAsync(&d_fitPars[offset], &fitPars[offset],
                                  streamDataBytes[FitData::FitParams],
                                  cudaMemcpyHostToDevice, stream[i]));
        GPUERRCHK(cudaMemcpyAsync(&d_fitStatus[offset], &fitStatus[offset],
                                  streamDataBytes[FitData::FitStatus],
                                  cudaMemcpyHostToDevice, stream[i]));
        // Use shared memory for one track if requested
        std::size_t bufsize = 100000000; 
        cudaDeviceSetLimit ( cudaLimitPrintfFifoSize , bufsize);
        if (useSharedMemory) {
          fitKernelBlockPerTrack<<<grid, block, 0, stream[i]>>>(
              d_kFitter, d_sourcelinks, d_boundStates, d_targetSurfaces,
              d_fitOptions, d_fitStates, d_fitPars, d_fitStatus, d_surfaces,
              nSurfaces, streamTracks, offset);
        } else {
          fitKernelThreadPerTrack<<<grid, block, 0, stream[i]>>>(
              d_kFitter, d_sourcelinks, d_boundStates, d_targetSurfaces,
              d_fitOptions, d_fitStates, d_fitPars, d_fitStatus, d_surfaces,
              nSurfaces, streamTracks, offset);
        }

        // cudaDeviceSynchronize();
        // cudaDeviceReset();
        // Copy the fitted states to host
        GPUERRCHK(cudaMemcpyAsync(&fitStates[offset * nSurfaces],
                                  &d_fitStates[offset * nSurfaces],
                                  streamDataBytes[FitData::FitStates],
                                  cudaMemcpyDeviceToHost, stream[i]));
        if (smoothing) {
          // Copy the fitted params to host
          GPUERRCHK(cudaMemcpyAsync(&fitPars[offset], &d_fitPars[offset],
                                    streamDataBytes[FitData::FitParams],
                                    cudaMemcpyDeviceToHost, stream[i]));
        }
        // Copy the fit status to host
        GPUERRCHK(cudaMemcpyAsync(&fitStatus[offset], &d_fitStatus[offset],
                                  streamDataBytes[FitData::FitStatus],
                                  cudaMemcpyDeviceToHost, stream[i]));
      }
      GPUERRCHK(cudaPeekAtLastError());
      GPUERRCHK(cudaDeviceSynchronize());

      // Free the memory on device
      GPUERRCHK(cudaFree(d_sourcelinks));
      GPUERRCHK(cudaFree(d_boundStates));
      GPUERRCHK(cudaFree(d_targetSurfaces));
      GPUERRCHK(cudaFree(d_fitOptions));
      GPUERRCHK(cudaFree(d_fitStates));
      GPUERRCHK(cudaFree(d_fitPars));
      GPUERRCHK(cudaFree(d_fitStatus));
      GPUERRCHK(cudaFree(d_kFitter));
      GPUERRCHK(cudaFree(d_surfaces));

      // Destroy the streams
      for (Size i = streamStartIdx; i < streamEndIdx; i++) {
        GPUERRCHK(cudaStreamDestroy(stream[i]));
      }

      stats[devId].stopDeviceTime = omp_get_wtime();
    }

    auto endFitTime = omp_get_wtime();
    sec = endFitTime - startFitTime;

    // Log timing measurements at different devices
    for (int i = 0; i < nDevices; i++) {
      printf("INFO: Time (ms) for KF track fitting on "
             "device %d : %f\n",
             i, (stats[i].stopDeviceTime - stats[i].startDeviceTime) * 1000);
    }
    // Log the total timing measurement in ms
    printf("INFO: Total Wall clock time (ms) for KF track fitting: %f\n",
           sec * 1000);

    // Persistify the total timing measurement in ms
    std::string precision = doublePrecision ? "timing_double" : "timing";
    Test::Logger::logTime(
        Test::Logger::buildFilename(
            precision, machine, "nTracks", std::to_string(nTracks), "nStreams",
            std::to_string(nStreams), "gridSize", dim3ToString(grid),
            "blockSize", dim3ToString(block), "sharedMemory",
            std::to_string(static_cast<Size>(useSharedMemory))),
        sec * 1000);

  } else {
    /// Test on CPU
    int threads = 1;
    auto start_fit = std::chrono::high_resolution_clock::now();
#pragma omp parallel for num_threads(nThreads)
    for (Size it = 0; it < nTracks; it++) {
      // The fit result wrapper
      KalmanFitterResultType kfResult;
      kfResult.fittedStates = Acts::CudaKernelContainer<TSType>(
          &fitStates[it * nSurfaces], nSurfaces);
      // The input source links wrapper
      auto sourcelinkTrack = Acts::CudaKernelContainer<Acts::PixelSourceLink>(
          sourcelinks + it * nSurfaces, nSurfaces);
      fitOptions[it].referenceSurface = &targetSurfaces[it];
      // Run the fit. The fitStates will be changed here
      auto status = kFitter.fit(sourcelinkTrack, startParsCollection[it],
                                fitOptions[it], kfResult, surfaces, nSurfaces);
      // if (not status) {
      //  std::cout << "WARNING: fit failure for track " << it << std::endl;
      //}

      // Store the fit parameters and status
      fitStatus[it] = status;
      fitPars[it] = kfResult.fittedParameters;
      threads = omp_get_num_threads();
    }
    auto end_fit = std::chrono::high_resolution_clock::now();
    elapsed_seconds = end_fit - start_fit;

    // Log the timing measurement in ms
    std::cout << "INFO: Time (ms) to run KF track fitting for " << nTracks
              << " with " << threads
              << " OMP threads: " << elapsed_seconds.count() * 1000
              << std::endl;

    // Persistify the timing measurement in ms
    std::string precision =
        doublePrecision ? "timing_double_semi" : "timing_semi";
    Test::Logger::logTime(
        Test::Logger::buildFilename(precision, machine, "nTracks",
                                    std::to_string(nTracks), "OMP_NumThreads",
                                    std::to_string(threads)),
        elapsed_seconds.count() * 1000);
  }

  if (output) {
    std::cout << "INFO: Writing KF track fitting results" << std::endl;
    std::string stateFileName;
    std::string csvFileName;

    // The type of output parameters
    std::string state = smoothing ? "smoothed" : "filtered";
    stateFileName.append("fitted_");
    stateFileName.append(state);

    // The fitted parameters at the target surface
    csvFileName.append("fitted_");
    csvFileName.append("param");

    // The type of machines
    std::string machine_prefix = useGPU ? "_" : "_semi_";
    stateFileName.append(machine_prefix);
    stateFileName.append(machine);

    csvFileName.append(machine_prefix);
    csvFileName.append(machine);

    // The number of tracks
    stateFileName.append("_nTracks_");
    csvFileName.append("_nTracks_");

    // The type of the file written out
    stateFileName.append(std::to_string(nTracks)).append(".obj");
    csvFileName.append(std::to_string(nTracks)).append(".csv");
    writeStatesObj(fitStates, fitStatus, nTracks, nSurfaces, stateFileName,
                   state);
    // The fitted parameters are only available after smoothing
    if (smoothing) {
      writeParamsCsv(fitPars, fitStatus, nTracks, csvFileName);
    }
  }

  std::cout << "------------------------  ending  -----------------------"
            << std::endl;

  // Free the pinned memory
  GPUERRCHK(cudaFreeHost(surfaces));
  GPUERRCHK(cudaFreeHost(sourcelinks));
  GPUERRCHK(cudaFreeHost(boundStates));
  GPUERRCHK(cudaFreeHost(targetSurfaces));
  GPUERRCHK(cudaFreeHost(fitOptions));
  GPUERRCHK(cudaFreeHost(fitStates));
  GPUERRCHK(cudaFreeHost(fitPars));
  GPUERRCHK(cudaFreeHost(fitStatus));

  return 0;
}
