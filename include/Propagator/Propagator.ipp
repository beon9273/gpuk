#include "Utilities/Profiling.hpp"

template <typename S, typename N>
template <typename parameters_t, typename propagator_options_t,
          typename path_aborter_t>
ACTS_DEVICE_FUNC Acts::PropagatorResult Acts::Propagator<S, N>::propagate(
    const parameters_t &start, const propagator_options_t &options,
    typename propagator_options_t::action_type::result_type &actorResult)
    const {
  PUSH_RANGE("propagate", 1);

  PropagatorResult result;

  int surface_steps = 0;
  int surface_counts = 0;


  using StateType = State<propagator_options_t>;
  StateType state(start, options);

  path_aborter_t pathAborter;
  // pathAborter.internalLimit = options.pathLimit;

  state.options.initializer(state, m_stepper, result.initializerResult);
  // Navigator initialize state call
  m_navigator.status(state, m_stepper);
  // Pre-Stepping call to the action list
  state.options.action(state, m_stepper, actorResult);
  // assume negative outcome, only set to true later if we actually have
  // a positive outcome.
  // This is needed for correct error logging
  bool terminatedNormally = false;

  // Pre-Stepping: abort condition check
  if (!state.options.aborter(state, m_stepper, actorResult) and
      !pathAborter(state, m_stepper)) {
    // Pre-Stepping: target setting
    m_navigator.target(state, m_stepper);
    // Propagation loop : stepping

    PUSH_RANGE("for-loop", 2);

    for (; result.steps < state.options.maxSteps; ++result.steps) {
      // Perform a propagation step - it takes the propagation state

      printf("surface id: %d\n", surface_counts);

      PUSH_RANGE("step", 3);
      // int64_t t0 = clock ();
      bool res = m_stepper.step(state);
      // int64_t t1 = clock ();
      // How to handle the error here
      // if (not res) {
      //}
      // Accumulate the path length
      // ActsScalar s = *res;
      // result.pathLength += s;

      POP_RANGE();
      // std::cout << "state pos after step:" << state.stepping.pos(0, 0) << ", " << state.stepping.pos(0, 1) << ", " << state.stepping.pos(0, 2) << std::endl; 
      // printf("state pos after step: (%d, %d, %d)\n", state.stepping.pos(0, 0), state.stepping.pos(0, 1), state.stepping.pos(0, 2));
      // printf("Surface Id %d:\n", result.steps/2);
      ++surface_steps;
      printf("step id: %d\n", surface_steps);
      printf("state pos after step: (%f, %f, %f)\n", state.stepping.pos(0, 0), state.stepping.pos(0, 1), state.stepping.pos(0, 2));
      printf("state dir after step: (%f, %f, %f)\n", state.stepping.dir(0, 0), state.stepping.dir(0, 1), state.stepping.dir(0, 2));
      printf("state momentum: %f\n", state.stepping.p);
      printf("state charge: %d\n", state.stepping.q);
      printf("state num of stepTrails is: %zu\n", state.stepping.nStepTrials);
      // std::cout << "state pos after step:" << state.stepping.pos << std::endl;
      // ++surface_steps;
    

      // Post-stepping:
      // navigator status call - action list - aborter list - target call

      PUSH_RANGE("status + action", 4);
      m_navigator.status(state, m_stepper);

      auto surface = state.navigation.currentSurface;
      if (surface != nullptr) {
        // printf("Steps %d; %d; %ld\n", surface_steps, surface_counts, t1-t0);
        // printf("Steps %d; %d\n", surface_steps, surface_counts);
        surface_steps = 0;
        ++surface_counts;
      }

      state.options.action(state, m_stepper, actorResult);

      // printf("state pos after kalman: (%f, %f, %f)\n", state.stepping.pos(0, 0), state.stepping.pos(0, 1), state.stepping.pos(0, 2));

      if (state.options.aborter(state, m_stepper, actorResult) or
          pathAborter(state, m_stepper)) {
        terminatedNormally = true;
        break;
      }

      POP_RANGE();

      m_navigator.target(state, m_stepper);
    }

    POP_RANGE();
  }

  // if we didn't terminate normally (via aborters) set navigation break.
  // this will trigger error output in the lines below
  if (!terminatedNormally) {
    state.navigation.navigationBreak = true;
  }

  // Post-stepping call to the action list
  state.options.action(state, m_stepper, actorResult);

  /// Convert into return type and fill the result object
  //  auto curvState = m_stepper.curvilinearState(state.stepping);
  // Fill the end parameters
  // result.endParameters = std::make_unique<const
  // CurvilinearParameters>(std::get<CurvilinearParameters>(curvState));
  // Only fill the transport jacobian when covariance transport was done
  //  if (state.stepping.covTransport) {
  //    result.transportJacobian = std::get<Jacobian>(curvState);
  //  }

  POP_RANGE()

  return result;
}

#ifdef __CUDACC__
template <typename S, typename N>
template <typename parameters_t, typename propagator_options_t,
          typename path_aborter_t>
__device__ void Acts::Propagator<S, N>::propagate(
    const parameters_t &start, const propagator_options_t &options,
    typename propagator_options_t::action_type::result_type &actorResult,
    Acts::PropagatorResult &result) const {

  const bool IS_MAIN_THREAD = (threadIdx.x == 0 && threadIdx.y == 0);

  using StateType = State<propagator_options_t>;

  __shared__ StateType state;
  __shared__ path_aborter_t pathAborter;
  // This is needed for correct error logging
  __shared__ bool terminatedNormally;
  __shared__ bool terminatedEarly;

  // Initialize with main thread
  if (IS_MAIN_THREAD) {
    state = StateType(start, options);
    pathAborter = path_aborter_t();
    // pathAborter.internalLimit = options.pathLimit;

    state.options.initializer(state, m_stepper, result.initializerResult);
    // Navigator initialize state call
    m_navigator.status(state, m_stepper);
    // assume negative outcome, only set to true later if we actually have
    // a positive outcome.
    terminatedNormally = false;
    terminatedEarly = false;
  }
  __syncthreads();
  // Pre-Stepping call to the action list
  state.options.action.actionOnDevice(state, m_stepper, actorResult);
  // Pre-Stepping: abort condition check
  if (IS_MAIN_THREAD) {
    if (state.options.aborter(state, m_stepper, actorResult) or
        pathAborter(state, m_stepper)) {
      terminatedEarly = true;
    }
  }
  __syncthreads();

  if (!terminatedEarly) {
    // Pre-Stepping: target setting
    if (IS_MAIN_THREAD) {
      m_navigator.target(state, m_stepper);
    }
    __syncthreads();
    // Propagation loop : stepping
    // int surface_steps = 0;
    // int surface_counts = 0;

    for (int step = result.steps; step < state.options.maxSteps; ++step) {
      // Perform a propagation step - it takes the propagation state
      if (IS_MAIN_THREAD) {
        ++result.steps;
        // ++surface_steps;
      }
      // maybe don't need syncthreads here
      __syncthreads();

      bool res = m_stepper.stepOnDevice(state);
      // How to handle the error here
      // if (not res) {
      //}
      // Accumulate the path length
      // ActsScalar s = *res;
      // result.pathLength += s;

      // Post-stepping:
      // navigator status call - action list - aborter list - target call
      if (IS_MAIN_THREAD) {
        m_navigator.status(state, m_stepper);
      }
      __syncthreads();
      auto surface = state.navigation.currentSurface;
      // printf("Steps %d; %d\n", surface_steps, surface_counts);
      // if (surface != nullptr && IS_MAIN_THREAD) {
      //   printf("Steps %d; %d\n", surface_steps, surface_counts);
      //   surface_steps = 0;
      //   ++surface_counts;
      // }
      // The state and actorResult is at shared memory. The m_stepper is at
      // global memory
      state.options.action.actionOnDevice(state, m_stepper, actorResult);
      // state.options.action(state, m_stepper, actorResult);

      if (IS_MAIN_THREAD) {
        if (state.options.aborter(state, m_stepper, actorResult) or
            pathAborter(state, m_stepper)) {
          terminatedNormally = true;
        }
      }
      __syncthreads();

      if (terminatedNormally) {
        break;
      }

      if (IS_MAIN_THREAD) {
        m_navigator.target(state, m_stepper);
      }
      __syncthreads();
    }
  }

  if (IS_MAIN_THREAD) {
    // if we didn't terminate normally (via aborters) set navigation break.
    // this will trigger error output in the lines below
    if (!terminatedNormally) {
      state.navigation.navigationBreak = true;
    }
    // Post-stepping call to the action list
    state.options.action(state, m_stepper, actorResult);

    /// Convert into return type and fill the result object
    //  auto curvState = m_stepper.curvilinearState(state.stepping);
    // Fill the end parameters
    // result.endParameters = std::make_unique<const
    // CurvilinearParameters>(std::get<CurvilinearParameters>(curvState));
    // Only fill the transport jacobian when covariance transport was done
    //  if (state.stepping.covTransport) {
    //    result.transportJacobian = std::get<Jacobian>(curvState);
    //  }
  }
  __syncthreads();
}
#endif
