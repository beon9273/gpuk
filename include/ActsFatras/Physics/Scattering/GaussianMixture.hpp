// This file is part of the Acts project.
//
// Copyright (C) 2018-2020 CERN for the benefit of the Acts project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#pragma once

#include "ActsFatras/Physics/Scattering/detail/Scattering.hpp"
#include "Material/Interactions.hpp"

#include <random>

namespace ActsFatras {
namespace detail {

/// Generate scattering angles using a Gaussian mixture model.
struct GaussianMixture {
  /// Steering parameter
  bool optGaussianMixtureG4 = false;
  ActsScalar gausMixSigma1_a0 = 8.471e-1;
  ActsScalar gausMixSigma1_a1 = 3.347e-2;
  ActsScalar gausMixSigma1_a2 = -1.843e-3;
  ActsScalar gausMixEpsilon_a0 = 4.841e-2;
  ActsScalar gausMixEpsilon_a1 = 6.348e-3;
  ActsScalar gausMixEpsilon_a2 = 6.096e-4;
  ActsScalar gausMixEpsilon_b0 = -1.908e-2;
  ActsScalar gausMixEpsilon_b1 = 1.106e-1;
  ActsScalar gausMixEpsilon_b2 = -5.729e-3;

  /// Generate a single 3D scattering angle.
  ///
  /// @param[in]     generator is the random number generator
  /// @param[in]     slab      defines the passed material
  /// @param[in,out] particle  is the particle being scattered
  /// @return a 3d scattering angle
  ///
  /// @tparam generator_t is a RandomNumberEngine
  template <typename generator_t>
  ActsScalar operator()(generator_t &generator, const Acts::MaterialSlab &slab,
                        Particle &particle) const {
    /// Calculate the highland formula first
    ActsScalar sigma = Acts::computeMultipleScatteringTheta0(
        slab, particle.pdg(), particle.mass(),
        particle.charge() / particle.absMomentum(), particle.charge());
    ActsScalar sigma2 = sigma * sigma;

    // Gauss distribution, will be sampled with generator
    std::normal_distribution<ActsScalar> gaussDist(0., 1.);
    // Uniform distribution, will be sampled with generator
    std::uniform_real_distribution<ActsScalar> uniformDist(0., 1.);

    // Now correct for the tail fraction
    // d_0'
    // beta?? = (p/E)?? = p??/(p?? + m??) = 1/(1 + (m/p)??)
    // 1/beta?? = 1 + (m/p)??
    ActsScalar mOverP = particle.mass() / particle.absMomentum();
    ActsScalar beta2inv = 1 + mOverP * mOverP;
    ActsScalar dprime = slab.thicknessInX0() * beta2inv;
    ActsScalar log_dprime = std::log(dprime);
    // d_0''
    ActsScalar log_dprimeprime =
        std::log(std::pow(slab.material().Z(), 2.0 / 3.0) * dprime);

    // get epsilon
    ActsScalar epsilon =
        log_dprimeprime < 0.5
            ? gausMixEpsilon_a0 + gausMixEpsilon_a1 * log_dprimeprime +
                  gausMixEpsilon_a2 * log_dprimeprime * log_dprimeprime
            : gausMixEpsilon_b0 + gausMixEpsilon_b1 * log_dprimeprime +
                  gausMixEpsilon_b2 * log_dprimeprime * log_dprimeprime;

    // the standard sigma
    ActsScalar sigma1square = gausMixSigma1_a0 + gausMixSigma1_a1 * log_dprime +
                              gausMixSigma1_a2 * log_dprime * log_dprime;

    // G4 optimised / native ActsScalar Gaussian model
    if (optGaussianMixtureG4) {
      sigma2 =
          225. * dprime / (particle.absMomentum() * particle.absMomentum());
    }
    // throw the random number core/tail
    if (uniformDist(generator) < epsilon) {
      sigma2 *= (1. - (1. - epsilon) * sigma1square) / epsilon;
    }
    // return back to the
    return M_SQRT2 * std::sqrt(sigma2) * gaussDist(generator);
  }
};

} // namespace detail

using GaussianMixtureScattering = detail::Scattering<detail::GaussianMixture>;

} // namespace ActsFatras
