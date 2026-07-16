module sum_mod 
    implicit none
contains

    subroutine sum_two(a,b,result)
    real, intent(in) :: a,b
    real, intent(out) :: result

    result = a+b

    end subroutine sum_two

end module sum_mod