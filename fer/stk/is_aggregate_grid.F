	SUBROUTINE IS_AGGREGATE_GRID(uvar, dset, cx, status )

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
* examine members of an aggregate datset, getting grids for 
* elements that are user-defined (LET/D) variables. Use the 
* interpretation stack in order to determine a defining grid for the
* overall aggregate dataset.
* Detailed description of the underlying logic is in MERGE_CONTEXT
* Note: When pseudo-variables are used (eg. LIST U/Z[K=1:3]) the grids for them
*	may not be known until all other components are examined.  In this
*	case a 2nd pass is required

* programmer - Ansley Manke (from is_uvar_grid)
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* V6.83 *acm* 11/30/2012 If variable isn't a file variable, get the right definition.

* V685  4/13 *acm* Better grid handling.
* V685 10/13 *acm* Fix ticket 1098, error defining ensemble when LET/D variables are present.
* V698  3/16 *acm* Remove unneeded xdset_parms.cmn
* V699  6/16 *sh*  replace variable uvar_grid with calls to c LIST structures
* V710 *acm* 10/16 Ticket 2422: variables uvar_grid, uvar_data_type, uvar_aux_cat, 
*                  uvar_aux_var to be replaced with calls to LIST routines in NCF_Util.c 

* calling argument declarations:
* uvar and dset point to the variable in the aggregate dataset
* And cx_orig points to the context for that variable.

	INTEGER	uvar, dset, cx, status

* internal variable declarations:
	LOGICAL its_dynamic
	INTEGER NCF_GET_AGG_COUNT, TM_LENSTR1, STR_SAME, KNOWN_GRID,
     .		cx_orig, agg_cx, hi_cx, big_cx, isp_orig, agg_dset, 
     .		agg_len, imemb, fer_uvar, memb_dset, memb_grid, iline, 
     .		nv, test_grid, this_grid, len_name, agg_dim, gnum, var,
     .		varid, idim, i, igrid, lo_cx, slen

	CHARACTER vname*512, buff*512, nm*3

#include "netcdf.inc"
	include	'tmap_errors.parm'
	include 'tmap_dims.parm'
	include	'xtm_grid.cmn_text'
	external xgt_grid_data
	include	'ferret.parm'
	include	'errmsg.parm'
	include	'interp_stack.parm'
	include	'xcontext.cmn'
	include	'xvariables.cmn'
	include	'xprog_state.cmn'
	include	'xfr_grid.cmn'
	include 'xdset_info.cmn_text'
	external xdset_info_data
	include 'xdset_info.cd_equiv'

*        ... interpretation stack setup at the time this is called ...
*	stack level		stack contents
*	isp+1	<--	level to get grids for components
*	 isp	<--	current level: evaluate user-variable grid

* --- end of introductory code ---

* initialize

	IF (ds_type(dset) .EQ. 'ENS') agg_dim = e_dim
	IF (ds_type(dset) .EQ. 'FCT') agg_dim = f_dim

	test_grid = unspecified_int4

	agg_dset = dset
	status = NCF_GET_AGG_COUNT (agg_dset, agg_len)

	agg_cx = cx

	vname = uvar_text(uvar)
	len_name = TM_LENSTR1(vname)

* are we pointing at a "LET var = [some expr with an agg var]"
* If so then the vname is not in the agg dset. Find the 
* var in the list of uvar_code, and get the right uvar_text
* (this is a hack, something is wrong with my stack handling)

	CALL CD_GET_VAR_ID (agg_dset, vname, varid, status)
	IF (status .NE. ferr_ok) THEN 
	   DO 30, i = uvar, 1, -1
 	      IF (STR_SAME(vname, uvar_name_code(i)) .EQ. 0) THEN
	         vname =  uvar_text(i)
	         len_name = TM_LENSTR1(vname)
	         CALL CD_GET_VAR_ID (agg_dset, vname, varid, status)
	         IF (status .NE. ferr_ok) GOTO 5010 
	         GOTO 40
               ENDIF
   30	   CONTINUE
	   GOTO 5010 
   40	   CONTINUE
	ENDIF

	DO 90 imemb = 1, agg_len

* See if the previous two members have matching grids (except for aggretage direction)
	   IF (test_grid.NE.unspecified_int4 .AND. test_grid.NE.this_grid) THEN
	      DO 80 idim = 1, nferdims
	         IF ( (idim .NE. agg_dim) .AND. 
     .	              (grid_line(idim,this_grid) .NE. grid_line(idim,test_grid)) ) GOTO 5300

   80	      CONTINUE
	   ENDIF

	   CALL CD_GET_AGG_VAR_INFO (agg_dset, vname, imemb, 
     .         fer_uvar, memb_dset, memb_grid, iline, nv, status)
	   IF (fer_uvar .EQ. cat_user_var .AND. memb_grid .EQ. unspecified_int4) 
     .           memb_grid = KNOWN_GRID(memb_dset, cat_user_var, nv) 
	   IF (memb_grid .NE. unspecified_int4) THEN
	      test_grid = memb_grid
	      this_grid = memb_grid
	      GOTO 90
	   ENDIF

* Get ready to call is_uvar_grid. 
* pre-load the variable info onto the CX stack

	   cx_orig = cx_stack_ptr
	   CALL STACK_PTR_UP( cx_stack_ptr, max_context, status )
	   IF ( status .NE. ferr_ok ) GOTO 5000
	   lo_cx  = is_cx( isp )
	   hi_cx = cx_stack_ptr
	   CALL GET_VAR_CONTEXT (  vname(:len_name),
     .				lo_cx,
     .				hi_cx,
     .				status )

	   cx_data_set(hi_cx) = memb_dset
	   cx_grid(hi_cx) = memb_grid
	   cx_variable(hi_cx) = nv
	   cx_category(hi_cx) = cat_user_var

* pre-load the variable info onto the IS stack
	   isp_orig = isp
	   CALL PUSH_INTERP_STACK( isp, status )
	   IF ( status .NE. ferr_ok ) GOTO 5000
	   is_cx   ( isp ) = hi_cx
	   is_uvar ( isp ) = nv
	   is_act  ( isp ) = isact_get_grid

* initialize the stacks - (repeated for each component)

 100	   CALL IS_GRID_MODE( status )
           hi_cx = is_big_cx(isp) + 1  ! ???
	   IF ( status .NE. ferr_ok ) GOTO 5000

* evaluate the grid by merging component grids
*  ... exit 100 is to evaluate the grid for a component uvar
*  ... exit 300 means that a grid has been obtained
*  ... "normal" return indicates an error has occurred
 200	   CALL IS_UVAR_GRID( *100, *300, status )
	   GOTO 5000

* a grid has been obtained.  Are we done ?
 300	   IF ( isp .EQ. isp_orig ) THEN
* ... yes - clean up and go home
              this_grid = cx_grid(hi_cx) 
	      IF ( cx_stack_ptr .NE. cx_orig ) WRITE (6,*) 'agg_v_gd'	! temp
	      GOTO 90
	   ELSE
* ... no - go back for more
	      GOTO 200
	   ENDIF

 90	CONTINUE

* Test that the grids match for the last aggregate member (except for ensemble direction)

	IF (test_grid.NE.unspecified_int4 .AND. test_grid.NE.this_grid) THEN
	   DO 180 idim = 1, nferdims
	      IF ( (idim .NE. agg_dim) .AND. 
     .	           (grid_line(idim,this_grid) .NE. grid_line(idim,test_grid)) ) GOTO 5300
 180	CONTINUE
	ENDIF

* Define the aggregrate grid here. Need a new context?  Should this be done when
* we get back to is_uvar_grid?

	big_cx = is_big_cx( isp )
	
	igrid = cx_grid(big_cx)
	DO 400 idim = 1, nferdims
	   grid_line(idim, igrid) = grid_line(idim,test_grid)
  400	CONTINUE
	grid_line(agg_dim, igrid) = iline

* catalog this result checking for matching previously existing grid
	CALL TM_GET_LIKE_DYN_GRID(igrid, its_dynamic, gnum, 
     .				grd_stk_ptr, status ) 

* set context for aggregate grid
	cx_grid(agg_cx) = gnum
	CALL SAVE_UVAR_GRID(uvar, gnum, ptype_float, dset)

	cx_grid(agg_cx) = gnum
	cx_data_set(agg_cx) = agg_dset
	IF (agg_dim .EQ. e_dim) cx_category(agg_cx) = cat_agg_e_var
	IF (agg_dim .EQ. f_dim) cx_category(agg_cx) = cat_agg_f_var

	uvar_dset( uvar ) = dset
	uvar_need_dset( uvar ) = .TRUE.

	var = cx_variable(agg_cx)
	ds_grid_number(var) = gnum 

* Get ds_grid_start, ds_grid_end, ds_ordering from the last file variable

	IF (test_grid .NE. unspecified_int4) THEN
	   DO 720 nv = 1, maxvars
	       IF (ds_grid_number(nv) .EQ. test_grid)  GOTO 725
 720	   CONTINUE
 725	   CONTINUE
        ENDIF

	IF (nv .GT. maxvars) GOTO 5010

        DO 730 idim = 1, nferdims
	   ds_grid_start(idim,var)= ds_grid_start(idim,nv)
	   ds_grid_end(idim,var)  = ds_grid_end(idim,nv)
	   ds_ordering(idim,var)  = ds_ordering(idim,nv)
 730	CONTINUE
        ds_ordering(agg_dim,var) = agg_dim
        ds_grid_start(agg_dim,var) = 1
        ds_grid_end(agg_dim,var) = line_dim(iline)

	is_cx(isp) = agg_cx
	is_uvar ( isp ) = uvar

* Now we have the grid for the variable in the agg. dataset. Store the grid 
* number for future use.

CC dont think this is right. should be the MEMBER grids not the aggregate var grid.
	DO 800 imemb = 1, agg_len
	   CALL CD_PUT_AGG_MEMB_GRID (agg_dset, vname, imemb, gnum, status)
 800	CONTINUE

	RETURN

* error exit
 5000	CALL DEALLO_ALL_GRIDS
	RETURN
 5300	CALL ERRMSG( ferr_aggregate_error, status,
     .   'grids for LET/D variables do not match for aggregate dataset'
     .   //vname,*5000 )
 5010	vname = uvar_text(uvar)
	CALL ERRMSG( ferr_aggregate_error, status,
     .   'error defining grid for variable in aggregate dataset'
     .   //vname,*5000 )

	END	
