	CHARACTER*(*) FUNCTION KEY_STRING( cx, flags, slen )

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
* generate a string that describes the given context using the flags as
* guidelines for what limits, transformations, etc. to document

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system

* V200: 1/2/89
* V230:  11/4/92 - expanded variable name length
* V420:	 9/25/95 - comments appropriate to dynamic grids
* V500 *kob* 3/99- up VAR_CODE  to 64 chars and VAR_TITLE to 128
* V552 *acm* 4/03- up VAR_CODE  to 128 chars and name to 256 (ds_name)
* V67  *acm* 3/11- fix ticket 1821
*       *acm* 3/12 Add E and F dimensions (use nferdims in tmap_dims.parm)
* V685+ *acm* 12/13 For 6D Ferret, the array coming in as flags is longer for extra dimensions

	include	'tmap_dims.parm'
	include	'ferret.parm'
	include	'xcontext.cmn'
	include	'xtext_info.cmn'
	include	'xtm_grid.cmn_text'
	external xgt_grid_data
	include	'xdset_info.cmn_text'
	external xdset_info_data

* calling argument declarations
	LOGICAL	flags(0:12)
	INTEGER	cx, slen

* local variable declarations:
	LOGICAL		save_by_ss
	INTEGER		TM_LENSTR1, idim, maxlen, plen, categ, var, dset
	CHARACTER 	ALG_TRANS_CODE*3, ARG_STRING*12, VAR_CODE*128,
     .			VAR_TITLE*128, CX_DIM_STR*40, REGRID_COMMENTS*64,
     .			prefix*1, dim_name*1, name*256

* local parameter declarations:
	LOGICAL		full_prec
	PARAMETER     ( full_prec = .TRUE. )

* initialize
	var     = cx_variable( cx )
	categ   = cx_category( cx )
	dset    = cx_data_set( cx )
	prefix = '['
	maxlen = LEN( KEY_STRING )

* begin with the code for this variable	
	KEY_STRING = VAR_CODE( categ, var )
	IF ( INDEX(KEY_STRING,'#') .GT. 0 ) KEY_STRING = VAR_TITLE ( cx )
	IF ( INDEX(KEY_STRING,'(C') .GT. 0 .AND. INDEX(KEY_STRING,',V') .GT. 0) 
     .                                KEY_STRING = VAR_TITLE ( cx )
	slen = TM_LENSTR1( KEY_STRING )

* document the data set
	IF ( flags(pdoc_dset) .AND. cx_data_set(cx).NE.pdset_irrelevant ) THEN
	   name = ds_name( cx_data_set(cx) )
	   plen = TM_LENSTR1(name)
	   KEY_STRING = KEY_STRING(:slen)//prefix//'D='//name(:plen)
	   slen = MIN( maxlen, slen+plen+3 )
	   prefix = ','
	ENDIF	   

* document any regridding
* (as of FERRET v2.00 the flag for this is ignored)
	IF ( cx_unstand_grid(cx) ) THEN
	   KEY_STRING = KEY_STRING(:slen)//prefix//'G='//
     .			REGRID_COMMENTS(cx, plen)
	   slen = MIN( maxlen, slen+3+plen )
	   prefix = ','
	ENDIF

* document each axis (and it's transformation) that's requested
	DO 100 idim = 1, nferdims
* ... all keys in world coordinates
	   save_by_ss = cx_by_ss( idim, cx )
	   cx_by_ss( idim, cx ) = .FALSE.
	   IF ( flags(idim)
     .    .AND. cx_lo_ww(idim,cx) .NE. unspecified_val8
     .    .AND. cx_lo_ww(idim,cx) .NE. unspec_val8_2	) THEN
	      KEY_STRING = KEY_STRING(:slen)//prefix//
     .				CX_DIM_STR(idim,cx,':',full_prec,plen)
	      slen = MIN( maxlen, slen+plen+1 )
	      prefix = ','
	   ELSEIF ( flags(idim+pdoc_offset_xform)
     .    .AND. cx_trans(idim,cx) .NE. trans_no_transform
     .    .AND. cx_trans(idim,cx) .NE. unspecified_int4 ) THEN
	      IF ( cx_by_ss( idim, cx ) ) THEN
	         dim_name = ss_dim_name( idim )
	      ELSE
	         dim_name = ww_dim_name( idim )
	      ENDIF
	      KEY_STRING = KEY_STRING(:slen)//prefix//dim_name//'=@'//
     .				ALG_TRANS_CODE( cx_trans( idim, cx )) //
     .				ARG_STRING( cx_trans_arg( idim, cx ))
	      slen = TM_LENSTR1( KEY_STRING )
	      prefix = ','
	   ENDIF
* ... restore " by subscript" info
	   cx_by_ss( idim, cx ) = save_by_ss
 100	CONTINUE

* clean up
	IF ( prefix .EQ. ',' ) THEN
	   KEY_STRING = KEY_STRING(:slen)//']'
	   slen = MIN( maxlen, slen+1 )
	ENDIF
	IF ( slen .EQ. maxlen ) KEY_STRING(slen:slen) = '*'

	RETURN
	END
