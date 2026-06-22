BINDIR ?= $(HOME)/.local/bin
APPDIR ?= $(HOME)/.local/share/applications/tv

.PHONY: all install uninstall

all:
	@echo "Run 'make install' to install the TV launchers."

install:
	install -d $(BINDIR)
	install -d $(APPDIR)
	install -m 755 launch-to-tv $(BINDIR)/launch-to-tv
	install -m 644 steam-tv.desktop $(APPDIR)/steam-tv.desktop
	install -m 644 vacuumtube-tv.desktop $(APPDIR)/vacuumtube-tv.desktop

uninstall:
	rm -f $(BINDIR)/launch-to-tv
	rm -f $(APPDIR)/steam-tv.desktop
	rm -f $(APPDIR)/vacuumtube-tv.desktop
	-rmdir $(APPDIR)
