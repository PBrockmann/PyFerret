	PROGRAM TEST_STREAM

* For gfortran under linux 2/2012, with double-precision Ferret,
* gfortran -o make_stream_file -Dreclen_in_bytes -Ddouble_p -fdefault-real-8 -fdefault-double-8 make_stream_file.F

	INTEGER i,j

	REAL myvar(10,5)

* generates a test file of REAL direct access values
!	  1  2  3  4  5  6  7  8  9 10
!	 11 12 13 14 15 16 17 18 19 20
!	 21 22 23 24 25 26 27 28 29 30
!	 31 32 33 34 35 36 37 38 39 40
!	 41 42 43 44 45 46 47 48 49 50

* fill with dummy data
	DO 5 j = 1,5
	DO 5 i = 1,10
 5	myvar(i,j) = (j-1)*10+i


* messages to user
	WRITE (6,*)
     .		'Creating machine-specific binary file stream10by5.unf'
	WRITE (6,*)
     .		'Remember to mv stream10by5.unf to stream10by5_{$machine}.unf'

#ifdef double_p
* create output file
	OPEN(UNIT=20,
     .	     STATUS='unknown',
     .	     FILE='stream10by5.unf',
     .	     ACCESS='DIRECT',
#ifdef reclen_in_bytes
     .	     RECL=80)
#else
     .	     RECL=20)
#endif

#else
	OPEN(UNIT=20,
     .	     STATUS='unknown',
     .	     FILE='stream10by5.unf',
     .	     ACCESS='DIRECT',
#ifdef reclen_in_bytes
     .	     RECL=40)
#else
     .	     RECL=10)
#endif
#endif

	DO 100 j = 1, 5
 100	WRITE (20,REC=j) (myvar(i,j),i=1,10)

	STOP
	END
