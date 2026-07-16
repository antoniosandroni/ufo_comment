# (C) Copyright 2017-2018 UCAR.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

set ( sigma_files
    sigmaParameters/ObssigmaParameters.h
    Obssigma.h
    Obssigma.cc
    ObssigmaTLAD.h
    ObssigmaTLAD.cc
    Obssigma.interface.F90
    Obssigma.interface.h
    ObssigmaTLAD.interface.F90
    ObssigmaTLAD.interface.h
    ufo_sigma_mod.F90
    ufo_sigma_tlad_mod.F90
    ufo_sigma_utils_mod.f90
    sum_mod.F90
)
PREPEND( _p_sigma_files     "operators/sigma"     ${sigma_files} )

set ( sigma_src_files
      ${_p_sigma_files}
      PARENT_SCOPE
)
