SRCS     = src/nif/gb_markdown_leaf_info.cc \
	   src/nif/gb_markdown_parent_info.cc \
	   src/nif/gb_markdown_analyzer.cc \
	   src/nif/gb_markdown_nif.cc

CXXFLAGS += -g -ansi -pedantic -Wall -Wextra
CXXFLAGS += -Wno-unused-parameter -std=c++11 -fPIC
ifeq ($(MIX_ENV), text)
	CXXFLAGS += -O0
else
	CXXFLAGS += -O0
endif
#CXXFLAGS  = -g -O3 -ansi -pedantic -Wall -Wextra -Werror


ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
ifeq ($(wildcard deps/hoedown),)
	HOEDOWN_PATH = ../hoedown
else
	HOEDOWN_PATH = deps/hoedown
endif

CXXFLAGS += -I$(ERLANG_PATH) -I$(HOEDOWN_PATH)/src -Isrc/nif/include

ifeq ($(shell uname),Darwin)
	LDFLAGS += -dynamiclib -undefined dynamic_lookup
endif

all: _build/$(MIX_ENV)/lib/greenbar/priv/greenbar_markdown.so

_build/$(MIX_ENV)/lib/greenbar/priv/greenbar_markdown.so: $(SRCS) Makefile
	mkdir -p $(shell dirname $@)
	$(MAKE) -C $(HOEDOWN_PATH) libhoedown.a
	$(CXX) $(CXXFLAGS) -shared $(LDFLAGS) -o $@ $(SRCS) $(HOEDOWN_PATH)/libhoedown.a
