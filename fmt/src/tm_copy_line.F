	SUBROUTINE TM_COPY_LINE ( source, dest )
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
*
* Copies line information from source to dest
*
* revision 0.00 - 11/22/88
* 10/95 - check to see if a dynamic line -- some variables don't get copied
*  1/96 - repaired bug (incomplete test) in 10/95 check
*  1/01 - *acm* add line_cal_name parallel with treatment of line_t0
* V581 *acm* 6/05 - For fix to bug 1271, add flag line_shift_origin
* V62  *acm* 3/09 - copy line_name_orig, used to keep original axis names 
*                   for use with attribute structure, e.g. save/keep_axisname
* v694 1/15 *acm* (see ticket 2227) handle the line_dim_only flag

* Arguments
	INTEGER*4	source, dest
*
* Parameters and commons

	include 'tmap_dims.parm'
#include "tmap_dset.parm"
#include "gt_lib.parm"
	include 'xtm_grid.cmn_text'
	external xgt_grid_data

*
	line_name(dest)      = line_name(source)
	line_name_orig(dest) = line_name_orig(source)
	line_dim(dest)       = line_dim(source) 
	line_units(dest)     = line_units(source) 
	line_unit_code(dest) = line_unit_code(source) 
	line_direction(dest) = line_direction(source) 
	line_regular(dest)   = line_regular(source) 
	line_modulo(dest)    = line_modulo(source) 
	line_start(dest)     = line_start(source) 
	line_delta(dest)     = line_delta(source) 
	line_t0(dest)        = line_t0(source) 
	line_shift_origin(dest) = line_shift_origin(source) 
	line_tunit(dest)     = line_tunit(source) 
	line_cal_name(dest)  = line_cal_name(source) 
	line_dim_only(dest)  = line_dim_only(source)

	IF ( dest.LE.max_lines .AND. source.LE.max_lines) THEN
* non-dynamic lines, only
	   line_subsc1(dest)    = line_subsc1(source)
	ELSEIF ( dest.GT.max_lines .AND. source.GT.max_lines) THEN! ELSEIF 1/96
* dynamic lines, only
	   line_class (dest)	= line_class (source)
	   line_parent(dest)	= line_parent(source)
	ENDIF

	RETURN
	END
