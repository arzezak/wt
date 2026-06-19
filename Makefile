PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin

.PHONY: build install uninstall test clean

build:
	shards build --release

test:
	crystal spec

install: build
	install -d $(BINDIR)
	install -m 755 bin/wt $(BINDIR)/wt

uninstall:
	rm -f $(BINDIR)/wt

clean:
	rm -rf bin lib .shards
