# Maintainer: Eric Vidal <eric@obarun.org>

pkgname=obarun-install
pkgver=0.2.8
pkgrel=1
pkgdesc=" Script for automatic installation"
arch=(x86_64)
url=("https://github.com/Obarun/obarun-install")
license=('BEERWARE')
depends=('arch-install-scripts' 'mc' 'yaourt')
backup=()
install=
source=("obarun-install::git+https://github.com/Obarun/obarun-install#tag=v0.3.2")
md5sums=('SKIP')


package() {
	cd "$srcdir/$pkgname"
	

	install -Dm755 "obarun-install.in" "$pkgdir/opt/obarun-install/obarun-install"
	install -Dm644 "functions" "$pkgdir/opt/obarun-install/functions"
	cp -af "config" "$pkgdir/opt/obarun-install/config"
	install -Dm644 "LICENSE" "$pkgdir/usr/share/licenses/obarun-install/LICENSE"
}
