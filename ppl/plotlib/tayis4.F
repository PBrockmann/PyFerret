      SUBROUTINE TAYIS4(TLO,ITIME1,ITIME2,DT,NSMTIC,LABEL,IHDB,IDDB,
     .    TFACT,X,XFACT,CSIZE,xacross,hgrat,hcolor,hline,color0,
     .    is_hours_axis)

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
* From tayis0: separate routine for hour:min labeling on time axes
C V7.1 *acm* 8/2016 Ticket 2466: Graticule lines too dense
* *acm* - 8/16   ticket 1787: restore pen 0 correctly after graticule
* *acm* - 9/16   ticket 2466: graticule lines on major tics by default
*                Rewrite this routine to make it echo taxis4.F
C
C**
C**    @(#)tayis4.f	1.1   12/09/15
C**
C**
C***********************************************************************
C**
C**                 PLOT+ Scientific Graphics System
C**
C***********************************************************************
C**
C**
C     THIS ROUTINE PLOTS A TIME AXIS AND LABELS IT WITH THE HOUR, MINUTE.
C     VARIBLES:
C         TLO=X VALUE CORRESPONDING TO THE START TIME.
C         ITIME1 = START TIME (IE.  7708190100)
C                  WE RESTRICT THE PERMISSIBLE START TIMES TO BE
C                  EVEN HOURS.  (THAT IS THE LAST 4 DIGITS OF ITIME1
C                  MUST BE 0)
C         ITIME2 = END TIME (IE   7709072300)
C                  THIS IS THE FIRST HOUR NOT TO BE PLOTTED, AND IT
C                  MUST BE AN EVEN HOUR.
C         DT = SAMPLING RATE IN MINUTES.
C         NSMTIC = NUMBER OF SMALL TICS TO MAKE EACH HOUR.
C         LABEL > 0 IF LABELS ARE TO BE DRAWN ABOVE THE AXIS.
C               = 0 IF NO LABELS ARE TO BE DRAWN.
C               < 0 IF LABEL ARE TO BE DRAWN BELOW THE AXIS.
C         IABS(LABEL) = 1 FOR LABELS OF THE STYLE
C                  1..........1..........1..........1..........1
C                       3           4          5        6
C                                    JUN 7
C         IHDB = PRINT LABELS OF HOURS DIVIBLE BY THIS NUMBER ONLY.
C                IF(IHDB = 0) PRINT NO DAY LABELS.
C         IDDB = PRINT LABELS OF DAYS DIVISIBLE BY THIS NUMBER ONLY.
C                IF(IDDB = 0) PRINT NO MONTH LABELS.
C                THIS VARIBLE ONLY APPLYS WHEN IABS(LABEL) = 1
C         TFACT = (LENGTH OF T AXIS IN INCHES)/(LENGTH OF T AXIS IN USER
C         X = X COORDINATE OF TIME AXIS. 
C         XFACT = (LENGTH OF X AXIS IN INCHES)/(LENGTH OF X AXIS IN USER 
C         CSIZE = SIZE TO DRAW HOUR LABELS.
C                 DAY LABELS WILL BE 1.5 TIMES AS LARGE.
C
C
C     THIS ROUTINE WAS FIRST WRITTEN BY DAVID MANDEL IN JULY 1980.
C
	CHARACTER ITIME3*14,DATE*6,BUFF*14,YEAR*4
	CHARACTER ITIME*14,ITIME1*14,ITIME2*14,SYM*21
	COMMON/TICS/TSMX,TLX,TSMY,TLY,IX,IY
	COMMON/AXLWID/XWID,YWID


	REAL*8  DIFF, difft
	REAL*8  td, xtemp1, tfact_d, xfact_d
	REAL    delt, rem, angl
	INTEGER is_hours_axis, labint, ticint, hrint
	LOGICAL hvytic

* Parameters for drawing tics across plot

        REAL xacross
        REAL dash1_1, dash1_2, dash1_3, dash1_4
        REAL dash2_1, dash2_2, dash2_3, dash2_4
        REAL hgrat(4,2)        ! line type: 0=tics only, <0=line, >0=dash lengths 
        INTEGER hcolor(*)      ! pen number for graticule lines
	INTEGER hcolor0	       ! pen number to restore
        LOGICAL hline          ! If true, do the lines across.
        LOGICAL solid1, solid2   ! solid lines across at tics
        LOGICAL dashed1, dashed2 ! dashed lines across at tics
        INTEGER ltic, color1, color2
	LOGICAL heavy_at_labels  ! When lots of tic marks, make heavy 
				 !tic/graticule at the location of labels.

* TMAP interrupt flag
	include 'xinterrupt.cmn'
        include 'century.cmn'  ! with MONYRLAB flag
	
  80	FORMAT(I2.2)
  82	FORMAT(I2.2,':00')
  84	FORMAT(I2.2,':',I2.2)

	difft = DIFF(ITIME1,ITIME2)
	angl = 0.

C     CHECK THE PARAMETERS PASSED TO THE SUBROUTINE.

	IF (is_hours_axis .EQ. 0) THEN
	   IF(ITIME1(9:10).NE.'00')STOP ',1'  ! MINUTE,SECOND ARE 0
	   IF(ITIME2(9:10).NE.'00')STOP ',2'
	ENDIF

        IF(ITIME1(13:14)//ITIME1(1:12).GE.
     .	   ITIME2(13:14)//ITIME2(1:12)) STOP',3'

C     SET PARAMETERS.
        TIC = 60./DT  
        TICd = 60./DT  
        NTIC = NSMTIC + 1
        delt = 60.
        labint = 120
	ticint = labint
	hrint = 1
      
! On short-time interval axes, tic and label interval
! for hours axis (is_hours_axis eq 1) if difft > 60,
! then labint, ticint should be on the hour or half hour, so
! multiples of 30.
! for more than 12 hours, label on a multiple of even hours, 
! up to a max of 36 hours labeled hh:mm (set in taxis_style)

	IF (is_hours_axis.EQ.1) THEN
           labint = 30
           delt = 1.
	   ticint = 5
           IF (difft .GE.  300) labint = 60
           IF (difft .GE.  600) labint = 120
	   IF (difft .GE.  300) ticint = 30
           IF (difft .GE. 1200) hrint = 2
           IF (difft .GE. 1800) hrint = 4
        ENDIF
        IF (is_hours_axis.EQ.2) THEN
           labint = 10
           delt = 1
	   ticint = 1
           IF (difft .LE. 30) labint = 5
           IF (difft .LE. 20) labint = 4
           IF (difft .LE. 10) labint = 1
           IF (difft .GE. 60) ticint = 2
           IF (difft .GE. 120) ticint = 4
           IF (difft .GE. 240) ticint = 4
        ENDIF

        tic = delt/dt
        ticd = delt/dt

C set up for plotting graticules across at tic marks
        
        solid1 = (hgrat(1,1).LT.0 .AND. hgrat(2,1).LT.0 .AND.  
     .            hgrat(3,1).LT.0 .AND.  hgrat(4,1).LT.0 )
        solid2 = (hgrat(1,2).LT.0 .AND. hgrat(2,2).LT.0 .AND.  
     .            hgrat(3,2).LT.0 .AND.  hgrat(4,2).LT.0 )
        dashed1 = (hgrat(1,1).GT.0 .OR. hgrat(2,1).GT.0 .OR.  
     .            hgrat(3,1).GT.0 .OR.  hgrat(4,1).GT.0 )
        dashed2 = (hgrat(1,2).GT.0 .OR. hgrat(2,2).GT.0 .OR.  
     .            hgrat(3,2).GT.0 .OR.  hgrat(4,2).GT.0 )

        color1 = hcolor(1)
        color2 = hcolor(2)

        IF (dashed1) THEN
           dash1_1 = hgrat(1,1)
           dash1_2 = hgrat(2,1)
           dash1_3 = hgrat(3,1)
           dash1_4 = hgrat(4,1)
        ENDIF
        IF (dashed2) THEN
           dash2_1 = hgrat(1,2)
           dash2_2 = hgrat(2,2)
           dash2_3 = hgrat(3,2)
           dash2_4 = hgrat(4,2)
        ENDIF
C

	IF(NSMTIC.LT.0)THEN
		IHVY=-6
		INML=-5
	ELSE
		IHVY=-10
		INML=-6
		TDIST = TIC/NTIC
	ENDIF
	IF(LABEL+IY.EQ.0)THEN
		XTEMP=0.0
	ELSE
		XTEMP=TLY*0.5
	ENDIF
	IF(IHDB.NE.0)THEN
	FIHDB=0.0
	ELSE
	FIHDB=-1.4
	ENDIF

      XTEMP1=X+DBLE(LABEL*(0.9*CSIZE+XTEMP)/XFACT)
      IF (is_hours_axis.GT.0 .AND. LABEL.LT.0) XTEMP1=XTEMP1-1.5*CSIZE/XFACT
      IF(LABEL.LT.0) THEN
          XTEMP2=X-((4.0+FIHDB)*CSIZE+XTEMP)/XFACT
          IF (is_hours_axis.GT.0) XTEMP2=XTEMP2-1.5*CSIZE/XFACT
      ELSE
          XTEMP2=X+((2.5+FIHDB)*CSIZE+XTEMP)/XFACT
         IF (is_hours_axis.GT.0) XTEMP2=X+3*CSIZE/XFACT
      ENDIF

      IF(LABEL.NE.0)YWID=(4.0+FIHDB)*CSIZE+XTEMP
      T=TLO  ! Time in hours, plot units
      td = tlo
      ITIME=ITIME1
      CALL TIME3(ITIME,IYR,IMON,IDAY,IHR,IMIN,ISEC,ICEN)
      TDAY=T

      tfact_d = tfact
      xfact_d = xfact
	
      CALL PLOT(X,TLO,0,0)
      IF(IHR.EQ.0 .AND.is_hours_axis.EQ.0 )THEN
         CALL PLOTT7(X,TLO,XFACT,TFACT,1,IHVY)  ! draw to the location and make a mark
      ELSE
         IF (MOD(imin,labint) .EQ. 0) THEN
            CALL PLOTT7(X,TLO,XFACT,TFACT,1,IHVY)
         ELSE
	    CALL PLOTT7(X,TLO,XFACT,TFACT,1,INML)
         ENDIF
      ENDIF
	
      CALL TIME1(1,ITIME,2,' ',I3,ITIME3,delt)  ! next time stepping from 1 (arg 1) to 2 (arg 2) -- return ITIME3
      ITIME = ITIME3

c Check whether to make an hour label at the start of the axis
c ihdb is hour-label frequency
      IF(IABS(LABEL).EQ.1) THEN
         IF (IHR.EQ.IHDB*(IHR/IHDB) .AND. is_hours_axis.EQ.0) THEN 
            WRITE(SYM,80) IHR
	    CALL scinot_d(XTEMP1,td,0.,CSIZE,2,SYM,0,wid,xfact_d, tfact_d)
	 ENDIF
	   IF (is_hours_axis .GT. 0) THEN
	    IF (IMIN .EQ. 0) THEN
               WRITE(SYM,82) IHR
	       CALL scinot_d(XTEMP1,td,angl,CSIZE,5,SYM,0,wid,xfact_d, tfact_d)
	    ENDIF
	 ENDIF
      ENDIF

c ----  count number of large tics. If no large tics will be drawn
c ----  then will want to draw graticule lines at the small ones.

c Set itime1, itime3 as above

      ITIME=ITIME1
      CALL TIME3(ITIME,IYR,IMON,IDAY,IHR,IMIN,ISEC,ICEN)
      CALL TIME1(1,ITIME,2,' ',I3,ITIME3,delt) 
      ITIME = ITIME3

C      LOOP:
       ltic = 0
  110  CONTINUE

	CALL TIME3(ITIME,IYR,IMON,IDAY,IHR,IMIN,ISEC,ICEN)
  	CALL TIME1(1,ITIME,2,' ',I3,ITIME3,delt)
	ITIME=ITIME3

	IF(ITIME(13:14)//ITIME(1:12) .LE.
     .       ITIME2(13:14)//ITIME2(1:12)) THEN
           IF(IHR.EQ.0 .AND. is_hours_axis.EQ.0) ltic = ltic + 1
c           IF(IHR.EQ.0 .AND. imin.EQ.0 .AND. is_hours_axis.GT.0) ltic = ltic + 1
	   IF (is_hours_axis .GT. 0) THEN
	      IF (difft.LE.12 .AND. sec.EQ.0.) THEN 
	         ltic = ltic+1
              ELSE
	         IF (imin.EQ.0. .AND. ihr.NE.0) ltic = ltic+1
              ENDIF
	   ENDIF
           GO TO 110
        ENDIF
     
! IF no large tics, and if graticules at just the large tics were
! requested, then plot graticules at the small tics

	IF (ltic .EQ. 0) THEN   
           IF ( (.NOT.solid2) .AND. (solid1) ) THEN
              solid2 = solid1
              color2 = color1
           ENDIF
           IF ( (.NOT.dashed2) .AND. (dashed1) ) THEN 
              dashed2 = dashed1
              dash2_1 = dash1_1
              dash2_2 = dash1_2
              dash2_3 = dash1_3
              dash2_4 = dash1_4
              color2 = color1
           ENDIF

        ENDIF

! IF many large tics, make fewer - at the locations of labels
        heavy_at_labels = ltic .GT. 20

! Restore the state of ITIME, ITIME3
      ITIME=ITIME1
      CALL TIME3(ITIME,IYR,IMON,IDAY,IHR,IMIN,ISEC,ICEN)

      CALL TIME1(1,ITIME,2,' ',I3,ITIME3,delt)
      ITIME = ITIME3

c ----

C      LOOP:
   10     CALL PLOT(X,T,0,0)
	  IF ( interrupted ) RETURN		! TMAP interrupt
          DO 20 I=1,NSMTIC
              CALL PLOTT7(X,T+FLOAT(I)*TDIST,XFACT,TFACT,1,INML)

              IF ((solid2.OR.dashed2) .AND. hline) THEN ! make line across
                 CALL COLOR(color2)
                 IF (dashed2) THEN
                    CALL DASHSZ(dash2_1,dash2_2,dash2_3,dash2_4)
                    CALL DASHES
                 ENDIF
                 CALL PLOT(X,T+FLOAT(I)*TDIST,0,0) 
                 CALL PLOT(xacross,T+FLOAT(I)*TDIST,1,0)
                 CALL PLOT(X,T+FLOAT(I)*TDIST,0,0) 
                 CALL COLOR(color0)
                 CALL VECTRS
              ENDIF

   20     CONTINUE
          CALL TIME3(ITIME,IYR,IMON,IDAY,IHR,IMIN,ISEC,ICEN)
	  
          hvytic = ((is_hours_axis.EQ.0 .AND. IHR.EQ.0) .OR. 
     .            (is_hours_axis.GT.0 .AND. MOD(imin,labint).EQ.0))
     	  IF (heavy_at_labels) THEN
             IF (is_hours_axis .GT. 0) THEN
	        hvytic = ( (imin .EQ. 0 .AND. MOD(ihr,hrint).EQ.0) .OR. 
     .                     (MOD(imin,labint) .EQ. 0 .AND. hrint.LE.1) )
             ELSE
	        hvytic = (IHR.EQ.IHDB*(IHR/IHDB))
	     ENDIF
	  ENDIF

          IF(hvytic)THEN
             CALL PLOTT7(X,T+TIC,XFACT,TFACT,1,IHVY)
	
              IF ((solid1.OR.dashed1) .AND. hline) THEN ! make line across
                 CALL COLOR(color1)
                 IF (dashed1) THEN
                    CALL DASHSZ(dash1_1,dash1_2,dash1_3,dash1_4)
                    CALL DASHES
                 ENDIF
                 CALL PLOT(X,t+tic,0,0) 
                 CALL PLOT(xacross,t+tic,1,0)
                 CALL PLOT(X,t+tic,0,0) 
                 CALL COLOR(color0)
                 CALL VECTRS
              ENDIF
      
	  ELSE
              IF (is_hours_axis.GT.0) THEN
	         IF (MOD(imin,ticint).EQ.0) THEN
                    CALL PLOTT7(X,T+TIC,XFACT,TFACT,1,INML)
		    
c                 graticule line at tic
		    IF ((solid2.OR.dashed2) .AND. hline) THEN ! make line across
                       CALL COLOR(color2)
                       IF (dashed2) THEN
                          CALL DASHSZ(dash2_1,dash2_1,dash2_3,dash2_4)
                          CALL DASHES
                       ENDIF
                       CALL PLOT(x,t+tic,0,0) 
                       CALL PLOT(xacross,t+tic,1,0)
                       CALL PLOT(x,t+tic,0,0) 
                       CALL COLOR(color0)
                       CALL VECTRS
                    ENDIF

		 ELSE 
                    CALL PLOT(X,T+TIC,1,0)
		 ENDIF
              ELSE
	         CALL PLOTT7(X,T+TIC,XFACT,TFACT,1,INML)
		 
c                 graticule line at tic
                    IF ((solid1.OR.dashed1) .AND. hline) THEN ! make line across
                       CALL COLOR(color1)
                       IF (dashed1) THEN
                          CALL DASHSZ(dash1_1,dash2_1,dash1_3,dash1_4)
                          CALL DASHES
                       ENDIF
                       CALL PLOT(x,t+tic,0,0) 
                       CALL PLOT(xacross,t+tic,1,0)
                       CALL PLOT(x,t+tic,0,0) 
                       CALL COLOR(color0)
                       CALL VECTRS
                    ENDIF

              ENDIF
    

	ENDIF
C         THE LABELS

	  IF (IABS(LABEL).EQ.1) THEN
             IF (is_hours_axis .GT. 0) THEN
	        IF (imin .EQ. 0 .AND. MOD(ihr,hrint).EQ.0) THEN
	           WRITE(SYM,82) IHR
	           CALL scinot_d(XTEMP1,Td+TICd,0.,CSIZE,5,SYM,0,wid,xfact_d, tfact_d)
		ELSE
                   IF (MOD(imin,labint) .EQ. 0 .AND. hrint.LE.1) THEN
		      WRITE(SYM,84) ihr, imin
	              CALL scinot_d(XTEMP1,Td+TICd,0.,CSIZE,5,SYM,0,wid,xfact_d, tfact_d)
		   ENDIF
		ENDIF
             ELSE
	        IF(IHR.EQ.IHDB*(IHR/IHDB)) THEN
	           WRITE(SYM,80) IHR
	           CALL scinot_d(XTEMP1,Td+TIC,td,angl,CSIZE,2,SYM,0,wid,xfact_d, tfact_d)
	        ENDIF
             ENDIF
	  ENDIF

          CALL TIME1(1,ITIME,2,' ',I3,ITIME3,delt)
          IF(IDDB.EQ.0.OR.IABS(LABEL).NE.1) GO TO 70
              CALL TIME3(ITIME3,IYR3,IMON3,IDAY3,IHR3,IMIN3,ISEC3,ICEN3)
              IF(IDAY.EQ.IDAY3) GO TO 70
              IF(IDAY.NE.IDDB*(IDAY/IDDB))GO TO 60
C             ELSE:
	IF(T-TDAY.GT.180./DT)THEN
           CALL TIME2(ITIME,SYM)
	   READ(SYM,55) DATE, YEAR
55	   FORMAT(6X,A6,1X,A4)
65         FORMAT(A6,1X,A4)
           IF (MONYRLAB) THEN
	      WRITE (BUFF, 65) DATE, YEAR
              TSYM=TDAY+(T+TIC-TDAY-SYMWID(CSIZE,14,BUFF)/TFACT)*.5
              CALL SYMBEL(XTEMP2,TSYM,90.,CSIZE,14,BUFF)
	   ELSE
              TSYM=TDAY+(T+TIC-TDAY-SYMWID(1.5*CSIZE,6,DATE)/TFACT)*.5
	      CALL SYMBEL(XTEMP2,TSYM,90.,1.5*CSIZE,6,DATE)
	   ENDIF
	ENDIF
   60   TDAY=T+TIC
   70     CONTINUE
          ITIME=ITIME3
          T=T+TIC
	  td = td + ticd
	  t=td
c          IF(ITIME.LE.ITIME2) GO TO 10

          IF(ITIME(13:14)//ITIME(1:12) .LE.
     .       ITIME2(13:14)//ITIME2(1:12)) GO TO 10

      IF(IDDB.EQ.0) RETURN

      IF(IABS(LABEL).EQ.1.AND.IDAY.EQ.IDDB*(IDAY/IDDB) ) THEN
         IF (is_hours_axis.GT.0 .OR. IHR3.GE.4) THEN
           CALL TIME2(ITIME,SYM)
	   READ(SYM,55) DATE, YEAR
	   IF (MONYRLAB) THEN
	      WRITE (BUFF, 65) DATE, YEAR
              TSYM=TDAY+(T-TDAY-SYMWID(CSIZE,14,BUFF)/TFACT)*.5
              CALL SYMBEL(XTEMP2,TSYM,90.,CSIZE,14,BUFF)
           ELSE
              TSYM=TDAY+(T-TDAY-SYMWID(1.5*CSIZE,6,DATE)/TFACT)*.5
	      CALL SYMBEL(XTEMP2,TSYM,90.,1.5*CSIZE,6,DATE)
           ENDIF

         ENDIF
      ENDIF


c Finish out the line
      CALL PLOT (X,TLO,0,0)
      t = TLO + DIFF(ITIME1, ITIME2)/dt
      CALL PLOT (X,T,1,0)
      CALL COLOR(color0)

      RETURN
      END
