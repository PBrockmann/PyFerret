	SUBROUTINE TM_EXIT ( )
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

* exit the TMAP library, closing all open files as we do so
* V510 - *sh* 12/99 -- needed for netCDF caching to work right
* v540 *acm* 10/01 increase length of ds_name
* v540 *acm* 10/01  remove VMS include statements
* v604 *acm* 7/07 increase length of ds_name, ds_des_name
* V701  7/16 *kms* Compare ds_name to char_init2048 instead of char_init1024

	include 'tmap_errors.parm'	! error code parameter defs
#include "tmap_dset.parm"
	include 'tmap_dims.parm'
	include 'xstep_files.cmn_text'
	external xstep_files_data
	include 'xdset_info.cmn_text'
	external xdset_info_data

* internal variable declarations
        LOGICAL   its_cdf
	INTEGER   ds_num,status,f_num

* loop over all data sets
	DO 500 ds_num = 1, maxdsets
	   IF (ds_name(ds_num) .EQ. char_init2048) GOTO 500

* save the data format
           its_cdf = ds_type(ds_num) .EQ. 'CDF'
     .        .OR.   ds_type(ds_num) .EQ. 'ECDF' 

* Now loop through stepfiles closing files
	   DO 100 f_num = 1, maxstepfiles
	     IF (sf_setnum(f_num) .NE. ds_num) GOTO 100

* close step file or CDF file ?
	    IF ( sf_lunit (f_num) .NE. file_not_open) THEN	! open ?
               IF ( its_cdf ) THEN
                  CALL CD_CLOSE_SET( sf_lunit(f_num), status )
               ELSE
	          CALL TM_CLOSE_STEP (f_num, status)
               ENDIF
	     ENDIF
  100	   CONTINUE

 500	CONTINUE

	RETURN
	END
