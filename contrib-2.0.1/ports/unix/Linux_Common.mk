#
# Copyright (c) 2001, 2002 Swedish Institute of Computer Science.
# All rights reserved. 
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission. 
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT 
# SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING 
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
# OF SUCH DAMAGE.
#
# This file is part of the lwIP TCP/IP stack.
# 
# Author: Adam Dunkels <adam@sics.se>
#
#CC=/home/root1/anmol/aarch64-linux-android/bin/aarch64-linux-android-gcc
#CC=gcc
#CC=clang
CCDEP?=$(CC)
#-DLWIP_UNIX_LINUX
CFLAGS+=-fpic -Wall -DLWIP_DEBUG \
	-Wparentheses -Wsequence-point -Wswitch-default \
	-Wextra -Wundef -Wshadow -Wpointer-arith \
	-Wwrite-strings -Wcast-align \
	-Wno-address \
	-Wunreachable-code -Wuninitialized -Wno-unused-function

ifeq (,$(findstring clang,$(CC)))
CFLAGS+= -Wlogical-op
# if GCC is newer than 4.8/4.9 you may use:
#CFLAGS:=$(CFLAGS) -fsanitize=address -fstack-protector -fstack-check -fsanitize=undefined -fno-sanitize=alignment
else
# we cannot sanitize alignment on x86-64 targets because clang wants 64 bit alignment
CFLAGS+= -fsanitize=address -fsanitize=undefined -fno-sanitize=alignment -Wdocumentation
endif

# not used for now but interesting:
# -Wpacked
# -ansi
# -std=c89

LDFLAGS+=-pthread -lutil -lrt -lc 
CONTRIBDIR?=../../..
LWIPARCH?=$(CONTRIBDIR)/ports/unix/port
ARFLAGS?=rs

#Set this to where you have the lwip core module checked out from git
#default assumes it's a dir named lwip at the same level as the contrib module
LWIPDIR?=$(CONTRIBDIR)/../lwip/src

CFLAGS+=-I. \
	-I$(CONTRIBDIR) \
	-I$(LWIPDIR)/include \
	-I$(LWIPARCH)/include \
	-I$(CONTRIBDIR)/../../netmap/sys

include $(CONTRIBDIR)/ports/Filelists.mk
include $(LWIPDIR)/Filelists.mk

# ARCHFILES: architecture specific files.
ARCHFILES=$(LWIPARCH)/perf.c $(LWIPARCH)/sys_arch.c $(LWIPARCH)/netif/tapif.c $(LWIPARCH)/netif/tunif.c \
	$(LWIPARCH)/netif/unixif.c $(LWIPARCH)/netif/list.c $(LWIPARCH)/netif/tcpdump.c \
	$(LWIPARCH)/netif/delif.c $(LWIPARCH)/netif/sio.c $(LWIPARCH)/netif/fifo.c $(LWIPARCH)/netif/netmapif.c

LWIPFILES=$(LWIPNOAPPSFILES) $(ARCHFILES)
LWIPOBJS=$(notdir $(LWIPFILES:.c=.o))

LWIPLIBCOMMON=liblwipcommon.a
$(LWIPLIBCOMMON): $(LWIPOBJS)
	$(CC) -nostartfiles -shared -fpic $(LWIPOBJS) -o $(LWIPLIBCOMMON)
#	$(AR) $(ARFLAGS) $(LWIPLIBCOMMON) $?

APPFILES=$(CONTRIBAPPFILES) $(LWIPAPPFILES)
APPLIB=liblwipapps.a
APPOBJS=$(notdir $(APPFILES:.c=.o))
$(APPLIB): $(APPOBJS)
	$(AR) $(ARFLAGS) $(APPLIB) $?

%.o:
	$(CC) $(CFLAGS) -c $(<:.o=.c)
