	SUBROUTINE CD_NCOPEN ( urlstring, dset, status )
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
* Just do an nc_close on the ncid for the dataset. We're going to 
* re-open it with F-TDS variable definitions, so leave all the
* dataset initialization information in place.
*
* programmer - Ansley Manke
* NOAA/PMEL, Seattle, WA - Thermal Modeling and Analysis Program
* 2/2013  Ferret v6.85
*
* arguments:
*	dset	- data set number 

        include 'netcdf.inc'
        include 'tmap_errors.parm'
	include 'tmap_dims.parm'
	include 'xstep_files.cmn_text'
	external xstep_files_data

* Argument variable declarations
	INTEGER   dset, status
	CHARACTER*(*) urlstring

* Local variable declarations
	INTEGER cdfid
	CHARACTER*500 errbuff


#ifdef usingDODSf2cUnderscore 
	status = NF_OPEN_(urlstring, NF_NOWRITE, cdfid) 
#else
	status = NF_OPEN(urlstring, NF_NOWRITE, cdfid) 
#endif
	
	IF ( status .NE. NF_NOERR ) GOTO 5100
	sf_lunit(dset) = cdfid

* successful completion
        status = merr_ok
 5000	RETURN

* error messages
 5100   CONTINUE

        errbuff = 
     .    'Unable to open URL with REMOTE variable definitions: '

        CALL TM_ERRMSG
     .     ( merr_nc_open, status, 'CD_NCOPEN', dset,
     .        no_stepfile, errbuff, no_errstring, *5000 )


	END
