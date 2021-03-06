#
# Makefile (for FERRET/fer/efi statically linked EF code)
#
# Feb 28, 2000  -- based on other TMAP external functions makefiles
# Ansley Manke
# Jonathan Callahan (with some help from Joe Sirott)
#
# *acm* 3/23/2000 link  ../common to ferret_cmn  rather than using the
#       link in ef_utility (which may not be present when this is compiled.)
#  ACM  2/2001  debug macros
#
#  Note that these functions must be decleared in ../ccr/EF_InternalUtil.c
#  Run the perl script in this directory int_dlsym.pl ./ > intcode.c
#  put the resulting lines in three places in EF_InternalUtil.c as
#  noted in the comments at the start of that file.

#
# include site specific macro definitions
#
include ../ef_utility/site_specific.mk

#
# include platform specific macro definitions
#
include ../ef_utility/platform_specific.mk.$(BUILDTYPE)

#
# Matlab specific. Only works for Solaris cc and f77 compiler
# Dependent on location of MATLAB installation
#
MATLAB_INCLUDES=-I/opt/local/matlab/matlab5.2/extern/include
MATLAB_DIR=/opt/local/matlab/matlab5.2/extern/lib/sol2
MATLAB_LIBS=$(MATLAB_DIR)/libeng.so $(MATLAB_DIR)/libmat.so
CFLAGS += $(MATLAB_INCLUDES) -K PIC
FFLAGS += -PIC

#
# Macros
#

OBJSF = $(SRCS_F:.F=.o)

#
# Targets
#

all:	matlab.so matlab_func.so

debug:
	$(MAKE) "FFLAGS = $(FFLAGS) $(FFLAGS_DEBUG)" "CFLAGS = $(CFLAGS) $(CFLAGS_DEBUG)" all

clean:
	rm -f *.so *.o

matlab.so: matlab.o matlab_link.o
	$(LD) -L $(MATLAB_DIR) $(LD_DYN_FLAGS) matlab.o \
		matlab_link.o -leng -lmat $(SYSLIBS) -o matlab.so	

matlab_func.so: matlab_func.o matlab_func_link.o
	$(LD) -L $(MATLAB_DIR) $(LD_DYN_FLAGS) matlab_func.o \
		matlab_func_link.o -leng -lmat $(SYSLIBS) -o matlab_func.so

#
# End of Makefile
#
