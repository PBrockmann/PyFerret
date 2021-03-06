*
* tax_datestring.F
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* Jing Y. Li 
* May 2006
* 18-may-2006 ACM change to compare only the first 3 characters of the precision string.
* V68  *acm* 1/12  ifdef double_p for double-precision ferret.
* 27-Feb-2013 ACM  Fix ticket 2043: remove old code for handling single-
*                  precision values coming in from argument 1
* v695  *acm 2/15  Return dates on an F axis or a T axis.
*
* Returns string of dates 
*
* In this subroutine we provide information about
* the function.  The user configurable information 
* consists of the following:
*
* descr              Text description of the function
*
* num_args           Required number of arguments
*
* axis_inheritance   Type of axis for the result
*                       ( CUSTOM, IMPLIED_BY_ARGS, NORMAL, tax_datestring )
*                       CUSTOM          - user defined axis
*                       IMPLIED_BY_ARGS - same axis as the incoming argument
*                       NORMAL          - the result is normal to this axis
*                       ABSTRACT        - an axis which only has index values
*
* piecemeal_ok       For memory optimization:
*                       axes where calculation may be performed piecemeal
*                       ( YES, NO )


      SUBROUTINE tax_datestring_init(id)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'

      INTEGER id, arg

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      CALL ef_set_desc(id,
     .        'Returns date string for time axis coordinate values' )
      CALL ef_set_num_args(id, 3)
      CALL ef_set_axis_inheritance_6d(id,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS,
     .                                IMPLIED_BY_ARGS, IMPLIED_BY_ARGS)
      CALL ef_set_piecemeal_ok_6d(id, NO, NO, NO, NO, NO, NO)
      CALL ef_set_result_type(id, STRING_RETURN)

      arg = 1
      CALL ef_set_arg_name(id, arg, 'A')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg, 'time steps to convert')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              YES, YES, YES, YES, YES, YES)

      arg = 2
      CALL ef_set_arg_name(id, arg, 'B')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg, 'variable with reference time axis')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              NO, NO, NO, NO, NO, NO)

*     Set data type as string
      arg = 3
      CALL ef_set_arg_type (id, arg, STRING_ARG)
      CALL ef_set_arg_name(id, arg, 'C')
      CALL ef_set_arg_unit(id, arg, ' ')
      CALL ef_set_arg_desc(id, arg, 'output precision')
      CALL ef_set_axis_influence_6d(id, arg,
     .                              NO, NO, NO, NO, NO, NO)

*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      RETURN 
      END


* In this subroutine we compute the result
*
      SUBROUTINE tax_datestring_compute(id, arg_1, arg_2, arg_3, 
     .                                  result)

      IMPLICIT NONE
      INCLUDE 'EF_Util.cmn'
      INCLUDE 'EF_mem_subsc.cmn'

      INTEGER strdf
#ifdef double_p
      PARAMETER (strdf = 1)
#else
      PARAMETER (strdf = 2)
#endif

      INTEGER id

      REAL arg_1(mem1lox:mem1hix, mem1loy:mem1hiy, mem1loz:mem1hiz, 
     .           mem1lot:mem1hit, mem1loe:mem1hie, mem1lof:mem1hif)
      REAL arg_2(mem2lox:mem2hix, mem2loy:mem2hiy, mem2loz:mem2hiz, 
     .           mem2lot:mem2hit, mem2loe:mem2hie, mem2lof:mem2hif)
      REAL arg_3(strdf, mem3lox:mem3hix, mem3loy:mem3hiy,
     .                  mem3loz:mem3hiz, mem3lot:mem3hit,
     .                  mem3loe:mem3hie, mem3lof:mem3hif)

      REAL result(strdf, memreslox:memreshix, memresloy:memreshiy, 
     .                   memresloz:memreshiz, memreslot:memreshit,
     .                   memresloe:memreshie, memreslof:memreshif)

* After initialization, the 'res_' arrays contain indexing information 
* for the result axes.  The 'arg_' arrays will contain the indexing 
* information for each variable''s axes. 

      INTEGER res_lo_ss(6),
     .        res_hi_ss(6),
     .        res_incr (6)
      INTEGER arg_lo_ss(6,EF_MAX_ARGS),
     .        arg_hi_ss(6,EF_MAX_ARGS),
     .        arg_incr (6,EF_MAX_ARGS)

      REAL bad_flag(EF_MAX_ARGS), bad_flag_result

* **********************************************************************
*                                            USER CONFIGURABLE PORTION |
*                                                                      |
*                                                                      V

      INTEGER i, j, k, l, m, n
      INTEGER i1, j1, k1, l1, m1, n1
      INTEGER i3, j3, k3, l3, m3, n3
      INTEGER slen
      CHARACTER*20 datestring
      CHARACTER*3 precistring
      INTEGER L2, LL, dir
      CHARACTER*255 err_msg
      REAL*8 ddate

*  variables for checking axis characteristics (modulo axes)
      CHARACTER ax_name(6)*16, ax_units(6)*16
      LOGICAL backward(6), modulo(6), regular(6), tmodulo

      CALL ef_get_res_subscripts_6d(id, res_lo_ss, res_hi_ss, res_incr)
      CALL ef_get_arg_subscripts_6d(id, arg_lo_ss, arg_hi_ss, arg_incr)
      CALL ef_get_bad_flags(id, bad_flag, bad_flag_result)

*  Check to see if time axis of arg 2 is modulo
      CALL ef_get_axis_info_6d(id, ARG2, ax_name, ax_units,
     .                         backward, modulo, regular)
* Get the direction of arg 2
      IF (arg_lo_ss(T_AXIS, ARG2) .NE. ef_unspecified_int4) THEN
         dir = T_AXIS
         tmodulo = modulo(T_AXIS)
      ENDIF
      IF (arg_lo_ss(F_AXIS, ARG2) .NE. ef_unspecified_int4) THEN
         dir = F_AXIS
         tmodulo = modulo(F_AXIS)
      ENDIF

*     Get the precision for output (string)
      i3 = arg_lo_ss(X_AXIS, ARG3)
      j3 = arg_lo_ss(Y_AXIS, ARG3)
      k3 = arg_lo_ss(Z_AXIS, ARG3)
      l3 = arg_lo_ss(T_AXIS, ARG3)
      m3 = arg_lo_ss(E_AXIS, ARG3)
      n3 = arg_lo_ss(F_AXIS, ARG3)
      CALL ef_get_string_arg_element_6d(id, ARG3, arg_3,
     .                       i3, j3, k3, l3, m3, n3, slen, precistring)
      CALL LOWER_CASE(precistring)

      n1 = arg_lo_ss(F_AXIS,ARG1)
      DO 600 n = res_lo_ss(F_AXIS), res_hi_ss(F_AXIS)

      m1 = arg_lo_ss(E_AXIS,ARG1)
      DO 500 m = res_lo_ss(E_AXIS), res_hi_ss(E_AXIS)

      l1 = arg_lo_ss(T_AXIS,ARG1)
      DO 400 l = res_lo_ss(T_AXIS), res_hi_ss(T_AXIS)

      k1 = arg_lo_ss(Z_AXIS,ARG1)
      DO 300 k = res_lo_ss(Z_AXIS), res_hi_ss(Z_AXIS)

      j1 = arg_lo_ss(Y_AXIS,ARG1)
      DO 200 j = res_lo_ss(Y_AXIS), res_hi_ss(Y_AXIS)

      i1 = arg_lo_ss(X_AXIS,ARG1)
      DO 100 i = res_lo_ss(X_AXIS), res_hi_ss(X_AXIS)

         ddate = arg_1(i1,j1,k1,l1,m1,n1) 
         ddate = ddate  
         IF ( ddate .NE. bad_flag(ARG1) ) THEN

*     Get the date string corresponding to time ddate for the variable ARG2
            CALL EF_GET_AXIS_DATES 
     .                   (id, ARG2, ddate, dir, 1, datestring)

*     Assign the appropriate substring to the result.
            IF ( .NOT. tmodulo ) THEN
               IF ( precistring .EQ. 'sec' ) THEN
                  slen = 20
                  CALL EF_PUT_STRING(datestring, slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'min' ) THEN
                  slen = 17
                  CALL EF_PUT_STRING(datestring(1:17), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'hou' ) THEN
                  slen = 14
                  CALL EF_PUT_STRING(datestring(1:14), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'day' ) THEN
                  slen = 11
                  CALL EF_PUT_STRING(datestring(1:11), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'mon' ) THEN
                  slen = 8
                  CALL EF_PUT_STRING(datestring(4:11), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'yea' ) THEN
                  slen = 4
                  CALL EF_PUT_STRING(datestring(8:11), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE
                  slen = 20
                  CALL EF_PUT_STRING (datestring, slen,
     .                               result(1,i,j,k,l,m,n))
               ENDIF

            ELSE  ! modulo time axis.  Datestring looks like 15-FEB 02:54:36

               IF ( precistring .EQ. 'sec' ) THEN
                  slen = 15
                  CALL EF_PUT_STRING(datestring(1:15), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'min' ) THEN
                  slen = 12
                  CALL EF_PUT_STRING(datestring(1:12), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'hou' ) THEN
                  slen = 9
                  CALL EF_PUT_STRING(datestring(1:9), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'day' ) THEN
                  slen = 6
                  CALL EF_PUT_STRING(datestring(1:6), slen, 
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'mon' ) THEN
                  slen = 3
                  CALL EF_PUT_STRING(datestring(4:6), slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE IF ( precistring .EQ. 'yea' ) THEN
                  datestring = '...'
                  slen = 3
                  CALL EF_PUT_STRING(datestring, slen,
     .                               result(1,i,j,k,l,m,n))
               ELSE
                           slen = 15
                           CALL EF_PUT_STRING(datestring, slen,
     .                                        result(1,i,j,k,l,m,n))
               ENDIF

            ENDIF  ! Modulo time

         ELSE  ! ddate .NE. bad_flag(ARG1)

            datestring = '...'
            slen = 3
            CALL EF_PUT_STRING(datestring, slen,
     .                                  result(1,i,j,k,l,m,n))

         ENDIF

         i1 = i1 + arg_incr(X_AXIS,ARG1)
 100  CONTINUE

         j1 = j1 + arg_incr(Y_AXIS,ARG1)
 200  CONTINUE

         k1 = k1 + arg_incr(Z_AXIS,ARG1)
 300  CONTINUE

         l1 = l1 + arg_incr(T_AXIS,ARG1)
 400  CONTINUE

         m1 = m1 + arg_incr(E_AXIS,ARG1)
 500  CONTINUE

         n1 = n1 + arg_incr(F_AXIS,ARG1)
 600  CONTINUE

      RETURN

 999  CALL ef_bail_out (id, err_msg)

*                                                                      ^
*                                                                      |
*                                            USER CONFIGURABLE PORTION |
* **********************************************************************

      END
