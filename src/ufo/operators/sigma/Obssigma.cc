/*
 * (C) Copyright 2021- UCAR
 * 
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0. 
 */

#include "ufo/operators/sigma/Obssigma.h"

#include <ostream>

#include "ioda/ObsVector.h"

#include "ufo/operators/sigma/Obssigma.interface.h"
#include "ufo/GeoVaLs.h"
#include "ufo/ObsDiagnostics.h"

namespace ufo {

// -----------------------------------------------------------------------------
static ObsOperatorMaker<Obssigma> makersigma_("sigma");
// -----------------------------------------------------------------------------

Obssigma::Obssigma(const ioda::ObsSpace & odb,
                       const Parameters_ & parameters)
  : ObsOperatorBase(odb), keyOpersigma_(0), odb_(odb), varin_()
{  // here in crtm there is the channel parsing 
  std::cout << "FROM Obssigma.cc: prima di tutto" << std::endl;
 // parse channels from the config and create variable names AGGIUNTA
  const oops::ObsVariables & observed = odb.assimvariables();
  std::vector<int> channels_list = observed.channels();

  ufo_sigma_setup_f90(keyOpersigma_, parameters.toConfiguration(),
                      channels_list.size(), channels_list[0], odb.obsvariables(), varin_, odb.comm());
  
  oops::Log::info() << "Obssigma channels: " << channels_list << std::endl;
  oops::Log::trace() << "Obssigma created." << std::endl;

  //AGGIUNTO questo pint
  const std::vector<std::string> vars = varin_.variables();
  std::cout << "FROM Obssigma.cc: varin_ contains:" << std::endl;
  for (const auto & v : vars) {std::cout << "  " << v << std::endl;}  
}

// -----------------------------------------------------------------------------

Obssigma::~Obssigma() {
  ufo_sigma_delete_f90(keyOpersigma_);
  oops::Log::trace() << "Obssigma destructed" << std::endl;
}

// -----------------------------------------------------------------------------

void Obssigma::simulateObs(const GeoVaLs & gv, ioda::ObsVector & ovec,
                             ObsDiagnostics & d, const QCFlags_t & qc_flags) const {
  ufo_sigma_simobs_f90(keyOpersigma_, gv.toFortran(), odb_, ovec.nvars(), ovec.nlocs(),
                         ovec.toFortran());
  oops::Log::trace() << "Obssigma: observation operator run" << std::endl;
}

// -----------------------------------------------------------------------------

void Obssigma::print(std::ostream & os) const {
  os << "Obssigma::print not implemented";
}

// -----------------------------------------------------------------------------

}  // namespace ufo
