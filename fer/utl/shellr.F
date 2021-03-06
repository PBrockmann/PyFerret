      SUBROUTINE SHELLR(SDAT, IDAT, BAD, N)

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
*from http://www.cs.mcgill.ca/~ratzer/progs15_6.html  23-APR-1998
*  Gerald Ratzer, McGill school of Computer Science, McGill University,
*  Montreal, Quebec, Canada

* Changed data to REAL. Added IDAT, to sort along with SDAT.  
* Removed NCOUNTS, NCOMP, NSWAP.

* V530 *sh* - based on SHELL (also in Ferret)
* optimized for missing value flags in input (sort to end of list)



      REAL     SDAT(*),IDAT(*), BAD, tmp
      INTEGER  N, M
      INTEGER  I, J, ngd

* since the input array may be large but sparse, begin by sorting
* the missing value flags to the end of the list
        ngd = 0
        DO j = 1, n
           IF (sdat(j) .NE. bad) THEN
              ngd = ngd + 1
              sdat(ngd) = sdat(j)
              idat(ngd) = idat(j)
           ENDIF 
        END DO

        DO j = ngd+1, n
           sdat(j) = bad
           idat(j) = 0.0  ! just for house-keeping
        END DO

* now sort only the valid (non-BAD) inputs
      M=ngd
      DO WHILE (M .gt. 1)
         M=(M+2)/3
         DO I=M+1,ngd
            DO J=I,M+1,-M
               IF (SDAT(J-M).GE. SDAT(J)) THEN
                 tmp = sdat(j)
                 sdat(j) = sdat(j-m)
                 sdat(j-m) = tmp
                 tmp = idat(j)
                 idat(j) = idat(j-m)
                 idat(j-m) = tmp
               ENDIF
            END DO 
         END DO 
      END DO
      RETURN
      END

