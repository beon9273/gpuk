// This file is part of the Acts project.
//
// Copyright (C) 2016-2018 CERN for the benefit of the Acts project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

///////////////////////////////////////////////////////////////////
// Surface.cpp, Acts project
///////////////////////////////////////////////////////////////////

#include "Surfaces/Surface.hpp"

#include <iomanip>
#include <iostream>
#include <utility>

Acts::Surface::Surface(const Transform3D &tform)
    : GeometryObject(), m_transform(std::move(tform)) {}

Acts::Surface::Surface(const Surface &other)
    : GeometryObject(other), m_transform(other.m_transform) {}

Acts::Surface::Surface(const GeometryContext &gctx, const Surface &other,
                       const Transform3D &shift)
    : GeometryObject(),
      m_transform(Transform3D(shift * other.transform(gctx))) {}

Acts::Surface::Surface(const Vector3D &center, const Vector3D &normal)
{
  /// the right-handed coordinate system is defined as
  /// T = normal
  /// U = Z x T if T not parallel to Z otherwise U = X x T
  /// V = T x U
  Vector3D T = normal.normalized();
  Vector3D U = std::abs(T.dot(Vector3D::UnitZ())) < s_curvilinearProjTolerance
                   ? Vector3D::UnitZ().cross(T).normalized()
                   : Vector3D::UnitX().cross(T).normalized();
  Vector3D V = T.cross(U);
  RotationMatrix3D curvilinearRotation;
  curvilinearRotation.col(0) = U;
  curvilinearRotation.col(1) = V;
  curvilinearRotation.col(2) = T;

  // curvilinear surfaces are boundless
  Transform3D transform{curvilinearRotation};
  transform.pretranslate(center);
  m_transform = transform;
}

bool Acts::Surface::isOnSurface(const GeometryContext &gctx,
                                const Vector3D &position,
                                const Vector3D &momentum,
                                const BoundaryCheck &bcheck) const {
  // create the local position
  Vector2D lposition{0., 0.};
  // global to local transformation
  bool gtlSuccess = globalToLocal(gctx, position, momentum, lposition);
  if (gtlSuccess) {
    //return bcheck ? bounds().inside(lposition, bcheck) : true;
    return true; 
  }
  // did not succeed
  return false;
}

Acts::Surface &Acts::Surface::operator=(const Surface &other) {
  if (&other != this) {
    //@Todo: active this  
    //GeometryObject::operator=(other);
    // detector element, identifier & layer association are unique
    m_transform = other.m_transform;
  }
  return *this;
}

bool Acts::Surface::operator==(const Surface &other) const {
  // (a) fast exit for pointer comparison
  if (&other == this) {
    return true;
  }
  // (b) fast exit for type
  if (other.type() != type()) {
    return false;
  }
//  // (c) fast exit for bounds
//  if (other.bounds() != bounds()) {
//    return false;
//  }
  // (e) compare transform values
  if (!m_transform.isApprox(other.m_transform, 1e-9)) {
    return false;
  }

  // we should be good
  return true;
}

bool Acts::Surface::operator!=(const Acts::Surface &sf) const {
  return !(operator==(sf));
}
