# Maintainer: Obarun-install scripts <eric@obarun.org>
# DO NOT EDIT this PKGBUILD if you don't know what you make

pkgname=obarun-install
pkgver=23536df
pkgrel=1
pkgdesc=" Script for automatic installation"
arch=(x86_64)
url="file:///opt/$pkgname/.build/$pkgname"
license=('BEERWARE')
depends=('arch-install-scripts' 'mc' 'yaourt' 'git' 'pacman' 'sudo')
backup=()
install=
source=("$pkgname::git+file:///opt/$pkgname/.build/$pkgname")
md5sums=('SKIP')
validpgpkeys=('6DD4217456569BA711566AC7F06E8FDE7B45DAAC') # Eric Vidal

pkgver() {
	cd "${pkgname}"
	if git_version=$(git rev-parse --short HEAD); then
		read "$rev-parse" <<< "$git_version"
		printf '%s' "$git_version"
	fi
}

package() {
	cd "$srcdir/$pkgname"
	
	install -dm755 "$pkgdir/opt/obarun-install/gnupg"
	install -Dm744 "obarun-install.in" "$pkgdir/opt/obarun-install/obarun-install"
	install -Dm644 "functions" "$pkgdir/opt/obarun-install/functions"
	install -dm755 "$pkgdir/usr/share/licenses/obarun-install/"
	install -Dm644 "LICENSE" "$pkgdir/usr/share/licenses/obarun-install/LICENSE"
	
	cp -aT "config" "$pkgdir/opt/obarun-install/config"	
}

