// This file is part of the Acts project.
//
// Copyright (C) 2018 CERN for the benefit of the Acts project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#pragma once

#include "Utilities/Definitions.hpp"

#include <algorithm>
#include <array>
#include <iomanip>
#include <limits>
#include <sstream>

namespace Acts {

/// A constrained step class for the steppers
struct ConstrainedStep {
  /// the types of constraints
  /// from accuracy - this can vary up and down given a good step estimator
  /// from actor    - this would be a typical navigation step
  /// from aborter  - this would be a target condition
  /// from user     - this is user given for what reason ever
  enum Type : int { accuracy = 0, actor = 1, aborter = 2, user = 3 };

  /// the step size tuple
  // std::array<ActsScalar, 4> values = {
  ActsScalar values[4] = {std::numeric_limits<ActsScalar>::max(),
                          std::numeric_limits<ActsScalar>::max(),
                          std::numeric_limits<ActsScalar>::max(),
                          std::numeric_limits<ActsScalar>::max()};

  /// The Navigation direction
  NavigationDirection direction = forward;

  ACTS_DEVICE_FUNC ActsScalar max() const {
    ActsScalar max = std::numeric_limits<ActsScalar>::lowest();
    for (unsigned int i = 0; i < 4; i++) {
      if (values[i] > max) {
        max = values[i];
      }
    }
    return max;
  }

  ACTS_DEVICE_FUNC ActsScalar min() const {
    ActsScalar min = std::numeric_limits<ActsScalar>::max();
    for (unsigned int i = 0; i < 4; i++) {
      if (values[i] < min) {
        min = values[i];
      }
    }
    return min;
  }

  /// Update the step size of a certain type
  ///
  /// Only navigation and target abortion step size
  /// updates may change the sign due to overstepping
  ///
  /// @param value is the new value to be updated
  /// @param type is the constraint type
  ACTS_DEVICE_FUNC void update(const ActsScalar &value, Type type,
                               bool releaseStep = false) {
    if (releaseStep) {
      release(type);
    }
    // The check the current value and set it if appropriate
    ActsScalar cValue = values[type];
    values[type] = std::abs(cValue) < std::abs(value) ? cValue : value;
  }

  /// release a certain constraint value
  /// to the (signed) biggest value available, hence
  /// it depends on the direction
  ///
  /// @param type is the constraint type to be released
  ACTS_DEVICE_FUNC void release(Type type) {
    ActsScalar mvalue = (direction == forward) ? max() : min();
    values[type] = mvalue;
  }

  /// constructor from ActsScalar
  /// @paramn value is the user given initial value
  ACTS_DEVICE_FUNC ConstrainedStep(ActsScalar value)
      : direction(value > 0. ? forward : backward) {
    values[accuracy] *= direction;
    values[actor] *= direction;
    values[aborter] *= direction;
    values[user] = value;
  }

  /// The assignment operator from one ActsScalar
  /// @note this will set only the accuracy, as this is the most
  /// exposed to the Propagator, this adapts also the direction
  ///
  /// @param value is the new accuracy value
  ACTS_DEVICE_FUNC ConstrainedStep &operator=(const ActsScalar &value) {
    /// set the accuracy value
    values[accuracy] = value;
    // set/update the direction
    direction = value > 0. ? forward : backward;
    return (*this);
  }

  /// Cast operator to ActsScalar, returning the min/max value
  /// depending on the direction
  ACTS_DEVICE_FUNC operator ActsScalar() const {
    if (direction == forward) {
      return min();
    }
    return max();
  }

  /// Access to a specific value
  ///
  /// @param type is the resquested parameter type
  ACTS_DEVICE_FUNC ActsScalar value(Type type) const { return values[type]; }

  /// Access to currently leading min type
  ///
  //  ACTS_DEVICE_FUNC Type currentType() const {
  //    if (direction == forward) {
  //      return Type(std::min_element(values.begin(), values.end()) -
  //                  values.begin());
  //    }
  //    return Type(std::max_element(values.begin(), values.end()) -
  //                values.begin());
  //  }

#ifndef __CUDACC__
  /// return the split value as string for debugging
  std::string toString() const;
#endif
};

#ifndef __CUDACC__
inline std::string ConstrainedStep::toString() const {
  std::stringstream dstream;

  // Helper method to avoid unreadable screen output
  auto streamValue = [&](ConstrainedStep::Type cstep) -> void {
    ActsScalar val = values[cstep];
    dstream << std::setw(5);
    if (std::abs(val) == std::numeric_limits<ActsScalar>::max()) {
      dstream << (val > 0 ? "+???" : "-???");
    } else {
      dstream << val;
    }
  };

  dstream << "(";
  streamValue(accuracy);
  dstream << ", ";
  streamValue(actor);
  dstream << ", ";
  streamValue(aborter);
  dstream << ", ";
  streamValue(user);
  dstream << " )";
  return dstream.str();
}
#endif

} // namespace Acts
