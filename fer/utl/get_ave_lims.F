	SUBROUTINE GET_AVE_LIMS( src_lo, src_hi, src_grid,
     .				 dst_lo, dst_hi, dst_grid,
     .				 idim, subsc )

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
* for regridding axis idim from source grid to destination grid:
* determine source grid boxes containing destination box edges

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program

* revision 0.0 -  1/9/89
* V230: 8/23/92 - bug fix: time axes require special treatment
* V312:	 6/7/94 - use TDST_WORLD for simpler, faster date conversions
* V510: *sh* 1/00 - modify axis end point behavior so that partially filled
*		destination cells also get processed
*       *acm* 3/12 cleanup ifdefs and unnecessary include files
*       *acm* 4/12 6D Ferret: time axis may be in t or f direction.

	include 'ferret.parm'
	include 'errmsg.parm'

* calling argument declarations:
	INTEGER src_lo, src_hi, dst_lo, dst_hi, src_grid, dst_grid, idim
	INTEGER subsc(dst_lo:dst_hi+1)

* internal variable declarations:
	INTEGER	ISUBSCRIPT, ii, status
	REAL*8	TM_WORLD, TDEST_WORLD, xdst, xmin, xmax

* initialize
	IF ( idim .EQ. t_dim .OR. idim .EQ. f_dim ) THEN
*	  TDST_WORLD gives dates from the source axis as they would be
*	  encoded on the destination axis 
*   ==>	  ALL TIME/DATE CALCULATIONS ARE DONE IN THE SOURCE AXIS ENCODING
	   CALL TDEST_WORLD_INIT ( dst_grid, src_grid, idim, status ) ! src<->dst
	   IF ( status .NE. ferr_ok ) RETURN   ! note - status not passed!!!
	ENDIF
	xmin = TM_WORLD( src_lo, src_grid, idim, box_lo_lim )
	xmax = TM_WORLD( src_hi, src_grid, idim, box_hi_lim )

* find lower bounds of destination grid boxes on source axis
	DO 100 ii = dst_lo, dst_hi

	   xdst = TDEST_WORLD( ii, dst_grid, idim, box_lo_lim )

	   IF ( xdst .LT. xmin .OR. xdst .GT. xmax ) THEN

* ... destination point doesn't lie within source grid bounds
	      subsc( ii ) = unspecified_int4

	   ELSE

	      subsc(ii) = ISUBSCRIPT( xdst, src_grid, idim, round_up)

	   ENDIF

 100	CONTINUE

* correct first destination point if has a partial fill
	IF ( subsc(dst_lo) .EQ. unspecified_int4 ) THEN
	   xdst = TDEST_WORLD( dst_lo, dst_grid, idim, box_hi_lim )
	   IF ( xmin .LT. xdst )  THEN
	      subsc( dst_lo ) = src_lo
	   ENDIF
	ENDIF


* find upper bound of top destination grid box on source axis
	   xdst = TDEST_WORLD( dst_hi, dst_grid, idim, box_lo_lim )
	   IF ( xdst .GE. xmax ) THEN
	      subsc( dst_hi+1 ) = unspecified_int4
           ELSE
	      subsc( dst_hi+1 ) = src_hi
	   ENDIF

	RETURN
	END	
