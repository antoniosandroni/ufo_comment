program test_main_sigma

use parameters
use structures
use configuration
use sigma_subs

use ufo_sigma_mod

implicit none

type(ufo_sigma) :: self

self%conf%nconfig_file=1
self%conf%config_file(1)=("/glade/derecho/scratch/sandroni/newobsoperator_mpas_jedi/mpas_bundle_v3/code/sigma/conf/clear.conf")

call sigma_read_configuration_files(self%conf%config_file,self%conf%nconfig_file,self%conf,self%ios)

if (self%ios /= IERR_SUCCESS) then
    write(*,*) "Error reading configuration: ", sigma_strerror(self%ios)
    stop 1
end if

call print_configuration(self%conf)


end program test_main_sigma