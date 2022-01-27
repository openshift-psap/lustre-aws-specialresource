ifndef DESTDIR
DESTDIR=/usr/
endif
ifndef CONFDIR
CONFDIR=/etc
endif

install:
	install -v -m 644 lustre-client-lib.sh $(DESTDIR)/lib/kvc/
	install -v -m 644 lustre-client.conf $(CONFDIR)/kvc/
	install -v -m 755 lustre-client-wrapper.sh $(DESTDIR)/lib/kvc/
	ln -sf ../lib/kvc/lustre-client-wrapper.sh $(DESTDIR)/bin/spkut
