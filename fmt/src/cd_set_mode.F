	SUBROUTINE CD_SET_MODE(cdfid, mode, status)

*
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
* Set the netCDF mode to DATA or DEFINE
* but first check to see if it is already in the desired mode

* Programmer Steve Hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program

* revision 0.0 - 10/92
* V65  *acm* 1/10  Change all netcdf2-style calls and parameter names to 
*                  netcdf3-style calls, which are also consistent with netcdf4.
* V65  *acm* 1/10  Add #ifdef usingDODSf2cUnderscore, for 32-bit linux build
*                  linked with OPeNDAP library.
* V6.74 3/12 *acm* cleanup ifdefs and unnecessary include files

* argument definitions:
*       cdfid   - returned pointer to open CDF file
*       mode    - parameter value from cdf_tmap.parm
*	status	- return status

* argument declarations:
	INTEGER	 cdfid, mode, status

* include files
        include 'netcdf.inc'
        include 'cdf_tmap.parm'
        include 'tmap_errors.parm'

! Declare netcdf function names. 
! The ones without trailing underscore are declared in netcdf.inc
#include "netcdf_declareUnderscore.inc"

* local variable declarations:
      INTEGER cdf_mode, cdfstat

* must be remembered between calls
      SAVE cdf_mode

      IF ( mode .EQ. cdf_mode ) THEN
         status = merr_ok
         RETURN      ! no change requested
      ELSEIF ( mode .EQ. pcd_mode_define ) THEN
* ... enter define mode
#ifdef usingDODSf2cUnderscore
         cdfstat = NF_REDEF_( cdfid )
#else
         cdfstat = NF_REDEF( cdfid )
#endif

         IF ( cdfstat .NE. NF_NOERR ) GOTO 5100
      ELSEIF ( mode .EQ. pcd_mode_data ) THEN
* ... enter data mode
#ifdef usingDODSf2cUnderscore
         cdfstat = NF_ENDDEF_( cdfid )
#else
         cdfstat = NF_ENDDEF( cdfid )
#endif

         IF ( cdfstat .NE. NF_NOERR ) GOTO 5100
      ENDIF

* save the specified mode (the only action taken when mode < 0)
      cdf_mode = ABS( mode ) 

* successful completion
      status = merr_ok
      RETURN

* error messages
 5100 CALL TM_ERRMSG
     .     ( cdfstat+pcdferr, status, 'CD_SET_MODE', cdfid,
     .     no_varid, 'could not change CDF mode', ' ', *5000 )

* error exit
 5000 RETURN
	END
