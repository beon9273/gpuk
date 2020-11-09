// This file is part of the Acts project.
//
// Copyright (C) 2016-2020 CERN for the benefit of the Acts project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#pragma once

#include "Material/Material.hpp"

#include <iosfwd>
#include <vector>

namespace Acts {

/// Material description for an object with defined thickness.
///
/// This is intended to describe concrete surface materials.
///
/// @see Material for a description of the available parameters.
class MaterialSlab {
public:
  /// Construct vacuum without thickness.
  MaterialSlab() = default;
  /// Construct vacuum with thickness.
  ACTS_DEVICE_FUNC MaterialSlab(float thickness);
  /// Construct from material description.
  ///
  /// @param material  is the material description
  /// @param thickness is the thickness of the material
  ACTS_DEVICE_FUNC MaterialSlab(const Material &material, float thickness);

  ~MaterialSlab() = default;

  MaterialSlab(MaterialSlab &&) = default;
  MaterialSlab(const MaterialSlab &) = default;
  MaterialSlab &operator=(MaterialSlab &&) = default;
  MaterialSlab &operator=(const MaterialSlab &) = default;

  /// Scale the material thickness by the given factor.
  ACTS_DEVICE_FUNC void scaleThickness(float scale);

  /// Check if the material is valid, i.e. it is finite and not vacuum.
  ACTS_DEVICE_FUNC constexpr operator bool() const {
    return m_material and (0.0f < m_thickness);
  }

  /// Access the (average) material parameters.
  ACTS_DEVICE_FUNC constexpr const Material &material() const {
    return m_material;
  }
  /// Return the thickness.
  ACTS_DEVICE_FUNC constexpr float thickness() const { return m_thickness; }
  /// Return the radiation length fraction.
  ACTS_DEVICE_FUNC constexpr float thicknessInX0() const {
    return m_thicknessInX0;
  }
  /// Return the nuclear interaction length fraction.
  ACTS_DEVICE_FUNC constexpr float thicknessInL0() const {
    return m_thicknessInL0;
  }

private:
  Material m_material;
  float m_thickness = 0.0f;
  float m_thicknessInX0 = 0.0f;
  float m_thicknessInL0 = 0.0f;

  friend constexpr bool operator==(const MaterialSlab &lhs,
                                   const MaterialSlab &rhs) {
    // t/X0 and t/L0 are dependent variables and need not be checked
    return (lhs.m_material == rhs.m_material) and
           (lhs.m_thickness == rhs.m_thickness);
  }
  friend constexpr bool operator!=(const MaterialSlab &lhs,
                                   const MaterialSlab &rhs) {
    return !(lhs == rhs);
  }
};

} // namespace Acts

#include "Material/detail/MaterialSlab.ipp"