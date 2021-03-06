	SUBROUTINE SHOW_DATA_SET_VARS_XML( lun, dset)

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
* List information about all variables in the data set in xml-style format

* programmer - Ansley Manke, based on show_data_set_vars.F
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* 6-Aug-2003
* V5.80 13-Sep-2004 *acm* Add data-set specific user variables to the listing
*       13-Oct-2004 *acm* Make the current dataset the default dataset so
*                         we can get all the info on dataset-specific user-defined
*                         variables in all files.
* V6.1  2/2008 *acm* Use attribute structure to get all attributes for the variable.
* V612  8/2007 *acm* Revert to old xml style output for infile_datatype and 
*                    ferret_datatype attributes
* V616 12/2008 *acm* Close the tag correctly; line written using format 2075 needs
*                    the attribute name given a second time.
* V616  1/2009 *acm* Fixing LAS ticket 481, new style of xml output
* V631 11/09 *acm* For XML-formatted output check for and replace the strings < > and &
*                  with &lt; etc.
* V650  2/10 *acm* LAS ticket 761: consistency of the missing-value flags. Use a Fortran
*                  format rather than TM_FMT to write the value to the xml output.
* V67  *acm* 2/11  XML fixes. New attribute formatting, ![CDATA] escape, upper/lowercase handling.
* V685 *acm* 2/13  Always list the default Ferret bad-flag in the xml header. The script 
*                  get_datavar.jnl under LAS iosp/scripts makes sure that is the value written 
*                  to the netcdf data files.
* V698  2/16 *acm* For ticket 2352: variables defined with LET/D are
*                  added to that dataset in the attribute structure, 
*                  and are shown with their dataset on SHOW DATA commands
* V7    6/16 *acm* Fix ticket 2441. For LET/D variables need to store the 
*                  uvar list in a local array. If using deleted_list_result,
*                  it got changed by the call to get the grid of the variable  
* V710 *acm* 10/16 Ticket 2422: variables uvar_grid, uvar_data_type, uvar_aux_cat, 
*                  uvar_aux_var to be replaced with calls to LIST routines in NCF_Util.c 

	include 'tmap_dims.parm'
#	include "tmap_dset.parm"
	include 'ez_lib.parm'
	include 'xdset_info.cmn_text'
	external xdset_info_data
	include 'xtm_grid.cmn_text'
	external xgt_grid_data
	include 'xez_info.cmn_text'
	external xez_info_data
	include	'ferret.parm'
	include	'xvariables.cmn'
	include	'xtext_info.cmn'
	include	'xprog_state.cmn'
	include	'xrisc.cmn'
	include	'xcontext.cmn'
	include 'errmsg.parm'
        include 'netcdf.inc'

* calling argument declarations:
	INTEGER	lun, dset
	
* local variable declarations:
	INTEGER   TM_LENSTR, TM_LENSTR1, GRID_FROM_NAME_XML,
     .            STR_SAME, 
     .            ivar, slen, llen, grid, cx_expr, dset_save,
     .            varid, vtype, nvdims, vdims(8), nvatts, blen, i, 
     .            len_attbuff, attoutflag, all_outflag, attid, 
     .            attlen, attype, iatt, iset, alen, npts, 
     .            num_indices, status, let_d_uvars_list(max_uvar), 
     .            itype
	REAL      vals(100)

        LOGICAL   NC_GET_ATTRIB, got_it, coordvar, newatt, have_units,
     .            have_title, have_dims


	CHARACTER TM_FMT*16
        CHARACTER show_str*128
        CHARACTER uvarname*150, attname*128, attbuff*2048, buff*128,
     .            outstring*2048, aname*128, atype*10

C New form for attribute output, dont implement it yet. (Check the
C Write statement that uses number 2075 when we change to using these.)

 2010  FORMAT ('<var name="', A, '">' )
 2020  FORMAT ('<attribute name="', A, '" type="char">' )
 2030  FORMAT ('<attribute name="', A, '" type="float">' )
 2040  FORMAT ('<attribute name="',  A, '" type="', A,'">' )

 2050  FORMAT ('   <value>', A, '</value>')
 2055  FORMAT ('   <value><![CDATA[', A, ']]></value>')
 2060  FORMAT ('</attribute>')

 2070  FORMAT ('</var>')

* describe the variables in the set, including a report on the axes of this grid.

* Initialize flag for writing axes that are used in the dataset variables.

	DO 100 i = 1, line_ceiling
	   line_write(i) = .FALSE.
 100	CONTINUE

* temporarily make this the default data set

        dset_save = cx_data_set(cx_last)
        cx_data_set(cx_last) = dset

	DO 400 ivar = 1, maxvars
	   IF ( ds_var_setnum(ivar) .NE. dset ) GOTO 400

           IF ( ds_var_code(ivar) .EQ. '-' ) GOTO 400  

* ... output variable code, units, grid, and type

*           slen = TM_LENSTR1(ds_var_code(ivar))

          uvarname = ds_var_code(ivar)

           CALL CD_GET_VAR_ID (dset, uvarname, varid, status)
           CALL CD_GET_VAR_INFO (dset, varid, uvarname, vtype, nvdims,
     .           vdims, nvatts, coordvar, all_outflag, status)

           CALL string_array_get_strlen1(ds_var_code_head, ivar, slen)
           CALL ESCAPE_FOR_XML (uvarname, outstring, slen)
           WRITE ( risc_buff, 2010 ) outstring(1:slen)
	   CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

           slen = TM_LENSTR(ds_var_units(ivar))
           IF (ds_var_units(ivar)(1:2) .NE. char_init 
     .           .AND. slen.GT.0) THEN
              CALL ESCAPE_FOR_XML (ds_var_units(ivar), outstring, slen)
              WRITE ( risc_buff, 2020 ) 'units'
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
              WRITE (risc_buff, 2055) outstring(1:slen)
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
              WRITE ( risc_buff, 2060 ) 
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

           ENDIF

           slen = TM_LENSTR(ds_var_title(ivar))
           IF (ds_var_title(ivar)(1:2) .NE. char_init 
     .           .AND. slen.GT.0) THEN
              CALL ESCAPE_FOR_XML (ds_var_title(ivar), outstring, slen)
              WRITE ( risc_buff, 2020 ) 'long_name'
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
              WRITE (risc_buff, 2055) outstring(1:slen)
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
              WRITE ( risc_buff, 2060 ) 
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
           ENDIF

           slen = TM_LENSTR(ds_var_titl_mod(ivar))
           IF (ds_var_titl_mod(ivar)(1:2) .NE. char_init 
     .           .AND. slen.GT.0) THEN
              CALL ESCAPE_FOR_XML (ds_var_titl_mod(ivar), outstring, slen)
              WRITE ( risc_buff, 2020 ) 'history'
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
              WRITE (risc_buff, 2055) outstring(1:slen)
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
              WRITE ( risc_buff, 2060 ) 
              CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
           ENDIF

! missing_flag comes from attribute FillValue; 
! bad_flag comes from missing_value

          uvarname = ds_var_code(ivar)
          CALL CD_GET_VAR_ID (dset, uvarname, varid, status)
	   
          attname = '_FillValue'
          CALL CD_GET_VAR_ATT_ID (dset, varid, attname, iatt, status)
          IF (status .EQ. ferr_ok) THEN

             CALL CD_GET_VAR_ATT_INFO (dset, varid, iatt, attname, attype, 
     .          attlen, attoutflag, status )
             got_it = NC_GET_ATTRIB (dset, varid, attname, 
     .          .TRUE., uvarname, blen, attlen, 
     .          attoutflag, attbuff, vals)

* For double-prec Ferret, check whether we need more precision to write the value
* If the _FillValue or missing_value are NaN on input, change them to Ferret's 
* default missing value as Ferret does when writing data.

	     show_str = TM_FMT(vals(1), 7,16,slen)
	     IF (STR_SAME(show_str, 'NaN') .EQ. 0) THEN
	       vals(1) = bad_val4
	    ENDIF

	     CALL FLOAT2STRING_FOR_XML (vals(1), attype, show_str, slen)

             CALL ESCAPE_FOR_XML (show_str, outstring, slen)
             WRITE ( risc_buff, 2030 ) '_FillValue' 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE (risc_buff, 2050) outstring(1:slen)
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE ( risc_buff, 2060 ) 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
          ENDIF

          attname = 'missing_value'
          CALL CD_GET_VAR_ATT_ID (dset, varid, attname, iatt, status)
          IF (status .EQ. ferr_ok) THEN

             CALL CD_GET_VAR_ATT_INFO (dset, varid, iatt, attname, attype, 
     .          attlen, attoutflag, status )
             got_it = NC_GET_ATTRIB (dset, varid, attname, 
     .          .TRUE., uvarname, blen, attlen, 
     .          attoutflag, attbuff, vals)
	     
	     show_str = TM_FMT(vals(1), 7,16,slen)
	     IF (STR_SAME(show_str, 'NaN') .EQ. 0) THEN
	       vals(1) = bad_val4
	    ENDIF

	     CALL FLOAT2STRING_FOR_XML (vals(1), attype, show_str, slen)

             CALL ESCAPE_FOR_XML (show_str, outstring, slen)
             WRITE ( risc_buff, 2030 ) 'missing_value'
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE (risc_buff, 2050) outstring(1:slen)
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE ( risc_buff, 2060 ) 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
          ENDIF

          IF (vtype .EQ. NF_CHAR ) THEN
             show_str = 'STRING'
          ELSE
             show_str = 'FLOAT'
          ENDIF
          CALL ESCAPE_FOR_XML (show_str, outstring, slen)
          WRITE ( risc_buff, 2020 ) 'ferret_datatype'
          CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

          WRITE (risc_buff, 2055) outstring(1:slen)
          CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
          WRITE ( risc_buff, 2060 ) 
          CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

* other attributes

           uvarname = ds_var_code(ivar)
           CALL CD_GET_VAR_ID (dset, uvarname, varid, status)
           CALL CD_GET_VAR_INFO (dset, varid, uvarname, vtype, nvdims,
     .           vdims, nvatts, coordvar, all_outflag, status)

* Data type of the variable in the file...

           IF (vtype .EQ. ncbyte ) THEN
              show_str = 'BYTE'
           ELSE IF (vtype .EQ. ncchar ) THEN
              show_str = 'CHAR'
           ELSE IF (vtype .EQ. ncshort ) THEN
              show_str = 'SHORT'
           ELSE IF (vtype .EQ. nclong ) THEN
              show_str = 'LONG'
           ELSE IF (vtype .EQ. ncfloat ) THEN
              show_str = 'FLOAT'
           ELSE IF (vtype .EQ. ncdouble ) THEN
              show_str = 'DOUBLE'
           ENDIF

           CALL ESCAPE_FOR_XML (show_str, outstring, slen)
           WRITE ( risc_buff, 2020 ) 'infile_datatype'
           CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

           WRITE (risc_buff, 2055) outstring(1:slen)
           CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
           WRITE ( risc_buff, 2060 ) 
           CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

* All attributes not already listed.
* Skip 'parent_grid', 'slab_min_index', 'slab_max_index' as these
* wind up causing an incomplete spec of the grid in the F-TDS dataset

           DO 200 iatt = 1, nvatts
              CALL CD_GET_VAR_ATT_INFO (dset, varid, iatt, attname, 
     .              attype, attlen, attoutflag, status )

              newatt = .TRUE.
              newatt = (STR_SAME(attname, 'units') .NE. 0)       .AND. 
     .              (STR_SAME(attname, 'long_name') .NE. 0)      .AND. 
     .              (STR_SAME(attname, 'history') .NE. 0)        .AND. 
     .              (STR_SAME(attname, 'missing_value') .NE. 0)  .AND. 
     .              (STR_SAME(attname, '_FillValue') .NE. 0)     .AND. 
     .              (STR_SAME(attname, 'parent_grid') .NE. 0)    .AND. 
     .              (STR_SAME(attname, 'slab_min_index') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'slab_max_index') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'ferret_datatype') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'infile_datatype') .NE. 0)

              IF (newatt) THEN
                 blen = 2048  ! len of attbuff
                 got_it = NC_GET_ATTRIB (dset, varid, attname, 
     .                                .TRUE., uvarname, blen, attlen, 
     .                                attoutflag, attbuff, vals)
                 IF (attlen .GT. 0) THEN

                 CALL ESCAPE_FOR_XML (attname, aname, slen)

		 IF (attype .EQ. NCCHAR)   atype = 'char'
		 IF (attype .EQ. NCBYTE)   atype = 'byte'
		 IF (attype .EQ. NCSHORT)  atype = 'int'
		 IF (attype .EQ. NCLONG)   atype = 'int'
		 IF (attype .EQ. NCFLOAT)  atype = 'float'
		 IF (attype .EQ. NCDOUBLE) atype = 'double'
		 alen = TM_LENSTR1(atype)

		 WRITE (risc_buff, 2040) aname(1:slen), atype(1:alen)
		 CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

		 IF (attype .NE. NCCHAR) THEN
		    slen = 1
		    attbuff = ' '
		    DO 150 i = 1, attlen
                       CALL FLOAT2STRING_FOR_XML (vals(i), attype, buff, slen)

                       CALL ESCAPE_FOR_XML (buff, outstring, llen)
                       WRITE ( risc_buff, 2050 ) outstring(1:llen)
                       CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
 150                CONTINUE
		 ELSE 
		    CALL ESCAPE_FOR_XML (attbuff, outstring, llen)
		    WRITE ( risc_buff, 2055 ) outstring(1:llen)
		    CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
		 ENDIF

		 WRITE ( risc_buff, 2060 )
		 CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

              ENDIF  ! attlen GT 0
              ENDIF

 200       CONTINUE

           grid = ds_grid_number(ivar)

! If its a string get the name and length of the string dimension.
           IF (vtype .EQ. NCCHAR ) THEN
              CALL CD_GET_DS_DIMS (dset, vdims(1), buff, npts, status)
              CALL SHOW_GRID_STRING_XML (lun, grid, unspecified_int4,
     .                  buff, npts)
	   ELSE
              CALL SHOW_GRID_XML (lun, grid, unspecified_int4)
	   ENDIF

	   WRITE ( risc_buff, 2070 )
	   CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

 400	CONTINUE

* show the data-set-specific user-defined variables

	CALL deleted_list_get_undel(uvar_num_items_head,
     .                              let_d_uvars_list(1),
     .                              max_uvar, num_indices )
	DO 600 ivar = 1, num_indices
           i = let_d_uvars_list(ivar)

	   IF (uvar_dset(i) .EQ. dset .AND.
     .         uvar_parent(i) .EQ. 0   ) THEN

* ... output variable code, units, grid, and type
*     Skip intermediate variables by checking uvar_parent

             uvarname = uvar_name_code(i)
             IF (uvar_parent(i) .NE. 0) GOTO 600
	     IF (uvarname(1:3) .EQ. 'EX#') GOTO 600

	     CALL CD_GET_VAR_ID (dset, uvarname, varid, status)
             CALL CD_GET_VAR_INFO (dset, varid, uvarname, vtype, nvdims, 
     .          vdims, nvatts, coordvar, all_outflag, status)

             CALL ESCAPE_FOR_XML (uvarname, outstring, slen)
             WRITE ( risc_buff, 2010 ) outstring(1:slen)


             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             slen = TM_LENSTR1(uvar_text(i))
             CALL ESCAPE_FOR_XML (uvar_text(i), outstring, slen)
             WRITE ( risc_buff, 2020 ) 'definition'
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE (risc_buff, 2055) outstring(1:slen)
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE ( risc_buff, 2060 ) 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

* Write the units and title
             slen = TM_LENSTR(uvar_units(i))
             IF (uvar_units(i)(1:2) .NE. char_init 
     .             .AND. slen.GT.0) THEN
                slen = TM_LENSTR1(uvar_units(i))
                CALL ESCAPE_FOR_XML (uvar_units(i), outstring, slen)
                WRITE ( risc_buff, 2020 ) 'units'
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
                WRITE (risc_buff, 2055) outstring(1:slen)
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
                WRITE ( risc_buff, 2060 ) 
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
		have_units = .TRUE.
             ENDIF

             slen = TM_LENSTR(uvar_title(i))
             IF (uvar_title(i)(1:2) .NE. char_init 
     .             .AND. slen.GT.0) THEN
                CALL ESCAPE_FOR_XML (uvar_title(i), outstring, slen)
                WRITE ( risc_buff, 2020 ) 'long_name'
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
                WRITE (risc_buff, 2055) outstring(1:slen)
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
                WRITE ( risc_buff, 2060 ) 
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
		have_title = .TRUE.
             ENDIF

! missing_flag and _FillValue same for user-variable 

             CALL FLOAT2STRING_FOR_XML (uvar_bad_data(i), attype, show_str, slen)
             CALL ESCAPE_FOR_XML (show_str, outstring, slen)
             WRITE ( risc_buff, 2030 ) '_FillValue' 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE (risc_buff, 2050) outstring(1:slen)
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE ( risc_buff, 2060 ) 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

             WRITE ( risc_buff, 2030 ) 'missing_value'
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE (risc_buff, 2050) outstring(1:slen)
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
             WRITE ( risc_buff, 2060 ) 
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)


* Now get other attributes that may have been assigned.

	     CALL CD_GET_VAR_ID (dset, uvarname, varid, status)
             CALL CD_GET_VAR_INFO (dset, varid, uvarname, vtype, nvdims, 
     .          vdims, nvatts, coordvar, all_outflag, status)
             IF (status .NE. ferr_ok) GOTO 600  ! or where?
             DO 700 iatt = 1, nvatts

                CALL CD_GET_VAR_ATT_INFO (dset, varid, iatt, attname, 
     .              attype, attlen, attoutflag, status )

* All attributes not already listed.
* Skip 'parent_grid', 'slab_min_index', 'slab_max_index' as these
* wind up causing an incomplete spec of the grid in the F-TDS dataset.
* For transformed variables, the range, min, and max from the original variable
* do not apply.
* Attributes are inherited from the defining variable. That variable got 
* attributes direction, infile_datatype when writing from the header file
* based on the original dataset. ferret_datatype is defined just above. 
* Skip those here.

                newatt = .TRUE.
                newatt = 
     .              (STR_SAME(attname, 'missing_value')  .NE. 0) .AND. 
     .              (STR_SAME(attname, '_FillValue')     .NE. 0) .AND. 
     .              (STR_SAME(attname, 'parent_grid')    .NE. 0) .AND. 
     .              (STR_SAME(attname, 'slab_min_index') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'slab_max_index') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'valid_range') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'valid_min') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'valid_max') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'direction') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'ferret_datatype') .NE. 0) .AND. 
     .              (STR_SAME(attname, 'infile_datatype') .NE. 0)

                IF (STR_SAME(attname, 'units').EQ.0 .AND.have_units) 
     .                newatt = .FALSE.
                IF (STR_SAME(attname, 'long_name').EQ.0 .AND.
     .                have_title) newatt = .FALSE.


                IF (newatt) THEN
                  blen = 2048  ! len of attbuff
                  got_it = NC_GET_ATTRIB (dset, varid, attname, 
     .                                .TRUE., uvarname, blen, attlen, 
     .                                attoutflag, attbuff, vals)
                  IF (attlen .GT. 0) THEN

                   CALL ESCAPE_FOR_XML (attname, aname, slen)

                   IF (attype .EQ. NCCHAR)   atype = 'char'
                   IF (attype .EQ. NCBYTE)   atype = 'byte'
                   IF (attype .EQ. NCSHORT)  atype = 'int'
                   IF (attype .EQ. NCLONG)   atype = 'int'
                   IF (attype .EQ. NCFLOAT)  atype = 'float'
                   IF (attype .EQ. NCDOUBLE) atype = 'double'
                   alen = TM_LENSTR1(atype)

                   WRITE (risc_buff, 2040) aname(1:slen), atype(1:alen)
                   CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

                   IF (attype .NE. NCCHAR) THEN
                      slen = 1
                      attbuff = ' '
                      DO 750 i = 1, attlen
                         CALL FLOAT2STRING_FOR_XML (vals(i), attype, buff, slen)
                         CALL ESCAPE_FOR_XML (buff, outstring, llen)
                         WRITE ( risc_buff, 2050 ) outstring(1:llen)
                         CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
 750                  CONTINUE
                   ELSE 
		      CALL ESCAPE_FOR_XML (attbuff, outstring, llen)
		      WRITE ( risc_buff, 2055 ) outstring(1:llen)
		      CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
		   ENDIF

                   WRITE ( risc_buff, 2060 )
                   CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

                 ENDIF  ! attlen GT 0
                ENDIF  ! newatt
 
 700         CONTINUE

* The grid, if available.
             grid = GRID_FROM_NAME_XML( uvarname, cx_last, cx_expr, status )
	     
             IF (status .EQ. ferr_ok .AND. grid.NE.unspecified_int4) THEN

* Once the grid is set, the dtype is also known. Write that, then the grid.

                iset = uvar_dset(i)
                IF (iset .LE. pdset_irrelevant) iset = pdset_uvars
                CALL GET_SAVED_UVAR_DTYPE(i, iset, itype)

                show_str = 'FLOAT'
                IF (itype .EQ. ptype_string ) show_str = 'STRING'

                CALL ESCAPE_FOR_XML (show_str, outstring, slen)
                WRITE ( risc_buff, 2020 ) 'ferret_datatype'
		
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

                WRITE (risc_buff, 2055) outstring(1:slen)
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
                WRITE ( risc_buff, 2060 ) 
                CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)      

	        CALL SHOW_GRID_XML (lun, grid, cx_expr)

	     ENDIF
             WRITE ( risc_buff, 2070 )
             CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
         ENDIF  ! uvar_dset(i) .EQ. dset .AND. uvar_parent(i) .EQ. 0
 600  CONTINUE


* Write the axes used in the dataset
      
      risc_buff = '</dataset>'
      CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
      risc_buff = '</datasets>'
      CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

      risc_buff = '<axes>'
      CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
      DO 800, i = 1, line_ceiling
         IF (line_write(i)) CALL SHOW_LINE_XML( show_lun, i)
 800  CONTINUE

      risc_buff = '</axes>'
      CALL SPLIT_LIST(pttmode_explct, show_lun, risc_buff, 0)

* were there string variables?  If so write basic info about their string dimensions.

      have_dims = .FALSE.
      DO 900 i = 1, maxvars
         IF ( ds_var_setnum(i) .NE. dset ) GOTO 900
         IF ( ds_var_code(i) .EQ. '-' ) GOTO 900  
         uvarname = ds_var_code(i)

         CALL CD_GET_VAR_ID (dset, uvarname, varid, status)
         CALL CD_GET_VAR_INFO (dset, varid, uvarname, vtype, nvdims,
     .         vdims, nvatts, coordvar, all_outflag, status)
         IF (vtype .EQ. NCCHAR ) THEN
            IF (.NOT.have_dims) THEN
               have_dims = .TRUE.
               risc_buff = '<dimensions>'
               CALL SPLIT_LIST(pttmode_explct, show_lun, risc_buff, 0)
            ENDIF

	    CALL CD_GET_DS_DIMS (dset, vdims(1), buff, npts, status)
            CALL SHOW_DIM_XML(buff, npts, show_lun)
         ENDIF
 900  CONTINUE
                  
      IF (have_dims) THEN
         risc_buff = '</dimensions>'
         CALL SPLIT_LIST(pttmode_explct, show_lun, risc_buff, 0)
       ENDIF

* Restore the default data set

      cx_data_set(cx_last) = dset_save

 5000 RETURN
 5100   CALL errmsg( ferr_unknown_grid, status, 
     .          'Cannot get grid for variable', *5000 )
      END
