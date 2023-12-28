MODNAME=mod_zigdemo
MODCFLAGS=-Wall -Werror
TESTS=test/test_*.c
TEST_ENV_DIR=/tmp/$(MODNAME)
TEST_MOD_DIR="$(TEST_ENV_DIR)/.libs"

CC=zig cc
CFLAGS=`pkg-config freeswitch --cflags`
LDFLAGS=`pkg-config freeswitch --libs`

all: check

zig-out/lib/lib$(MODNAME).so: src/main.zig
	zig build
$(MODNAME).so: zig-out/lib/lib$(MODNAME).so
	cp -fv $< $@

clean:
	rm -rf module/zig-out

check: $(TESTS) $(MODNAME).so
	mkdir -p $(TEST_MOD_DIR)
	cp -rf test $(TEST_ENV_DIR)
	cp -f $(MODNAME).so $(TEST_MOD_DIR)
	$(CC) $(CFLAGS) -DSWITCH_TEST_BASE_DIR_FOR_CONF=\"$(TEST_ENV_DIR)/test\" -DSWITCH_TEST_BASE_DIR_OVERRIDE=\"$(TEST_ENV_DIR)/test\" -o .check $(TESTS) $(LDFLAGS) && ./.check

.PHONY: check clean all
