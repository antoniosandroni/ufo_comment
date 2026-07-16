! (C) Copyright 2017-2018 UCAR
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

!> Fortran module for sigma tl/ad observation operator

module ufo_sigma_tlad_mod
 
 use,intrinsic :: iso_c_binding
 use oops_variables_mod
 use obs_variables_mod
 use ufo_vars_mod
 use kinds

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

 !> Fortran derived type for the tl/ad observation operator
 ! TODO: add to the below type what you need for your tl/ad observation operator
 !       this type can hold information on trajectory, for sigma
 type, public :: ufo_sigma_tlad
 private
  type(obs_variables), public :: obsvars
  type(oops_variables), public :: geovars !geovars qui va popolato con le variabili del modello che ci interessano
  !per il calcolo degli jacobiani, quindi temperatura e gas ozono e co2...
  character(len=MAXVARLEN), public, allocatable :: varin(:) !AGGIUNTA
  integer, allocatable                          :: channels(:)
  type(configuration_params) :: conf !qua ci vanno i dati del file xml, vecchio sigma_iasi.input
  type(atmosphere)           :: atm
  type(od_dbase)             :: od
  type(radiances)            :: rad
  type(isrf_convolution)     :: isrf
  type(fckit_mpi_comm)       :: comm !aggiunto noi
  integer                    :: n_Profiles          ! <-- AGGIUNTO
  real(kind=PREC), allocatable :: JT_lr_traj(:,:,:) !<-- AGGIUNTO (canali, livelli, profilo)
  real(kind=PREC), allocatable :: JH2O_lr_traj(:,:,:)! <-- AGGIUNTO (canali, livelli, profilo)
  real(kind=PREC), allocatable :: JCO2_lr_traj(:,:,:)! <-- AGGIUNTO (canali, livelli, profilo)
  real(kind=PREC), allocatable :: JO3_lr_traj(:,:,:)! <-- AGGIUNTO (canali, livelli, profilo)
  real(kind=PREC), allocatable :: ln_press_from_model_traj(:)   ! <-- necessario per portare geoval
  real(kind=PREC), allocatable :: ln_press_grid_traj(:)         
  integer                       :: nlayers_sigma_traj           



  logical                    :: ltraj = .false.
  integer(kind=I32) :: reset = FULL_RESET !con questo flag vengono lette le LUT
  integer(kind=I32) :: ios   = IERR_SUCCESS


 contains
  procedure :: setup  => ufo_sigma_tlad_setup
  procedure :: settraj => ufo_sigma_tlad_settraj
  procedure :: simobs_tl  => ufo_sigma_simobs_tl
  procedure :: simobs_ad  => ufo_sigma_simobs_ad
  final :: destructor
 end type ufo_sigma_tlad

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
! TODO: add setup of your TL/AD observation operator (optional)
subroutine ufo_sigma_tlad_setup(self, f_conf, channels, comm) !aggiunto argomento comm e in tutta la trafila di interfacce
use fckit_configuration_module, only: fckit_configuration
use kinds
implicit none
class(ufo_sigma_tlad), intent(inout) :: self

! TODO: consider whether passing the Configuration object to this function
! is necessary. If only a small number of parameters are used,
! you could pass them in directly instead. In that case you can modify the
! interface appropriately.
type(fckit_configuration), intent(in)  :: f_conf
type(fckit_mpi_comm), intent(in) :: comm !AGGIUNTO per selezionare rank, lo usiamo per inizializzare self e poi
!il self viene passato alle subroutine successive con già il membro comm inizializzato
integer(c_int),   intent(in)    :: channels(:)  !List of channels to use
integer :: nvars_in, rank

nvars_in = size(varin_default)
allocate(self%varin(nvars_in))
self%varin = varin_default
self%comm = comm 
rank = self%comm%rank()

! TODO: setup input variables varin (updated model variables)
call self%geovars%push_back(self%varin)
!because in varin_default there is the temprature in the geovals I will have jacobians wrt the temperature
! save channels
allocate(self%channels(size(channels)))
self%channels(:) = channels(:)
print *, "INIZIO SIGMA TLAD SETUP"
print *, "Prova array canali di size da ufo_sigma_tlad_mod ",size(self%channels), self%channels(1), self%channels(2), self%channels(size(self%channels)-1)
flush(6)
self%conf%nconfig_file=1
self%conf%config_file(1)=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/conf/clear.conf")
self%conf%od_dbase=("lblrtm")
self%conf%od_dbase_dir=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/auxiliary/lblrtm/")

if (rank == 0) then
  call sigma_read_configuration_files(self%conf%config_file,self%conf%nconfig_file,self%conf,self%ios)!in configuration.f90
  !//////////////////CONFIGURAZIONE MANUALE DI CONF//////////////////////////////////////////
  !---- Scalar strings ----
  self%conf%od_dbase          = 'lblrtm'
  self%conf%atmosphere_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/prof_20210720T120000_1")
  self%conf%emissivity_file=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code_fix/sigma/Input_files/e_CLAIM7")
  self%conf%isrf_file         = 'iasi-ng-isrf.dat'
  self%conf%isrf_file=("")

  !---- Scalar reals ----
  self%conf%sigma0            = 5.00000_R64
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
  self%conf%lr_jacs           = .true. !qua ci servono gli jacobiani
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
  if (self%conf%custom_emissivity) then
    call sigma_read_emissivity(self%conf%emissivity_file,self%conf,self%od,self%ios)!sigma_read_inputfiles.f90
  end if  
end if
call broadcast_conf(self%conf, self%comm)
call broadcast_od(self%od, self%comm)
call sigma_set_isrf(self%conf,self%isrf,self%od,self%ios)
call sigma_set_pressure_layers(self%conf,self%atm,self%ios)

if (rank == 0) then !questa cosa andrà rimossa
  call sigma_read_atmospheric_profile(self%conf%atmosphere_file, self%atm, self%ios)
end if
call broadcast_atm(self%atm, self%comm)
self%atm%cos_s = 0.0_PREC
self%atm%cos_r = 0.0_PREC
self%atm%cos_dazm = 0.0_PREC
self%atm%sin_v = 0.0_PREC
self%atm%sin_r = 0.0_PREC
self%atm%rcos_vr = 0.0_PREC
self%atm%WK = 0.0_PREC
print *, "FINE DI UFO_SIGMA_TLAD_SETUP"

end subroutine ufo_sigma_tlad_setup

! ------------------------------------------------------------------------------
! TODO: add cleanup of your TL/AD observation operator (optional)
subroutine destructor(self)
implicit none
type(ufo_sigma_tlad), intent(inout) :: self

end subroutine destructor

! ------------------------------------------------------------------------------
! TODO: replace below function with your set trajectory for tl/ad code
subroutine ufo_sigma_tlad_settraj(self, geovals, obss, hofxdiags)
use iso_c_binding
use ufo_geovals_mod, only: ufo_geovals, ufo_geoval, ufo_geovals_get_var
use obsspace_mod
use kinds

implicit none
class(ufo_sigma_tlad), intent(inout) :: self
type(ufo_geovals),       intent(in)    :: geovals !qui sono i profili completi, non gli incrementi
type(c_ptr), value,      intent(in)    :: obss
type(ufo_geovals),       intent(inout) :: hofxdiags    !non-h(x) diagnostics
integer(kind=I32)                 :: nlayers_grid, nlayers_model, ind, f, tb_index
integer :: r, n_temp, n_atm, i !aggiunte per reverse copy
integer :: livello, k, idx_canale, n_canali
real :: rnd
real(kind=PREC) :: valore_estratto
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
integer :: jprofile, reset_flag, rank

rank = self%comm%rank()
self%n_Profiles = geovals%nlocs
jprofile=self%n_Profiles !vale 1 nel test di 64 osservazioni ma ora 10
print *, "INIZIO UFO_SIGMA_TLAD_SETTRAJ"
print *, "QUI SETTO PLAYERS_GRID=PRESS DEL FILE INPUT"
print *, "Numero di profili: ",jprofile
players_grid=self%atm%press
allocate(ln_press_grid(size(players_grid)))
ln_press_grid=log(players_grid)

call ufo_geovals_get_var(geovals, var_ts,   temp_var_ts)
call ufo_geovals_get_var(geovals, var_prs,  temp_var_prs)
call ufo_geovals_get_var(geovals, var_sfc_ltmp, temp_var_sfc_tskin)!dovrei usare skin_temperature
call ufo_geovals_get_var(geovals, var_mixr, temp_var_mixr)
call ufo_geovals_get_var(geovals, var_oz,   temp_var_oz)
call ufo_geovals_get_var(geovals, var_co2,  temp_var_co2)

!********TEMPERATURE*****************
n_temp = size(temp_var_ts%vals,1) !64 layers del modello, 55 nel test LIVELLI DEL MODELLO
n_atm  = size(self%atm%temp)-1 !61-1 il primo è indicizzato a 0 con valore non definito, 60 al netto LIVELLI SIGMA
print *, "Il numero di layers per la temperatura dell'aria nel modello è: ",n_temp
print *, "Il numero di layers in SIGMA per la temperatura è: ",n_atm
allocate(temp_from_model(n_temp))
allocate(temp_interp_ongrid(n_atm))
temp_from_model = 0.0_PREC
do f = 1,n_temp
  temp_from_model(f) = temp_var_ts%vals(n_temp - f + 1, 1)!il secondo argomento è per il numero del profilo
end do
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
ln_press_from_model=log(press_from_model)
!*****SURFACE TEMP********
n_temp = size(temp_var_sfc_tskin%vals,1) !1
n_atm  = 1 !1
print *,"La surface temperature nel modello ha layers: ",n_temp
print *, temp_var_sfc_tskin%vals(:, 1)
print *, self%atm%ts
!****HUMIDITY MIXING RATIO************
print *, "HUMIDITY MIXING RATIO"
n_temp = size(temp_var_mixr%vals,1)
n_atm  = size(self%atm%wmol(:,1)) !60 qui non abbiamo l'elemento 0
print *, "Il numero di layers per humidity mixing ratio nel modello è: ",n_temp
print *, "Il numero di layers in SIGMA per H2O è: ",n_atm 
allocate(hummixrat_interp_ongrid(n_atm))
allocate(hummixrat_from_model(n_temp))
nlayers_grid = n_atm
nlayers_model = n_temp
do f = 1,n_temp
  hummixrat_from_model(f) = temp_var_mixr%vals(n_temp - f + 1, 1)
end do
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
write(*,*) "*********************************************************************************"
write(*,*) "********************INTERPOLAZIONE P-T IN TLAD********************************"
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
self%atm%temp(1:) = temp_interp_ongrid
self%atm%wmol(:,1) = hummixrat_interp_ongrid
!self%atm%wmol(:,2) = co2_interp_ongrid
!self%atm%wmol(:,3) = oz_interp_ongrid
print *, "These are the values interpolated on the layers "
print *, self%atm%temp
print *, self%atm%press
print *, self%atm%wmol(:,1)

!call deallocate_od(self%od)
if (rank == 0) then
   print *, "Rank 0 legge LUT"
   call sigma_noradjacob(self%conf,self%atm,self%rad,self%od,self%reset,self%ios) !sigma_frontend.f90
  !lettura od->da trasmettere ai ranks 
  !qui dentro vengono allocate le radianze, quindi va fatto su tutti i ranks
endif
print *, "Rank", rank, "dopo sigma_noradjacob"
call broadcast_od(self%od,self%comm)
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
if (rank /= 0) then
   call allocate_radiances(self%conf, self%od, self%rad)
end if
call broadcast_rad(self%rad,self%comm)
print *, "Prima di radandjacob"
call radandjacob(self%conf,self%atm,self%rad,self%od,self%ios)
print *, "Dopo radandjacob"
call apply_isrf(self%conf,self%atm,self%isrf,self%od,self%rad)

if (allocated(self%JT_lr_traj)) deallocate(self%JT_lr_traj)
allocate(self%JT_lr_traj(self%rad%nlrmax, NLAYERMAX, self%n_Profiles))
self%JT_lr_traj(:,:,1) = self%rad%JT_lr(:,:) !al posto di 1 ci va jprofile

if (allocated(self%JH2O_lr_traj)) deallocate(self%JH2O_lr_traj)
allocate(self%JH2O_lr_traj(self%rad%nlrmax, NLAYERMAX, self%n_Profiles))
self%JH2O_lr_traj(:,:,1) = self%rad%JH2O_lr(:,:) !al posto di 1 ci va jprofile

if (allocated(self%JCO2_lr_traj)) deallocate(self%JCO2_lr_traj)
allocate(self%JCO2_lr_traj(self%rad%nlrmax, NLAYERMAX, self%n_Profiles))
self%JCO2_lr_traj(:,:,1) = self%rad%JCO2_lr(:,:) !al posto di 1 ci va jprofile

if (allocated(self%JO3_lr_traj)) deallocate(self%JO3_lr_traj)
allocate(self%JO3_lr_traj(self%rad%nlrmax, NLAYERMAX, self%n_Profiles))
self%JO3_lr_traj(:,:,1) = self%rad%JO3_lr(:,:) !al posto di 1 ci va jprofile

!print *,"Printo jacobiani del primo profilo", self%JT_lr_traj(:,:,1)
!printo 1000 valori casuali degli jacobiani tra i 9217 canali per ogni livello per il primo profilo
n_canali = size(self%JT_lr_traj, 1)   ! 9217
do livello = 1, size(self%JT_lr_traj, 2)   ! 1 a 60

  print *, "Livello ", livello, " -> 1000 elementi casuali estratti dai canali:"

  do k = 1, 1000
    call random_number(rnd)
    idx_canale = int(rnd * n_canali) + 1        ! indice casuale tra 1 e n_canali
    if (idx_canale > n_canali) idx_canale = n_canali   ! sicurezza sui bordi

    valore_estratto = self%JT_lr_traj(idx_canale, livello, 1)
    print *, "  canale ", idx_canale, " -> valore: ", valore_estratto
  end do

end do

print *, "Shape di JT_lr_traj: ", shape(self%JT_lr_traj)
print *, "Dimensione 1 (canali/nlrmax): ", size(self%JT_lr_traj, 1)
print *, "Dimensione 2 (livelli): ", size(self%JT_lr_traj, 2)
print *, "Dimensione 3 (profili): ", size(self%JT_lr_traj, 3)

print *, "Shape di JH2O_lr_traj: ", shape(self%JH2O_lr_traj)
print *, "Dimensione 1 (canali/nlrmax): ", size(self%JH2O_lr_traj, 1)
print *, "Dimensione 2 (livelli): ", size(self%JH2O_lr_traj, 2)
print *, "Dimensione 3 (profili): ", size(self%JH2O_lr_traj, 3)
!per portare in simobs i profili del modello
if (allocated(self%ln_press_from_model_traj)) deallocate(self%ln_press_from_model_traj)
allocate(self%ln_press_from_model_traj(size(ln_press_from_model)))
self%ln_press_from_model_traj = ln_press_from_model

if (allocated(self%ln_press_grid_traj)) deallocate(self%ln_press_grid_traj)
allocate(self%ln_press_grid_traj(size(ln_press_grid)))
self%ln_press_grid_traj = ln_press_grid

self%nlayers_sigma_traj = n_atm

self%ltraj = .true.
print *, "FINE UFO_SIGMA_TLAD_SETTRAJ"

call write_wn_R_lr_to_file(self%rad,'output_sigma_tlad/wn_R_lr_dafile.txt')
call write_jacobian_T_heatmap_to_file(self, "output_sigma_tlad/jacobian_T_heatmap.txt")
call write_jacobian_H2O_heatmap_to_file(self, "output_sigma_tlad/jacobian_H2O_heatmap.txt")
call write_jacobian_CO2_heatmap_to_file(self, "output_sigma_tlad/jacobian_CO2_heatmap.txt")
call write_jacobian_O3_heatmap_to_file(self, "output_sigma_tlad/jacobian_O3_heatmap.txt")


end subroutine ufo_sigma_tlad_settraj

! ------------------------------------------------------------------------------
! TODO: replace below function with your tl observation operator.
! Note: this can use information saved from trajectory in your ufo_sigma_tlad type
! Input geovals parameter represents dx for tangent linear model
subroutine ufo_sigma_simobs_tl(self, geovals, obss, nvars, nlocs, hofx)
use iso_c_binding
use ufo_geovals_mod, only: ufo_geovals, ufo_geoval, ufo_geovals_get_var
use obsspace_mod
implicit none
class(ufo_sigma_tlad), intent(in)    :: self
type(ufo_geovals),       intent(in)    :: geovals !qui prendo i profili incrementali dal modello
integer,                 intent(in)    :: nvars, nlocs
real(c_double),          intent(inout) :: hofx(nvars, nlocs)
character(len=*), parameter :: myname_="ufo_radiancecrtm_simobs_tl"
type(c_ptr), value,      intent(in)    :: obss
type(ufo_geoval), pointer :: geoval_d  !aggiunta qui ci metto gli incrementi delle variabili
real(kind=PREC), allocatable :: dT_from_model(:), dT_interp_ongrid(:)
real(kind=PREC), allocatable :: dRad(:)
integer :: f, n_temp, n_atm, ind, jprofile, ch
! Matrice costante (non modificabile)
integer :: risultato(3),i
integer, parameter :: matrice(3,3) = reshape( (/1, 2, 3, 4, 5, 6, 7, 8, 9/), (/3, 3/) )
integer :: vettore(3)

vettore = (/ 1, 2, 3 /)
risultato = matmul(matrice, vettore)

print *, "--- Matrice originale ---"
do i = 1, 3
    print *, matrice(i, :)
end do
    
print *, ""
print *, "--- Vettore ---"
print *, vettore

print *, ""
print *, "--- Risultato di matmul(matrice, vettore) ---"
print *, risultato

! Initial checks
 ! --------------

! Check if trajectory was set
if (.not. self%ltraj) then
  write(err_msg,*) myname_, ' trajectory wasnt set!'
  call abor1_ftn(err_msg)
endif

! Initialize hofx
! ---------------
hofx(:,:) = 0.0_kind_real

call ufo_geovals_get_var(geovals, var_ts, geoval_d)
print*,"Check vettore differenze"
print *, "I livelli del modello sono: ",size(geoval_d%vals,1)
print *, "Il numero di profili é: ",size(geoval_d%vals,2)
if (allocated(geoval_d%vals) .and. size(geoval_d%vals, 2) >= 1) then
    print *, "Print del primo profilo di dT: ", geoval_d%vals(:, 1)
else
    print *, "Errore: l'array vals non è allocato o non contiene profili!"
end if

n_temp=size(geoval_d%vals,1) !livelli modello
n_atm=self%nlayers_sigma_traj !livelli sigma
allocate(dT_from_model(n_temp))
allocate(dT_interp_ongrid(n_atm))
do f = 1, n_temp
  dT_from_model(f) = geoval_d%vals(n_temp - f + 1, 1)
end do
do f = 1, n_atm
    call linint_saf(self%ln_press_from_model_traj, dT_from_model,n_temp, self%ln_press_grid_traj(f),dT_interp_ongrid(f), ind)
end do
if (allocated(dT_interp_ongrid) .and. size(dT_interp_ongrid) >= 1) then
  print *, "Print delle differenze interpolate: ", dT_interp_ongrid(:), "con size: ",size(dT_interp_ongrid)  
else
    print *, "Errore: l'array dT_interp_ongrid non è allocato o non contiene profili!"
end if
allocate(dRad(size(self%JT_lr_traj,1))) !dimensione pari ai canali lr
dRad = matmul(self%JT_lr_traj(:,:,1), dT_interp_ongrid)
print*,"nvars vale: ",nvars,"mentre il numero di canali di JT è: ",size(self%JT_lr_traj,1)
print *, "dRad ha size: ",size(dRad), "ed è: ",dRad(1),dRad(100),dRad(1000),dRad(3000),dRad(8000),dRad(9000)
!do ch = 1, nvars
 ! hofx(ch, 1) = dRad(ch)
!end do
hofx(:,1) = dRad(1000:SIZE(hofx,1)+999) !elementi dal 1000 al 6001

deallocate(dT_from_model, dT_interp_ongrid, dRad)



end subroutine ufo_sigma_simobs_tl

! ------------------------------------------------------------------------------
! TODO: replace below function with your ad observation operator.
! Note: this can use information saved from trajectory in your ufo_sigma_tlad type
subroutine ufo_sigma_simobs_ad(self, geovals, obss, nvars, nlocs, hofx)
use iso_c_binding
use ufo_geovals_mod, only: ufo_geovals, ufo_geoval, ufo_geovals_get_var
use obsspace_mod
implicit none
class(ufo_sigma_tlad), intent(in)    :: self
type(ufo_geovals),       intent(inout) :: geovals
integer,                 intent(in)    :: nvars, nlocs
real(c_double),          intent(in)    :: hofx(nvars, nlocs)
type(c_ptr), value,      intent(in)    :: obss


end subroutine ufo_sigma_simobs_ad

! ------------------------------------------------------------------------------

subroutine write_jacobian_T_heatmap_to_file(self, filename)
  use structures
  implicit none

  class(ufo_sigma_tlad), intent(in) :: self
  character(len=*), intent(in) :: filename

  integer :: livello, i, n_livelli, nelements, first_wn, last_wn, u
  real(kind=PREC) :: wn

  ! Check che JT_lr_traj e wave_lr siano allocati
  if (.not. allocated(self%JT_lr_traj)) return
  if (.not. allocated(self%rad%wave_lr)) return

  n_livelli = size(self%JT_lr_traj, 2)
  first_wn  = self%rad%I1
  last_wn   = self%rad%I2
  nelements = last_wn - first_wn + 1

  print *, "Scrittura heatmap Jacobiano: ", nelements, " canali x ", n_livelli, " livelli"
  print *, "Wavenumber tra ", first_wn, " e ", last_wn

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Header
  write(u,'(A)') "# wavenumber  livello  jacobiano"

  ! Tre colonne: wavenumber, livello, valore del Jacobiano
  do livello = 1, n_livelli
    do i = 0, nelements-1
      wn = self%rad%wave_lr(i+1)
      write(u,'(E20.12,1X,I8,1X,E20.12)') wn, livello, &
            self%JT_lr_traj(first_wn+i, livello, 1)
    end do
  end do

  close(u)

end subroutine write_jacobian_T_heatmap_to_file

subroutine write_jacobian_H2O_heatmap_to_file(self, filename)
  use structures
  implicit none

  class(ufo_sigma_tlad), intent(in) :: self
  character(len=*), intent(in) :: filename

  integer :: livello, i, n_livelli, nelements, first_wn, last_wn, u
  real(kind=PREC) :: wn

  ! Check che JH2O_lr_traj e wave_lr siano allocati
  if (.not. allocated(self%JH2O_lr_traj)) return
  if (.not. allocated(self%rad%wave_lr)) return

  n_livelli = size(self%JH2O_lr_traj, 2)
  first_wn  = self%rad%I1
  last_wn   = self%rad%I2
  nelements = last_wn - first_wn + 1

  print *, "Scrittura heatmap Jacobiano: ", nelements, " canali x ", n_livelli, " livelli"
  print *, "Wavenumber tra ", first_wn, " e ", last_wn

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Header
  write(u,'(A)') "# wavenumber  livello  jacobiano"

  ! Tre colonne: wavenumber, livello, valore del Jacobiano
  do livello = 1, n_livelli
    do i = 0, nelements-1
      wn = self%rad%wave_lr(i+1)
      write(u,'(E20.12,1X,I8,1X,E20.12)') wn, livello, &
            self%JH2O_lr_traj(first_wn+i, livello, 1)
    end do
  end do

  close(u)

end subroutine write_jacobian_H2O_heatmap_to_file

subroutine write_jacobian_CO2_heatmap_to_file(self, filename)
  use structures
  implicit none

  class(ufo_sigma_tlad), intent(in) :: self
  character(len=*), intent(in) :: filename

  integer :: livello, i, n_livelli, nelements, first_wn, last_wn, u
  real(kind=PREC) :: wn

  ! Check che JCO2_lr_traj e wave_lr siano allocati
  if (.not. allocated(self%JCO2_lr_traj)) return
  if (.not. allocated(self%rad%wave_lr)) return

  n_livelli = size(self%JCO2_lr_traj, 2)
  first_wn  = self%rad%I1
  last_wn   = self%rad%I2
  nelements = last_wn - first_wn + 1

  print *, "Scrittura heatmap Jacobiano CO2: ", nelements, " canali x ", n_livelli, " livelli"
  print *, "Wavenumber tra ", first_wn, " e ", last_wn

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Header
  write(u,'(A)') "# wavenumber  livello  jacobiano"

  ! Tre colonne: wavenumber, livello, valore del Jacobiano
  do livello = 1, n_livelli
    do i = 0, nelements-1
      wn = self%rad%wave_lr(i+1)
      write(u,'(E20.12,1X,I8,1X,E20.12)') wn, livello, &
            self%JCO2_lr_traj(first_wn+i, livello, 1)
    end do
  end do

  close(u)

end subroutine write_jacobian_CO2_heatmap_to_file

subroutine write_jacobian_O3_heatmap_to_file(self, filename)
  use structures
  implicit none

  class(ufo_sigma_tlad), intent(in) :: self
  character(len=*), intent(in) :: filename

  integer :: livello, i, n_livelli, nelements, first_wn, last_wn, u
  real(kind=PREC) :: wn

  ! Check che JO3_lr_traj e wave_lr siano allocati
  if (.not. allocated(self%JO3_lr_traj)) return
  if (.not. allocated(self%rad%wave_lr)) return

  n_livelli = size(self%JO3_lr_traj, 2)
  first_wn  = self%rad%I1
  last_wn   = self%rad%I2
  nelements = last_wn - first_wn + 1

  print *, "Scrittura heatmap Jacobiano O3: ", nelements, " canali x ", n_livelli, " livelli"
  print *, "Wavenumber tra ", first_wn, " e ", last_wn

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Header
  write(u,'(A)') "# wavenumber  livello  jacobiano"

  ! Tre colonne: wavenumber, livello, valore del Jacobiano
  do livello = 1, n_livelli
    do i = 0, nelements-1
      wn = self%rad%wave_lr(i+1)
      write(u,'(E20.12,1X,I8,1X,E20.12)') wn, livello, &
            self%JO3_lr_traj(first_wn+i, livello, 1)
    end do
  end do

  close(u)

end subroutine write_jacobian_O3_heatmap_to_file

end module ufo_sigma_tlad_mod
