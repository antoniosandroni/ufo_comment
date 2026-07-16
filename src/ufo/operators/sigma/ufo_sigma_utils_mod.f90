MODULE ufo_sigma_utils_mod

use fckit_configuration_module, only: fckit_configuration
use fckit_mpi_module,   only: fckit_mpi_comm
use iso_c_binding
use kinds

use ufo_geovals_mod, only: ufo_geovals, ufo_geoval, ufo_geovals_get_var
use ufo_vars_mod
use obsspace_mod
use ufo_utils_mod, only: cmp_strings

use mpi
use structures
use parameters
use iso_fortran_env

implicit none
private

public print_configuration
public print_atmosphere
public print_atmosphere_iu
public print_radiances
public write_R_hr_to_file
public write_wn_R_lr_to_file
public write_R_lr_to_file
public find_around_max_array
public print_od
public print_od_iu
public print_od_iu_secure
public print_ufo_geoval_object
public linint_saf
public write_twoarrays_to_file
public from_rad_to_bt
public broadcast_od
public broadcast_rad
public broadcast_conf
public broadcast_atm 
public broadcast_continuum_inputs
public broadcast_sunglint

contains

subroutine print_configuration(conf)
  use structures
  implicit none

  type(configuration_params), intent(in) :: conf
  integer :: i

  ! Scalar integers
  print *, "nconfig_file = ", conf%nconfig_file
  print *, "config_file = ", conf%config_file
  print *, "nparams = ", conf%nparams
  print *, "n_threads = ", conf%n_threads
  print *, "openmp = ", conf%openmp
  print *, "altitude_profile = ", conf%altitude_profile
  print *, "reflection_type = ", conf%reflection_type
  print *, "nemiss_in = ", conf%nemiss_in
  print *, "nisrf_in = ", conf%nisrf_in

  ! Scalars characters
  print *, "od_dbase = ", trim(conf%od_dbase)
  print *, "od_dbase_dir = ", trim(conf%od_dbase_dir)
  print *, "atmosphere_file = ", trim(conf%atmosphere_file)
  print *, "emissivity_file = ", trim(conf%emissivity_file)
  print *, "isrf_file = ", trim(conf%isrf_file)

  ! Scalars real
  print *, "sigma0 = ", conf%sigma0
  print *, "sigma1 = ", conf%sigma1
  print *, "dsigma_low = ", conf%dsigma_low
  print *, "obs_pres = ", conf%obs_pres
  print *, "bot_pres = ", conf%bot_pres
  print *, "wind_speed = ", conf%wind_speed
  print *, "cloud_fraction = ", conf%cloud_fraction

  ! Logical scalars
  print *, "custom_emissivity = ", conf%custom_emissivity
  print *, "custom_isrf = ", conf%custom_isrf
  print *, "flag_ref = ", conf%flag_ref
  print *, "lr_need = ", conf%lr_need
  print *, "lr_rad = ", conf%lr_rad
  print *, "hr_rad = ", conf%hr_rad
  print *, "lr_jacs = ", conf%lr_jacs
  print *, "wind_sunglint = ", conf%wind_sunglint
  print *, "clear = ", conf%clear
  print *, "cloudy = ", conf%cloudy
  print *, "overcast = ", conf%overcast
  print *, "day = ", conf%day
  print *, "night = ", conf%night

  ! Arrays
  do i=1, conf%nconfig_file
     print *, "config_file(",i,") = ", trim(conf%config_file(i))
  end do

  print *, "view_angles = ", conf%view_angles
  print *, "solar_angles = ", conf%solar_angles

  ! Vectors for emissivity and isrf
  if (allocated(conf%emiss_in)) print *, "emiss_in = ", conf%emiss_in
  if (allocated(conf%wemiss_in)) print *, "wemiss_in = ", conf%wemiss_in
  if (allocated(conf%isrf_in)) print *, "isrf_in = ", conf%isrf_in
  if (allocated(conf%wisrf_in)) print *, "wisrf_in = ", conf%wisrf_in

  ! Logical arrays
  print *, "comp_jacs = ", conf%comp_jacs
  print *, "cntnm_jacs = ", conf%cntnm_jacs
  print *, "clouds_jacs = ", conf%clouds_jacs
  print *, "rte_output = ", conf%rte_output

  ! Complex array
  !print *, "waopc = "
  !do i=1, size(conf%waopc)
   !  print *, conf%waopc(i)
  !end do

end subroutine print_configuration

subroutine print_atmosphere(atm)
  use structures
  implicit none

  type(atmosphere), intent(in) :: atm
  integer :: i, j, nprint

  ! --------------------------------------------------------------------------
  ! Scalar integers
  print *, "iprof        = ", atm%iprof
  print *, "startlayer   = ", atm%startlayer
  print *, "endlayer     = ", atm%endlayer
  print *, "st           = ", atm%st
  print *, "jl           = ", atm%jl
  print *, "jr           = ", atm%jr
  print *, "layer0       = ", atm%layer0
  print *, "layer1       = ", atm%layer1
  print *, "nlayers      = ", atm%nlayers
  print *, "nmol         = ", atm%nmol

  ! --------------------------------------------------------------------------
  ! Viewing and solar angles
  print *, "ang_v        = ", atm%ang_v
  print *, "ang_s        = ", atm%ang_s
  print *, "ang_r        = ", atm%ang_r
  print *, "ang_dazm     = ", atm%ang_dazm
  print *, "cos_v        = ", atm%cos_v
  print *, "cos_s        = ", atm%cos_s
  print *, "cos_r        = ", atm%cos_r
  print *, "cos_dazm     = ", atm%cos_dazm
  print *, "sin_v        = ", atm%sin_v
  print *, "sin_s        = ", atm%sin_s
  print *, "sin_r        = ", atm%sin_r
  print *, "rcos_vr      = ", atm%rcos_vr
  print *, "rcos_vs      = ", atm%rcos_vs

  ! --------------------------------------------------------------------------
  ! Small arrays (print first few elements)
  nprint = size(atm%temp)
  print *, "temp (first ", nprint, ") = ", atm%temp(1:nprint)

  nprint = size(atm%press)     !min(10, size(atm%press))
  print *, "press (first ", nprint, ") = ", atm%press(1:nprint)

  nprint = min(10, size(atm%z))
  print *, "z (first ", nprint, ") = ", atm%z(1:nprint)

  nprint = min(10, size(atm%pg))
  print *, "pg (first ", nprint, ") = ", atm%pg(1:nprint)

  nprint = min(10, size(atm%pbar))
  print *, "pbar (first ", nprint, ") = ", atm%pbar(1:nprint)

  nprint = min(10, size(atm%fp))
  print *, "fp (first ", nprint, ") = ", atm%fp(1:nprint)

  nprint = min(10, size(atm%lwccs))
  print *, "lwccs (first ", nprint, ") = ", atm%lwccs(1:nprint)

  nprint = min(10, size(atm%recs))
  print *, "recs (first ", nprint, ") = ", atm%recs(1:nprint)

  nprint = min(10, size(atm%iwccs))
  print *, "iwccs (first ", nprint, ") = ", atm%iwccs(1:nprint)

  nprint = min(10, size(atm%dgecs))
  print *, "dgecs (first ", nprint, ") = ", atm%dgecs(1:nprint)

  ! --------------------------------------------------------------------------
  ! wmol 2D array (first few layers & species)
  !nprint = min(5, size(atm%wmol,1))
  !print *, size(atm%wmol,2)
  !do i = 1, nprint
     !print '(A,I2,A,5E12.4)', "wmol(", i, ") = ", (atm%wmol(i,j), j=1, min(5, size(atm%wmol,2)))
  !end do
  print *, "wmol(:,1) prima specie", atm%wmol(:,1)
  print *, "wmol(:,2) seconda specie", atm%wmol(:,2)
  print *, "wmol(:,3) terza specie", atm%wmol(:,3)
  print *, "wmol(:,4) quart specie", atm%wmol(:,4)


  print *, "wmol(:,12) ", atm%wmol(:,12)
  print *, "wmol(:,13)", atm%wmol(:,13)
  print *, "wmol(:,14)", atm%wmol(:,14)
  print *, "wmol(:,30)", atm%wmol(:,30)
  !print *, "wmol(:,31)", atm%wmol(:,31)



  ! WK vector
  nprint = min(5, size(atm%WK))
  print *, "WK (first ", nprint, ") = ", atm%WK(1:nprint)

  ! --------------------------------------------------------------------------
  ! Scalar temperature at surface
  print *, "ts = ", atm%ts

  ! --------------------------------------------------------------------------
  ! Nested types
  print *, "Number of continuum layers (cont) = ", size(atm%cont)
  ! For example, first layer's continuum info could be printed if needed

  print *, "Sunglint struct:"
  print *, "  ... details of sg can be printed here ..."

  ! --------------------------------------------------------------------------
  print *, "-------------------- End of Atmosphere --------------------"

end subroutine print_atmosphere

subroutine print_atmosphere_iu(atm, iu)

use structures
implicit none

type(atmosphere), intent(in) :: atm
integer, intent(in) :: iu

integer :: i, j, nprint

! --------------------------------------------------------------------------
! Scalar integers
write(iu,*) "iprof        = ", atm%iprof
write(iu,*) "startlayer   = ", atm%startlayer
write(iu,*) "endlayer     = ", atm%endlayer
write(iu,*) "st           = ", atm%st
write(iu,*) "jl           = ", atm%jl
write(iu,*) "jr           = ", atm%jr
write(iu,*) "layer0       = ", atm%layer0
write(iu,*) "layer1       = ", atm%layer1
write(iu,*) "nlayers      = ", atm%nlayers
write(iu,*) "nmol         = ", atm%nmol

! --------------------------------------------------------------------------
! Viewing and solar angles
write(iu,*) "ang_v        = ", atm%ang_v
write(iu,*) "ang_s        = ", atm%ang_s
write(iu,*) "ang_r        = ", atm%ang_r
write(iu,*) "ang_dazm     = ", atm%ang_dazm

write(iu,*) "cos_v        = ", atm%cos_v
write(iu,*) "cos_s        = ", atm%cos_s
write(iu,*) "cos_r        = ", atm%cos_r
write(iu,*) "cos_dazm     = ", atm%cos_dazm

write(iu,*) "sin_v        = ", atm%sin_v
write(iu,*) "sin_s        = ", atm%sin_s
write(iu,*) "sin_r        = ", atm%sin_r

write(iu,*) "rcos_vr      = ", atm%rcos_vr
write(iu,*) "rcos_vs      = ", atm%rcos_vs

! --------------------------------------------------------------------------
! Arrays

nprint = size(atm%temp)
write(iu,*) "temp (first ", nprint, ") = ", atm%temp(1:nprint)

nprint = size(atm%press)
write(iu,*) "press (first ", nprint, ") = ", atm%press(1:nprint)

nprint = min(10, size(atm%z))
write(iu,*) "z (first ", nprint, ") = ", atm%z(1:nprint)

nprint = min(10, size(atm%pg))
write(iu,*) "pg (first ", nprint, ") = ", atm%pg(1:nprint)

nprint = min(10, size(atm%pbar))
write(iu,*) "pbar (first ", nprint, ") = ", atm%pbar(1:nprint)

nprint = min(10, size(atm%fp))
write(iu,*) "fp (first ", nprint, ") = ", atm%fp(1:nprint)

nprint = min(10, size(atm%lwccs))
write(iu,*) "lwccs (first ", nprint, ") = ", atm%lwccs(1:nprint)

nprint = min(10, size(atm%recs))
write(iu,*) "recs (first ", nprint, ") = ", atm%recs(1:nprint)

nprint = min(10, size(atm%iwccs))
write(iu,*) "iwccs (first ", nprint, ") = ", atm%iwccs(1:nprint)

nprint = min(10, size(atm%dgecs))
write(iu,*) "dgecs (first ", nprint, ") = ", atm%dgecs(1:nprint)

! --------------------------------------------------------------------------
! WMOL

write(iu,*) "wmol(:,1) prima specie"
write(iu,*) atm%wmol(:,1)

write(iu,*) "wmol(:,2) seconda specie"
write(iu,*) atm%wmol(:,2)

write(iu,*) "wmol(:,3) terza specie"
write(iu,*) atm%wmol(:,3)

write(iu,*) "wmol(:,4) quarta specie"
write(iu,*) atm%wmol(:,4)

write(iu,*) "wmol(:,12)"
write(iu,*) atm%wmol(:,12)

write(iu,*) "wmol(:,13)"
write(iu,*) atm%wmol(:,13)

write(iu,*) "wmol(:,14)"
write(iu,*) atm%wmol(:,14)

write(iu,*) "wmol(:,30)"
write(iu,*) atm%wmol(:,30)

! --------------------------------------------------------------------------
! WK

nprint = min(5, size(atm%WK))
write(iu,*) "WK (first ", nprint, ") = ", atm%WK(1:nprint)

! --------------------------------------------------------------------------
! Surface temperature

write(iu,*) "ts = ", atm%ts

! --------------------------------------------------------------------------
! Continuum

write(iu,*) "Number of continuum layers (cont) = ", size(atm%cont)

! --------------------------------------------------------------------------
! Sunglint

write(iu,*) "Sunglint struct:"
write(iu,*) "  ... details of sg can be printed here ..."

! --------------------------------------------------------------------------
write(iu,*) "-------------------- End of Atmosphere --------------------"

end subroutine print_atmosphere_iu


subroutine print_radiances(rad)
  use iso_fortran_env, only : output_unit
  use structures
  implicit none

  type(radiances), intent(in) :: rad
  integer :: u

  u = output_unit

  write(u,*) '==================== RADIANCES OBJECT ===================='

  ! ---- Scalars
  write(u,*) 'nlrmax   = ', rad%nlrmax
  write(u,*) 'nlr      = ', rad%nlr
  write(u,*) 'nhr      = ', rad%nhr
  write(u,*) 'nref     = ', rad%nref

  write(u,*) 'I1,I2        = ', rad%I1, rad%I2
  write(u,*) 'I1hr,I2hr    = ', rad%I1hr, rad%I2hr
  write(u,*) 'I1ref,I2ref  = ', rad%I1ref, rad%I2ref
  write(u,*) 'I1hrc,I2hrc  = ', rad%I1hrc, rad%I2hrc
  write(u,*) 'I1refc,I2refc= ', rad%I1refc, rad%I2refc

  write(u,*) 'ntot_hr   = ', rad%ntot_hr
  write(u,*) 'ntot_hrc  = ', rad%ntot_hrc
  write(u,*) 'ntot_lr   = ', rad%ntot_lr
  write(u,*) 'ntot_ref  = ', rad%ntot_ref
  write(u,*) 'ntot_refc = ', rad%ntot_refc

  ! ---- 1D allocatables
  call print_1d('wave_lr', rad%wave_lr)
  call print_1d('wave_hr', rad%wave_hr)
  call print_1d('wave_hrc',rad%wave_hrc)

  call print_1d('RADa', rad%RADa)
  call print_1d('RADaC',rad%RADaC)
  call print_1d('R_lr', rad%R_lr)
  call print_1d('R_hr', rad%R_hr)
  call print_1d('T_hr', rad%T_hr)

  ! ---- 2D allocatables (sizes only)
  call print_2d('tt',        rad%tt)
  call print_2d('ttc',       rad%ttc)
  call print_2d('ttp',       rad%ttp)
  call print_2d('ttcp',      rad%ttcp)
  call print_2d('Taus',      rad%Taus)

  call print_2d('JT_lr',     rad%JT_lr)
  call print_2d('JH2O_lr',   rad%JH2O_lr)
  call print_2d('JT_hr',     rad%JT_hr)
  call print_2d('JH2O_hr',   rad%JH2O_hr)

  write(u,*) '================== END RADIANCES OBJECT =================='

contains

  subroutine print_1d(name, arr)
    character(len=*), intent(in) :: name
    real(kind=PREC), allocatable, intent(in) :: arr(:)

    if (allocated(arr)) then
      write(u,*) trim(name),' allocated, size = ', size(arr)
      write(u,*) '  first elements:', arr(1:min(10,size(arr)))
    else
      write(u,*) trim(name),' NOT allocated'
    end if
  end subroutine print_1d

  subroutine print_2d(name, arr)
    character(len=*), intent(in) :: name
    real(kind=PREC), allocatable, intent(in) :: arr(:,:)

    if (allocated(arr)) then
      write(u,*) trim(name),' allocated, shape = ', shape(arr)
    else
      write(u,*) trim(name),' NOT allocated'
    end if
  end subroutine print_2d

end subroutine print_radiances

subroutine write_R_hr_to_file(rad, filename)
  use structures
  implicit none

  type(radiances), intent(in) :: rad
  character(len=*), intent(in) :: filename

  integer :: i, n, u

  ! Check that R_hr is allocated
  if (.not. allocated(rad%R_hr)) return

  n = size(rad%R_hr)

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Write two columns: index (starting from 0) and R_hr value
  do i = 1, n
     write(u,'(I6,1X,E20.12)') i-1, rad%R_hr(i)
  end do

  close(u)

end subroutine write_R_hr_to_file

subroutine write_wn_R_lr_to_file(rad, filename)
  use structures
  implicit none

  type(radiances), intent(in) :: rad
  character(len=*), intent(in) :: filename

  integer :: i, n, u, n_wave, nelements, first_wn, last_wn

  ! Check that R_hr is allocated
  if (.not. allocated(rad%R_lr)) return
  if (.not. allocated(rad%wave_lr)) return

  n = size(rad%R_lr)
  n_wave = size(rad%wave_lr)
  first_wn = rad%I1
  last_wn = rad%I2
  nelements = last_wn-first_wn+1

  print *, "The size of Rad_lr e wave_lr are: ",n," ",n_wave
  print *, "we will the values of R_lr between the wn ", first_wn, " and ", last_wn

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Write two columns: wave_number and R_hr value
  do i = 0, nelements-1
     write(u,'(E20.12,1X,E20.12)') rad%wave_lr(i+1), rad%R_lr(first_wn+i)
  end do

  close(u)

end subroutine write_wn_R_lr_to_file

subroutine write_R_lr_to_file(rad, filename)
  use structures
  implicit none

  type(radiances), intent(in) :: rad
  character(len=*), intent(in) :: filename

  integer :: i, n, u

  ! Check that R_lr is allocated
  if (.not. allocated(rad%R_lr)) return

  n = size(rad%R_lr)

  ! Open file for writing
  open(newunit=u, file=trim(filename), status='replace', &
       action='write', form='formatted')

  ! Write two columns: index (starting from 0) and R_hr value
  do i = 1, n
     write(u,'(I6,1X,E20.12)') i-1, rad%R_lr(i)
  end do

  close(u)

end subroutine write_R_lr_to_file

subroutine find_around_max_array(arr)
  use kinds
  use :: parameters, only : MAX_STRING_LENGTH, NWCUR, PREC, I32, R32, R64, WAT_OPT_FILE
  implicit none
  real(kind=PREC), intent(in) :: arr(:)   ! input 1D array
  integer :: imax, i1, i2, n
  n = size(arr)
  imax = maxloc(arr, dim=1)  ! index of maximum

  ! Define window limits safely
  i1 = max(1, imax - 5)
  i2 = min(n, imax + 4)

  ! Print the values around the maximum
  write(*,*) 'Max index = ', imax
  write(*,*) 'Values around maximum: ', arr(i1:i2)

end subroutine find_around_max_array

subroutine print_od(od)
  use kinds
  use structures
  implicit none

  type(od_dbase), intent(in) :: od
  integer :: i, j

  ! ---- Scalars
  print *, "double_precision = ", od%double_precision
  print *, "noi = ", od%noi
  print *, "nof = ", od%nof
  print *, "v1cur = ", od%v1cur
  print *, "v2cur = ", od%v2cur
  print *, "wn_thresh = ", od%wn_thresh
  print *, "continuum_model = ", od%continuum_model
  print *, "nwhrbandmax = ", od%nwhrbandmax
  print *, "nwhrbandmaxR = ", od%nwhrbandmaxR
  print *, "nwvcur = ", od%nwvcur
  print *, "nqucur = ", od%nqucur
  print *, "szmax = ", od%szmax
  print *, "szmax2 = ", od%szmax2
  print *, "nwref = ", od%nwref
  print *, "nwcur = ", od%nwcur
  print *, "nwvcurR = ", od%nwvcurR
  print *, "nqucurR = ", od%nqucurR
  print *, "szmaxR = ", od%szmaxR
  print *, "szmax2R = ", od%szmax2R
  print *, "nx1awp = ", od%nx1awp
  print *, "nx1aip = ", od%nx1aip
  print *, "nx2awp = ", od%nx2awp
  print *, "nx2aip = ", od%nx2aip

  ! ---- 1D allocatable integer arrays
  if (allocated(od%npn)) print *, "npn = ", od%npn
  if (allocated(od%point)) print *, "point = ", od%point
  if (allocated(od%quad)) print *, "quad = ", od%quad
  if (allocated(od%npnR)) print *, "npnR = ", od%npnR
  if (allocated(od%pointR)) print *, "pointR = ", od%pointR
  if (allocated(od%quadR)) print *, "quadR = ", od%quadR

  ! ---- 2D allocatable integer arrays
  if (allocated(od%squad)) then
     print *, "squad = "
     do i=1,min(5,size(od%squad,1))
        print *, od%squad(i,1:min(5,size(od%squad,2)))
     end do
  end if
  if (allocated(od%equad)) then
     print *, "equad = "
     do i=1,min(5,size(od%equad,1))
        print *, od%equad(i,1:min(5,size(od%equad,2)))
     end do
  end if
  if (allocated(od%squadR)) then
     print *, "squadR = "
     do i=1,min(5,size(od%squadR,1))
        print *, od%squadR(i,1:min(5,size(od%squadR,2)))
     end do
  end if
  if (allocated(od%equadR)) then
     print *, "equadR = "
     do i=1,min(5,size(od%equadR,1))
        print *, od%equadR(i,1:min(5,size(od%equadR,2)))
     end do
  end if

  ! ---- 1D allocatable real arrays
  if (allocated(od%cq0)) print *, "cq0 = ", od%cq0
  if (allocated(od%cq1)) print *, "cq1 = ", od%cq1
  if (allocated(od%cq2)) print *, "cq2 = ", od%cq2
  if (allocated(od%cq3)) print *, "cq3 = ", od%cq3
  if (allocated(od%cq0R)) print *, "cq0R = ", od%cq0R
  if (allocated(od%cq1R)) print *, "cq1R = ", od%cq1R
  if (allocated(od%cq2R)) print *, "cq2R = ", od%cq2R
  if (allocated(od%cq3R)) print *, "cq3R = ", od%cq3R
  if (allocated(od%Isol)) print *, "Isol = ", od%Isol

  ! ---- 2D allocatable real arrays (clouds)
  if (allocated(od%Pbetaw)) then
     print *, "Pbetaw = "
     do i=1,min(5,size(od%Pbetaw,1))
        print *, od%Pbetaw(i,1:min(5,size(od%Pbetaw,2)))
     end do
  end if
  if (allocated(od%Pomegaw)) then
     print *, "Pomegaw = "
     do i=1,min(5,size(od%Pomegaw,1))
        print *, od%Pomegaw(i,1:min(5,size(od%Pomegaw,2)))
     end do
  end if
  if (allocated(od%Pbw)) then
     print *, "Pbw = "
     do i=1,min(5,size(od%Pbw,1))
        print *, od%Pbw(i,1:min(5,size(od%Pbw,2)))
     end do
  end if
  if (allocated(od%Pbetai)) then
     print *, "Pbetai = "
     do i=1,min(5,size(od%Pbetai,1))
        print *, od%Pbetai(i,1:min(5,size(od%Pbetai,2)))
     end do
  end if
  if (allocated(od%Pomegai)) then
     print *, "Pomegai = "
     do i=1,min(5,size(od%Pomegai,1))
        print *, od%Pomegai(i,1:min(5,size(od%Pomegai,2)))
     end do
  end if
  if (allocated(od%Pbi)) then
     print *, "Pbi = "
     do i=1,min(5,size(od%Pbi,1))
        print *, od%Pbi(i,1:min(5,size(od%Pbi,2)))
     end do
  end if

end subroutine print_od

subroutine print_od_iu(od, iu)

  use kinds
  use structures
  implicit none

  type(od_dbase), intent(in) :: od
  integer, intent(in) :: iu

  integer :: i, j

  ! ---- Scalars
  write(iu,*) "double_precision = ", od%double_precision
  write(iu,*) "noi = ", od%noi
  write(iu,*) "nof = ", od%nof
  write(iu,*) "v1cur = ", od%v1cur
  write(iu,*) "v2cur = ", od%v2cur
  write(iu,*) "wn_thresh = ", od%wn_thresh
  write(iu,*) "continuum_model = ", od%continuum_model
  write(iu,*) "nwhrbandmax = ", od%nwhrbandmax
  write(iu,*) "nwhrbandmaxR = ", od%nwhrbandmaxR
  write(iu,*) "nwvcur = ", od%nwvcur
  write(iu,*) "nqucur = ", od%nqucur
  write(iu,*) "szmax = ", od%szmax
  write(iu,*) "szmax2 = ", od%szmax2
  write(iu,*) "nwref = ", od%nwref
  write(iu,*) "nwcur = ", od%nwcur
  write(iu,*) "nwvcurR = ", od%nwvcurR
  write(iu,*) "nqucurR = ", od%nqucurR
  write(iu,*) "szmaxR = ", od%szmaxR
  write(iu,*) "szmax2R = ", od%szmax2R
  write(iu,*) "nx1awp = ", od%nx1awp
  write(iu,*) "nx1aip = ", od%nx1aip
  write(iu,*) "nx2awp = ", od%nx2awp
  write(iu,*) "nx2aip = ", od%nx2aip

  ! ---- 1D allocatable integer arrays
  if (allocated(od%npn))    write(iu,*) "npn = ", od%npn
  if (allocated(od%point))  write(iu,*) "point = ", od%point
  if (allocated(od%quad))   write(iu,*) "quad = ", od%quad
  if (allocated(od%npnR))   write(iu,*) "npnR = ", od%npnR
  if (allocated(od%pointR)) write(iu,*) "pointR = ", od%pointR
  if (allocated(od%quadR))  write(iu,*) "quadR = ", od%quadR

  ! ---- 2D allocatable integer arrays
  if (allocated(od%squad)) then
     write(iu,*) "squad = "
     do i = 1, min(5,size(od%squad,1))
        write(iu,*) od%squad(i,1:min(5,size(od%squad,2)))
     end do
  end if

  if (allocated(od%equad)) then
     write(iu,*) "equad = "
     do i = 1, min(5,size(od%equad,1))
        write(iu,*) od%equad(i,1:min(5,size(od%equad,2)))
     end do
  end if

  if (allocated(od%squadR)) then
     write(iu,*) "squadR = "
     do i = 1, min(5,size(od%squadR,1))
        write(iu,*) od%squadR(i,1:min(5,size(od%squadR,2)))
     end do
  end if

  if (allocated(od%equadR)) then
     write(iu,*) "equadR = "
     do i = 1, min(5,size(od%equadR,1))
        write(iu,*) od%equadR(i,1:min(5,size(od%equadR,2)))
     end do
  end if

  ! ---- 1D allocatable real arrays
  if (allocated(od%cq0))   write(iu,*) "cq0 = ", od%cq0
  if (allocated(od%cq1))   write(iu,*) "cq1 = ", od%cq1
  if (allocated(od%cq2))   write(iu,*) "cq2 = ", od%cq2
  if (allocated(od%cq3))   write(iu,*) "cq3 = ", od%cq3

  if (allocated(od%cq0R))  write(iu,*) "cq0R = ", od%cq0R
  if (allocated(od%cq1R))  write(iu,*) "cq1R = ", od%cq1R
  if (allocated(od%cq2R))  write(iu,*) "cq2R = ", od%cq2R
  if (allocated(od%cq3R))  write(iu,*) "cq3R = ", od%cq3R

  if (allocated(od%Isol))  write(iu,*) "Isol = ", od%Isol

  ! ---- 2D allocatable real arrays (clouds)

  if (allocated(od%Pbetaw)) then
     write(iu,*) "Pbetaw = "
     do i = 1, min(5,size(od%Pbetaw,1))
        write(iu,*) od%Pbetaw(i,1:min(5,size(od%Pbetaw,2)))
     end do
  end if

  if (allocated(od%Pomegaw)) then
     write(iu,*) "Pomegaw = "
     do i = 1, min(5,size(od%Pomegaw,1))
        write(iu,*) od%Pomegaw(i,1:min(5,size(od%Pomegaw,2)))
     end do
  end if

  if (allocated(od%Pbw)) then
     write(iu,*) "Pbw = "
     do i = 1, min(5,size(od%Pbw,1))
        write(iu,*) od%Pbw(i,1:min(5,size(od%Pbw,2)))
     end do
  end if

  if (allocated(od%Pbetai)) then
     write(iu,*) "Pbetai = "
     do i = 1, min(5,size(od%Pbetai,1))
        write(iu,*) od%Pbetai(i,1:min(5,size(od%Pbetai,2)))
     end do
  end if

  if (allocated(od%Pomegai)) then
     write(iu,*) "Pomegai = "
     do i = 1, min(5,size(od%Pomegai,1))
        write(iu,*) od%Pomegai(i,1:min(5,size(od%Pomegai,2)))
     end do
  end if

  if (allocated(od%Pbi)) then
     write(iu,*) "Pbi = "
     do i = 1, min(5,size(od%Pbi,1))
        write(iu,*) od%Pbi(i,1:min(5,size(od%Pbi,2)))
     end do
  end if

end subroutine print_od_iu

subroutine print_od_iu_secure(od, iu)

  use kinds
  use structures
  implicit none

  type(od_dbase), intent(in) :: od
  integer, intent(in) :: iu

  integer :: i, nmax

  !=========================================================
  ! SCALARS
  !=========================================================
  write(iu,*) "double_precision = ", od%double_precision
  write(iu,*) "noi = ", od%noi
  write(iu,*) "nof = ", od%nof
  write(iu,*) "v1cur = ", od%v1cur
  write(iu,*) "v2cur = ", od%v2cur
  write(iu,*) "wn_thresh = ", od%wn_thresh
  write(iu,*) "continuum_model = ", od%continuum_model

  write(iu,*) "nwhrbandmax = ", od%nwhrbandmax
  write(iu,*) "nwhrbandmaxR = ", od%nwhrbandmaxR

  write(iu,*) "nwvcur = ", od%nwvcur
  write(iu,*) "nqucur = ", od%nqucur
  write(iu,*) "szmax = ", od%szmax
  write(iu,*) "szmax2 = ", od%szmax2

  write(iu,*) "nwref = ", od%nwref
  write(iu,*) "nwcur = ", od%nwcur

  write(iu,*) "nwvcurR = ", od%nwvcurR
  write(iu,*) "nqucurR = ", od%nqucurR
  write(iu,*) "szmaxR = ", od%szmaxR
  write(iu,*) "szmax2R = ", od%szmax2R

  write(iu,*) "nx1awp = ", od%nx1awp
  write(iu,*) "nx1aip = ", od%nx1aip
  write(iu,*) "nx2awp = ", od%nx2awp
  write(iu,*) "nx2aip = ", od%nx2aip


  !=========================================================
  ! 1D INTEGER ARRAYS (LIMITED)
  !=========================================================
  if (allocated(od%npn)) then
     nmax = min(5, size(od%npn))
     write(iu,*) "npn (first values) = ", od%npn(1:nmax)
  end if

  if (allocated(od%point)) then
     nmax = min(5, size(od%point))
     write(iu,*) "point = ", od%point(1:nmax)
  end if

  if (allocated(od%quad)) then
     nmax = min(5, size(od%quad))
     write(iu,*) "quad = ", od%quad(1:nmax)
  end if


  if (allocated(od%npnR)) then
     nmax = min(5, size(od%npnR))
     write(iu,*) "npnR = ", od%npnR(1:nmax)
  end if

  if (allocated(od%pointR)) then
     nmax = min(5, size(od%pointR))
     write(iu,*) "pointR = ", od%pointR(1:nmax)
  end if

  if (allocated(od%quadR)) then
     nmax = min(5, size(od%quadR))
     write(iu,*) "quadR = ", od%quadR(1:nmax)
  end if


  !=========================================================
  ! 2D INTEGER ARRAYS (LIMITED)
  !=========================================================
  if (allocated(od%squad)) then
     write(iu,*) "squad (sample)"
     do i = 1, min(5, size(od%squad,1))
        write(iu,*) od%squad(i,1:min(5,size(od%squad,2)))
     end do
  end if

  if (allocated(od%equad)) then
     write(iu,*) "equad (sample)"
     do i = 1, min(5, size(od%equad,1))
        write(iu,*) od%equad(i,1:min(5,size(od%equad,2)))
     end do
  end if


  if (allocated(od%squadR)) then
     write(iu,*) "squadR (sample)"
     do i = 1, min(5, size(od%squadR,1))
        write(iu,*) od%squadR(i,1:min(5,size(od%squadR,2)))
     end do
  end if

  if (allocated(od%equadR)) then
     write(iu,*) "equadR (sample)"
     do i = 1, min(5, size(od%equadR,1))
        write(iu,*) od%equadR(i,1:min(5,size(od%equadR,2)))
     end do
  end if


  !=========================================================
  ! 1D REAL ARRAYS (LIMITED)
  !=========================================================
  if (allocated(od%cq0)) then
     nmax = min(5, size(od%cq0))
     write(iu,*) "cq0 = ", od%cq0(1:nmax)
  end if

  if (allocated(od%cq1)) then
     nmax = min(5, size(od%cq1))
     write(iu,*) "cq1 = ", od%cq1(1:nmax)
  end if

  if (allocated(od%cq2)) then
     nmax = min(5, size(od%cq2))
     write(iu,*) "cq2 = ", od%cq2(1:nmax)
  end if

  if (allocated(od%cq3)) then
     nmax = min(5, size(od%cq3))
     write(iu,*) "cq3 = ", od%cq3(1:nmax)
  end if


  if (allocated(od%cq0R)) then
     nmax = min(5, size(od%cq0R))
     write(iu,*) "cq0R = ", od%cq0R(1:nmax)
  end if

  if (allocated(od%cq1R)) then
     nmax = min(5, size(od%cq1R))
     write(iu,*) "cq1R = ", od%cq1R(1:nmax)
  end if

  if (allocated(od%cq2R)) then
     nmax = min(5, size(od%cq2R))
     write(iu,*) "cq2R = ", od%cq2R(1:nmax)
  end if

  if (allocated(od%cq3R)) then
     nmax = min(5, size(od%cq3R))
     write(iu,*) "cq3R = ", od%cq3R(1:nmax)
  end if


  if (allocated(od%Isol)) then
     nmax = min(5, size(od%Isol))
     write(iu,*) "Isol = ", od%Isol(1:nmax)
  end if


  !=========================================================
  ! 2D REAL ARRAYS (LIMITED)
  !=========================================================
  if (allocated(od%Pbetaw)) then
     write(iu,*) "Pbetaw (sample)"
     do i = 1, min(5, size(od%Pbetaw,1))
        write(iu,*) od%Pbetaw(i,1:min(5,size(od%Pbetaw,2)))
     end do
  end if

  if (allocated(od%Pomegaw)) then
     write(iu,*) "Pomegaw (sample)"
     do i = 1, min(5, size(od%Pomegaw,1))
        write(iu,*) od%Pomegaw(i,1:min(5,size(od%Pomegaw,2)))
     end do
  end if

  if (allocated(od%Pbw)) then
     write(iu,*) "Pbw (sample)"
     do i = 1, min(5, size(od%Pbw,1))
        write(iu,*) od%Pbw(i,1:min(5,size(od%Pbw,2)))
     end do
  end if

  if (allocated(od%Pbetai)) then
     write(iu,*) "Pbetai (sample)"
     do i = 1, min(5, size(od%Pbetai,1))
        write(iu,*) od%Pbetai(i,1:min(5,size(od%Pbetai,2)))
     end do
  end if

  if (allocated(od%Pomegai)) then
     write(iu,*) "Pomegai (sample)"
     do i = 1, min(5, size(od%Pomegai,1))
        write(iu,*) od%Pomegai(i,1:min(5,size(od%Pomegai,2)))
     end do
  end if

  if (allocated(od%Pbi)) then
     write(iu,*) "Pbi (sample)"
     do i = 1, min(5, size(od%Pbi,1))
        write(iu,*) od%Pbi(i,1:min(5,size(od%Pbi,2)))
     end do
  end if


end subroutine print_od_iu_secure

subroutine print_ufo_geoval_object(obj)
   use ufo_geovals_mod
   implicit none
 
   type(ufo_geoval), intent(in) :: obj
   integer :: i, j, nlevels, nprofiles

   nlevels=size(obj%vals,1)
   print *, nlevels


end subroutine print_ufo_geoval_object

subroutine linint_saf(rx, ry, ipro, rx1, ry1, ind)
  use structures

  implicit none
  real(kind=PREC), intent(in) :: rx(ipro), ry(ipro), rx1!saf pressure, saf temp., one target pressure
  real(kind=PREC), intent(out) :: ry1!interpolated temperature
  integer, intent(in) :: ipro
  integer, intent(out) :: ind
  integer :: j

  ! Check profile ordering
  if (rx(1) < rx(ipro)) then !ASCENDING VALUES
     ! ASCENDING ORDERING from lowest to highest
     !if the value to which interpolate is smaller than the first of the data one
     if (rx1 < rx(1)) then !rx1 is the pressure of the grid of reference to which we want interpolate ry1
        ! Profile extrapolated under first
        ry1 = ry(1) + ((ry(2) - ry(1)) / (rx(2) - rx(1))) * (rx1 - rx(1))
        ind = 1
        return
     end if
     ! Profile interpolated
     do j = 2, ipro
        if (rx1 <= rx(j)) then
           ry1 = ry(j-1) + ((ry(j) - ry(j-1)) / (rx(j) - rx(j-1))) * (rx1 - rx(j-1))
           ind = 0
           return
        end if
     end do
     ! Profile extrapolated over last
     ry1 = ry(ipro-1) + ((ry(ipro) - ry(ipro-1)) / (rx(ipro) - rx(ipro-1))) * (rx1 - rx(ipro-1))
     ind = 2
     return
  else
     ! DESCENDING ORDERING from highest to lowest: THIS IS THE COMMON SITUATION IN ORM  
     if (rx1 > rx(1)) then
        ! Profile extrapolated ABOVE
        ry1 = ry(1) + ((ry(2) - ry(1)) / (rx(2) - rx(1))) * (rx1 - rx(1))
        ind = 2
        return
     else if (rx1 < rx(ipro)) then!se sono oltre l'ultimo valore delle misure
        ! Profile extrapolated BELOW
        ry1 = ry(ipro-1) + ((ry(ipro) - ry(ipro-1)) / (rx(ipro) - rx(ipro-1))) * (rx1 - rx(ipro-1))
        ind = 1
        return
     else
        call find_interval(rx, ipro, rx1, j)
        ry1 = ry(j-1) + ((ry(j) - ry(j-1)) / (rx(j) - rx(j-1))) * (rx1 - rx(j-1))
        ind = 0
        return
     end if
  end if
end subroutine linint_saf

subroutine find_interval(z, n, z0, k)
  use structures
  implicit none
  integer, intent(in) :: n
  real(kind=PREC), intent(in) :: z(n), z0
  integer, intent(out) :: k
  integer :: i0, i1, ii

  i0 = 1; i1 = n; ii = (i0 + i1) / 2
  do
     if (z0 > z(ii)) then
        if (i0 == ii - 1) then
           k = ii
           return
        else
           i1 = ii
        end if
     else
        if (i1 == ii + 1) then
           k = i1
           return
        else
           i0 = ii
        end if
     end if
     ii = (i0 + i1) / 2
  end do
end subroutine find_interval

subroutine write_twoarrays_to_file(x,y,n,filename)
  use :: parameters, only : MAX_STRING_LENGTH, NWCUR, PREC, I32, R32, R64, WAT_OPT_FILE
  implicit none
  ! Arguments
  integer, intent(in) :: n                 ! Length of arrays
  real(kind=PREC), intent(in) :: x(n), y(n)   ! Arrays to print
  character(len=*), intent(in) :: filename ! Name of the output file

  ! Local variables
  integer :: i
  integer :: unit

  ! Open the file (unit automatically assigned)
  open(newunit=unit, file=filename, status='replace', action='write', &
       iostat=i)
  if (i /= 0) then
    print *, "Error opening file ", trim(filename)
    return
  end if

  ! Write header
  !write(unit, '(A)') '# Column1  Column2'

  ! Loop over array elements
  do i = 1, n
    write(unit, '(F15.6,1X,F15.6)') x(i), y(i)
  end do

  ! Close the file
  close(unit)

end subroutine write_twoarrays_to_file

subroutine from_rad_to_bt(rad, Tb)
   use structures
   use parameters
   implicit none

   type(radiances), intent(in) :: rad
   real(kind=PREC), allocatable, intent(out) :: Tb(:)
   ! Constants
   real(kind=PREC), parameter :: h = 6.62607015e-34  ! Planck constant [J·s]
   real(kind=PREC), parameter :: c = 2.99792458e10   ! Speed of light [cm/s]
   real(kind=PREC), parameter :: kB = 1.380649e-23   ! Boltzmann constant [J/K]
   integer :: i, n
   real(kind=PREC) :: nu, R
   if (.not. allocated(rad%R_lr) .or. .not. allocated(rad%wave_lr)) then
     print *, "Error: rad%R_lr or rad%wave_lr not allocated"
     return
   endif
   n = rad%I2-rad%I1+1 
   print *, n,"Elements we will save"
   print *, size(rad%wave_lr), "Lenght of wave_lr" !wave_lr from 1 to 7681
   print *, size(rad%R_lr),"Lenght of R_lr" !R_lr from 1 to 7681
   print *, "I print the whole wave_lr array"
   print *, rad%wave_lr(1), rad%wave_lr(rad%I1),rad%wave_lr(rad%I1+1), rad%wave_lr(rad%I2-2),rad%wave_lr(rad%I2-1), rad%wave_lr(rad%I2)
   !of these object we take 7655 elements
   if (allocated(rad%JT_lr)) then
      print *, "shape =", shape(rad%JT_lr)
      print *, "nrows =", size(rad%JT_lr,1)
      print *, "ncols =", size(rad%JT_lr,2)
   endif

   !of wave_lr from 1 to 7655
   !of R_lr from 14 to 7681
   allocate(Tb(n))
   do i = 1, n
     nu = rad%wave_lr(i)  ! wavenumber in cm^-1
     R  = rad%R_lr(rad%I1-1+i)     ! radiance

     ! Avoid division by zero or negative radiance
     if (R <= 0.0d0) then
        Tb(i) = 0.0d0
     else
        Tb(i) = (h*c*nu)/(kB*log(1.0d0 + (2.0d0*h*c**2*nu**3)/(R*0.0001)))!we need the radiance with cm^-2
     endif
   end do
   !print *, "CALCOLO 100 1.3204531"
   !print *, (h*100*c)/(kB*log(1.0d0 + (2.0d0*h*(100)**3*c**2)/(1.3204531e-02)))
end subroutine from_rad_to_bt

subroutine broadcast_od(od, comm)

use structures
use parameters
use fckit_mpi_module, only: fckit_mpi_comm
implicit none

type(od_dbase), intent(inout) :: od
type(fckit_mpi_comm), intent(in) :: comm

integer :: rank
integer :: n1, n2

!========================================================
! logical flags for allocatables, the array quantities
!========================================================
logical :: npn_alloc, point_alloc, squad_alloc, equad_alloc, quad_alloc
logical :: cq0_alloc, cq1_alloc, cq2_alloc, cq3_alloc
logical :: npnR_alloc, pointR_alloc, squadR_alloc, equadR_alloc, quadR_alloc
logical :: cq0R_alloc, cq1R_alloc, cq2R_alloc, cq3R_alloc
logical :: Pbetaw_alloc, Pomegaw_alloc, Pbw_alloc
logical :: Pbetai_alloc, Pomegai_alloc, Pbi_alloc
logical :: Isol_alloc
logical :: tmp_double_precision

rank = comm%rank()

!========================================================
! BROADCAST SCALARS
!========================================================

if (rank == 0) tmp_double_precision = od%double_precision
call comm%broadcast(tmp_double_precision, 0)
od%double_precision = tmp_double_precision

call comm%broadcast(od%noi,            0)
call comm%broadcast(od%nof,            0)
call comm%broadcast(od%v1cur,          0)
call comm%broadcast(od%v2cur,          0)
call comm%broadcast(od%wn_thresh,      0)
call comm%broadcast(od%continuum_model,0)
call comm%broadcast(od%nwhrbandmax,    0)
call comm%broadcast(od%nwhrbandmaxR,   0)
call comm%broadcast(od%nwvcur,         0)
call comm%broadcast(od%nqucur,         0)
call comm%broadcast(od%szmax,          0)
call comm%broadcast(od%szmax2,         0)
call comm%broadcast(od%nwref,          0)
call comm%broadcast(od%nwcur,          0)
call comm%broadcast(od%nwvcurR,        0)
call comm%broadcast(od%nqucurR,        0)
call comm%broadcast(od%szmaxR,         0)
call comm%broadcast(od%szmax2R,        0)
call comm%broadcast(od%nx1awp,         0)
call comm%broadcast(od%nx1aip,         0)
call comm%broadcast(od%nx2awp,         0)
call comm%broadcast(od%nx2aip,         0)

!========================================================
! allocation flags on root
!========================================================

if (rank == 0) then
   npn_alloc    = allocated(od%npn)
   point_alloc  = allocated(od%point)
   squad_alloc  = allocated(od%squad)
   equad_alloc  = allocated(od%equad)
   quad_alloc   = allocated(od%quad)
   cq0_alloc    = allocated(od%cq0)
   cq1_alloc    = allocated(od%cq1)
   cq2_alloc    = allocated(od%cq2)
   cq3_alloc    = allocated(od%cq3)
   npnR_alloc   = allocated(od%npnR)
   pointR_alloc = allocated(od%pointR)
   squadR_alloc = allocated(od%squadR)
   equadR_alloc = allocated(od%equadR)
   quadR_alloc  = allocated(od%quadR)
   cq0R_alloc   = allocated(od%cq0R)
   cq1R_alloc   = allocated(od%cq1R)
   cq2R_alloc   = allocated(od%cq2R)
   cq3R_alloc   = allocated(od%cq3R)
   Pbetaw_alloc  = allocated(od%Pbetaw)
   Pomegaw_alloc = allocated(od%Pomegaw)
   Pbw_alloc     = allocated(od%Pbw)
   Pbetai_alloc  = allocated(od%Pbetai)
   Pomegai_alloc = allocated(od%Pomegai)
   Pbi_alloc     = allocated(od%Pbi)
   Isol_alloc    = allocated(od%Isol)
endif

!========================================================
! broadcast allocation flags
!========================================================

call comm%broadcast(npn_alloc,    0)
call comm%broadcast(point_alloc,  0)
call comm%broadcast(squad_alloc,  0)
call comm%broadcast(equad_alloc,  0)
call comm%broadcast(quad_alloc,   0)
call comm%broadcast(cq0_alloc,    0)
call comm%broadcast(cq1_alloc,    0)
call comm%broadcast(cq2_alloc,    0)
call comm%broadcast(cq3_alloc,    0)
call comm%broadcast(npnR_alloc,   0)
call comm%broadcast(pointR_alloc, 0)
call comm%broadcast(squadR_alloc, 0)
call comm%broadcast(equadR_alloc, 0)
call comm%broadcast(quadR_alloc,  0)
call comm%broadcast(cq0R_alloc,   0)
call comm%broadcast(cq1R_alloc,   0)
call comm%broadcast(cq2R_alloc,   0)
call comm%broadcast(cq3R_alloc,   0)
call comm%broadcast(Pbetaw_alloc,  0)
call comm%broadcast(Pomegaw_alloc, 0)
call comm%broadcast(Pbw_alloc,     0)
call comm%broadcast(Pbetai_alloc,  0)
call comm%broadcast(Pomegai_alloc, 0)
call comm%broadcast(Pbi_alloc,     0)
call comm%broadcast(Isol_alloc,    0)

!========================================================
! npn
!========================================================

if (npn_alloc) then

   if (rank == 0) then
      n1 = size(od%npn)
   endif

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(od%npn)) deallocate(od%npn)

      allocate(od%npn(n1))

   endif

   call comm%broadcast(od%npn, 0)

endif

!========================================================
! point
!========================================================

if (point_alloc) then

   if (rank == 0) then
      n1 = size(od%point)
   endif

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(od%point)) deallocate(od%point)

      allocate(od%point(n1))

   endif

   call comm%broadcast(od%point, 0)

endif

!========================================================
! squad
!========================================================

if (squad_alloc) then

   if (rank == 0) then
      n1 = size(od%squad,1)
      n2 = size(od%squad,2)
   endif

   call comm%broadcast(n1, 0)
   call comm%broadcast(n2, 0)

   if (rank /= 0) then

      if (allocated(od%squad)) deallocate(od%squad)

      allocate(od%squad(n1,n2))

   endif

   call comm%broadcast(od%squad, 0)

endif

!========================================================
! equad
!========================================================

if (equad_alloc) then

   if (rank == 0) then
      n1 = size(od%equad,1)
      n2 = size(od%equad,2)
   endif

   call comm%broadcast(n1, 0)
   call comm%broadcast(n2, 0)

   if (rank /= 0) then

      if (allocated(od%equad)) deallocate(od%equad)

      allocate(od%equad(n1,n2))

   endif

   call comm%broadcast(od%equad, 0)

endif

!========================================================
! quad
!========================================================

if (quad_alloc) then

   if (rank == 0) then
      n1 = size(od%quad)
   endif

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(od%quad)) deallocate(od%quad)

      allocate(od%quad(n1))

   endif

   call comm%broadcast(od%quad, 0)

endif

!========================================================
! cq arrays
!========================================================

if (cq0_alloc) then

   if (rank == 0) n1 = size(od%cq0)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq0)) deallocate(od%cq0)

      allocate(od%cq0(n1))

   endif

   call comm%broadcast(od%cq0,0)

endif

if (cq1_alloc) then

   if (rank == 0) n1 = size(od%cq1)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq1)) deallocate(od%cq1)

      allocate(od%cq1(n1))

   endif

   call comm%broadcast(od%cq1,0)

endif

if (cq2_alloc) then

   if (rank == 0) n1 = size(od%cq2)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq2)) deallocate(od%cq2)

      allocate(od%cq2(n1))

   endif

   call comm%broadcast(od%cq2,0)

endif

if (cq3_alloc) then

   if (rank == 0) n1 = size(od%cq3)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq3)) deallocate(od%cq3)

      allocate(od%cq3(n1))

   endif

   call comm%broadcast(od%cq3,0)

endif

!========================================================
! npnR
!========================================================

if (npnR_alloc) then

   if (rank == 0) n1 = size(od%npnR)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%npnR)) deallocate(od%npnR)

      allocate(od%npnR(n1))

   endif

   call comm%broadcast(od%npnR,0)

endif

!========================================================
! pointR
!========================================================

if (pointR_alloc) then

   if (rank == 0) n1 = size(od%pointR)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%pointR)) deallocate(od%pointR)

      allocate(od%pointR(n1))

   endif

   call comm%broadcast(od%pointR,0)

endif

!========================================================
! squadR
!========================================================

if (squadR_alloc) then

   if (rank == 0) then
      n1 = size(od%squadR,1)
      n2 = size(od%squadR,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%squadR)) deallocate(od%squadR)

      allocate(od%squadR(n1,n2))

   endif

   call comm%broadcast(od%squadR,0)

endif

!========================================================
! equadR
!========================================================

if (equadR_alloc) then

   if (rank == 0) then
      n1 = size(od%equadR,1)
      n2 = size(od%equadR,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%equadR)) deallocate(od%equadR)

      allocate(od%equadR(n1,n2))

   endif

   call comm%broadcast(od%equadR,0)

endif

!========================================================
! quadR
!========================================================

if (quadR_alloc) then

   if (rank == 0) n1 = size(od%quadR)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%quadR)) deallocate(od%quadR)

      allocate(od%quadR(n1))

   endif

   call comm%broadcast(od%quadR,0)

endif

!========================================================
! cq0R
!========================================================

if (cq0R_alloc) then

   if (rank == 0) n1 = size(od%cq0R)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq0R)) deallocate(od%cq0R)

      allocate(od%cq0R(n1))

   endif

   call comm%broadcast(od%cq0R,0)

endif

!========================================================
! cq1R
!========================================================

if (cq1R_alloc) then

   if (rank == 0) n1 = size(od%cq1R)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq1R)) deallocate(od%cq1R)

      allocate(od%cq1R(n1))

   endif

   call comm%broadcast(od%cq1R,0)

endif

!========================================================
! cq2R
!========================================================

if (cq2R_alloc) then

   if (rank == 0) n1 = size(od%cq2R)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq2R)) deallocate(od%cq2R)

      allocate(od%cq2R(n1))

   endif

   call comm%broadcast(od%cq2R,0)

endif

!========================================================
! cq3R
!========================================================

if (cq3R_alloc) then

   if (rank == 0) n1 = size(od%cq3R)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(od%cq3R)) deallocate(od%cq3R)

      allocate(od%cq3R(n1))

   endif

   call comm%broadcast(od%cq3R,0)

endif

!========================================================
! Pbetaw
!========================================================

if (Pbetaw_alloc) then

   if (rank == 0) then
      n1 = size(od%Pbetaw,1)
      n2 = size(od%Pbetaw,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%Pbetaw)) deallocate(od%Pbetaw)

      allocate(od%Pbetaw(n1,n2))

   endif

   call comm%broadcast(od%Pbetaw,0)

endif

!========================================================
! Pomegaw
!========================================================

if (Pomegaw_alloc) then

   if (rank == 0) then
      n1 = size(od%Pomegaw,1)
      n2 = size(od%Pomegaw,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%Pomegaw)) deallocate(od%Pomegaw)

      allocate(od%Pomegaw(n1,n2))

   endif

   call comm%broadcast(od%Pomegaw,0)

endif

!========================================================
! Pbw
!========================================================

if (Pbw_alloc) then

   if (rank == 0) then
      n1 = size(od%Pbw,1)
      n2 = size(od%Pbw,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%Pbw)) deallocate(od%Pbw)

      allocate(od%Pbw(n1,n2))

   endif

   call comm%broadcast(od%Pbw,0)

endif

!========================================================
! Pbetai
!========================================================

if (Pbetai_alloc) then

   if (rank == 0) then
      n1 = size(od%Pbetai,1)
      n2 = size(od%Pbetai,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%Pbetai)) deallocate(od%Pbetai)

      allocate(od%Pbetai(n1,n2))

   endif

   call comm%broadcast(od%Pbetai,0)

endif

!========================================================
! Pomegai
!========================================================

if (Pomegai_alloc) then

   if (rank == 0) then
      n1 = size(od%Pomegai,1)
      n2 = size(od%Pomegai,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%Pomegai)) deallocate(od%Pomegai)

      allocate(od%Pomegai(n1,n2))

   endif

   call comm%broadcast(od%Pomegai,0)

endif

!========================================================
! Pbi
!========================================================

if (Pbi_alloc) then

   if (rank == 0) then
      n1 = size(od%Pbi,1)
      n2 = size(od%Pbi,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(od%Pbi)) deallocate(od%Pbi)

      allocate(od%Pbi(n1,n2))

   endif

   call comm%broadcast(od%Pbi,0)

endif

!========================================================
! Isol
!========================================================

if (Isol_alloc) then

   if (rank == 0) then
      n1 = size(od%Isol)
   endif

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(od%Isol)) deallocate(od%Isol)

      allocate(od%Isol(n1))

   endif

   call comm%broadcast(od%Isol, 0)

endif

print *, "Rank ", rank, " completed broadcast_od"

end subroutine broadcast_od

subroutine broadcast_rad(rad, comm)

use structures
use parameters
use fckit_mpi_module, only : fckit_mpi_comm

implicit none

type(radiances), intent(inout) :: rad
type(fckit_mpi_comm), intent(in) :: comm
type(contnm_variable) :: con_local

integer :: rank
integer :: n1, n2

!========================================================
! allocation flags
!========================================================

logical :: wave_lr_alloc, wave_hr_alloc, wave_hrc_alloc
logical :: dumttorad_alloc, RADr_alloc, wREF_alloc, RADrHR_alloc

logical :: ttpR_alloc, poldtsR_alloc, poldtsRhr_alloc
logical :: ttr_alloc, ttrHR_alloc
logical :: tt_alloc, ttc_alloc, ttp_alloc, ttcp_alloc
logical :: Taus_alloc, tts_alloc

logical :: dtauwr_alloc, dtauir_alloc
logical :: kextwath_alloc, kexticeh_alloc

logical :: RADa_alloc, RADaC_alloc
logical :: bndemi_alloc
logical :: poldts_cl_alloc, poldts_alloc

logical :: rDIR_alloc, rSURlr_alloc, rDIRlr_alloc

logical :: R_lr_alloc
logical :: R_hr_alloc, T_hr_alloc

logical :: JT_lr_alloc, JH2O_lr_alloc, JCO2_lr_alloc
logical :: JO3_lr_alloc, JN2O_lr_alloc, JCO_lr_alloc
logical :: JCH4_lr_alloc, JSO2_lr_alloc, JHNO3_lr_alloc
logical :: JNH3_lr_alloc, JOCS_lr_alloc, JHDO_lr_alloc
logical :: JCF4_lr_alloc, JMXGAS_lr_alloc

logical :: JTS_lr_alloc, JEM_lr_alloc, JEMC_lr_alloc
logical :: JTC_lr_alloc

logical :: JCSELF_lr_alloc, JCFORE_lr_alloc, JCCO2_lr_alloc

logical :: JCLD_LIQ_con_lr_alloc, JCLD_LIQ_rad_lr_alloc
logical :: JCLD_ICE_con_lr_alloc, JCLD_ICE_rad_lr_alloc

logical :: JSW_lr_alloc

logical :: JT_hr_alloc, JH2O_hr_alloc, JCO2_hr_alloc
logical :: JO3_hr_alloc, JN2O_hr_alloc, JCO_hr_alloc
logical :: JCH4_hr_alloc, JSO2_hr_alloc, JHNO3_hr_alloc
logical :: JNH3_hr_alloc, JOCS_hr_alloc, JHDO_hr_alloc
logical :: JCF4_hr_alloc, JMXGAS_hr_alloc

logical :: JTS_hr_alloc, JEM_hr_alloc, JEMC_hr_alloc
logical :: JTC_hr_alloc

logical :: JCSELF_hr_alloc, JCFORE_hr_alloc, JCCO2_hr_alloc

logical :: JCLD_LIQ_con_hr_alloc, JCLD_LIQ_rad_hr_alloc
logical :: JCLD_ICE_con_hr_alloc, JCLD_ICE_rad_hr_alloc

logical :: JSW_hr_alloc

rank = comm%rank()

!========================================================
! BROADCAST SCALARS
!========================================================

call comm%broadcast(rad%nlrmax, 0)
call comm%broadcast(rad%nlr,    0)
call comm%broadcast(rad%nhr,    0)
call comm%broadcast(rad%nref,   0)

call comm%broadcast(rad%I1,     0)
call comm%broadcast(rad%I2,     0)

call comm%broadcast(rad%I1hr,   0)
call comm%broadcast(rad%I2hr,   0)

call comm%broadcast(rad%I1ref,  0)
call comm%broadcast(rad%I2ref,  0)

call comm%broadcast(rad%I1hrc,  0)
call comm%broadcast(rad%I2hrc,  0)

call comm%broadcast(rad%I1refc, 0)
call comm%broadcast(rad%I2refc, 0)

call comm%broadcast(rad%ntot_hr,   0)
call comm%broadcast(rad%ntot_hrc,  0)
call comm%broadcast(rad%ntot_lr,   0)
call comm%broadcast(rad%ntot_ref,  0)
call comm%broadcast(rad%ntot_refc, 0)

!========================================================
! contnm_variable
!========================================================

if (rank == 0) con_local = rad%con

call comm%broadcast(con_local%v1cur,   0)
call comm%broadcast(con_local%v2cur,   0)
call comm%broadcast(con_local%V1ABS,   0)
call comm%broadcast(con_local%V2ABS,   0)

call comm%broadcast(con_local%NPTABS,  0)
call comm%broadcast(con_local%DVABS,   0)

call comm%broadcast(con_local%XSELF,   0)
call comm%broadcast(con_local%XFRGN,   0)
call comm%broadcast(con_local%XCO2C,   0)
call comm%broadcast(con_local%XO3CN,   0)
call comm%broadcast(con_local%XO2CN,   0)
call comm%broadcast(con_local%XN2CN,   0)
call comm%broadcast(con_local%XRAYL,   0)

if (rank /= 0) rad%con = con_local

!========================================================
! allocation flags on root
!========================================================

if (rank == 0) then

   wave_lr_alloc = allocated(rad%wave_lr)
   wave_hr_alloc = allocated(rad%wave_hr)
   wave_hrc_alloc = allocated(rad%wave_hrc)

   dumttorad_alloc = allocated(rad%dumttorad)
   RADr_alloc      = allocated(rad%RADr)
   wREF_alloc      = allocated(rad%wREF)
   RADrHR_alloc    = allocated(rad%RADrHR)

   ttpR_alloc      = allocated(rad%ttpR)
   poldtsR_alloc   = allocated(rad%poldtsR)
   poldtsRhr_alloc = allocated(rad%poldtsRhr)

   ttr_alloc       = allocated(rad%ttr)
   ttrHR_alloc     = allocated(rad%ttrHR)

   tt_alloc        = allocated(rad%tt)
   ttc_alloc       = allocated(rad%ttc)
   ttp_alloc       = allocated(rad%ttp)
   ttcp_alloc      = allocated(rad%ttcp)

   Taus_alloc      = allocated(rad%Taus)
   tts_alloc       = allocated(rad%tts)

   dtauwr_alloc    = allocated(rad%dtauwr)
   dtauir_alloc    = allocated(rad%dtauir)

   kextwath_alloc  = allocated(rad%kextwath)
   kexticeh_alloc  = allocated(rad%kexticeh)

   RADa_alloc      = allocated(rad%RADa)
   RADaC_alloc     = allocated(rad%RADaC)

   bndemi_alloc    = allocated(rad%bndemi)

   poldts_cl_alloc = allocated(rad%poldts_cl)
   poldts_alloc    = allocated(rad%poldts)

   rDIR_alloc      = allocated(rad%rDIR)
   rSURlr_alloc    = allocated(rad%rSURlr)
   rDIRlr_alloc    = allocated(rad%rDIRlr)

   R_lr_alloc      = allocated(rad%R_lr)

   R_hr_alloc      = allocated(rad%R_hr)
   T_hr_alloc      = allocated(rad%T_hr)

   JT_lr_alloc     = allocated(rad%JT_lr)
   JH2O_lr_alloc   = allocated(rad%JH2O_lr)
   JCO2_lr_alloc   = allocated(rad%JCO2_lr)
   JO3_lr_alloc    = allocated(rad%JO3_lr)
   JN2O_lr_alloc   = allocated(rad%JN2O_lr)
   JCO_lr_alloc    = allocated(rad%JCO_lr)
   JCH4_lr_alloc   = allocated(rad%JCH4_lr)
   JSO2_lr_alloc   = allocated(rad%JSO2_lr)
   JHNO3_lr_alloc  = allocated(rad%JHNO3_lr)
   JNH3_lr_alloc   = allocated(rad%JNH3_lr)
   JOCS_lr_alloc   = allocated(rad%JOCS_lr)
   JHDO_lr_alloc   = allocated(rad%JHDO_lr)
   JCF4_lr_alloc   = allocated(rad%JCF4_lr)
   JMXGAS_lr_alloc = allocated(rad%JMXGAS_lr)

   JTS_lr_alloc   = allocated(rad%JTS_lr)
   JEM_lr_alloc   = allocated(rad%JEM_lr)
   JEMC_lr_alloc  = allocated(rad%JEMC_lr)
   JTC_lr_alloc   = allocated(rad%JTC_lr)

   JCSELF_lr_alloc = allocated(rad%JCSELF_lr)
   JCFORE_lr_alloc = allocated(rad%JCFORE_lr)
   JCCO2_lr_alloc  = allocated(rad%JCCO2_lr)
   JCLD_LIQ_con_lr_alloc = allocated(rad%JCLD_LIQ_con_lr)
   JCLD_LIQ_rad_lr_alloc = allocated(rad%JCLD_LIQ_rad_lr)
   JCLD_ICE_con_lr_alloc = allocated(rad%JCLD_ICE_con_lr)
   JCLD_ICE_rad_lr_alloc = allocated(rad%JCLD_ICE_rad_lr)

   JSW_lr_alloc   = allocated(rad%JSW_lr)

   JT_hr_alloc     = allocated(rad%JT_hr)
   JH2O_hr_alloc   = allocated(rad%JH2O_hr)
   JCO2_hr_alloc   = allocated(rad%JCO2_hr)
   JO3_hr_alloc    = allocated(rad%JO3_hr)
   JN2O_hr_alloc   = allocated(rad%JN2O_hr)
   JCO_hr_alloc    = allocated(rad%JCO_hr)
   JCH4_hr_alloc   = allocated(rad%JCH4_hr)
   JSO2_hr_alloc   = allocated(rad%JSO2_hr)
   JHNO3_hr_alloc  = allocated(rad%JHNO3_hr)
   JNH3_hr_alloc   = allocated(rad%JNH3_hr)
   JOCS_hr_alloc   = allocated(rad%JOCS_hr)
   JHDO_hr_alloc   = allocated(rad%JHDO_hr)
   JCF4_hr_alloc   = allocated(rad%JCF4_hr)
   JMXGAS_hr_alloc = allocated(rad%JMXGAS_hr)

   JTS_hr_alloc   = allocated(rad%JTS_hr)
   JEM_hr_alloc   = allocated(rad%JEM_hr)
   JEMC_hr_alloc  = allocated(rad%JEMC_hr)
   JTC_hr_alloc   = allocated(rad%JTC_hr)

   JCSELF_hr_alloc = allocated(rad%JCSELF_hr)
   JCFORE_hr_alloc = allocated(rad%JCFORE_hr)
   JCCO2_hr_alloc  = allocated(rad%JCCO2_hr)
   JCLD_LIQ_con_hr_alloc = allocated(rad%JCLD_LIQ_con_hr)
   JCLD_LIQ_rad_hr_alloc = allocated(rad%JCLD_LIQ_rad_hr)
   JCLD_ICE_con_hr_alloc = allocated(rad%JCLD_ICE_con_hr)
   JCLD_ICE_rad_hr_alloc = allocated(rad%JCLD_ICE_rad_hr)

   JSW_hr_alloc   = allocated(rad%JSW_hr)


endif

!========================================================
! broadcast allocation flags
!========================================================

call comm%broadcast(wave_lr_alloc, 0)
call comm%broadcast(wave_hr_alloc, 0)
call comm%broadcast(wave_hrc_alloc,0)

call comm%broadcast(dumttorad_alloc,0)
call comm%broadcast(RADr_alloc,0)
call comm%broadcast(wREF_alloc,0)
call comm%broadcast(RADrHR_alloc,0)

call comm%broadcast(ttpR_alloc,0)
call comm%broadcast(poldtsR_alloc,0)
call comm%broadcast(poldtsRhr_alloc,0)

call comm%broadcast(ttr_alloc,0)
call comm%broadcast(ttrHR_alloc,0)

call comm%broadcast(tt_alloc,0)
call comm%broadcast(ttc_alloc,0)
call comm%broadcast(ttp_alloc,0)
call comm%broadcast(ttcp_alloc,0)

call comm%broadcast(Taus_alloc,0)
call comm%broadcast(tts_alloc,0)

call comm%broadcast(dtauwr_alloc,0)
call comm%broadcast(dtauir_alloc,0)

call comm%broadcast(kextwath_alloc,0)
call comm%broadcast(kexticeh_alloc,0)

call comm%broadcast(RADa_alloc,0)
call comm%broadcast(RADaC_alloc,0)

call comm%broadcast(bndemi_alloc,0)

call comm%broadcast(poldts_cl_alloc,0)
call comm%broadcast(poldts_alloc,0)

call comm%broadcast(rDIR_alloc,0)
call comm%broadcast(rSURlr_alloc,0)
call comm%broadcast(rDIRlr_alloc,0)

call comm%broadcast(R_lr_alloc,0)

call comm%broadcast(R_hr_alloc,0)
call comm%broadcast(T_hr_alloc,0)

!========================================================
! broadcast allocation flags (J* last variables) 1D
!========================================================

call comm%broadcast(JTS_lr_alloc, 0)
call comm%broadcast(JEM_lr_alloc, 0)
call comm%broadcast(JEMC_lr_alloc, 0)
call comm%broadcast(JTC_lr_alloc, 0)
call comm%broadcast(JSW_lr_alloc, 0)

call comm%broadcast(JTS_hr_alloc, 0)
call comm%broadcast(JEM_hr_alloc, 0)
call comm%broadcast(JEMC_hr_alloc, 0)
call comm%broadcast(JTC_hr_alloc, 0)
call comm%broadcast(JSW_hr_alloc, 0)

!========================================================
! broadcast allocation flags (J* last variables) 2D
!========================================================

!==================== LR ====================

call comm%broadcast(JT_lr_alloc, 0)
call comm%broadcast(JH2O_lr_alloc, 0)
call comm%broadcast(JCO2_lr_alloc, 0)
call comm%broadcast(JO3_lr_alloc, 0)
call comm%broadcast(JN2O_lr_alloc, 0)
call comm%broadcast(JCO_lr_alloc, 0)
call comm%broadcast(JCH4_lr_alloc, 0)
call comm%broadcast(JSO2_lr_alloc, 0)
call comm%broadcast(JHNO3_lr_alloc, 0)
call comm%broadcast(JNH3_lr_alloc, 0)
call comm%broadcast(JOCS_lr_alloc, 0)
call comm%broadcast(JHDO_lr_alloc, 0)
call comm%broadcast(JCF4_lr_alloc, 0)
call comm%broadcast(JMXGAS_lr_alloc, 0)

call comm%broadcast(JCSELF_lr_alloc, 0)
call comm%broadcast(JCFORE_lr_alloc, 0)
call comm%broadcast(JCCO2_lr_alloc, 0)

call comm%broadcast(JCLD_LIQ_con_lr_alloc, 0)
call comm%broadcast(JCLD_LIQ_rad_lr_alloc, 0)
call comm%broadcast(JCLD_ICE_con_lr_alloc, 0)
call comm%broadcast(JCLD_ICE_rad_lr_alloc, 0)


!==================== HR ====================

call comm%broadcast(JT_hr_alloc, 0)
call comm%broadcast(JH2O_hr_alloc, 0)
call comm%broadcast(JCO2_hr_alloc, 0)
call comm%broadcast(JO3_hr_alloc, 0)
call comm%broadcast(JN2O_hr_alloc, 0)
call comm%broadcast(JCO_hr_alloc, 0)
call comm%broadcast(JCH4_hr_alloc, 0)
call comm%broadcast(JSO2_hr_alloc, 0)
call comm%broadcast(JHNO3_hr_alloc, 0)
call comm%broadcast(JNH3_hr_alloc, 0)
call comm%broadcast(JOCS_hr_alloc, 0)
call comm%broadcast(JHDO_hr_alloc, 0)
call comm%broadcast(JCF4_hr_alloc, 0)
call comm%broadcast(JMXGAS_hr_alloc, 0)

call comm%broadcast(JCSELF_hr_alloc, 0)
call comm%broadcast(JCFORE_hr_alloc, 0)
call comm%broadcast(JCCO2_hr_alloc, 0)

call comm%broadcast(JCLD_LIQ_con_hr_alloc, 0)
call comm%broadcast(JCLD_LIQ_rad_hr_alloc, 0)
call comm%broadcast(JCLD_ICE_con_hr_alloc, 0)
call comm%broadcast(JCLD_ICE_rad_hr_alloc, 0)

!========================================================
! wave_lr
!========================================================

if (wave_lr_alloc) then

   if (rank == 0) n1 = size(rad%wave_lr)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(rad%wave_lr)) deallocate(rad%wave_lr)

      allocate(rad%wave_lr(n1))

   endif

   call comm%broadcast(rad%wave_lr,0)

endif

!========================================================
! wave_hr
!========================================================

if (wave_hr_alloc) then

   if (rank == 0) n1 = size(rad%wave_hr)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(rad%wave_hr)) deallocate(rad%wave_hr)

      allocate(rad%wave_hr(n1))

   endif

   call comm%broadcast(rad%wave_hr,0)

endif

!========================================================
! wave_hrc
!========================================================

if (wave_hrc_alloc) then

   if (rank == 0) n1 = size(rad%wave_hrc)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(rad%wave_hrc)) deallocate(rad%wave_hrc)

      allocate(rad%wave_hrc(n1))

   endif

   call comm%broadcast(rad%wave_hrc,0)

endif

!========================================================
! dumttorad
!========================================================

if (dumttorad_alloc) then

   if (rank == 0) n1 = size(rad%dumttorad)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%dumttorad)) deallocate(rad%dumttorad)
      allocate(rad%dumttorad(n1))
   endif

   call comm%broadcast(rad%dumttorad, 0)

endif

!========================================================
! RADr
!========================================================

if (RADr_alloc) then

   if (rank == 0) n1 = size(rad%RADr)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(rad%RADr)) deallocate(rad%RADr)

      allocate(rad%RADr(n1))

   endif

   call comm%broadcast(rad%RADr,0)

endif

!========================================================
! wREF
!========================================================

if (wREF_alloc) then

   if (rank == 0) n1 = size(rad%wREF)

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(rad%wREF)) deallocate(rad%wREF)

      allocate(rad%wREF(n1))

   endif

   call comm%broadcast(rad%wREF,0)

endif

!========================================================
! RADrHR
!========================================================

if (RADrHR_alloc) then

   if (rank == 0) n1 = size(rad%RADrHR)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%RADrHR)) deallocate(rad%RADrHR)

      allocate(rad%RADrHR(n1))

   endif

   call comm%broadcast(rad%RADrHR, 0)

endif

!========================================================
! tts
!========================================================

if (tts_alloc) then

   if (rank == 0) n1 = size(rad%tts)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%tts)) deallocate(rad%tts)

      allocate(rad%tts(n1))

   endif

   call comm%broadcast(rad%tts, 0)

endif

!========================================================
! RADa
!========================================================

if (RADa_alloc) then

   if (rank == 0) n1 = size(rad%RADa)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%RADa)) deallocate(rad%RADa)

      allocate(rad%RADa(n1))

   endif

   call comm%broadcast(rad%RADa, 0)

endif

!========================================================
! RADaC
!========================================================

if (RADaC_alloc) then

   if (rank == 0) n1 = size(rad%RADaC)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%RADaC)) deallocate(rad%RADaC)

      allocate(rad%RADaC(n1))

   endif

   call comm%broadcast(rad%RADaC, 0)

endif

!========================================================
! bndemi
!========================================================

if (bndemi_alloc) then

   if (rank == 0) n1 = size(rad%bndemi)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%bndemi)) deallocate(rad%bndemi)

      allocate(rad%bndemi(n1))

   endif

   call comm%broadcast(rad%bndemi, 0)

endif

!========================================================
! rDIR
!========================================================

if (rDIR_alloc) then

   if (rank == 0) n1 = size(rad%rDIR)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%rDIR)) deallocate(rad%rDIR)

      allocate(rad%rDIR(n1))

   endif

   call comm%broadcast(rad%rDIR, 0)

endif

!========================================================
! rSURlr
!========================================================

if (rSURlr_alloc) then

   if (rank == 0) n1 = size(rad%rSURlr)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%rSURlr)) deallocate(rad%rSURlr)

      allocate(rad%rSURlr(n1))

   endif

   call comm%broadcast(rad%rSURlr, 0)

endif

!========================================================
! rDIRlr
!========================================================

if (rDIRlr_alloc) then

   if (rank == 0) n1 = size(rad%rDIRlr)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%rDIRlr)) deallocate(rad%rDIRlr)

      allocate(rad%rDIRlr(n1))

   endif

   call comm%broadcast(rad%rDIRlr, 0)

endif

!========================================================
! R_lr
!========================================================

if (R_lr_alloc) then

   if (rank == 0) n1 = size(rad%R_lr)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%R_lr)) deallocate(rad%R_lr)

      allocate(rad%R_lr(n1))

   endif

   call comm%broadcast(rad%R_lr, 0)

endif

!========================================================
! R_hr
!========================================================

if (R_hr_alloc) then

   if (rank == 0) n1 = size(rad%R_hr)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%R_hr)) deallocate(rad%R_hr)

      allocate(rad%R_hr(n1))

   endif

   call comm%broadcast(rad%R_hr, 0)

endif

!========================================================
! T_hr
!========================================================

if (T_hr_alloc) then

   if (rank == 0) n1 = size(rad%T_hr)

   call comm%broadcast(n1, 0)

   if (rank /= 0) then

      if (allocated(rad%T_hr)) deallocate(rad%T_hr)

      allocate(rad%T_hr(n1))

   endif

   call comm%broadcast(rad%T_hr, 0)

endif

!========================================================
! J* arrays (1D)
!========================================================
!==================== JTS_lr ====================
if (JTS_lr_alloc) then

   if (rank == 0) n1 = size(rad%JTS_lr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JTS_lr)) deallocate(rad%JTS_lr)
      allocate(rad%JTS_lr(n1))
   endif

   call comm%broadcast(rad%JTS_lr, 0)

endif


!==================== JEM_lr ====================
if (JEM_lr_alloc) then

   if (rank == 0) n1 = size(rad%JEM_lr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JEM_lr)) deallocate(rad%JEM_lr)
      allocate(rad%JEM_lr(n1))
   endif

   call comm%broadcast(rad%JEM_lr, 0)

endif


!==================== JEMC_lr ====================
if (JEMC_lr_alloc) then

   if (rank == 0) n1 = size(rad%JEMC_lr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JEMC_lr)) deallocate(rad%JEMC_lr)
      allocate(rad%JEMC_lr(n1))
   endif

   call comm%broadcast(rad%JEMC_lr, 0)

endif


!==================== JTC_lr ====================
if (JTC_lr_alloc) then

   if (rank == 0) n1 = size(rad%JTC_lr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JTC_lr)) deallocate(rad%JTC_lr)
      allocate(rad%JTC_lr(n1))
   endif

   call comm%broadcast(rad%JTC_lr, 0)

endif


!==================== JSW_lr ====================
if (JSW_lr_alloc) then

   if (rank == 0) n1 = size(rad%JSW_lr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JSW_lr)) deallocate(rad%JSW_lr)
      allocate(rad%JSW_lr(n1))
   endif

   call comm%broadcast(rad%JSW_lr, 0)

endif


!==================== HR ====================

if (JTS_hr_alloc) then

   if (rank == 0) n1 = size(rad%JTS_hr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JTS_hr)) deallocate(rad%JTS_hr)
      allocate(rad%JTS_hr(n1))
   endif

   call comm%broadcast(rad%JTS_hr, 0)

endif


if (JEM_hr_alloc) then

   if (rank == 0) n1 = size(rad%JEM_hr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JEM_hr)) deallocate(rad%JEM_hr)
      allocate(rad%JEM_hr(n1))
   endif

   call comm%broadcast(rad%JEM_hr, 0)

endif


if (JEMC_hr_alloc) then

   if (rank == 0) n1 = size(rad%JEMC_hr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JEMC_hr)) deallocate(rad%JEMC_hr)
      allocate(rad%JEMC_hr(n1))
   endif

   call comm%broadcast(rad%JEMC_hr, 0)

endif


if (JTC_hr_alloc) then

   if (rank == 0) n1 = size(rad%JTC_hr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JTC_hr)) deallocate(rad%JTC_hr)
      allocate(rad%JTC_hr(n1))
   endif

   call comm%broadcast(rad%JTC_hr, 0)

endif


if (JSW_hr_alloc) then

   if (rank == 0) n1 = size(rad%JSW_hr)
   call comm%broadcast(n1, 0)

   if (rank /= 0) then
      if (allocated(rad%JSW_hr)) deallocate(rad%JSW_hr)
      allocate(rad%JSW_hr(n1))
   endif

   call comm%broadcast(rad%JSW_hr, 0)

endif

!=====qui i 2D==============
!========================================================
! ttpR
!========================================================

if (ttpR_alloc) then

   if (rank == 0) then
      n1 = size(rad%ttpR,1)
      n2 = size(rad%ttpR,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then

      if (allocated(rad%ttpR)) deallocate(rad%ttpR)

      allocate(rad%ttpR(n1,n2))

   endif

   call comm%broadcast(rad%ttpR,0)

endif

!========================================================
! poldtsR
!========================================================
if (poldtsR_alloc) then

   if (rank == 0) then
      n1 = size(rad%poldtsR,1)
      n2 = size(rad%poldtsR,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%poldtsR)) deallocate(rad%poldtsR)
      allocate(rad%poldtsR(n1,n2))
   endif

   call comm%broadcast(rad%poldtsR,0)

endif


!========================================================
! poldtsRhr
!========================================================
if (poldtsRhr_alloc) then

   if (rank == 0) then
      n1 = size(rad%poldtsRhr,1)
      n2 = size(rad%poldtsRhr,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%poldtsRhr)) deallocate(rad%poldtsRhr)
      allocate(rad%poldtsRhr(n1,n2))
   endif

   call comm%broadcast(rad%poldtsRhr,0)

endif


!========================================================
! ttr
!========================================================
if (ttr_alloc) then

   if (rank == 0) then
      n1 = size(rad%ttr,1)
      n2 = size(rad%ttr,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%ttr)) deallocate(rad%ttr)
      allocate(rad%ttr(n1,n2))
   endif

   call comm%broadcast(rad%ttr,0)

endif


!========================================================
! ttrHR
!========================================================
if (ttrHR_alloc) then

   if (rank == 0) then
      n1 = size(rad%ttrHR,1)
      n2 = size(rad%ttrHR,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%ttrHR)) deallocate(rad%ttrHR)
      allocate(rad%ttrHR(n1,n2))
   endif

   call comm%broadcast(rad%ttrHR,0)

endif


!========================================================
! tt
!========================================================
if (tt_alloc) then

   if (rank == 0) then
      n1 = size(rad%tt,1)
      n2 = size(rad%tt,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%tt)) deallocate(rad%tt)
      allocate(rad%tt(n1,n2))
   endif

   call comm%broadcast(rad%tt,0)

endif


!========================================================
! ttc
!========================================================
if (ttc_alloc) then

   if (rank == 0) then
      n1 = size(rad%ttc,1)
      n2 = size(rad%ttc,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%ttc)) deallocate(rad%ttc)
      allocate(rad%ttc(n1,n2))
   endif

   call comm%broadcast(rad%ttc,0)

endif


!========================================================
! ttp
!========================================================
if (ttp_alloc) then

   if (rank == 0) then
      n1 = size(rad%ttp,1)
      n2 = size(rad%ttp,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%ttp)) deallocate(rad%ttp)
      allocate(rad%ttp(n1,n2))
   endif

   call comm%broadcast(rad%ttp,0)

endif


!========================================================
! ttcp
!========================================================
if (ttcp_alloc) then

   if (rank == 0) then
      n1 = size(rad%ttcp,1)
      n2 = size(rad%ttcp,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%ttcp)) deallocate(rad%ttcp)
      allocate(rad%ttcp(n1,n2))
   endif

   call comm%broadcast(rad%ttcp,0)

endif


!========================================================
! Taus
!========================================================
if (Taus_alloc) then

   if (rank == 0) then
      n1 = size(rad%Taus,1)
      n2 = size(rad%Taus,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%Taus)) deallocate(rad%Taus)
      allocate(rad%Taus(n1,n2))
   endif

   call comm%broadcast(rad%Taus,0)

endif


!========================================================
! dtauwr
!========================================================
if (dtauwr_alloc) then

   if (rank == 0) then
      n1 = size(rad%dtauwr,1)
      n2 = size(rad%dtauwr,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%dtauwr)) deallocate(rad%dtauwr)
      allocate(rad%dtauwr(n1,n2))
   endif

   call comm%broadcast(rad%dtauwr,0)

endif


!========================================================
! dtauir
!========================================================
if (dtauir_alloc) then

   if (rank == 0) then
      n1 = size(rad%dtauir,1)
      n2 = size(rad%dtauir,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%dtauir)) deallocate(rad%dtauir)
      allocate(rad%dtauir(n1,n2))
   endif

   call comm%broadcast(rad%dtauir,0)

endif


!========================================================
! kextwath
!========================================================
if (kextwath_alloc) then

   if (rank == 0) then
      n1 = size(rad%kextwath,1)
      n2 = size(rad%kextwath,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%kextwath)) deallocate(rad%kextwath)
      allocate(rad%kextwath(n1,n2))
   endif

   call comm%broadcast(rad%kextwath,0)

endif


!========================================================
! kexticeh
!========================================================
if (kexticeh_alloc) then

   if (rank == 0) then
      n1 = size(rad%kexticeh,1)
      n2 = size(rad%kexticeh,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%kexticeh)) deallocate(rad%kexticeh)
      allocate(rad%kexticeh(n1,n2))
   endif

   call comm%broadcast(rad%kexticeh,0)

endif


!========================================================
! poldts_cl
!========================================================
if (poldts_cl_alloc) then

   if (rank == 0) then
      n1 = size(rad%poldts_cl,1)
      n2 = size(rad%poldts_cl,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%poldts_cl)) deallocate(rad%poldts_cl)
      allocate(rad%poldts_cl(n1,n2))
   endif

   call comm%broadcast(rad%poldts_cl,0)

endif


!========================================================
! poldts
!========================================================
if (poldts_alloc) then

   if (rank == 0) then
      n1 = size(rad%poldts,1)
      n2 = size(rad%poldts,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%poldts)) deallocate(rad%poldts)
      allocate(rad%poldts(n1,n2))
   endif

   call comm%broadcast(rad%poldts,0)

endif

!========================================================
! JT_lr
!========================================================
if (JT_lr_alloc) then

   if (rank == 0) then
      n1 = size(rad%JT_lr,1)
      n2 = size(rad%JT_lr,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%JT_lr)) deallocate(rad%JT_lr)
      allocate(rad%JT_lr(n1,n2))
   endif

   call comm%broadcast(rad%JT_lr,0)

endif


!========================================================
! LR species (2D)
!========================================================

if (JH2O_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JH2O_lr,1); n2 = size(rad%JH2O_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JH2O_lr)) deallocate(rad%JH2O_lr)
      allocate(rad%JH2O_lr(n1,n2))
   endif
   call comm%broadcast(rad%JH2O_lr,0)
endif


if (JCO2_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCO2_lr,1); n2 = size(rad%JCO2_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCO2_lr)) deallocate(rad%JCO2_lr)
      allocate(rad%JCO2_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCO2_lr,0)
endif


if (JO3_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JO3_lr,1); n2 = size(rad%JO3_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JO3_lr)) deallocate(rad%JO3_lr)
      allocate(rad%JO3_lr(n1,n2))
   endif
   call comm%broadcast(rad%JO3_lr,0)
endif


if (JN2O_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JN2O_lr,1); n2 = size(rad%JN2O_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JN2O_lr)) deallocate(rad%JN2O_lr)
      allocate(rad%JN2O_lr(n1,n2))
   endif
   call comm%broadcast(rad%JN2O_lr,0)
endif


if (JCO_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCO_lr,1); n2 = size(rad%JCO_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCO_lr)) deallocate(rad%JCO_lr)
      allocate(rad%JCO_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCO_lr,0)
endif


if (JCH4_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCH4_lr,1); n2 = size(rad%JCH4_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCH4_lr)) deallocate(rad%JCH4_lr)
      allocate(rad%JCH4_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCH4_lr,0)
endif


if (JSO2_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JSO2_lr,1); n2 = size(rad%JSO2_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JSO2_lr)) deallocate(rad%JSO2_lr)
      allocate(rad%JSO2_lr(n1,n2))
   endif
   call comm%broadcast(rad%JSO2_lr,0)
endif


if (JHNO3_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JHNO3_lr,1); n2 = size(rad%JHNO3_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JHNO3_lr)) deallocate(rad%JHNO3_lr)
      allocate(rad%JHNO3_lr(n1,n2))
   endif
   call comm%broadcast(rad%JHNO3_lr,0)
endif


if (JNH3_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JNH3_lr,1); n2 = size(rad%JNH3_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JNH3_lr)) deallocate(rad%JNH3_lr)
      allocate(rad%JNH3_lr(n1,n2))
   endif
   call comm%broadcast(rad%JNH3_lr,0)
endif


if (JOCS_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JOCS_lr,1); n2 = size(rad%JOCS_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JOCS_lr)) deallocate(rad%JOCS_lr)
      allocate(rad%JOCS_lr(n1,n2))
   endif
   call comm%broadcast(rad%JOCS_lr,0)
endif


if (JHDO_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JHDO_lr,1); n2 = size(rad%JHDO_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JHDO_lr)) deallocate(rad%JHDO_lr)
      allocate(rad%JHDO_lr(n1,n2))
   endif
   call comm%broadcast(rad%JHDO_lr,0)
endif


if (JCF4_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCF4_lr,1); n2 = size(rad%JCF4_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCF4_lr)) deallocate(rad%JCF4_lr)
      allocate(rad%JCF4_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCF4_lr,0)
endif


if (JMXGAS_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JMXGAS_lr,1); n2 = size(rad%JMXGAS_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JMXGAS_lr)) deallocate(rad%JMXGAS_lr)
      allocate(rad%JMXGAS_lr(n1,n2))
   endif
   call comm%broadcast(rad%JMXGAS_lr,0)
endif


!========================================================
! cloud terms LR
!========================================================

if (JCSELF_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCSELF_lr,1); n2 = size(rad%JCSELF_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCSELF_lr)) deallocate(rad%JCSELF_lr)
      allocate(rad%JCSELF_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCSELF_lr,0)
endif


if (JCFORE_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCFORE_lr,1); n2 = size(rad%JCFORE_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCFORE_lr)) deallocate(rad%JCFORE_lr)
      allocate(rad%JCFORE_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCFORE_lr,0)
endif


if (JCCO2_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCCO2_lr,1); n2 = size(rad%JCCO2_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCCO2_lr)) deallocate(rad%JCCO2_lr)
      allocate(rad%JCCO2_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCCO2_lr,0)
endif


if (JCLD_LIQ_con_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_LIQ_con_lr,1); n2 = size(rad%JCLD_LIQ_con_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_LIQ_con_lr)) deallocate(rad%JCLD_LIQ_con_lr)
      allocate(rad%JCLD_LIQ_con_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_LIQ_con_lr,0)
endif


if (JCLD_LIQ_rad_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_LIQ_rad_lr,1); n2 = size(rad%JCLD_LIQ_rad_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_LIQ_rad_lr)) deallocate(rad%JCLD_LIQ_rad_lr)
      allocate(rad%JCLD_LIQ_rad_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_LIQ_rad_lr,0)
endif


if (JCLD_ICE_con_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_ICE_con_lr,1); n2 = size(rad%JCLD_ICE_con_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_ICE_con_lr)) deallocate(rad%JCLD_ICE_con_lr)
      allocate(rad%JCLD_ICE_con_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_ICE_con_lr,0)
endif


if (JCLD_ICE_rad_lr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_ICE_rad_lr,1); n2 = size(rad%JCLD_ICE_rad_lr,2)
   endif
   call comm%broadcast(n1,0); call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_ICE_rad_lr)) deallocate(rad%JCLD_ICE_rad_lr)
      allocate(rad%JCLD_ICE_rad_lr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_ICE_rad_lr,0)
endif

!==================== HR 2D ARRAYS ====================

if (JT_hr_alloc) then

   if (rank == 0) then
      n1 = size(rad%JT_hr,1)
      n2 = size(rad%JT_hr,2)
   endif

   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)

   if (rank /= 0) then
      if (allocated(rad%JT_hr)) deallocate(rad%JT_hr)
      allocate(rad%JT_hr(n1,n2))
   endif

   call comm%broadcast(rad%JT_hr,0)
endif


if (JH2O_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JH2O_hr,1)
      n2 = size(rad%JH2O_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JH2O_hr)) deallocate(rad%JH2O_hr)
      allocate(rad%JH2O_hr(n1,n2))
   endif
   call comm%broadcast(rad%JH2O_hr,0)
endif


if (JCO2_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCO2_hr,1)
      n2 = size(rad%JCO2_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCO2_hr)) deallocate(rad%JCO2_hr)
      allocate(rad%JCO2_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCO2_hr,0)
endif


if (JO3_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JO3_hr,1)
      n2 = size(rad%JO3_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JO3_hr)) deallocate(rad%JO3_hr)
      allocate(rad%JO3_hr(n1,n2))
   endif
   call comm%broadcast(rad%JO3_hr,0)
endif


if (JN2O_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JN2O_hr,1)
      n2 = size(rad%JN2O_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JN2O_hr)) deallocate(rad%JN2O_hr)
      allocate(rad%JN2O_hr(n1,n2))
   endif
   call comm%broadcast(rad%JN2O_hr,0)
endif


if (JCO_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCO_hr,1)
      n2 = size(rad%JCO_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCO_hr)) deallocate(rad%JCO_hr)
      allocate(rad%JCO_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCO_hr,0)
endif


if (JCH4_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCH4_hr,1)
      n2 = size(rad%JCH4_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCH4_hr)) deallocate(rad%JCH4_hr)
      allocate(rad%JCH4_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCH4_hr,0)
endif


if (JSO2_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JSO2_hr,1)
      n2 = size(rad%JSO2_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JSO2_hr)) deallocate(rad%JSO2_hr)
      allocate(rad%JSO2_hr(n1,n2))
   endif
   call comm%broadcast(rad%JSO2_hr,0)
endif


if (JHNO3_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JHNO3_hr,1)
      n2 = size(rad%JHNO3_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JHNO3_hr)) deallocate(rad%JHNO3_hr)
      allocate(rad%JHNO3_hr(n1,n2))
   endif
   call comm%broadcast(rad%JHNO3_hr,0)
endif


if (JNH3_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JNH3_hr,1)
      n2 = size(rad%JNH3_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JNH3_hr)) deallocate(rad%JNH3_hr)
      allocate(rad%JNH3_hr(n1,n2))
   endif
   call comm%broadcast(rad%JNH3_hr,0)
endif


if (JOCS_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JOCS_hr,1)
      n2 = size(rad%JOCS_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JOCS_hr)) deallocate(rad%JOCS_hr)
      allocate(rad%JOCS_hr(n1,n2))
   endif
   call comm%broadcast(rad%JOCS_hr,0)
endif


if (JHDO_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JHDO_hr,1)
      n2 = size(rad%JHDO_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JHDO_hr)) deallocate(rad%JHDO_hr)
      allocate(rad%JHDO_hr(n1,n2))
   endif
   call comm%broadcast(rad%JHDO_hr,0)
endif


if (JCF4_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCF4_hr,1)
      n2 = size(rad%JCF4_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCF4_hr)) deallocate(rad%JCF4_hr)
      allocate(rad%JCF4_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCF4_hr,0)
endif


if (JMXGAS_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JMXGAS_hr,1)
      n2 = size(rad%JMXGAS_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JMXGAS_hr)) deallocate(rad%JMXGAS_hr)
      allocate(rad%JMXGAS_hr(n1,n2))
   endif
   call comm%broadcast(rad%JMXGAS_hr,0)
endif


if (JCSELF_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCSELF_hr,1)
      n2 = size(rad%JCSELF_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCSELF_hr)) deallocate(rad%JCSELF_hr)
      allocate(rad%JCSELF_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCSELF_hr,0)
endif


if (JCFORE_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCFORE_hr,1)
      n2 = size(rad%JCFORE_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCFORE_hr)) deallocate(rad%JCFORE_hr)
      allocate(rad%JCFORE_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCFORE_hr,0)
endif


if (JCCO2_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCCO2_hr,1)
      n2 = size(rad%JCCO2_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCCO2_hr)) deallocate(rad%JCCO2_hr)
      allocate(rad%JCCO2_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCCO2_hr,0)
endif


if (JCLD_LIQ_con_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_LIQ_con_hr,1)
      n2 = size(rad%JCLD_LIQ_con_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_LIQ_con_hr)) deallocate(rad%JCLD_LIQ_con_hr)
      allocate(rad%JCLD_LIQ_con_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_LIQ_con_hr,0)
endif


if (JCLD_LIQ_rad_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_LIQ_rad_hr,1)
      n2 = size(rad%JCLD_LIQ_rad_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_LIQ_rad_hr)) deallocate(rad%JCLD_LIQ_rad_hr)
      allocate(rad%JCLD_LIQ_rad_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_LIQ_rad_hr,0)
endif


if (JCLD_ICE_con_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_ICE_con_hr,1)
      n2 = size(rad%JCLD_ICE_con_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_ICE_con_hr)) deallocate(rad%JCLD_ICE_con_hr)
      allocate(rad%JCLD_ICE_con_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_ICE_con_hr,0)
endif


if (JCLD_ICE_rad_hr_alloc) then
   if (rank == 0) then
      n1 = size(rad%JCLD_ICE_rad_hr,1)
      n2 = size(rad%JCLD_ICE_rad_hr,2)
   endif
   call comm%broadcast(n1,0)
   call comm%broadcast(n2,0)
   if (rank /= 0) then
      if (allocated(rad%JCLD_ICE_rad_hr)) deallocate(rad%JCLD_ICE_rad_hr)
      allocate(rad%JCLD_ICE_rad_hr(n1,n2))
   endif
   call comm%broadcast(rad%JCLD_ICE_rad_hr,0)
endif


print *, "Rank ", rank, " completed broadcast_radiances"

end subroutine broadcast_rad

subroutine broadcast_conf(conf,comm)

use structures
use parameters
use fckit_mpi_module, only : fckit_mpi_comm

implicit none

type(configuration_params), intent(inout) :: conf
type(fckit_mpi_comm), intent(in)          :: comm

integer :: rank
integer :: n1, i

logical :: emiss_alloc
logical :: wemiss_alloc
logical :: isrf_alloc
logical :: wisrf_alloc

real(kind=PREC) :: waopc_re(JPCH)
real(kind=PREC) :: waopc_im(JPCH)

rank = comm%rank()

!========================================================
! Broadcast scalars and fixed-size arrays
!========================================================

call comm%broadcast(conf%nconfig_file,0)

do i=1,MAX_NUMBER_OF_CONFIG_FILES
   call comm%broadcast(conf%config_file(i),0)
enddo

call comm%broadcast(conf%nparams,0)

call comm%broadcast(conf%n_threads,0)
call comm%broadcast(conf%openmp,0)

call comm%broadcast(conf%od_dbase,0)
call comm%broadcast(conf%od_dbase_dir,0)
call comm%broadcast(conf%atmosphere_file,0)

call comm%broadcast(conf%sigma0,0)
call comm%broadcast(conf%sigma1,0)

call comm%broadcast(conf%dsigma_low,0)

call comm%broadcast(conf%view_angles,0)
call comm%broadcast(conf%solar_angles,0)

call comm%broadcast(conf%obs_pres,0)
call comm%broadcast(conf%bot_pres,0)

call comm%broadcast(conf%wind_speed,0)

call comm%broadcast(conf%altitude_profile,0)

call comm%broadcast(conf%custom_emissivity,0)
call comm%broadcast(conf%emissivity_file,0)
call comm%broadcast(conf%nemiss_in,0)

!call comm%broadcast(conf%waopc,0)
if (rank == 0) then
   waopc_re = real(conf%waopc,kind=PREC)
   waopc_im = aimag(conf%waopc)
endif

call comm%broadcast(waopc_re,0)
call comm%broadcast(waopc_im,0)

if (rank /= 0) then
   conf%waopc = cmplx(waopc_re,waopc_im,kind=PREC)
endif

call comm%broadcast(conf%custom_isrf,0)
call comm%broadcast(conf%isrf_file,0)
call comm%broadcast(conf%nisrf_in,0)

call comm%broadcast(conf%reflection_type,0)

call comm%broadcast(conf%cloud_fraction,0)

call comm%broadcast(conf%flag_ref,0)

call comm%broadcast(conf%lr_need,0)

call comm%broadcast(conf%lr_rad,0)
call comm%broadcast(conf%hr_rad,0)

call comm%broadcast(conf%lr_jacs,0)

call comm%broadcast(conf%comp_jacs,0)
call comm%broadcast(conf%cntnm_jacs,0)
call comm%broadcast(conf%clouds_jacs,0)

call comm%broadcast(conf%rte_output,0)

call comm%broadcast(conf%wind_sunglint,0)

call comm%broadcast(conf%clear,0)
call comm%broadcast(conf%cloudy,0)
call comm%broadcast(conf%overcast,0)
call comm%broadcast(conf%day,0)
call comm%broadcast(conf%night,0)

!========================================================
! Allocation flags
!========================================================

if (rank == 0) then

   emiss_alloc  = allocated(conf%emiss_in)
   wemiss_alloc = allocated(conf%wemiss_in)

   isrf_alloc   = allocated(conf%isrf_in)
   wisrf_alloc  = allocated(conf%wisrf_in)

endif

call comm%broadcast(emiss_alloc ,0)
call comm%broadcast(wemiss_alloc,0)

call comm%broadcast(isrf_alloc  ,0)
call comm%broadcast(wisrf_alloc ,0)

!========================================================
! emiss_in
!========================================================

if (emiss_alloc) then

   if (rank == 0) then
      n1 = size(conf%emiss_in)
   endif

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(conf%emiss_in)) then
         deallocate(conf%emiss_in)
      endif

      allocate(conf%emiss_in(n1))

   endif

   call comm%broadcast(conf%emiss_in,0)

endif

!========================================================
! wemiss_in
!========================================================

if (wemiss_alloc) then

   if (rank == 0) then
      n1 = size(conf%wemiss_in)
   endif

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(conf%wemiss_in)) then
         deallocate(conf%wemiss_in)
      endif

      allocate(conf%wemiss_in(n1))

   endif

   call comm%broadcast(conf%wemiss_in,0)

endif

!========================================================
! isrf_in
!========================================================

if (isrf_alloc) then

   if (rank == 0) then
      n1 = size(conf%isrf_in)
   endif

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(conf%isrf_in)) then
         deallocate(conf%isrf_in)
      endif

      allocate(conf%isrf_in(n1))

   endif

   call comm%broadcast(conf%isrf_in,0)

endif

!========================================================
! wisrf_in
!========================================================

if (wisrf_alloc) then

   if (rank == 0) then
      n1 = size(conf%wisrf_in)
   endif

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(conf%wisrf_in)) then
         deallocate(conf%wisrf_in)
      endif

      allocate(conf%wisrf_in(n1))

   endif

   call comm%broadcast(conf%wisrf_in,0)

endif

print *, "Rank ", rank, " completed broadcast_configuration"

end subroutine broadcast_conf

subroutine broadcast_continuum_inputs(cont, comm)

use structures
use parameters
use fckit_mpi_module, only : fckit_mpi_comm

implicit none

type(continuum_inputs), intent(inout) :: cont
type(fckit_mpi_comm),   intent(in)    :: comm

call comm%broadcast(cont%nmol,    0)

call comm%broadcast(cont%pave,    0)
call comm%broadcast(cont%tave,    0)
call comm%broadcast(cont%rhoair,  0)
call comm%broadcast(cont%wbroad,  0)

call comm%broadcast(cont%wk,      0)

end subroutine broadcast_continuum_inputs

subroutine broadcast_sunglint(sg, comm)

use structures
use parameters
use fckit_mpi_module, only : fckit_mpi_comm

implicit none

type(sunglint), intent(inout) :: sg
type(fckit_mpi_comm), intent(in) :: comm

integer :: rank
integer :: n1

logical :: omegaf_alloc
logical :: fresnel_alloc

rank = comm%rank()

!========================================================
! SCALARS
!========================================================

call comm%broadcast(sg%P_d,       0)
call comm%broadcast(sg%tan2beta,  0)
call comm%broadcast(sg%azimut,    0)
call comm%broadcast(sg%azimuts,   0)
call comm%broadcast(sg%betaratio, 0)
call comm%broadcast(sg%sigmaQQ,   0)

!========================================================
! FIXED SIZE ARRAYS
!========================================================

call comm%broadcast(sg%IndR, 0)
call comm%broadcast(sg%omp,  0)

!========================================================
! ALLOCATION FLAGS
!========================================================

if (rank == 0) then
   omegaf_alloc  = allocated(sg%omegaf)
   fresnel_alloc = allocated(sg%fresnel)
endif

call comm%broadcast(omegaf_alloc,  0)
call comm%broadcast(fresnel_alloc, 0)

!========================================================
! OMEGAF
!========================================================

if (omegaf_alloc) then

   if (rank == 0) then
      n1 = size(sg%omegaf)
   endif

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(sg%omegaf)) deallocate(sg%omegaf)

      allocate(sg%omegaf(n1))

   endif

   call comm%broadcast(sg%omegaf,0)

endif

!========================================================
! FRESNEL
!========================================================

if (fresnel_alloc) then

   if (rank == 0) then
      n1 = size(sg%fresnel)
   endif

   call comm%broadcast(n1,0)

   if (rank /= 0) then

      if (allocated(sg%fresnel)) deallocate(sg%fresnel)

      allocate(sg%fresnel(n1))

   endif

   call comm%broadcast(sg%fresnel,0)

endif

end subroutine broadcast_sunglint

subroutine broadcast_atm(atm, comm)

use structures
use parameters
use fckit_mpi_module, only : fckit_mpi_comm

implicit none

type(atmosphere), intent(inout) :: atm
type(fckit_mpi_comm), intent(in) :: comm

integer :: i

!========================================================
! INTEGER SCALARS
!========================================================

call comm%broadcast(atm%iprof,      0)

call comm%broadcast(atm%startlayer, 0)
call comm%broadcast(atm%endlayer,   0)
call comm%broadcast(atm%st,         0)

call comm%broadcast(atm%jl,         0)
call comm%broadcast(atm%jr,         0)

call comm%broadcast(atm%layer0,     0)
call comm%broadcast(atm%layer1,     0)
call comm%broadcast(atm%nlayers,    0)

call comm%broadcast(atm%nmol,       0)

!========================================================
! REAL SCALARS
!========================================================

call comm%broadcast(atm%ang_r,      0)
call comm%broadcast(atm%ang_dazm,   0)

call comm%broadcast(atm%cos_r,      0)
call comm%broadcast(atm%cos_dazm,   0)

call comm%broadcast(atm%sin_r,      0)

call comm%broadcast(atm%rcos_vr,    0)
call comm%broadcast(atm%rcos_vs,    0)

call comm%broadcast(atm%ts,         0)

!========================================================
! ARRAYS
!========================================================

call comm%broadcast(atm%ang_v,      0)
call comm%broadcast(atm%ang_s,      0)

call comm%broadcast(atm%cos_v,      0)
call comm%broadcast(atm%cos_s,      0)

call comm%broadcast(atm%sin_v,      0)
call comm%broadcast(atm%sin_s,      0)

call comm%broadcast(atm%temp,       0)

call comm%broadcast(atm%wmol,       0)

call comm%broadcast(atm%press,      0)
call comm%broadcast(atm%WK,         0)

call comm%broadcast(atm%z,          0)

call comm%broadcast(atm%pg,         0)
call comm%broadcast(atm%pbar,       0)
call comm%broadcast(atm%fp,         0)

call comm%broadcast(atm%lwccs,      0)
call comm%broadcast(atm%recs,       0)

call comm%broadcast(atm%iwccs,      0)
call comm%broadcast(atm%dgecs,      0)

!========================================================
! CONTINUUM INPUTS
!========================================================

do i = 1, NLAYERMAX
   call broadcast_continuum_inputs(atm%cont(i), comm)
enddo

!========================================================
! SUNGLINT
!========================================================

call broadcast_sunglint(atm%sg, comm)

print *, "Rank ", comm%rank(), " completed broadcast_atmosphere"

end subroutine broadcast_atm

! -----------------------------------------------------------------------------

END MODULE ufo_sigma_utils_mod
