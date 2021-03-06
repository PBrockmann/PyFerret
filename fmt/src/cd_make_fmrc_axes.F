	SUBROUTINE CD_MAKE_FMRC_AXES (dset, has_edges, varid, vname, vartype,
     .			    npts, nT, nF, axcalt, axlagf, status)

*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*.
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

* this routine synthesizes the T axis calendar time and F axis lead time
* axes that are needed to support FMRC visualization and analysis
* it uses the 2d time array stored in line_mem, and optionally an array of
* time edge positions stored just behind it

* V695+ *acm* and *sh*
* V698 2/16 *sh* - if identical pre-existing axes exist, re-use them
* V698 3/16 *sh* - F-lag axis starts at 1/2 avg_lag (low cell bound at zero) 

* include files
        include 'netcdf.inc'
	include 'tmap_errors.parm'
#include "gt_lib.parm"
	include 'tmap_dims.parm'
#include "tmap_dset.parm"
	include 'xdset_info.cmn_text'

	include 'xtm_grid.cmn_text'
	external xgt_grid_data
	include 'xbuild_grids.cmn'

	external xdset_info_data
        include 'xdset_info.cd_equiv'
        include 'xio.cmn_text'
        include 'xunits.cmn_text'
        external xunits_data
        include 'calendar.decl'
        include 'calendar.cmn'

* calling argument declarations
	LOGICAL	has_edges
	INTEGER dset, varid, vartype, nT, nF, npts, axcalt, axlagf, status
	CHARACTER*(*) vname


* internal variable declarations
	INTEGER bufflen
	PARAMETER (bufflen = 256)
	CHARACTER TM_STRING*13, buff*256, dbuf*3, vupcase*128, pCR*1

	LOGICAL TM_DFPEQ_TOL, TM_FPEQ_EPS, NC_GET_ATTRIB, 
     .		coordvar, got_it, do_warn, ok_cal, yyyymmdd_time, got_torg
	INTEGER STR_UPCASE, TM_LENSTR1, TM_GET_CALENDAR_ID, TM_UNIT_ID,
     .		TM_FIND_LIKE_DYN_LINE,
     .          i, l, n,  nvdim, vdims(8), nvatts, npts2d,
     .		npts_cdf, ipt1, ipte, iptn, iptnp1,
     .		outflag, next_line_storage, pre_exist,
     .		start(nferdims),count(nferdims), zero(nferdims),
     .          maxlen, attlen, attoutflag, cal_id, since_T0, slen, vlen, 
     .          units, istat, nlag, nleadtimes
	REAL val, epsilon_23, t0NextForecast
	REAL*8 depsilon_46, depsilon, dlast_coord, dfirs_coord,
     .       dfirst_delta, ddelta, avg_lag

        INTEGER tt  ! nice short name
        EQUIVALENCE (tt,lunit_errors)


!* start out by getting an overview of the 2D time variable
!	CALL CD_GET_VAR_INFO (dset, varid, vname, vartype, 
!     .            nvdim, vdims, nvatts, coordvar, outflag, status)

* initialize things
	next_line_storage = next_line_mem_pos
	do_warn = .FALSE.
	pCR = CHAR(15)
	ipt1 = next_line_mem_pos
	ipte = ipt1 + npts - 1
	npts2d = npts  ! save it

*********  FIRST THE 1D CALENDAR TIME AXIS OF THE FMRC  *************
* Define new axis

	CALL TM_ALLO_TMP_LINE (axcalt, status)


* Get units, calendar, origin

* Get the calendar name.

      line_cal_name(axcalt) = 'GREGORIAN'   ! default
      maxlen = bufflen
      got_it = NC_GET_ATTRIB( dset, varid, 'calendar', do_warn,
     .                        vname(:vlen), maxlen, attlen, attoutflag, 
     .                        buff, val)
      IF (got_it) then
         CALL CD_GET_CALENDAR_NAME(buff, ok_cal)
         IF (ok_cal) THEN
	    line_cal_name(axcalt) = buff
	 ELSe
            slen = TM_LENSTR1(buff)
            CALL TM_NOTE('calendar attribute for 2D Time variable "'//
     .               vname(:vlen)//'" is not recognized: '//buff(1:slen), tt)
            CALL TM_NOTE('Assuming Gregorian calendar', tt)
         ENDIF
      ENDIF
      cal_id = TM_GET_CALENDAR_ID (line_cal_name(axcalt))

* optional units for axis (may contain "tunits since T0_date" 2/95)
      line_units(axcalt) = ' '   ! default
      maxlen = bufflen
      got_it = NC_GET_ATTRIB( dset, varid, 'units', do_warn,
     .                        vname(:vlen), maxlen, attlen, attoutflag, 
     .                        buff, val)
      since_T0 = MAX( INDEX(buff,'since'), INDEX(buff,'SINCE') )
      yyyymmdd_time = buff(1:15) .EQ. 'yyyymmddhhmmss'

      IF ( since_T0 .GT. 2 ) THEN
         line_units(axcalt) = buff(:since_T0-1)  ! just the "tunits" part 

         istat = STR_UPCASE( dbuf, buff(1:3) )

         slen = TM_LENSTR1(buff)
         IF ( slen .GT. since_T0 + 5) THEN

            got_torg = .TRUE.
            CALL TM_DATE_REFORMAT(buff(since_T0+6:),pdate_numslashnum,
     .                            cal_id, line_t0(axcalt), 
     .                            pdate_vax, .FALSE., status )

c fix for bug 1394
c If the part after since is not a date/time, just keep the whole
c string as the units.  i.e., "days_since_event".

c           IF ( status .NE. merr_ok ) GOTO 1000        ! 3/99 soft error 

            IF ( status .NE. merr_ok ) THEN   
               line_units(axcalt) = buff(1:slen)
               got_torg = .FALSE.
               since_t0 = 0
               status = merr_ok
            ENDIF
         ELSE
            since_t0 = 0        ! flag that no T0 was present
         ENDIF
      ELSEIF ( yyyymmdd_time ) THEN
         line_units(axcalt) = 'days'
         line_t0(axcalt) = ' ' ! to be determined when coords are read
         got_torg = .TRUE.
      ELSE
         IF (got_it) line_units(axcalt) = buff
         got_torg = .FALSE.
      ENDIF

* ... decode the units

      units = TM_UNIT_ID( line_units(axcalt) )

* Named calendar with unit=year gets length of year in that calendar.

      IF (units .EQ. -6 .OR. units .EQ. -10) THEN
         IF (cal_id .EQ. d360) units = -9
         IF (cal_id .EQ. julian) units = -12
	 IF (cal_id .EQ. noleap) units = -11
	 IF (cal_id .EQ. all_leap) units = -8
      ENDIF

* Named calendar with unit=month gets length of month in that calendar.

      IF (units .EQ. -5) THEN
         IF (cal_id .EQ. d360) units = -14
         IF (cal_id .EQ. julian) units = -15
	 IF (cal_id .EQ. noleap) units = -13
      ENDIF

      line_unit_code(axcalt) = units
      IF  ( units.EQ.0 .AND. line_units(axcalt) .NE. ' ' ) THEN
         CALL TM_NOTE('Units on axis "'//vname(:vlen)//
     .                '" are not recognized: '//line_units(axcalt), tt)
         CALL TM_NOTE('They will not be convertible:', tt)
      ENDIF
      IF ( units .GE. 0 ) THEN
         line_tunit(axcalt) = real4_init
      ELSE
         line_tunit(axcalt) = un_convert(line_unit_code(axcalt))
      ENDIF

* The units must describe calendar time 

      ! check that this has mapped to the right TF orientation
      IF (line_tunit(axcalt) .NE. real4_init) THEN
         line_direction(axcalt) = 'TI'
      ELSE
         GOTO 5400
      ENDIF


* save some values needed for the forecast lead time axis
* average lag time (lag is constant except in case of monthly forecasts)
* and how many lag time steps before the subsequent forecast begins?
	avg_lag = (line_mem(ipt1+nT*(nF-1))-line_mem(ipt1))
     .	        / (nF-1)
	t0NextForecast = line_mem(ipt1+nT)
	DO nlag = 1, nT-1
	   IF (line_mem(ipt1+nlag) .EQ. t0NextForecast) GOTO 200
	ENDDO
	CALL TM_NOTE('Corrupted FMRC time array'//pCR//
     .		     'Time values dont match between forecasts', lunit_errors)

* Extract the unique values from the 2d array into a 1d "best time series" line
* the length of the forecasts is nT
* the number of forecasts is nF
* create the 1D array by traveling along each forecast and pulling out points
* until we reach the value of the first time step in the next forecast
 200	npts  = 0
	iptn = ipt1                ! start of forecast n
	DO n = 1, nF         ! n index loops over forecasts
	   iptnp1 = iptn + nT
	   l = 0                   ! zero-based l index over input time axis
	   IF (iptnp1 .LT. ipte) THEN
*   .. copy early time step values from this forecast into 1D axis
 	      DO WHILE (line_mem(iptn+l) .LT. line_mem(iptnp1))
	         line_mem(ipt1+npts) = line_mem(iptn+l)
	         IF (has_edges)  line_mem(ipt1+npts+npts2d) =
     .			         line_mem(iptn+l+npts2d)
	         npts  = npts + 1
	         l = l + 1
	      ENDDO
	   ELSE
*   .. copy all time step values from the final forecast into the 1D axis
	      DO l = 0, nT-1
	         line_mem(ipt1+npts) = line_mem(iptn+l)
	         IF (has_edges)  line_mem(ipt1+npts+npts2d) =
     .			         line_mem(iptn+l+npts2d)
	         npts  = npts + 1
	      ENDDO
	   ENDIF
	   iptn = iptnp1
	ENDDO

* now that the length of the 1D time axis is known, shift the edge bounds
* coordinates into their proper spot at the end of the coordinates
	IF (has_edges) THEN
	   DO i = 0, npts-1
	      line_mem(ipt1+npts+i) = line_mem(ipt1+npts2d+i)
	   ENDDO
	   line_mem(ipt1+2*npts) = line_mem(ipt1+2*npts2d)
        ENDIF

* ... until proven otherwise, this will look like an irregular axis
        line_subsc1(axcalt) = next_line_mem_pos
	line_dim(axcalt) = npts
	ipte = ipt1 + npts-1
	
* from cd_get_1_axis.
* check for regular spacing according to the data type of incoming data.
* the variables (depsilon, etc) are in double precision. The tolerance
* chec, in TM_FPEQ_EPS is done to an equivalent single precision tol.

	IF (vartype .EQ. ncdouble) THEN
	   dlast_coord = line_mem(ipte)
           dfirs_coord = line_mem(ipt1)
           dfirst_delta = line_mem(ipt1+1) - line_mem(ipt1)
           depsilon = depsilon_46 * 2.*(ABS(line_mem(ipt1)) / dfirst_delta )

	   DO 340 i = ipt1+2, ipte	
	      ddelta = line_mem(i) - line_mem(i-1)
	      IF (.NOT. TM_DFPEQ_TOL(dfirst_delta, ddelta, depsilon) ) GOTO 380
  340	   CONTINUE
	ELSE
           dlast_coord = line_mem(ipte)
           dfirs_coord = line_mem(ipt1)
           dfirst_delta = line_mem(ipt1+1) - line_mem(ipt1)
           depsilon = epsilon_23 * 2.*(ABS(line_mem(ipt1)) / dfirst_delta )

           DO 360 i=ipt1+2,ipte
              ddelta = line_mem(i) - line_mem(i-1)
              IF (.NOT. TM_FPEQ_EPS(depsilon, dfirst_delta, ddelta) ) GOTO 380
  360      CONTINUE
	ENDIF

* It's regular - save it as such
	line_regular(axcalt) = .TRUE.
	line_start  (axcalt) = line_mem(ipt1)
	line_delta  (axcalt) = 
     .              (line_mem(ipte)-line_mem(ipt1))/DBLE(npts-1)
	line_subsc1 (axcalt) = unspecified_int4

	GOTO 390

*  Irregular
  380	line_regular(axcalt) = .FALSE.
	IF ((next_line_mem_pos+2*npts+1).GT.maxlinestore) GOTO 5300
	IF (.NOT.has_edges) CALL TM_IRREGAX_MID( ipt1, npts )
	

 390	CONTINUE
 
* Save the axis name (upper case) and memory storage.  For all irregular axes, 
* we have saved N+1 edges for the axis cells. Increment the pointer.   
	CALL TM_NEW_LINE_NAME ( 'TF_CAL_T', buff )
	line_name(axcalt) = buff
	line_name_orig(axcalt) = buff
        IF ( .NOT.line_regular(axcalt) ) THEN
           next_line_mem_pos =  next_line_storage + 2*npts+1 
        ENDIF
	line_dattype(axcalt) = nf_double

*********  NOW FINALLY THE FORECAST LEAD TIME AXIS OF THE FMRC  *************
* lead times are only meaningful where runs overlap
* each forecast run contains nT time steps
* each forecast run lags the preceding by nlag time steps
* when the nT/nlag ration exceeds integer, there is a partial lead
* time cell on the F axis
        nleadtimes = (nT-1)/nlag + 1

	CALL TM_NEW_LINE_NAME ( 'TF_LAG_F', buff )
! pre 3/16	CALL TM_MAKE_BASIC_AXIS( buff, 0.0D0, avg_lag,
	CALL TM_MAKE_BASIC_AXIS( buff, avg_lag/2., avg_lag,
     .			nleadtimes, axlagf, status )

* inherit time units from the calendar time axis just created
	line_unit_code(axlagf) = line_unit_code(axcalt)
	line_units(axlagf)     = un_name(line_unit_code(axlagf))
	line_direction(axlagf) = 'FF'
	line_dattype(axlagf)   = nf_double
	line_dim_only(axlagf)  = .FALSE.    ! ?? why ??

********************
* We've gone to a lot of trouble creating this axis.  But if it is an exact
* duplicate of a pre-existing axis, then we should use that instead.
* (Shared axes are needed in order to E-aggregate multiple FMRCs)
 	pre_exist = TM_FIND_LIKE_DYN_LINE( axcalt )
 	IF (pre_exist .NE. unspecified_int4) THEN
 	   CALL TM_DEALLO_DYN_LINE(axcalt)
 	   axcalt = pre_exist
 	ENDIF
	pre_exist = TM_FIND_LIKE_DYN_LINE( axlagf )
	IF (pre_exist .NE. unspecified_int4) THEN
	   CALL TM_DEALLO_DYN_LINE(axlagf)
	   axlagf = pre_exist
	ENDIF

* successful completion
        status = merr_ok

 5000	RETURN


 5300	CALL TM_ERRMSG (merr_linstorlim, status, 'CD_MAKE_FMRC_AXES',
     .                  no_descfile, no_stepfile,
     .                  'MAX='//TM_STRING(DBLE(maxlinestore)),
     .                  no_errstring, *5000)

 5400	CALL TM_ERRMSG (merr_notimeinfo, status, 'CD_MAKE_FMRC_AXES',
     .                  no_descfile, no_stepfile,
     .                  'unrecognizable time encoding',
     .                  no_errstring, *5000)

	RETURN
	END
