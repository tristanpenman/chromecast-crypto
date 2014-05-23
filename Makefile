PREFIX ?= arm-linux-gnueabi
LD=$(PREFIX)-ld
CC=$(PREFIX)-gcc
CXX=$(PREFIX)-g++
AR="$(PREFIX)-ar r"
RANLIB=$(PREFIX)-ranlib

MOCKS ?= mocks
TOOLS ?= tools
INCPATH ?= includes
THIRD_PARTY ?= third_party
OPENSSL ?= $(THIRD_PARTY)/openssl
OUTDIR ?= bin

EUREKA_SRC ?= chromium/src
EUREKA_RELEASE := $(EUREKA_SRC)/out_arm_eureka/Release

INCLUDES=-I$(INCPATH)/wvcdm/ -I$(INCPATH)/wvcdm_sysdep/ -I$(EUREKA_SRC)
LIBPATH=-L$(EUREKA_RELEASE) -L$(MOCKS)/PEAgent -L$(OPENSSL)

CFLAGS=-Wall -Wextra -DNDEBUG -DEUREKA -DPOSIX -DLINUX \
	-Wno-unused-parameter -Wno-missing-field-initializers

CERT_PROVISIONING_LIBS=\
	-lwvcdm -lwvcdm_sysdep -loec_eureka -lPEAgent \
	-ldevice_files -llicense_protocol -lprotobuf_lite -lcrypto \
	-lstdc++ -lc -lpthread -lrt

CERT_PROVISIONING_OBJS=\
	$(EUREKA_SRC)/base/json/json_file_value_serializer.o \
	$(EUREKA_SRC)/base/json/json_string_value_serializer.o \
	$(EUREKA_SRC)/base/json/json_writer.o \
	$(EUREKA_SRC)/base/json/json_reader.o \
	$(EUREKA_SRC)/base/json/json_parser.o \
	$(EUREKA_SRC)/base/json/string_escape.o \
	$(EUREKA_SRC)/base/metrics/histogram.o \
	$(EUREKA_SRC)/base/metrics/histogram_base.o \
	$(EUREKA_SRC)/base/metrics/sparse_histogram.o \
	$(EUREKA_SRC)/base/metrics/sample_map.o \
	$(EUREKA_SRC)/base/metrics/sample_vector.o \
	$(EUREKA_SRC)/base/metrics/histogram_samples.o \
	$(EUREKA_SRC)/base/metrics/statistics_recorder.o \
	$(EUREKA_SRC)/base/metrics/bucket_ranges.o \
	$(EUREKA_SRC)/base/time/time.o \
	$(EUREKA_SRC)/base/time/time_posix.o \
	$(EUREKA_SRC)/base/files/file_path.o \
	$(EUREKA_SRC)/base/files/file_enumerator.o \
	$(EUREKA_SRC)/base/files/file_enumerator_posix.o \
	$(EUREKA_SRC)/base/files/file_path_constants.o \
	$(EUREKA_SRC)/base/memory/ref_counted.o \
	$(EUREKA_SRC)/base/memory/singleton.o \
	$(EUREKA_SRC)/base/strings/stringprintf.o \
	$(EUREKA_SRC)/base/strings/string_util.o \
	$(EUREKA_SRC)/base/strings/string_split.o \
	$(EUREKA_SRC)/base/strings/string_piece.o \
	$(EUREKA_SRC)/base/strings/string_number_conversions.o \
	$(EUREKA_SRC)/base/strings/utf_string_conversions.o \
	$(EUREKA_SRC)/base/strings/sys_string_conversions_posix.o \
	$(EUREKA_SRC)/base/strings/utf_string_conversion_utils.o \
	$(EUREKA_SRC)/base/strings/string16.o \
	$(EUREKA_SRC)/base/strings/string_util_constants.o \
	$(EUREKA_SRC)/base/debug/alias.o \
	$(EUREKA_SRC)/base/debug/debugger.o \
	$(EUREKA_SRC)/base/debug/debugger_posix.o \
	$(EUREKA_SRC)/base/debug/stack_trace.o \
	$(EUREKA_SRC)/base/debug/stack_trace_posix.o \
	$(EUREKA_SRC)/base/threading/platform_thread_posix.o \
	$(EUREKA_SRC)/base/threading/platform_thread_linux.o \
	$(EUREKA_SRC)/base/threading/thread_restrictions.o \
	$(EUREKA_SRC)/base/threading/thread_collision_warner.o \
	$(EUREKA_SRC)/base/threading/thread_id_name_manager.o \
	$(EUREKA_SRC)/base/threading/thread_local_storage_posix.o \
	$(EUREKA_SRC)/base/synchronization/lock.o \
	$(EUREKA_SRC)/base/synchronization/lock_impl_posix.o \
	$(EUREKA_SRC)/base/synchronization/waitable_event_posix.o \
	$(EUREKA_SRC)/base/synchronization/condition_variable_posix.o \
	$(EUREKA_SRC)/base/profiler/tracked_time.o \
	$(EUREKA_SRC)/base/profiler/alternate_timer.o \
	$(EUREKA_SRC)/base/process/process_handle_posix.o \
	$(EUREKA_SRC)/base/safe_strerror_posix.o \
	$(EUREKA_SRC)/base/lazy_instance.o \
	$(EUREKA_SRC)/base/at_exit.o \
	$(EUREKA_SRC)/base/callback_internal.o \
	$(EUREKA_SRC)/base/platform_file.o \
	$(EUREKA_SRC)/base/base_switches.o \
	$(EUREKA_SRC)/base/command_line.o \
	$(EUREKA_SRC)/base/file_util.o \
	$(EUREKA_SRC)/base/file_util_posix.o \
	$(EUREKA_SRC)/base/vlog.o \
	$(EUREKA_SRC)/base/logging.o \
	$(EUREKA_SRC)/base/platform_file_posix.o \
	$(EUREKA_SRC)/base/tracked_objects.o \
	$(EUREKA_SRC)/base/location.o \
	$(EUREKA_SRC)/base/pickle.o \
	$(EUREKA_SRC)/base/values.o \
	$(EUREKA_SRC)/base/third_party/icu/icu_utf.o \
	$(EUREKA_SRC)/base/third_party/dmg_fp/dtoa.o \
	$(EUREKA_SRC)/base/third_party/dmg_fp/g_fmt.o \
	$(EUREKA_SRC)/base/third_party/nspr/prtime.o \
	$(TOOLS)/cert_provisioning.o

.PHONY: all .tools .third_party clean tests

all: $(EUREKA_SRC) .third_party .tools

$(EUREKA_SRC):
	echo "Downloading Chromecast 'content shell' open source files ..."
	wget --continue https://www.googledrive.com/host/0B3j4zj2IQp7MQkE3R2pzQ1c3Sk0/chromecast_v1.5_content_shell.tgz
	tar zxf chromecast_v1.5_content_shell.tgz

.tools: $(OUTDIR)/cert_provisioning

.third_party: $(OPENSSL)/libssl.a

$(OPENSSL):
	echo "Cloning OpenSSL ..."
	test -d $(OPENSSL) || git clone https://github.com/openssl/openssl.git $(OPENSSL)
	cd $(OPENSSL) && git checkout OpenSSL_1_0_1g

$(OPENSSL)/libssl.a: $(OPENSSL)
	echo "Cross-compiling OpenSSL ..."
	cd $(OPENSSL) && ./Configure linux-generic32 no-shared -DL_ENDIAN
	make -C $(OPENSSL) CC=$(CC) AR=$(AR) RANLIB=$(RANLIB) LD=$(LD) MAKEDEPPROG=$(CC) PROCESSOR=ARM

$(OUTDIR)/cert_provisioning: $(MOCKS)/PEAgent/libPEAgent.so $(CERT_PROVISIONING_OBJS)
	mkdir -p $(OUTDIR)
	$(CXX) $(CFLAGS) $(INCLUDES) $(LIBPATH) \
		-o $(OUTDIR)/cert_provisioning $(CERT_PROVISIONING_OBJS) $(CERT_PROVISIONING_LIBS)

.c.o:
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.cc.o:
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.cpp.o:
	$(CXX) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(MOCKS)/PEAgent/libPEAgent.so: $(MOCKS)/PEAgent/oecc.o
	$(CC) $(CFLAGS) -fPIC -shared -Wl,-soname,libPEAgent.so -o \
		$(MOCKS)/PEAgent/libPEAgent.so $(MOCKS)/PEAgent/oecc.o

tests:
	make -C tests

clean:
	rm -f $(MOCKS)/PEAgent/*.so $(MOCKS)/PEAgent/*.o
	rm -f $(CERT_PROVISIONING_OBJS) $(OUTDIR)/cert_provisioning
	make -C $(OPENSSL) clean
