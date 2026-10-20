PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
RUBY ?= ruby

.PHONY: build install uninstall test clean

build:
	spin build

test: build
	$(RUBY) -e 'Dir["test/*_test.rb"].sort.each { |f| require File.expand_path(f) }'

install: build
	install -d $(BINDIR)
	install -m 755 build/bin/wt $(BINDIR)/wt
	@echo ""
	@echo "Installed to $(BINDIR)/wt"
	@echo ""
	@echo "Add to your .zshrc:"
	@echo '  eval "$$(command wt init zsh)"'

uninstall:
	rm -f $(BINDIR)/wt

clean:
	rm -rf build
