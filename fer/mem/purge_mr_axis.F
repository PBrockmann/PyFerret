	SUBROUTINE PURGE_MR_AXIS( old_axis, new_axis, status )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration''s (NOAA) Pacific Marine Environmental Lab(PMEL),
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
* eliminate all stored mrs that use a given axis
* and replace all references within grids to the old axis with the new axis

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* V200:  8/4/89 - from PURGE_USER_VAR
*Linux Port 1/97 *kob* - Added a preprocessor include for tmap_dset.parm
*			  because it needed a preprocessor.
* V450: 11/14/97 - check dynamic grids as well as static grids
*		(err450_redefine_axis_in_dyn_grid.jnl)
* V510 4/00 *sh* - netCDF data sets using dynamic grids, too
* V541 6/02 *acm*  call PACK_LINE_STORAGE to recover line_mem storage when irregular
*                  axis is cancelled.
*        2/12 *kms* Add E and F dimensions (use nferdims in tmap_dims.parm)
* v695 4/15 *acm*  Fix ticket 2271: If the record axis was redefined, we need
*                  to store that info in the record-axis storage

        IMPLICIT NONE
        include 'tmap_dims.parm'
#	include	"tmap_dset.parm"
	include	'ferret.parm'
	include	'errmsg.parm'
	include	'tmap_errors.parm'
	include 'xtm_grid.cmn_text'
	external xgt_grid_data
	include 'xdset_info.cmn_text'


* calling argument declaration:
	INTEGER	old_axis, new_axis, status

* internal variable declarations:
	INTEGER	TM_GET_LINENUM, grid, idim, num_protected_axes, iset
	CHARACTER	I6*6

* the lowest axes are protected
	num_protected_axes = TM_GET_LINENUM( 'EZ' )  ! top protected axis
	IF ( old_axis .LE. num_protected_axes ) GOTO 5200

* only regular axes may be re-defined
* (to avoid dealing with messy memory pointers)
!	IF ( .NOT. line_regular( old_axis ) ) GOTO 5100

* delete all variables in memory that are based on grids using this axis
	DO 100 grid = 1, max_dyn_grids
	  IF (grid_name(grid) .EQ. char_init16) GOTO 100

	  DO 50 idim = 1, nferdims
	     IF ( grid_line(idim,grid) .EQ. old_axis ) THEN
	         CALL PURGE_MR_GRID( grid, status ) 
	         IF ( status .NE. ferr_ok ) RETURN
	         GOTO 100
	     ENDIF
 50	  CONTINUE

 100	CONTINUE

* now we are safe from errors: replace the old axis with the new one
* 4/00: - check among dynamic grids, too -- though there would at present never
*	be a replacement of one of these axes
	DO 250 grid = 1, max_dyn_grids
	  IF (grid_name(grid) .EQ. char_init16) GOTO 250

	  DO 200 idim = 1, nferdims
	     IF ( grid_line(idim,grid) .EQ. old_axis ) THEN
	         grid_line(idim,grid) = new_axis
	     ENDIF
 200	  CONTINUE

 250	CONTINUE
	line_use_cnt(new_axis) = line_use_cnt(old_axis)

* check for the axis in the list of record axes; replace the old with the new
	DO 300 iset = 1, maxdsets
	   IF (ds_time_axis(iset) .EQ. old_axis) ds_time_axis(iset) = new_axis
 300	CONTINUE

* delete the old axis
	IF ( .NOT.line_regular(old_axis) ) THEN
           CALL PACK_LINE_STORAGE(old_axis)
c	   WRITE ( I6,'(I6)' ) line_dim(old_axis)
c	   CALL WARN( I6//' words of axis coordinate storage lost' )
c	   line_subsc1( old_axis ) = unspecified_int4
	ENDIF
	line_use_cnt(old_axis) = 0
	line_name( old_axis ) = char_init16

	status = ferr_ok
	RETURN

* error exit
 5000	RETURN
! 5100	CALL ERRMSG( ferr_grid_definition, status,
!     .		'cannot delete axes with irregular points: '
!     .		//line_name(old_axis),
!     .		*5000 )
 5200	CALL ERRMSG( ferr_grid_definition, status,
     .		'protected axis: '//line_name(old_axis), *5000 )
	END

