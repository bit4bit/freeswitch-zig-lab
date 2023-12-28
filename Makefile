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
mod_zig.so: module/zig-out/lib/libmod_zig.so
	cp -fv $< $@

.c.o: $<
	$(CC) $(CFLAGS) -fPIC -o $@ -c $<

.PHONY: clean
clean:
	rm -rf module/zig-out

.PHONY: install
install: $(MODNAME)
	install $(MODNAME) $(FS_MODULES)

.PHONY: check
check: $(TESTS) mod_zig.so
	mkdir -p /tmp/mod_zig
	cp -rf test /tmp/mod_zig
	$(CC) $(CFLAGS) -DSWITCH_TEST_BASE_DIR_FOR_CONF=\"/tmp/mod_zig/test\" -DSWITCH_TEST_BASE_DIR_OVERRIDE=\"/tmp/mod_zig/test\" -o .check $(TESTS) $(LDFLAGS) && ./.check
