MODNAME=mod_zig.so
MODCFLAGS=-Wall -Werror
TESTS=test/test_*.c

CC=gcc
CFLAGS=`pkg-config freeswitch --cflags`
LDFLAGS=`pkg-config freeswitch --libs`

.PHONY: all
all: check

module/zig-out/lib/libmod_zig.so: module/src/main.zig
	cd module && zig build
$(MODNAME): module/zig-out/lib/libmod_zig.so
	cp -fv $< $@

.PHONY: clean
clean:
	rm -rf module/zig-out

.PHONY: check
check: $(TESTS) $(MODNAME)
	mkdir -p /tmp/mod_zig/.libs
	cp -rf test /tmp/mod_zig
	cp -f mod_zig.so /tmp/mod_zig/.libs
	$(CC) $(CFLAGS) -DSWITCH_TEST_BASE_DIR_FOR_CONF=\"/tmp/mod_zig/test\" -DSWITCH_TEST_BASE_DIR_OVERRIDE=\"/tmp/mod_zig/test\" -o .check $(TESTS) $(LDFLAGS) && ./.check
