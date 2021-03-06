	INTEGER FUNCTION CD_WRITE_bndsdim ( cdfid, status )


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

* Create a netCDF dimension for the second dimension of a bounds 
* coordinate variable

* Programmer Ansley Manke
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* (from cd_write_strdim.F)

* V570 *acm* 5/04 
* V65  *acm* 1/10  Change all netcdf2-style calls and parameter names to 
*                  netcdf3-style calls, which are also consistent with netcdf4.
* V65  *acm* 1/10  Add #ifdef usingDODSf2cUnderscore, for 32-bit linux build
*                  linked with OPeNDAP library.
* V6.74 3/12 *acm* cleanup ifdefs and unnecessary include files


* argument definitions:
*     cdfid   - netCDF id number for already opened CDF file
*     status  - return status

* include files
        include 'netcdf.inc'
	include 'tmap_errors.parm'
	include 'cdf_tmap.parm'
#include "gt_lib.parm"

! Declare netcdf function names. 
! The ones without trailing underscore are declared in netcdf.inc
#include "netcdf_declareUnderscore.inc"

* argument declarations
      INTEGER cdfid, status

* local variable declarations:
      CHARACTER dimname*128
      INTEGER cdfstat, clen, nlen, dimid, nbnds

* initialize
      dimname = 'bnds'
      nbnds = 2
      nlen = 4

* is the dimension already defined ?
#ifdef usingDODSf2cUnderscore
      cdfstat = NF_INQ_DIMID_(cdfid, dimname(:nlen), dimid )
#else
      cdfstat = NF_INQ_DIMID (cdfid, dimname(:nlen), dimid )
#endif

      IF ( cdfstat .EQ. NF_NOERR ) THEN
* ... yes. make sure defn is consistent

* v5.40 *kob* - add ifdef to check whether or not to append an underscore
*               to the v3 routine name.  This necessary because DODS netcdf
*               fortran jackets can be configured assuming f2c, which appends
*               an additional underscore to routine names already containing
*               and underscore.  The real solution is to configure dods 
*               correctly, but the below may be necessary when linked with
*               unidata-built dods libraries

#ifdef usingDODSf2cUnderscore
	cdfstat = NF_INQ_DIMLEN_(cdfid, dimid, clen)
#else
	cdfstat = NF_INQ_DIMLEN(cdfid, dimid, clen)
#endif
	IF (clen .NE. nbnds) GOTO 5100
      ELSE
* ... no. define it
        CALL CD_SET_MODE(cdfid, pcd_mode_define, status)
        IF ( status .NE. merr_ok ) RETURN
#ifdef usingDODSf2cUnderscore
        cdfstat = NF_DEF_DIM_( cdfid, dimname(:nlen), nbnds, dimid )
#else
        cdfstat = NF_DEF_DIM( cdfid, dimname(:nlen), nbnds, dimid )
#endif

        IF ( cdfstat .NE. NF_NOERR ) GOTO 5200
      ENDIF

* successful completion
      status = merr_ok
      CD_WRITE_BNDSDIM = dimid
      RETURN

* error messages
 5100 CALL TM_ERRMSG
     . ( merr_linepredef, status, 'CD_WRITE_BNDSDIM', unspecified_int4,
     .   unspecified_int4,
     .  'dimension '//dimname(:nlen)//' doesnt match CDF file',
     .  no_errstring, *5900 )

 5200        CALL TM_ERRMSG
     .     ( cdfstat+pcdferr, status, 'CD_WRITE_BNDSDIM', cdfid,
     .       unspecified_int4, 'Failed creating dimension '
     .       //dimname(:nlen), no_errstring, *5900 )

* error exit
 5900   RETURN
	END
