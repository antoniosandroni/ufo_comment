! (C) Copyright 2017-2019 UCAR
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

!> Fortran sigma module for functions on the interface between C++ and Fortran
!  to handle observation operators

module ufo_sigma_mod_c

  use iso_c_binding
  use ufo_sigma_mod 
  use fckit_mpi_module,   only: fckit_mpi_comm !aggiunto
  implicit none
  private

  ! ------------------------------------------------------------------------------
#define LISTED_TYPE ufo_sigma

  !> Linked list interface - defines registry_t type
#include "oops/util/linkedList_i.f"

  !> Global registry
  type(registry_t) :: ufo_sigma_registry

  ! ------------------------------------------------------------------------------

contains

  ! ------------------------------------------------------------------------------
  !> Linked list implementation
#include "oops/util/linkedList_c.f"

! ------------------------------------------------------------------------------

subroutine ufo_sigma_setup_c(c_key_self, c_conf, c_nchan, c_channels, c_obsvars, c_geovars, c_comm) bind(c,name='ufo_sigma_setup_f90')
!in crtm I have as input also midPointJulday
use fckit_configuration_module, only: fckit_configuration
use oops_variables_mod
use obs_variables_mod
implicit none
integer(c_int), intent(inout)  :: c_key_self !keyOper_ in C++
type(c_ptr), value, intent(in) :: c_conf !parameters.toConfiguration() in C++
type(c_ptr), value, intent(in) :: c_obsvars ! odb.obsvariables() in C++
!perché crtm non ha obsvars(odb.obsvariables())?
type(c_ptr), value, intent(in) :: c_geovars ! variables requested from the model for SIGMA
type(c_ptr), value, intent(in) :: c_comm !AGGIUNTA per selezionare il rank di lavoro

type(ufo_sigma), pointer :: self !the ufo_sigma type is defined in the ufo_sigma_mod, the self object has 
!the methods to configure and produce sigma radiances
!this self object inside has the variable obsvars and oopsvars
type(fckit_configuration) :: f_conf
type(fckit_mpi_comm)      :: f_comm
!these are crtm variables
integer(c_int), intent(in) :: c_nchan !number of channles to assimilate
integer(c_int), intent(in) :: c_channels(c_nchan) !channels to assimilate
!integer(c_int64_t), intent(in) :: midPointJulday
call ufo_sigma_registry%setup(c_key_self, self)
f_conf = fckit_configuration(c_conf)
f_comm = fckit_mpi_comm(c_comm) 

!f_comm = fckit_mpi_comm(c_comm) in crtm

self%obsvars = obs_variables(c_obsvars)
!this mimicks oops_vars = oops_variables(c_varlist) of the CRTM interface
self%geovars = oops_variables(c_geovars)

call self%setup(f_conf, c_channels, f_comm)!inside this we add the varin array to the self%geovars variable->already linekd to c_geovars

end subroutine ufo_sigma_setup_c

! ------------------------------------------------------------------------------

subroutine ufo_sigma_delete_c(c_key_self) bind(c,name='ufo_sigma_delete_f90')
implicit none
integer(c_int), intent(inout) :: c_key_self

! if type ufo_sigma has allocatable data, it should implement a destructor
! marked final to deallocate the data. this will be called when remove
! deallocates the ufo_sigma instance from the registry.
call ufo_sigma_registry%remove(c_key_self)

end subroutine ufo_sigma_delete_c

! ------------------------------------------------------------------------------

subroutine ufo_sigma_simobs_c(c_key_self, c_key_geovals, c_obsspace, c_nvars, c_nlocs, &
                                c_hofx) bind(c,name='ufo_sigma_simobs_f90')
use ufo_geovals_mod,   only: ufo_geovals
use ufo_geovals_mod_c, only: ufo_geovals_registry
implicit none
integer(c_int), intent(in) :: c_key_self
integer(c_int), intent(in) :: c_key_geovals
type(c_ptr), value, intent(in) :: c_obsspace
integer(c_int), intent(in)     :: c_nvars, c_nlocs
real(c_double), intent(inout)  :: c_hofx(c_nvars, c_nlocs)

type(ufo_sigma), pointer :: self
type(ufo_geovals), pointer :: geovals

call ufo_sigma_registry%get(c_key_self, self) ! so that the self object points to already existent object with the key
call ufo_geovals_registry%get(c_key_geovals, geovals)
call self%simobs(geovals, c_obsspace, c_nvars, c_nlocs, c_hofx)

end subroutine ufo_sigma_simobs_c

! ------------------------------------------------------------------------------

end module ufo_sigma_mod_c
