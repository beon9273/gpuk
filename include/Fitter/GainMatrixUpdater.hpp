// This file is part of the Acts project.
//
// Copyright (C) 2016-2018 CERN for the benefit of the Acts project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#pragma once

#include "EventData/TrackParameters.hpp"
#include "Fitter/detail/VoidKalmanComponents.hpp"
#include "Utilities/Definitions.hpp"
#include "Utilities/Helpers.hpp"

#include <memory>

namespace Acts {

/// @brief Update step of Kalman Filter using gain matrix formalism
class GainMatrixUpdater {
public:
  /// @brief Public call operator for the boost visitor pattern
  ///
  /// @tparam track_state_t Type of the track state for the update
  ///
  /// @param gctx The current geometry context object, e.g. alignment
  /// @param trackState the measured track state
  /// @param direction the navigation direction
  ///
  /// @return Bool indicating whether this update was 'successful'
  /// @note Non-'successful' updates could be holes or outliers,
  ///       which need to be treated differently in calling code.
  template <typename track_state_t>
  ACTS_DEVICE_FUNC bool operator()(const GeometryContext &gctx,
                                   track_state_t &trackState) const {
    // printf("Invoked GainMatrixUpdater\n");
    using parameters_t = typename track_state_t::Parameters;
    using source_link_t = typename track_state_t::SourceLink;

    using CovMatrix_t = typename parameters_t::CovarianceMatrix;
    using ParVector_t = typename parameters_t::ParametersVector;

    using projector_t = typename source_link_t::projector_t;
    using meas_par_t = typename source_link_t::meas_par_t;
    using meas_cov_t = typename source_link_t::meas_cov_t;

    constexpr size_t measdim = meas_par_t::RowsAtCompileTime;

    // read-only prediction handle
    const parameters_t &predicted = trackState.parameter.predicted;
    const CovMatrix_t &predicted_covariance = *predicted.covariance();

    ParVector_t filtered_parameters;
    CovMatrix_t filtered_covariance;

    // The source link
    const auto &sl = trackState.measurement.uncalibrated;

    // Take the projector (measurement mapping function)
    const auto &H = sl.projector();
    meas_cov_t cov = H * predicted_covariance * H.transpose() + sl.covariance();
    meas_cov_t covInv = get2DMatrixInverse(cov);
    // The Kalman gain matrix
    const ActsMatrixD<eBoundParametersSize, measdim> K =
        predicted_covariance * H.transpose() * covInv;

    // filtered new parameters after update
    const ParVector_t gain = K * sl.residual(predicted);
    filtered_parameters = predicted.parameters() + gain;

    const CovMatrix_t KH = K * H;
    const CovMatrix_t C = CovMatrix_t::Identity() - KH;
    // updated covariance after filtering
    filtered_covariance = C * predicted_covariance;

    // Create new filtered parameters and covariance
    parameters_t filtered(gctx, std::move(filtered_covariance),
                          filtered_parameters, &sl.referenceSurface());
    //
    //    // calculate the chi2
    //    // chi2 = r^T * R^-1 * r
    //    // r is the residual of the filtered state
    //    // R is the covariance matrix of the filtered residual
    //    meas_cov_t R = (meas_cov_t::Identity() - H * K) * sl.covariance();
    //    meas_par_t residual = sl.residual(filtered);
    //    trackState.parameter.chi2 =
    //        (residual.transpose() *
    //         get2DMatrixInverse(R) *
    //         residual)
    //            .eval()(0, 0);
    //
    trackState.parameter.filtered = filtered;
    // trackState.parameter.filtered = predicted;

    // always succeed, no outlier logic yet
    return true;
  }
};

} // namespace Acts
