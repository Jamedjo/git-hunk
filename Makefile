PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
SCRIPTS = git-list-hunks git-add-hunk

.PHONY: install uninstall

install:
	install -d $(BINDIR)
	install -m 755 $(SCRIPTS) $(BINDIR)
	install -m 644 git_hunk_utils.py $(BINDIR)

uninstall:
	cd $(BINDIR) && rm -f $(SCRIPTS) git_hunk_utils.py
