/*
 * (C) Copyright 2021- UCAR
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 */

#ifndef TOOLS_NEW_OBSOP_EXAMPLE_OBSEXAMPLE_H_
#define TOOLS_NEW_OBSOP_EXAMPLE_OBSEXAMPLE_H_

#include <ostream>

#include "ioda/ObsDataVector.h"

#include "oops/base/Variables.h"

//#include "ufo/operators/sigma/ObssigmaParameters.h"
#include "ufo/Fortran.h"
#include "ufo/ObsOperatorBase.h"
#include "ufo/operators/sigma/sigmaParameters/ObssigmaParameters.h"

/// Forward declarations
namespace ioda {
  class ObsSpace;
  class ObsVector;
}

namespace ufo {
  class GeoVaLs;
  class ObsDiagnostics;

// -----------------------------------------------------------------------------
/// sigma observation operator class
class Obssigma : public ObsOperatorBase {
 public:
  /// The type of parameters accepted by the constructor of this operator.
  /// This typedef is used by the ObsOperatorFactory.
  typedef ObssigmaParameters Parameters_;
  typedef ioda::ObsDataVector<int> QCFlags_t; 

  Obssigma(const ioda::ObsSpace &, const Parameters_ &);
  virtual ~Obssigma();

// Obs Operator
  void simulateObs(const GeoVaLs &, ioda::ObsVector &, ObsDiagnostics &,
                   const QCFlags_t &) const override;

// Other
  const oops::Variables & requiredVars() const override {return varin_;}

  int & toFortran() {return keyOpersigma_;}
  const int & toFortran() const {return keyOpersigma_;}

 private:
  void print(std::ostream &) const override;
  F90hop keyOpersigma_;
  const ioda::ObsSpace& odb_;
  oops::Variables varin_;
};

// -----------------------------------------------------------------------------

}  // namespace ufo
#endif  // TOOLS_NEW_OBSOP_EXAMPLE_OBSEXAMPLE_H_
