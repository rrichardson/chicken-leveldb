# STANDARD BSD 2-CLAUSE LICENSE
#
# Copyright (c) 2012, Rick Richardson
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this 
# list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice, 
# this list of conditions and the following disclaimer in the documentation 
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# BLAH BLAH BLAH BLAH BLAH
#

TARGET := leveldb
SOURCE := $(TARGET).scm

# Paths
CSC         := csc
CSI         := csi
TEST_DIR    := tests
TEST_SCRIPT := run.scm

# Configure and uncomment the following lines if you get tired of
# specifying CFLAGS and LDFLAGS on the command line:
#
CFLAGS=-I.
LDFLAGS=-L/usr/local/lib/

# What libraries to include as part of csc's options
LIBS := -l$(TARGET) -lpthread

# Options
CSC_OPTIONS_1 := -d1 # debug level
CSC_OPTIONS_1 += -O2 # optimization level
CSC_OPTIONS_1 += -k  # keep intermediate files
CSC_OPTIONS_1 += -s  # generate dynamically loadable shared object file
CSC_OPTIONS_1 += -J  # emit import-libraries for all defined modules
CSC_OPTIONS_1 += -c++
CSC_OPTIONS_1 += $(CFLAGS)
CSC_OPTIONS_1 += $(LDFLAGS)
CSC_OPTIONS_1 += $(LIBS)

CSC_OPTIONS_2 := -d0 # debug level
CSC_OPTIONS_2 += -O2 # Optimization level
CSC_OPTIONS_2 += -k  # keep intermediate files
CSC_OPTIONS_2 += -s  # generate dynamically loadable shared object file
CSC_OPTIONS_2 += -J  # emit import-libraries for all defined modules
CSC_OPTIONS_2 += -c++
CSC_OPTIONS_2 += $(CFLAGS)
CSC_OPTIONS_2 += $(LDFLAGS)
CSC_OPTIONS_2 += $(LIBS)

CSC_OPTIONS_3 := -c  # stop after compilation to object files
CSC_OPTIONS_3 := -c++ # build with c++ 
CSC_OPTIONS_3 += -d1 # debug level
CSC_OPTIONS_3 += -O2 # Optimization level
CSC_OPTIONS_3 += $(CFLAGS)

CSI_OPTIONS += -s # use interpreter for shell scripts

.PHONY : all
.PHONY : clean
.PHONY : test


all: $(TARGET).so $(TARGET).import.so
#$(TARGET).o 

$(TARGET).so: $(SOURCE)
	$(CSC) $(CSC_OPTIONS_1) $(SOURCE) -j $(TARGET)

$(TARGET).import.so: $(TARGET).so $(TARGET).import.scm
	$(CSC) $(CSC_OPTIONS_2) $(TARGET).import.scm

$(TARGET).o: $(SOURCE)
	echo $(SOURCE) 
	$(CSC) $(CSC_OPTIONS_3) $(SOURCE) -unit $(TARGET) -j $(TARGET)

test: $(TEST_DIR)/$(TEST_SCRIPT)
	( cd $(TEST_DIR) ; $(CSI) $(CSI_OPTIONS) $(TEST_SCRIPT) )


clean:
	rm -f $(TARGET).c
	rm -f $(TARGET).import.scm
	rm -f $(TARGET).o
	rm -f $(TARGET).so
	rm -f $(TARGET).import.c
	rm -f $(TARGET).import.o
	rm -f $(TARGET).import.so

# vim: ft=make
