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
	@echo ""
	@echo "Installed to $(BINDIR)/wt"
	@echo ""
	@echo "Add to your .zshrc:"
	@echo '  eval "$$(command wt init zsh)"'

uninstall:
	rm -f $(BINDIR)/wt

clean:
	rm -rf bin lib .shards
