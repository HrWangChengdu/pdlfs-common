# Copyright (c) 2016 Carnegie Mellon University.
# Copyright (c) 2011 The LevelDB Authors.
# ---------------------------------------
# All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

#-----------------------------------------------
# Uncomment exactly one of the lines labeled (A), (B), and (C) below
# to switch between compilation modes.

# (A) Production use (optimized mode)
OPT ?= -O2 -DNDEBUG
# (B) Debug mode, w/ full line-level debugging symbols
# OPT ?= -g2
# (C) Profiling mode: opt, but w/debugging symbols
# OPT ?= -O2 -g2 -DNDEBUG
#-----------------------------------------------

# detect what platform we're building on
$(shell CC="$(CC)" CXX="$(CXX)" TARGET_OS="$(TARGET_OS)" \
    ./build_detect_platform build_config.mk ./)
# this file is generated by the previous line to set build flags and sources
include build_config.mk

TESTS = \
	src/arena_test \
	src/coding_test \
	src/crc32c_test \
	src/dbfiles_test \
	src/hash_test \
	src/cache_test \
	src/log_test \
	src/env_test \
	src/osd_test \
	src/leveldb/bloom_test \
	src/leveldb/filter_block_test \
	src/leveldb/skiplist_test \
	src/leveldb/table_test \
	src/leveldb/db/write_batch_test \
	src/leveldb/db/version_edit_test \
	src/leveldb/db/version_set_test \
	src/leveldb/db/dbformat_test \
	src/leveldb/db/db_test \
	src/leveldb/db/db_table_test \
	src/leveldb/db/autocompact_test \
	src/leveldb/db/corruption_test \
	src/leveldb/db/bulk_test \
	modules/rados/rados_test

# Put the object files in a subdirectory, but the application at the top of the object dir.
PROGNAMES := $(notdir $(TESTS))

CFLAGS += -I./include -I./src $(PLATFORM_CCFLAGS) $(OPT)
CXXFLAGS += -I./include -I./src $(PLATFORM_CXXFLAGS) $(OPT)

LDFLAGS += $(PLATFORM_LDFLAGS)
LIBS += $(PLATFORM_LIBS)

STATIC_OUTDIR=build

STATIC_PROGRAMS := $(addprefix $(STATIC_OUTDIR)/, $(PROGNAMES))

TESTUTIL := $(STATIC_OUTDIR)/src/testutil.o
TESTHARNESS := $(STATIC_OUTDIR)/src/testharness.o $(TESTUTIL)

STATIC_LIBOBJECTS := $(addprefix $(STATIC_OUTDIR)/, $(SOURCES:.cc=.o))

STATIC_TESTOBJS := $(addprefix $(STATIC_OUTDIR)/, $(addsuffix .o, $(TESTS)))
STATIC_ALLOBJS := $(STATIC_LIBOBJECTS) $(STATIC_TESTOBJS) $(TESTHARNESS)

default: all

all: $(STATIC_OUTDIR)/pdlfs-common.a

check: $(STATIC_PROGRAMS)
	for t in $(notdir $(TESTS)); do echo "***** Running $$t"; $(STATIC_OUTDIR)/$$t || exit 1; done

clean:
	-rm -rf $(STATIC_OUTDIR)
	-rm -f build_config.mk

$(STATIC_OUTDIR):
	mkdir -p $@

$(STATIC_OUTDIR)/src: | $(STATIC_OUTDIR)
	mkdir -p $@

$(STATIC_OUTDIR)/src/leveldb: | $(STATIC_OUTDIR)
	mkdir -p $@

$(STATIC_OUTDIR)/src/leveldb/db: | $(STATIC_OUTDIR)
	mkdir -p $@

$(STATIC_OUTDIR)/modules/rados: | $(STATIC_OUTDIR)
	mkdir -p $@

.PHONY: STATIC_OBJDIRS
STATIC_OBJDIRS: \
	$(STATIC_OUTDIR)/src \
	$(STATIC_OUTDIR)/src/leveldb \
	$(STATIC_OUTDIR)/src/leveldb/db \
	$(STATIC_OUTDIR)/modules/rados

$(STATIC_ALLOBJS): | STATIC_OBJDIRS

$(STATIC_OUTDIR)/pdlfs-common.a:$(STATIC_LIBOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(STATIC_LIBOBJECTS)

$(STATIC_OUTDIR)/arena_test:src/arena_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/arena_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/coding_test:src/coding_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/coding_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/crc32c_test:src/crc32c_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/crc32c_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/dbfiles_test:src/dbfiles_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/dbfiles_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/hash_test:src/hash_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/hash_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/cache_test:src/cache_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/cache_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/log_test:src/log_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/log_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/env_test:src/env_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/env_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/osd_test:src/osd_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/osd_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/bloom_test:src/leveldb/bloom_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/bloom_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/filter_block_test:src/leveldb/filter_block_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/filter_block_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/skiplist_test:src/leveldb/skiplist_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/skiplist_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/table_test:src/leveldb/table_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/table_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/write_batch_test:src/leveldb/db/write_batch_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/write_batch_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/version_edit_test:src/leveldb/db/version_edit_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/version_edit_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/version_set_test:src/leveldb/db/version_set_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/version_set_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/dbformat_test:src/leveldb/db/dbformat_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/dbformat_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/db_test:src/leveldb/db/db_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/db_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/db_table_test:src/leveldb/db/db_table_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/db_table_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/corruption_test:src/leveldb/db/corruption_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/corruption_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/autocompact_test:src/leveldb/db/autocompact_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/autocompact_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/bulk_test:src/leveldb/db/bulk_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) src/leveldb/db/bulk_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/rados_test:modules/rados/rados_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS)
	$(CXX) $(LDFLAGS) $(CXXFLAGS) modules/rados/rados_test.cc $(STATIC_LIBOBJECTS) $(TESTHARNESS) -o $@ $(LIBS)

$(STATIC_OUTDIR)/%.o: %.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(STATIC_OUTDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
