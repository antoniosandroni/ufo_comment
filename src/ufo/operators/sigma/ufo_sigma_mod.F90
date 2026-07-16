! (C) Copyright 2017-2018 UCAR
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

!> Fortran module for sigma observation operator

module ufo_sigma_mod

 use,intrinsic :: iso_c_binding
 use oops_variables_mod
 use obs_variables_mod
 use ufo_vars_mod
 use iso_c_binding


 use fckit_mpi_module, only: fckit_mpi_comm
!///////////////////////////////MODULI INNESTO SIGMA////////////////////////////////
 use parameters
 use structures
 use configuration
 use sigma_subs
 use ufo_sigma_utils_mod
!////////////////////////////////////////////////////////////////////////////////////

 implicit none
 private

!> Fortran derived type for the observation type
! TODO: fill in if needed

!declaration of type ufo_sigma
 type, public :: ufo_sigma
 
   type(obs_variables), public :: obsvars
   type(oops_variables), public :: geovars
   
   character(len=MAXVARLEN), public, allocatable :: varin(:) !AGGIUNTA
   integer, allocatable                          :: channels(:)
!  invece di type(crtm_conf) :: conf prendo l'oggetto conf di sigma 
!  queste strutture sono definite nel modulo structures
   type(configuration_params) :: conf !qua ci vanno i dati del file xml, vecchio sigma_iasi.input
   type(atmosphere)           :: atm
   type(od_dbase)             :: od
   type(radiances)            :: rad
   type(isrf_convolution)     :: isrf

  ! Return value from subroutines
   integer(kind=I32) :: reset = FULL_RESET !con questo flag vengono lette le LUT
   integer(kind=I32) :: ios   = IERR_SUCCESS
   type(fckit_mpi_comm)       :: comm

  !Auxiliary variables
   integer(kind=I32)                 :: i,j
   integer(kind=I32)                 :: res
   character(len=MAX_STRING_LENGTH)  :: new_conf_file
   character(len=MAX_STRING_LENGTH)  :: prefix
   real(kind=R64)                    :: a,b,c,rand
 contains
   procedure :: setup  => ufo_sigma_setup
   procedure :: simobs => ufo_sigma_simobs
   final :: destructor
 end type ufo_sigma
! variabili che UFO prende dal modello con i nomi di UFO
 character(len=maxvarlen), dimension(7), parameter :: varin_default = & !constant array of 16 strings
                          (/var_ts, var_prs, var_prsi,var_sfc_ltmp,               &
                            var_mixr, var_co2, var_oz                             &
                            !var_sfc_wfrac, var_sfc_lfrac, var_sfc_ifrac, var_sfc_sfrac, &
                            !var_sfc_wtmp,  var_sfc_ltmp,  var_sfc_itmp,  var_sfc_stmp,  &
                            !var_sfc_vegfrac, var_sfc_lai,                               &
                            !var_sfc_soilm, var_sfc_sdepth
                            /)                           

contains

! ------------------------------------------------------------------------------
! TODO: add setup of your observation operator (optional)
subroutine ufo_sigma_setup(self, f_confOper, channels, comm)
use ufo_utils_mod, only: cmp_strings
use fckit_configuration_module, only: fckit_configuration
implicit none
class(ufo_sigma), intent(inout)     :: self !this inside has conf, atm, od, rad, isrf
integer(c_int),   intent(in)    :: channels(:)  !List of channels to use
! TODO: consider whether passing the Configuration object to this function
! is necessary. If only a small number of parameters are used,
! you could pass them in directly instead. In that case you can modify the
! interface appropriately.
integer :: nvars_in ! this has the default variables varin_default and the one in the YAML file
integer(kind=I32)                 :: h
type(fckit_mpi_comm), intent(in) :: comm !AGGIUNTO per selezionare rank
type(fckit_configuration), intent(in) :: f_confOper !this should have the config of the operator
type(fckit_configuration) :: f_confOpts !this is a subset of f_confOper
!call f_confOper%get_or_die("obs options",f_confOpts)
nvars_in = size(varin_default) !qua si possono aggiungere il numero di variabili da yaml
self%comm = comm 
!////////////////////////////////////////////////////////////////////////////////////////////////////////////
!/////////////////////////////////////////PROVA INNESTO SIGMA/////////////////////////////////////////
!////////////////////////////////////////////////////////////////////////////////////////////////////////////
if (self%comm%rank() == 0) then  
  print * , "INIZIO TEST SIGMA!"
  open(unit=99, file='check_rank/debug_sigmasetup.txt', status='replace')
  write(99,*) "********************inizio setup******"
  flush(99)
  close(99)
  self%conf%nconfig_file=1
  self%conf%config_file(1)=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/conf/clear.conf")
  self%conf%od_dbase=("lblrtm")
  self%conf%od_dbase_dir=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/auxiliary/lblrtm/")
  call print_configuration(self%conf)
  call sigma_read_configuration_files(self%conf%config_file,self%conf%nconfig_file,self%conf,self%ios)!in configuration.f90

  !//////////////////CONFIGURAZIONE MANUALE DI CONF//////////////////////////////////////////////
  !---- Scalar strings ----
  self%conf%od_dbase          = 'lblrtm'
  !!self%conf%atmosphere_file   = 'prof_20210720T120000_1'
  self%conf%atmosphere_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/prof_20210720T120000_1")
  !!self%conf%emissivity_file   = 'e_CLAIM7'
  self%conf%emissivity_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/e_CLAIM7")
  self%conf%isrf_file         = 'iasi-ng-isrf.dat'

  !---- Scalar reals ----
  self%conf%sigma0            = 5.0_R64
  self%conf%sigma1            = 2760.0_R64
  self%conf%dsigma_low        = 0.360_PREC
  self%conf%obs_pres          = 0.507159E-01_PREC
  self%conf%bot_pres          = 0.101297E+04_PREC
  self%conf%wind_speed        = 0.0_PREC
  self%conf%cloud_fraction    = 0.0_PREC

  !---- Arrays ----
  self%conf%view_angles(1)    = 0.0_PREC
  self%conf%view_angles(2)    = 0.0_PREC
  self%conf%solar_angles(1)   = 180.0_PREC
  self%conf%solar_angles(2)   = 0.0_PREC

  !---- Integers ----
  self%conf%altitude_profile  = 6

  ! Reflection type: 'S' → 0 (Specular)
  self%conf%reflection_type   = 0

  !---- Logical flags ----
  self%conf%wind_sunglint     = .true.
  self%conf%custom_emissivity = .true.
  self%conf%custom_isrf       = .false.
  self%conf%flag_ref          = .true.

  ! Output radiance: "YY" → lr_rad = .true., hr_rad = .true.
  self%conf%lr_rad            = .true.
  self%conf%hr_rad            = .true.
  self%conf%lr_jacs           = .true.
  ! Jacobians: comp_jacobians = "TTTTTTTTTTTNNNNN"
  self%conf%comp_jacs = (/ .true., .true., .true., .true., .true., .true., .true., .true., .true., .true., .true., &
                    .false., .false., .false., .false., .false. /)

  ! cntnm_jacobians = "TNN"
  self%conf%cntnm_jacs = (/ .true., .false., .false. /)

  ! clouds_jacobians = "TT"
  self%conf%clouds_jacs = (/ .true., .true. /)

  ! rte_output = "NNNNN" → all false
  self%conf%rte_output = .false.

  !---- Derived logicals (optional but recommended) ----
  self%conf%clear    = (self%conf%cloud_fraction == 0.0_PREC)
  self%conf%cloudy   = (self%conf%cloud_fraction > 0.0_PREC .and. self%conf%cloud_fraction < 1.0_PREC)
  self%conf%overcast = (self%conf%cloud_fraction == 1.0_PREC)
  self%conf%day      = (self%conf%solar_angles(1) < 90.0_PREC)
  self%conf%night    = .not. self%conf%day
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************CONF MANUALE**************************************"
  write(*,*) "********************************+**************************************"
  write(*,*)
  call print_configuration(self%conf)

  self%conf%isrf_file=("")
  self%conf%atmosphere_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/prof_20210720T120000_1")
  self%conf%emissivity_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/e_CLAIM7")
  
  if (self%conf%custom_emissivity) then
    call sigma_read_emissivity(self%conf%emissivity_file,self%conf,self%od,self%ios)!sigma_read_inputfiles.f90
  end if
  write(*,*)
  write(*,*) "PRINT od EMPTY "
  write(*,*)
  call print_od(self%od) !here we have not allocated the od internal arrays
  call sigma_set_isrf(self%conf,self%isrf,self%od,self%ios)
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************PRINT ATM NO MODIFIED********************************"
  write(*,*) "*****************************************************************************"
  write(*,*)
  call print_atmosphere(self%atm)
  call sigma_set_pressure_layers(self%conf,self%atm,self%ios)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************DOPO SET PRESSUR LEVELS********************************"
  write(*,*) "*****************************************************************************"
  write(*,*)
  call print_atmosphere(self%atm)
  call sigma_read_atmospheric_profile(self%conf%atmosphere_file,self%atm,self%ios)!sigma_read_inputfiles.f90
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************LETTO IL PROFILO ATM DAL FILE********************************"
  write(*,*) "*****************************************************************************"
  write(*,*)
  print *, self%conf%atmosphere_file
  call print_atmosphere(self%atm)
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************IMPOSTO A 0 DA WMOL(:,4) WMOL(:,30)********************************"
  write(*,*) "*****************************************************************************"
  write(*,*)
  do h=4,30
    self%atm%wmol(:,h)=0.0_PREC
  end do
  !MODIFICA MANUALE DI ATM
  self%atm%cos_s = 0.0_PREC
  self%atm%cos_r = 0.0_PREC
  self%atm%cos_dazm = 0.0_PREC
  self%atm%sin_v = 0.0_PREC
  self%atm%sin_r = 0.0_PREC
  self%atm%rcos_vr = 0.0_PREC
  self%atm%WK = 0.0_PREC
  write(*,*) "*********************************************************************************"
  write(*,*) "********************MODIFICA MANUALE DEGLI ANGOLI********************************"
  write(*,*) "*****************************************************************************"
  write(*,*)
  call print_atmosphere(self%atm)
  write(*,*)
  write(*,*) "PRINT od AFTER PROCESS CONFIG "
  write(*,*)
  !!call print_od(self%od) ! here still not allocated internal arrays od od
  !!call deallocate_od(self%od) !sigma_aux_subs.f90
  !!call deallocate_radiances(self%rad)
  !!call sigma(self%conf,self%atm,self%rad,self%od,self%reset,self%ios)
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************PRINT MEMBRI RAD**************************************"
  write(*,*) "*****************************************************************************"
  !!call print_radiances(self%rad)
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************PRINT AROUND MAX RAD**************************************"
  write(*,*) "*****************************************************************************"
  !!call find_around_max_array(self%rad%R_hr)
  !!call write_R_hr_to_file(self%rad,'output_sigma/R_hr_test.txt')

  !!call apply_isrf(self%conf,self%atm,self%isrf,self%od,self%rad)
  write(*,*)
  write(*,*) "*********************************************************************************"
  write(*,*) "********************PRINT MEMBRI RAD DOPO ISRF NEL TEST**************************************"
  write(*,*) "*****************************************************************************"
  !!call print_radiances(self%rad)
  !!call write_wn_R_lr_to_file(self%rad,'output_sigma/wn_R_lr_test.txt')
end if
call self%comm%barrier()
!call write_R_lr_to_file(self%rad,'output_sigma/R_lr_test.txt')
!////////////////////////////////////////////////////////////////////////////////////////////////////////////
!////////////////////////////////////////////////////////////////////////////////////////////////////////////
!////////////////////////////////////////////////////////////////////////////////////////////////////////////
allocate(self%varin(nvars_in))
self%varin(1:size(varin_default)) = varin_default
!these print the associate string to the self%varin objects
print *, "PRINTO VARIN"
print *, self%varin(1)
print *, "next"
print *, self%varin(2)
print *, "next"
print *, self%varin(3)
print *, "next"
print *, self%varin(4)
print *, "next"
! TODO: add input variables (requested from the model)
call self%geovars%push_back(self%varin) !le geovars sono le variabili che da OOPS vengono fornite poi in Geovals
!questa operazione di pushback in ufo_crtmradiance_mod viene fatta nel file .interface.
print *, "ultimo print dentro il rank 0"
print *, "appena fuori rank 0"

! save channels
allocate(self%channels(size(channels)))
self%channels(:) = channels(:)
print *, "Prova array canali di size da ufo_sigma_mod ",size(self%channels), self%channels(1), self%channels(2), self%channels(size(self%channels)-1)

end subroutine ufo_sigma_setup

! ------------------------------------------------------------------------------
! TODO: add cleanup of your observation operator (optional)
subroutine destructor(self)
implicit none
type(ufo_sigma), intent(inout) :: self

end subroutine destructor

! ------------------------------------------------------------------------------
! TODO: put code for your nonlinear observation operator in this routine
! Code in this routine is for sigma only, please remove and replace
subroutine ufo_sigma_simobs(self, geovals, obss, nvars, nlocs, hofx)
use kinds
use ufo_geovals_mod, only: ufo_geovals, ufo_geoval, ufo_geovals_get_var
use iso_c_binding
use obsspace_mod
implicit none
class(ufo_sigma), intent(inout)    :: self
integer, intent(in)               :: nvars, nlocs !nvars è il numero di canali, non considerati singolarmente,
!ma solo il range, presenti nello yaml nella sezione obs space
!GEOVALS HAS ONLY THE varin VARIABLES CHOOSEN BEFORE NOT ALL THE ONES OF THE GEOVAL.NC FILE
type(ufo_geovals),  intent(in)    :: geovals
real(c_double),     intent(inout) :: hofx(nvars,nlocs)
!!real(c_double),     intent(inout) :: hofx(5001,nlocs)
type(c_ptr), value, intent(in)    :: obss
integer :: nlocs_global
integer :: ierr

! Local variables
character(*), parameter :: PROGRAM_NAME = 'ufo_sigma_simobs'
type(ufo_geoval), pointer :: temp
integer(kind=I32)                 :: nlayers_grid, nlayers_model, ind, f, tb_index
real(kind=R64)                                  :: p,T
integer :: n_Profiles_from_geoval, v
integer :: r, n_temp, n_atm, i !aggiunte per reverse copy
!type(ufo_geoval), pointer :: geoval
!real(kind_real), dimension(:), allocatable :: obss_metadata
type(ufo_geoval), pointer :: temp_var_ts
type(ufo_geoval), pointer :: temp_var_prs
type(ufo_geoval), pointer :: temp_var_sfc_tskin
type(ufo_geoval), pointer :: temp_var_mixr
type(ufo_geoval), pointer :: temp_var_q
type(ufo_geoval), pointer :: temp_var_oz
type(ufo_geoval), pointer :: temp_var_co2

!FOR THE LAYERS INTERPOLATION
real(kind=PREC), allocatable   :: temp_from_model(:), press_from_model(:), ln_press_from_model(:)
real(kind=PREC), allocatable   :: hummixrat_from_model(:), hummixrat_interp_ongrid(:)
real(kind=PREC), allocatable   :: spchum_from_model(:), spchum_interp_ongrid(:)
real(kind=PREC), allocatable   :: oz_from_model(:), oz_interp_ongrid(:)
real(kind=PREC), allocatable   :: co2_from_model(:), co2_interp_ongrid(:)
real(kind=PREC), allocatable   :: temp_interp_ongrid(:), ln_press_grid(:)
real(kind=PREC), allocatable   :: Tb(:)
real(kind=PREC) ::  players_grid(NLAYERMAX)
character(len=200) :: filename

integer :: rank, g, k, MPI_INTEGER, MPI_SUM
integer :: nlocs_local
! check if some variable is in geovals and get it (var_tv is defined in ufo_vars_mod)
!nelle geovals ho->var_ts, var_prs, var_prsi,var_sfc_soilt
!call ufo_geovals_get_var(geovals, var_tv, geoval)

!========================
! Local
!========================
rank = self%comm%rank()
hofx(:,:) = 0.0
v=rank
!!call ufo_geovals_get_var(geovals, var_ts, temp)
!allocate(obss_metadata(nlocs))
!call obsspace_get_db(obss, "MetaData", "some_metadata", obss_metadata)
!!if (self%comm%rank() == 0) then
!===========================================================
! 1. SETUP + I/O → SOLO RANK 0
!===========================================================

write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************TEST FUNZIONI DI SIGMA**************************************"
write(*,*) "*********************************************************************************"
write(*,*)
flush(6)
write(*,*) "rank", self%comm%rank(), "prima di nconfig_file"
flush(6)
self%conf%nconfig_file=1
write(*,*) "rank", self%comm%rank(), "dopo nconfig_file"
flush(6)
self%conf%config_file(1)=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/conf/clear.conf")
write(*,*) "rank", self%comm%rank(), "dopo config_file"
flush(6)
self%conf%od_dbase=("lblrtm")
write(*,*) "rank", self%comm%rank(), "dopo od_dbase"
flush(6)
self%conf%od_dbase_dir=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/auxiliary/lblrtm/")
write(*,*) "rank", self%comm%rank(), "dopo od_dbase_dir"
flush(6)
!//////////////////SCRIVO FILES DI LOG PER OGNI RANK////////////////////////////////////////
write(filename,'(A,I0,A)') 'check_rank/debug_rank_', rank, '.txt'
open(unit=99, file=filename, status='replace')
write(99,*) "********************inizio rank 0******"
flush(99)
!!call print_configuration(self%conf)
write(99,*) "********************dopo print_configuration******"
flush(99)

if (rank == 0) then
  call sigma_read_configuration_files(self%conf%config_file,self%conf%nconfig_file,self%conf,self%ios)!in configuration.f90
  write(99,*) "********************dopo sigma_read_configuration******"
  flush(99)
  !//////////////////CONFIGURAZIONE MANUALE DI CONF//////////////////////////////////////////
  !---- Scalar strings ----
  self%conf%od_dbase          = 'lblrtm'
  self%conf%atmosphere_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/prof_20210720T120000_1")
  self%conf%emissivity_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/e_CLAIM7")
  self%conf%isrf_file         = 'iasi-ng-isrf.dat'
  self%conf%isrf_file=("")

  !---- Scalar reals ----
  self%conf%sigma0            = 100.00000_R64
  self%conf%sigma1            = 1600.00000_R64
  self%conf%dsigma_low        = 0.30000_PREC
  self%conf%obs_pres          = 0.507159E-01_PREC
  self%conf%bot_pres          = 0.101297E+04_PREC
  self%conf%wind_speed        = 0.0_PREC
  self%conf%cloud_fraction    = 0.0_PREC

  !---- Arrays ----
  self%conf%view_angles(1)    = 0.0_PREC
  self%conf%view_angles(2)    = 0.0_PREC
  self%conf%solar_angles(1)   = 180.0_PREC
  self%conf%solar_angles(2)   = 0.0_PREC

  !---- Integers ----
  self%conf%altitude_profile  = 6

  ! Reflection type: 'S' → 0 (Specular)
  self%conf%reflection_type   = 0

  !---- Logical flags ----
  self%conf%wind_sunglint     = .true.
  self%conf%custom_emissivity = .true.
  self%conf%custom_isrf       = .false.
  self%conf%flag_ref          = .true.

  ! Output radiance: "YY" → lr_rad = .true., hr_rad = .true.
  self%conf%lr_rad            = .true.
  self%conf%hr_rad            = .true.
  self%conf%lr_jacs           = .true. 
  ! Jacobians: comp_jacobians = "TTTTTTTTTTTNNNNN"
  self%conf%comp_jacs = (/ .true., .true., .true., .true., .true., .true., .true., .true., .true., .true., .true., &
                    .false., .false., .false., .false., .false. /)

  ! cntnm_jacobians = "TNN"
  self%conf%cntnm_jacs = (/ .true., .false., .false. /)

  ! clouds_jacobians = "TT"
  self%conf%clouds_jacs = (/ .true., .true. /)

  ! rte_output = "NNNNN" → all false
  self%conf%rte_output = .false.

  !---- Derived logicals (optional but recommended) ----
  self%conf%clear    = (self%conf%cloud_fraction == 0.0_PREC)
  self%conf%cloudy   = (self%conf%cloud_fraction > 0.0_PREC .and. self%conf%cloud_fraction < 1.0_PREC)
  self%conf%overcast = (self%conf%cloud_fraction == 1.0_PREC)
  self%conf%day      = (self%conf%solar_angles(1) < 90.0_PREC)
  self%conf%night    = .not. self%conf%day
end if
call broadcast_conf(self%conf,self%comm)

write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************CONF MANUALE in simobs**************************************"
write(*,*) "**********************************************************************"
write(*,*)

do r = 0, self%comm%size()-1
   if (rank == r) then

      write(*,*)
      write(*,*) "==============================================="
      write(*,*) "RANK =", rank
      write(*,*) "PRINT CONFIGURATION"
      write(*,*) "==============================================="

      call print_configuration(self%conf)

   end if

   call self%comm%barrier()
end do

!!call print_configuration(self%conf)
write(99,*) "********************appena dopo conf manuale******"
flush(99)
close(99)

open(unit=99, file=filename, status='old', position='append')
if (self%conf%custom_emissivity) then
  call sigma_read_emissivity(self%conf%emissivity_file,self%conf,self%od,self%ios)!sigma_read_inputfiles.f90
end if

call sigma_set_isrf(self%conf,self%isrf,self%od,self%ios)
write(99,*) "********************dopo sigma_set_isrf******"
flush(99)
close(99)
!===========================================================
! 2. BROADCAST CONFIGURAZIONE A TUTTI
!===========================================================
!!call self%comm%broadcast(self%conf, 0)  
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************DOPO ISRF SET********************************"
write(*,*) "*****************************************************************************"
write(*,*)
!call print_configuration(conf)
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT ATM NO MODIFIED SIMOBS********************************"
write(*,*) "*****************************************************************************"
write(*,*)
call print_atmosphere(self%atm)
call sigma_set_pressure_layers(self%conf,self%atm,self%ios)
write(*,*) "*********************************************************************************"
write(*,*) "********************DOPO SET PRESSUR LEVELS********************************"
write(*,*) "*****************************************************************************"
write(*,*)
call print_atmosphere(self%atm)
!===========================================================
! 4. INIZIALIZZAZIONE hofx (SU TUTTI I RANK)
!===========================================================
if (rank == 0) then
  call sigma_read_atmospheric_profile(self%conf%atmosphere_file,self%atm,self%ios)!sigma_read_inputfiles.f90
end if
call broadcast_atm(self%atm,self%comm)
write(*,*) "*********************************************************************************"
write(*,*) "********************MODIFICA MANUALE DEGLI ANGOLI********************************"
write(*,*) "*****************************************************************************"
write(*,*)
!MODIFICA MANUALE DI ATM
self%atm%cos_s = 0.0_PREC
self%atm%cos_r = 0.0_PREC
self%atm%cos_dazm = 0.0_PREC
self%atm%sin_v = 0.0_PREC
self%atm%sin_r = 0.0_PREC
self%atm%rcos_vr = 0.0_PREC
self%atm%WK = 0.0_PREC
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINTO ARRAY TEMP E PRESS DI ATM DI OGNI RANK************"
write(*,*) "*****************************************************************************"
write(*,*)
!creo il file di check col rank 0
if (rank == 0) then
   open(unit=99, file='check_rank/debug_atm.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_atm.txt', &
           status='unknown', position='append', action='write')

      write(99,*)
      write(99,*) "=================================="
      write(99,*) "RANK =", rank
      write(99,*) "=================================="

       ! ----------------------------------------
      ! Check rapidi
      ! ----------------------------------------

      write(99,*) "CHECKSUMS"

      write(99,*) "checksum temp  = ", sum(self%atm%temp)
      write(99,*) "checksum press = ", sum(self%atm%press)
      write(99,*) "checksum wmol  = ", sum(self%atm%wmol)

      write(99,*) "max temp       = ", maxval(self%atm%temp)
      write(99,*) "min temp       = ", minval(self%atm%temp)

      write(99,*) "max press      = ", maxval(self%atm%press)
      write(99,*) "min press      = ", minval(self%atm%press)

      write(99,*) "max wmol       = ", maxval(self%atm%wmol)
      write(99,*) "min wmol       = ", minval(self%atm%wmol)

      write(99,*)

      call print_atmosphere_iu(self%atm, 99)

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do


write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************LETTO IL PROFILO ATM DAL FILE in simobs********************************"
write(*,*) "*****************************************************************************"
write(*,*)
print *, "QUI SETTO PLAYERS_GRID=PRESS DEL FILE INPUT"
players_grid=self%atm%press
allocate(ln_press_grid(size(players_grid)))
ln_press_grid=log(players_grid)
print *, players_grid

call print_atmosphere(self%atm)

write(*,*) "*********************************************************************************"
write(*,*) "********************SOSTITUZIONE PROFILO TEMPERATURA E PRESSIONE CON GEOVALS VALUES********************************"
write(*,*) "*****************************************************************************"
write(*,*)
call ufo_geovals_get_var(geovals, var_ts, temp_var_ts)
call ufo_geovals_get_var(geovals, var_prs, temp_var_prs)
call ufo_geovals_get_var(geovals, var_sfc_ltmp, temp_var_sfc_tskin)!dovrei usare skin_temperature
call ufo_geovals_get_var(geovals, var_mixr, temp_var_mixr)
!call ufo_geovals_get_var(geovals, var_q, temp_var_q)
call ufo_geovals_get_var(geovals, var_oz, temp_var_oz)
call ufo_geovals_get_var(geovals, var_co2, temp_var_co2)
print *, "Tutto ok..."
!=======PRINT DELLE GEOVALS========================================
!==============================air_temperature=====================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_geovals_air_temperature.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_geovals_air_temperature.txt', &
           status='unknown', position='append', action='write')

      write(99,*) "============================="
      write(99,*) "TEMP_VAR_TS: air_temperature"
      write(99,*) "============================="

      if (associated(temp_var_ts)) then

        write(99,*) "nval      = ", temp_var_ts%nval
        write(99,*) "nprofiles = ", temp_var_ts%nprofiles

        if (allocated(temp_var_ts%vals)) then
            write(99,*) "shape(vals) = ", shape(temp_var_ts%vals)
            write(99,*) "checksum    = ", sum(temp_var_ts%vals)
            write(99,*) "min         = ", minval(temp_var_ts%vals)
            write(99,*) "max         = ", maxval(temp_var_ts%vals)

            write(99,*) "sample:"
            write(99,*) temp_var_ts%vals(:,1)!nel modello vanno da alta a bassa quota

        else
            write(99,*) "vals not allocated"
        endif

      else
        write(99,*) "pointer not associated"
      endif

      

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!========================air_pressure==============================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_geovals_air_pressure.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_geovals_air_pressure.txt', &
           status='unknown', position='append', action='write')

      write(99,*) "============================="
      write(99,*) "TEMP_VAR_PRS: air_pressure"
      write(99,*) "============================="

      if (associated(temp_var_prs)) then

        write(99,*) "nval      = ", temp_var_prs%nval
        write(99,*) "nprofiles = ", temp_var_prs%nprofiles

        if (allocated(temp_var_prs%vals)) then
            write(99,*) "shape(vals) = ", shape(temp_var_prs%vals)
            write(99,*) "checksum    = ", sum(temp_var_prs%vals)
            write(99,*) "min         = ", minval(temp_var_prs%vals)
            write(99,*) "max         = ", maxval(temp_var_prs%vals)

            write(99,*) "sample:"
            write(99,*) temp_var_prs%vals(:,1)!nel modello vanno da alta a bassa quota
        else
            write(99,*) "vals not allocated"
        endif

      else
        write(99,*) "pointer not associated"
      endif

      

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!========================skin temperature==============================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_geovals_skin_temperature.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_geovals_skin_temperature.txt', &
           status='unknown', position='append', action='write')

      write(99,*) "============================="
      write(99,*) "TEMP_VAR_SFC_TSKIN: skin_temperature"
      write(99,*) "============================="

      if (associated(temp_var_prs)) then

        write(99,*) "nval      = ", temp_var_sfc_tskin%nval
        write(99,*) "nprofiles = ", temp_var_sfc_tskin%nprofiles

        if (allocated(temp_var_sfc_tskin%vals)) then
            write(99,*) "shape(vals) = ", shape(temp_var_sfc_tskin%vals)
            write(99,*) "checksum    = ", sum(temp_var_sfc_tskin%vals)
            write(99,*) "min         = ", minval(temp_var_sfc_tskin%vals)
            write(99,*) "max         = ", maxval(temp_var_sfc_tskin%vals)

            write(99,*) "sample:"
            write(99,*) temp_var_sfc_tskin%vals(:,1)
        else
            write(99,*) "vals not allocated"
        endif

      else
        write(99,*) "pointer not associated"
      endif

      

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!========================humidity_mixing_ratio==============================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_geovals_humidity_mixing_ratio.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_geovals_humidity_mixing_ratio.txt', &
           status='unknown', position='append', action='write')

      write(99,*) "============================="
      write(99,*) "TEMP_VAR_MIXR: humidity_mixing_ratio"
      write(99,*) "============================="

      if (associated(temp_var_mixr)) then

        write(99,*) "nval      = ", temp_var_mixr%nval
        write(99,*) "nprofiles = ", temp_var_mixr%nprofiles

        if (allocated(temp_var_mixr%vals)) then
            write(99,*) "shape(vals) = ", shape(temp_var_mixr%vals)
            write(99,*) "checksum    = ", sum(temp_var_mixr%vals)
            write(99,*) "min         = ", minval(temp_var_mixr%vals)
            write(99,*) "max         = ", maxval(temp_var_mixr%vals)

            write(99,*) "sample:"
            write(99,*) temp_var_mixr%vals(:,1)
        else
            write(99,*) "vals not allocated"
        endif

      else
        write(99,*) "pointer not associated"
      endif

      

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!========================ozone==============================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_geovals_ozone.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_geovals_ozone.txt', &
           status='unknown', position='append', action='write')

      write(99,*) "============================="
      write(99,*) "TEMP_VAR_OZ: mole_fraction_of_ozone_in_air"
      write(99,*) "============================="

      if (associated(temp_var_oz)) then

        write(99,*) "nval      = ", temp_var_oz%nval
        write(99,*) "nprofiles = ", temp_var_oz%nprofiles

        if (allocated(temp_var_oz%vals)) then
            write(99,*) "shape(vals) = ", shape(temp_var_oz%vals)
            write(99,*) "checksum    = ", sum(temp_var_oz%vals)
            write(99,*) "min         = ", minval(temp_var_oz%vals)
            write(99,*) "max         = ", maxval(temp_var_oz%vals)

            write(99,*) "sample:"
            write(99,*) temp_var_oz%vals(:,1)
        else
            write(99,*) "vals not allocated"
        endif

      else
        write(99,*) "pointer not associated"
      endif

      

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!========================co2==============================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_geovals_co2.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_geovals_co2.txt', &
           status='unknown', position='append', action='write')

      write(99,*) "============================="
      write(99,*) "TEMP_VAR_CO2: mole_fraction_of_carbon_dioxide_in_air"
      write(99,*) "============================="

      if (associated(temp_var_co2)) then

        write(99,*) "nval      = ", temp_var_co2%nval
        write(99,*) "nprofiles = ", temp_var_co2%nprofiles

        if (allocated(temp_var_co2%vals)) then
            write(99,*) "shape(vals) = ", shape(temp_var_co2%vals)
            write(99,*) "checksum    = ", sum(temp_var_co2%vals)
            write(99,*) "min         = ", minval(temp_var_co2%vals)
            write(99,*) "max         = ", maxval(temp_var_co2%vals)

            write(99,*) "sample:"
            write(99,*) temp_var_co2%vals(:,1)
        else
            write(99,*) "vals not allocated"
        endif

      else
        write(99,*) "pointer not associated"
      endif

      

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!=================FINE PRINT GEOVALS==============================
!QUI PREPARO GLI ARRAY CON lnP,T DEL MODELLO CON 64 ELEMENTI IN ORDINE DECRESCENTE E lnP DELLA GRIGLIA CON 60 ELEMENTI
!********TEMPERATURE*****************
!!do v=1,n_Profiles_from_geoval !ciclo sui profili delle geovals
!!!!!!!!!!QUI BISOGNA GESTIRE I PROFILI CHE OGNI RANK RICEVE!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!PER ORA OGNI RANK HA 1 PROFILO!!!!!!!!!!!!!!!!!
n_temp = size(temp_var_ts%vals,1) !64 layers del modello, 55 nel test
n_atm  = size(self%atm%temp)-1 !61-1 il primo è indicizzato a 0 con valore non definito, 60 al netto
print *, "Il numero di layers per la temperatura dell'aria nel modello è: ",n_temp
print *, "Il numero di layers in SIGMA per la temperatura è: ",n_atm
allocate(temp_from_model(n_temp))
allocate(temp_interp_ongrid(n_atm))
temp_from_model = 0.0_PREC
do f = 1,n_temp
  temp_from_model(f) = temp_var_ts%vals(n_temp - f + 1, 1)!il secondo argomento è per il numero del profilo
end do
print *, self%atm%temp(:)!il primo è unassigned value
print *, "*****"
print *, "Il modello ha ",size(temp_from_model)," layers di temperatura"
print *, "I layers del modello: ",temp_from_model
print *, "*****"
print *, temp_from_model(1)
print *, temp_from_model(2)

print *, temp_from_model(n_temp-1)
print *, temp_from_model(n_temp)
!****PRESSURE***********************************
n_temp = size(temp_var_prs%vals,1)
n_atm  = size(self%atm%press) !60 qui non abbiamo l'elemento 0
print *, "Il numero di layers per la pressione dell'aria nel modello è: ",n_temp
print *, "Il numero di layers in SIGMA per la pressione è: ",n_atm  
nlayers_grid = n_atm
nlayers_model = n_temp
allocate(press_from_model(n_temp))
press_from_model = 0.0_PREC
do f = 1,n_temp!devo passare a hPa
  press_from_model(f) = temp_var_prs%vals(n_temp - f + 1, 1)*0.01
end do

print *, self%atm%press(:)!il primo è unassigned value
print *, "*****"
print *, "Il modello ha ",size(press_from_model)," layers di pressione"
print *, "I layers del modello: ",press_from_model
print *, "*****"
print *, press_from_model(1)
print *, press_from_model(2)
!!print *, press_from_model(3)
!!print *, press_from_model(4)
!!print *, "dal 61 incluso in poi"
!!print *, press_from_model(61)
!!print *, press_from_model(62)
print *, press_from_model(n_temp-1)
print *, press_from_model(n_temp)
ln_press_from_model=log(press_from_model)
  
!*****SURFACE TEMP********
n_temp = size(temp_var_sfc_tskin%vals,1) !1
n_atm  = 1 !1
print *,"La surface temperature nel modello ha layers: ",n_temp
print *, temp_var_sfc_tskin%vals(:, 1)
print *, self%atm%ts
  !atm_geovals%ts = temp_var_sfc_tskin%vals(1, 1)

!****HUMIDITY MIXING RATIO************
print *, "HUMIDITY MIXING RATIO"
n_temp = size(temp_var_mixr%vals,1)
n_atm  = size(self%atm%wmol(:,1)) !60 qui non abbiamo l'elemento 0
print *, "Il numero di layers per humidity mixing ratio nel modello è: ",n_temp
print *, "Il numero di layers in SIGMA per H2O è: ",n_atm  

allocate(hummixrat_interp_ongrid(n_atm))
allocate(hummixrat_from_model(n_temp))
allocate(spchum_interp_ongrid(n_atm))
allocate(spchum_from_model(n_temp))
nlayers_grid = n_atm
nlayers_model = n_temp
do f = 1,n_temp
  hummixrat_from_model(f) = temp_var_mixr%vals(n_temp - f + 1, 1)
  spchum_from_model(f) = hummixrat_from_model(f)/(1+hummixrat_from_model(f))
end do
print *,"I valori di humidity mixing ratio del modello sono: ", hummixrat_from_model
print *, size(self%atm%wmol(:,1))
print *, self%atm%wmol(:,1)
print *, "*****"
print *,"I valori di specific humidity del modello sono: ", spchum_from_model
print *, "*****"

!****CO2**************************
print *, "CO2"
n_temp = size(temp_var_co2%vals,1)
n_atm  = size(self%atm%wmol(:,2)) !60 qui non abbiamo l'elemento 0
allocate(co2_interp_ongrid(n_atm))
allocate(co2_from_model(n_temp))
nlayers_grid = n_atm
nlayers_model = n_temp
do f = 1,n_temp
  co2_from_model(f) = temp_var_co2%vals(n_temp - f + 1, 1)*0.000001
end do

print *, size(self%atm%wmol(:,2))
print *, self%atm%wmol(:,2)
print *, "*****"
print *, size(co2_from_model)
print *, co2_from_model
print *, "*****"
!****O3************
print *, "O3"
n_temp = size(temp_var_oz%vals,1) 
n_atm  = size(self%atm%wmol(:,3)) !60 qui non abbiamo l'elemento 0
allocate(oz_interp_ongrid(n_atm))
allocate(oz_from_model(n_temp))
nlayers_grid = n_atm
nlayers_model = n_temp
do f = 1,n_temp
  oz_from_model(f) = temp_var_oz%vals(n_temp - f + 1, 1)*0.000001
end do

print *, size(self%atm%wmol(:,3))
print *, self%atm%wmol(:,3)
print *, "*****"
print *, size(oz_from_model)
print *, oz_from_model
print *, "*****"

write(*,*) "*********************************************************************************"
write(*,*) "********************INTERPOLAZIONE P-T********************************"
write(*,*) "*****************************************************************************"
write(*,*)
do f=1,nlayers_grid! from 1 to 60 layers of SIGMA
!the linint_saf subroutine fills *_interp_ongrid, which has 60 values
 call linint_saf(ln_press_from_model,temp_from_model,nlayers_model,ln_press_grid(f),temp_interp_ongrid(f),ind)
 call linint_saf(ln_press_from_model,hummixrat_from_model,nlayers_model,ln_press_grid(f),hummixrat_interp_ongrid(f),ind)
 !call linint_saf(ln_press_from_model,co2_from_model,nlayers_model,ln_press_grid(f),co2_interp_ongrid(f),ind)
 !call linint_saf(ln_press_from_model,oz_from_model,nlayers_model,ln_press_grid(f),oz_interp_ongrid(f),ind)
 !call linint_saf(ln_press_from_model,spchum_from_model,nlayers_model,ln_press_grid(f),spchum_interp_ongrid(f),ind)
enddo

write(filename, '(A,I0,A)') "output_sigma/press_temp_from_model_",v,".txt"
call write_twoarrays_to_file(press_from_model, temp_from_model,nlayers_model,filename)
write(filename, '(A,I0,A)') "output_sigma/press_temp_interp_ongrid_ufo_",v,".txt"
call write_twoarrays_to_file(players_grid, temp_interp_ongrid,nlayers_grid,filename)

!!write(filename, '(A,I0,A)') "output_sigma/press_hummixrat_from_model_",v,".txt"
!!call write_twoarrays_to_file(press_from_model, hummixrat_from_model,nlayers_model,filename)
!!write(filename, '(A,I0,A)') "output_sigma/press_hummixrat_interp_ongrid_ufo_",v,".txt" 
!!call write_twoarrays_to_file(players_grid, hummixrat_interp_ongrid,nlayers_grid,filename)

!!write(filename, '(A,I0,A)') "output_sigma/press_co2_from_model_",v,".txt"  
!!call write_twoarrays_to_file(press_from_model, co2_from_model,nlayers_model,filename)
!!write(filename, '(A,I0,A)') "output_sigma/press_co2_interp_ongrid_ufo_",v,".txt"   
!!call write_twoarrays_to_file(players_grid, co2_interp_ongrid,nlayers_grid,filename)

!!write(filename, '(A,I0,A)') "output_sigma/press_oz_from_model_",v,".txt"  
!!call write_twoarrays_to_file(press_from_model, oz_from_model,nlayers_model,filename)
!!write(filename, '(A,I0,A)') "output_sigma/press_oz_interp_ongrid_ufo_",v,".txt"   
!!call write_twoarrays_to_file(players_grid, oz_interp_ongrid,nlayers_grid,filename)

!!write(filename, '(A,I0,A)') "output_sigma/press_spchum_from_model_",v,".txt"  
!!call write_twoarrays_to_file(press_from_model, spchum_from_model,nlayers_model,filename)
!!write(filename, '(A,I0,A)') "output_sigma/press_spchum_interp_ongrid_ufo_",v,".txt"  
!!call write_twoarrays_to_file(players_grid, spchum_interp_ongrid,nlayers_grid,filename)

write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT ATM CON TEMPERATURA E PRESSIONE DA FILE********************************"
write(*,*) "*****************************************************************************"
write(*,*)
!call print_atmosphere(self%atm)
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************IMPOSTO A 0 DA WMOL(:,4) WMOL(:,30) IN SIMOBS********************************"
write(*,*) "*****************************************************************************"
write(*,*)
!do i=4,30
!   atm_geovals%wmol(:,i)=0.0_PREC
!end do
!call print_atmosphere(atm_geovals)
!call print_od(od)
write(*,*) "********************come siamo messi**************************************"
!!call deallocate_od(self%od) !sigma_aux_subs.f90
write(*,*) "********************qui?**************************************"
!!call deallocate_radiances(self%rad)
write(*,*) "********************still?**************************************"
!!call sigma(self%conf,self%atm,self%rad,self%od,self%reset,self%ios) !here sigma_read_lut allocates the od arrays
write(*,*) "********************bruh**************************************"

!call print_od(od) this would print thousand of values
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT MEMBRI RAD simobs**************************************"
write(*,*) "*****************************************************************************"
!!call print_radiances(self%rad)
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT AROUND MAX RAD simobs**************************************"
write(*,*) "*****************************************************************************"
!!call find_around_max_array(self%rad%R_hr)
    !!call write_R_hr_to_file(self%rad,'output_sigma/R_hr_dafile.txt')
    !call write_R_lr_to_file(rad,'R_lr.txt')
!!call apply_isrf(self%conf,self%atm,self%isrf,self%od,self%rad)
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT MEMBRI RAD DOPO ISRF**************************************"
write(*,*) "*****************************************************************************"
!!call print_radiances(self%rad)
!!call write_R_lr_to_file(self%rad,'output_sigma/R_lr_dafile.txt')
!!call write_wn_R_lr_to_file(self%rad,'output_sigma/wn_R_lr_dafile.txt')
!///////////NOW I MODIFY ATM WITH THE P-T VALUES INTERPOLATED FROM MODEL ON THE GRID LAYERS
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT ATM CON TEMPERATURA E PRESSIONE DA INTERPOLAZIONE SU LAYER DEL FILE********************************"
write(*,*) "*****************************************************************************"
write(*,*)
!qui reinizializzo i valori di atm per darli al sigma secondo il profilo del modello 
print *, "These are 60 values from file "
print *, self%atm%temp
print *, self%atm%press
print *, self%atm%wmol(:,1)
self%atm%temp(1:) = temp_interp_ongrid
self%atm%wmol(:,1) = hummixrat_interp_ongrid
!!self%atm%wmol(:,2) = co2_interp_ongrid
!!self%atm%wmol(:,3) = oz_interp_ongrid
print *, "These are the values interpolated on the layers "
print *, self%atm%temp
print *, self%atm%press
print *, self%atm%wmol(:,1)
!call print_atmosphere(self%atm)

write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINTO ATM CON TEMP,HUMIDITY INTERPOLATE************"
write(*,*) "*****************************************************************************"
write(*,*)
!creo il file di check col rank 0
if (rank == 0) then
   open(unit=99, file='check_rank/debug_atm_after_interp.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_atm_after_interp.txt', &
           status='unknown', position='append', action='write')

      write(99,*)
      write(99,*) "=================================="
      write(99,*) "RANK =", rank
      write(99,*) "=================================="

       ! ----------------------------------------
      ! Check rapidi
      ! ----------------------------------------

      write(99,*) "CHECKSUMS"

      write(99,*) "checksum temp  = ", sum(self%atm%temp)
      write(99,*) "checksum press = ", sum(self%atm%press)
      write(99,*) "checksum wmol  = ", sum(self%atm%wmol)

      write(99,*) "max temp       = ", maxval(self%atm%temp)
      write(99,*) "min temp       = ", minval(self%atm%temp)

      write(99,*) "max press      = ", maxval(self%atm%press)
      write(99,*) "min press      = ", minval(self%atm%press)

      write(99,*) "max wmol       = ", maxval(self%atm%wmol)
      write(99,*) "min wmol       = ", minval(self%atm%wmol)

      write(99,*)

      call print_atmosphere_iu(self%atm, 99)

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do

!!call deallocate_od(self%od) !sigma_aux_subs.f90
!!call deallocate_radiances(self%rad)

!!call sigma(self%conf,self%atm,self%rad,self%od,self%reset,self%ios)

!=========================================================
! DEBUG PRIMA DOPO BROADCAST
!=========================================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_atm_pre_noradandjacob.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_atm_pre_noradandjacob.txt', &
           status='unknown', position='append', action='write')

      write(99,*)
      write(99,*) "=================================="
      write(99,*) "RANK =", rank
      write(99,*) "=================================="

       ! ----------------------------------------
      ! Check rapidi
      ! ----------------------------------------

      write(99,*) "CHECKSUMS"

      write(99,*) "checksum temp  = ", sum(self%atm%temp)
      write(99,*) "checksum press = ", sum(self%atm%press)
      write(99,*) "checksum wmol  = ", sum(self%atm%wmol)

      write(99,*) "max temp       = ", maxval(self%atm%temp)
      write(99,*) "min temp       = ", minval(self%atm%temp)

      write(99,*) "max press      = ", maxval(self%atm%press)
      write(99,*) "min press      = ", minval(self%atm%press)

      write(99,*) "max wmol       = ", maxval(self%atm%wmol)
      write(99,*) "min wmol       = ", minval(self%atm%wmol)

      write(99,*)

      call print_atmosphere_iu(self%atm, 99)

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
call deallocate_od(self%od)
call deallocate_radiances(self%rad)
!qui i valori degli angoli di atm vanno ancora bene
if (rank == 0) then
   print *, "Rank 0 legge LUT"
   call sigma_noradjacob(self%conf,self%atm,self%rad,self%od,self%reset,self%ios) !sigma_frontend.f90
  !lettura od->da trasmettere ai ranks 
  !qui dentro vengono allocate le radianze, quindi va fatto su tutti i ranks
endif
print *, "Rank", rank, "dopo sigma_noradjacob"

!trasmetto a tutti i rank i valori inizializzati poi creo il file di debug
call broadcast_od(self%od,self%comm)
!l'oggetto atm viene modificato da sigma_noradandjacob quindi devo ribroadcastare atm a tutti i ranks
call broadcast_atm(self%atm,self%comm)
!MODIFICA MANUALE DI ATM
self%atm%temp(1:) = temp_interp_ongrid
self%atm%wmol(:,1) = hummixrat_interp_ongrid
self%atm%cos_s = 0.0_PREC
self%atm%cos_r = 0.0_PREC
self%atm%cos_dazm = 0.0_PREC
self%atm%sin_v = 0.0_PREC
self%atm%sin_r = 0.0_PREC
self%atm%rcos_vr = 0.0_PREC
self%atm%WK = 0.0_PREC
!=========================================================
! DEBUG OD DOPO BROADCAST
!=========================================================

if (rank == 0) then

   open(unit=99, file='check_rank/debug_od.txt', &
        status='replace', action='write')

   write(99,*) "******************** OD AFTER BROADCAST ******"

   close(99)

end if

call self%comm%barrier()

do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_od.txt', &
           status='unknown', position='append', action='write')

      write(99,*)
      write(99,*) "=================================="
      write(99,*) "RANK =", rank
      write(99,*) "=================================="

      !------------------------------------
      ! CHECK RAPIDI
      !------------------------------------

      write(99,*) "SCALARS"

      write(99,*) "noi       = ", self%od%noi
      write(99,*) "nof       = ", self%od%nof
      write(99,*) "nwcur     = ", self%od%nwcur
      write(99,*) "nwvcur    = ", self%od%nwvcur
      write(99,*) "nqucur    = ", self%od%nqucur

      if (allocated(self%od%Isol)) then
         write(99,'(A,ES24.16)') &
              "checksum Isol   = ", sum(self%od%Isol)
      end if

      if (allocated(self%od%cq0)) then
         write(99,'(A,ES24.16)') &
              "checksum cq0    = ", sum(self%od%cq0)
      end if

      if (allocated(self%od%cq1)) then
         write(99,'(A,ES24.16)') &
              "checksum cq1    = ", sum(self%od%cq1)
      end if

      if (allocated(self%od%cq2)) then
         write(99,'(A,ES24.16)') &
              "checksum cq2    = ", sum(self%od%cq2)
      end if

      if (allocated(self%od%cq3)) then
         write(99,'(A,ES24.16)') &
              "checksum cq3    = ", sum(self%od%cq3)
      end if

      if (allocated(self%od%Pbetaw)) then
         write(99,'(A,ES24.16)') &
              "checksum Pbetaw = ", sum(self%od%Pbetaw)
      end if

      if (allocated(self%od%Pomegaw)) then
         write(99,'(A,ES24.16)') &
              "checksum Pomegaw = ", sum(self%od%Pomegaw)
      end if

      if (allocated(self%od%Pbw)) then
         write(99,'(A,ES24.16)') &
              "checksum Pbw = ", sum(self%od%Pbw)
      end if

      write(99,*)

      call print_od_iu_secure(self%od,99)

      flush(99)

      close(99)

   end if

   call self%comm%barrier()

end do

!=========================================================

!=========================================================
! DEBUG ATM DOPO BROADCAST
!=========================================================
if (rank == 0) then
   open(unit=99, file='check_rank/debug_atm_after_noradjacob.txt', &
        status='replace', action='write')

   write(99,*) "******************** INIZIO SETUP ******"
   close(99)
end if
call self%comm%barrier()
! Scrittura serializzata
do r = 0, self%comm%size()-1

   if (rank == r) then

      open(unit=99, file='check_rank/debug_atm_after_noradjacob.txt', &
           status='unknown', position='append', action='write')

      write(99,*)
      write(99,*) "=================================="
      write(99,*) "RANK =", rank
      write(99,*) "=================================="

       ! ----------------------------------------
      ! Check rapidi
      ! ----------------------------------------

      write(99,*) "CHECKSUMS"

      write(99,*) "checksum temp  = ", sum(self%atm%temp)
      write(99,*) "checksum press = ", sum(self%atm%press)
      write(99,*) "checksum wmol  = ", sum(self%atm%wmol)

      write(99,*) "max temp       = ", maxval(self%atm%temp)
      write(99,*) "min temp       = ", minval(self%atm%temp)

      write(99,*) "max press      = ", maxval(self%atm%press)
      write(99,*) "min press      = ", minval(self%atm%press)

      write(99,*) "max wmol       = ", maxval(self%atm%wmol)
      write(99,*) "min wmol       = ", minval(self%atm%wmol)

      write(99,*)

      call print_atmosphere_iu(self%atm, 99)

      flush(99)
      close(99)

   end if

   call self%comm%barrier()

end do
!=========================================================

call broadcast_rad(self%rad,self%comm)
print *, "Prima di radandjacob"
call radandjacob(self%conf,self%atm,self%rad,self%od,self%ios)
print *, "Dopo radandjacob"

write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT MEMBRI RAD**************************************"
write(*,*) "*****************************************************************************"
call print_radiances(self%rad)
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT AROUND MAX RAD**************************************"
write(*,*) "*****************************************************************************"
call find_around_max_array(self%rad%R_hr)
write(filename, '(A,I0,A)') 'output_sigma/R_hr_interpongrid_',v,'.txt'
!!call write_R_hr_to_file(self%rad,filename)
!call write_R_lr_to_file(rad,'R_lr.txt')
call apply_isrf(self%conf,self%atm,self%isrf,self%od,self%rad)
write(*,*)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT MEMBRI RAD DOPO ISRF**************************************"
write(*,*) "*****************************************************************************"
call print_radiances(self%rad)
write(filename, '(A,I0,A)') 'output_sigma/R_lr_interpongrid_',v,'.txt'
call write_R_lr_to_file(self%rad,filename)
write(filename, '(A,I0,A)') 'output_sigma/wn_R_lr_interpongrid_',v,'.txt'
!!call write_wn_R_lr_to_file(self%rad,filename)
call from_rad_to_bt(self%rad,Tb)!we write 7655 elements
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT BRIGHTNESS TEMPERATURE DA R_lr*************************"
write(*,*) "**********************************************************************************"
f = self%rad%I2-self%rad%I1+1
print *, "size Tb", size(Tb), "size wnumber", size(self%rad%wave_lr), "", f, self%rad%ntot_lr !ntot_lr is assigned in sigma_aux_subs.F90
print *, Tb(1) !this is Tb(14)
print *, "************"
print *, Tb(f)
write(filename, '(A,I0,A)') "output_sigma/wn_Tb_",v,".txt"
!!call write_twoarrays_to_file(self%rad%wave_lr, Tb,f,filename)
write(*,*) "*********************************************************************************"
write(*,*) "********************PRINT AROUND MAX RAD**************************************"
write(*,*) "*****************************************************************************"
call find_around_max_array(self%rad%R_lr)
print *, nvars
print *, nlocs
print *, SIZE(hofx,1)
print *, SIZE(hofx,2)
!hofx(:,1) = 0.0
!hofx(:,2) = 0.0
!print *, hofx(:)
!print *, "seconda riga"
!print *, hofx(:,2)
write(*,*) "*********************************************************************************"
write(*,*) "********************HERE I PUT THE VALUES OF SIGMA BRIGHTNESS TEMPERATURES******"
write(*,*) "*****************************************************************************"
tb_index = 0
print *, Tb(1), Tb(5000),Tb(5001), Tb(5002), size(Tb) !in teoria Tb ha 5002 elementi ma hofx ha 5001 elementi nella riga
!do f=1,10
print *,"n_Profiles_from_geoval=geovals%nlocs vale:",n_Profiles_from_geoval, "invece"
print *,"nlocs vale:",nlocs
!!do v=1,n_Profiles_from_geoval   !vale nlocs
  !if (rank <=9) then
  !!write(*,*) "Rank per filling hofx:", rank
hofx(:,1) = Tb(1:SIZE(hofx,1))
  !end if  
!!hofx(:,v) = Tb(2)
!!end do
if (allocated(Tb)) deallocate(Tb)
write(*,*) "finito"

!print *, hofx(:,f)
!end do
!!if (allocated(temp_from_model)) deallocate(temp_from_model)
!!f (allocated(temp_interp_ongrid)) deallocate(temp_interp_ongrid)

!!if (allocated(press_from_model)) deallocate(press_from_model)

!!if (allocated(hummixrat_interp_ongrid)) deallocate(hummixrat_interp_ongrid)
!!if (allocated(hummixrat_from_model)) deallocate(hummixrat_from_model)

!!if (allocated(spchum_interp_ongrid)) deallocate(spchum_interp_ongrid)
!!if (allocated(spchum_from_model)) deallocate(spchum_from_model)

!!if (allocated(co2_interp_ongrid)) deallocate(co2_interp_ongrid)
!!if (allocated(co2_from_model)) deallocate(co2_from_model)

!!if (allocated(oz_interp_ongrid)) deallocate(oz_interp_ongrid)
!!if (allocated(oz_from_model)) deallocate(oz_from_model)
!!end do   
!!end if
!!call self%comm%barrier()  
!!end if  
end subroutine ufo_sigma_simobs


! ------------------------------------------------------------------------------

end module ufo_sigma_mod
