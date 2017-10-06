# Makefile for obarun-install

VERSION = $$(git describe --tags| sed 's/-.*//g;s/^v//;')
PKGNAME = obarun-install

BINDIR = /usr/bin

FILES = $$(find install/ -type f)
SCRIPTS = 	obarun-install.in \
			install.sh
			
install:
	
	for i in $(SCRIPTS) $(FILES); do \
		sed -i 's,@BINDIR@,$(BINDIR),' $$i; \
	done
	
	install -Dm755 obarun-install.in $(DESTDIR)/$(BINDIR)/obarun-install
	install -Dm755 install.sh $(DESTDIR)/usr/lib/obarun/install.sh
	
	for i in $(FILES); do \
		install -Dm755 $$i $(DESTDIR)/usr/lib/obarun/$$i; \
	done
	
	install -Dm644 install.conf	$(DESTDIR)/etc/obarun/install.conf
	
	install -Dm644 PKGBUILD $(DESTDIR)/var/lib/obarun/obarun-install/update_package/PKGBUILD

	install -dm755 $(DESTDIR)/var/lib/obarun/obarun-install/config
	
	install -Dm644 LICENSE $(DESTDIR)/usr/share/licenses/$(PKGNAME)/LICENSE

version:
	@echo $(VERSION)
	
.PHONY: install version
