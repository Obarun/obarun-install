# Maintainer: Obarun-install scripts <eric@obarun.org>
# DO NOT EDIT this PKGBUILD if you don't know what you do

pkgname=obarun-install
pkgver=23536df
pkgrel=1
pkgdesc=" Script for automatic installation"
arch=(x86_64)
url="file:///var/lib/obarun/$pkgname/update_package/$pkgname"
license=('BEERWARE')
depends=('arch-install-scripts' 'mc' 'git' 'pacman' 'cower' 'obarun-libs' 'obarun-install-themes')
backup=('etc/obarun/install.conf')
#install=
source=("$pkgname::git+file:///var/lib/obarun/$pkgname/update_package/$pkgname")
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
	
	install -Dm 0755 "obarun-install.in" "$pkgdir/usr/bin/obarun-install"
	install -Dm 0644 "install.sh" "$pkgdir/usr/lib/obarun/install.sh"
	install -dm 0755 "$pkgdir/usr/lib/obarun/install/"
	for file in install/{aur.sh,bootloader.sh,choose.sh,config.sh,define.sh,pac.sh,util.sh};do
		install -Dm 0755 "${file}" "$pkgdir/usr/lib/obarun/build/"
	done
	install -Dm 0644 "install.conf" "$pkgdir/etc/obarun/install.conf"
	install -dm 0755 "$pkgdir/usr/share/licenses/obarun-install/"
	install -Dm 0644 "LICENSE" "$pkgdir/usr/share/licenses/obarun-install/LICENSE"
	install -Dm 0644 "PKGBUILD" "$pkgdir/var/lib/obarun/obarun-install/update_package/PKGBUILD"
	
	install -dm 0755 "$pkgdir/var/lib/obarun/obarun-install/config"
	#cp -aT "config" "$pkgdir/var/lib/obarun/obarun-install/config"	

}

