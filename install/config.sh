#!/usr/bin/bash
#
# Authors:
# Eric Vidal <eric@obarun.org>
#
# Copyright (C) 2015-2017 Eric Vidal <eric@obarun.org>
#
## This script is under license BEER-WARE.
# "THE BEER-WARE LICENSE" (Revision 42):
# <eric@obarun.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Eric Vidal

config_custofile(){
	
	custo_once config_hostname
	custo_once config_locale
	custo_once config_localetime
	custo_once config_user
	custo_once config_keymap
	custo_once config_xkeymap
	custo_once config_resolv
	custo_once config_mirrorlist
	custo_once config_pac_sync
	custo_once config_pac
	custo_once config_gpg 
}

config_hostname(){
	
	if [[ "$HOSTNAME" != "" ]]; then
		sed -i 's/ .*$//' "${NEWROOT}"/etc/hosts
	fi
	
	sed -i "s/HOSTNAME=.*$/HOSTNAME=$HOSTNAME/g" "${NEWROOT}"/etc/s6/s6.conf
		
	#echo "$HOSTNAME" > /etc/hostname
	sed -i '/127.0.0.1/s/$/ '$HOSTNAME'/' "${NEWROOT}"/etc/hosts
	sed -i '/::1/s/$/ '$HOSTNAME'/' "${NEWROOT}"/etc/hosts
	
	out_valid "hostname was configured successfully"
}

config_locale(){
	
	local _locale
	
	# make sure the variable LOCALE is not empty before launch locale-gen
	_locale="${LOCALE:-en_US.UTF-8}"
	sed -i "s:^#${_locale}:${_locale}:g" "${NEWROOT}"/etc/locale.gen
	
	chroot "${NEWROOT}" locale-gen
	
	echo LANG="$LOCALE" > "${NEWROOT}"/etc/locale.conf
    echo LC_COLLATE=C >> "${NEWROOT}"/etc/locale.conf
	
	out_valid "Locale was created successfully"
}

config_localetime(){
	
	if [[ -n "$SUBZONE" ]]; then
		chroot "${NEWROOT}" ln -sf ${LOCALTIME}/$ZONE/$SUBZONE /etc/localtime
		sed -i "s/TZ=.*$/TZ=$ZONE\/$SUBZONE/g" "${NEWROOT}"/etc/s6/s6.conf
	else
		chroot "${NEWROOT}" ln -sf ${LOCALTIME}/$ZONE /etc/localtime
		sed -i "s/TZ=.*$/TZ=$ZONE/g" "${NEWROOT}"/etc/s6/s6.conf
	fi
	
	out_valid "Localetime was configured successfully"
}
pass_user(){
	
	passwd -R "$NEWROOT" "$NEWUSER"
	while [[ $? -ne 0 ]]; do
		out_notvalid "Password do not match, please retry"
		passwd -R "$NEWROOT" "$NEWUSER"
	done
}

config_user(){
	
	chroot "${NEWROOT}" useradd -m -g users -G "audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,video" -s /usr/bin/zsh "$NEWUSER"
	out_action "You need to define $NEWUSER password"
	pass_user
	
	out_valid "User $NEWUSER was created successfully" 
}

config_keymap(){
	
	sed -i "s,KEYMAP=.*$,KEYMAP=$KEYMAP,g" "${NEWROOT}"/etc/s6/s6.conf
	
	out_valid "Console keymap was configured successfully"
}

config_xkeymap(){
	
	if [[ -e "/etc/X11/xorg.conf.d/00-keyboard.conf" ]]; then
		out_action "Define keymap for X server in /etc/X11/xorg.conf.d/00-keyboard.conf"
		sed -i 's:Option "XkbLayout"\ .*$:Option "XkbLayout" "'$XKEYMAP'":g' "${NEWROOT}"/etc/X11/xorg.conf.d/00-keyboard.conf
	fi
	
	out_valid "Desktop xkeymap was configured successfully"
}

config_mirrorlist(){
	out_action "Uncomment server in mirrorlist"
	sed -i "s/#Server/Server/g" "${NEWROOT}"/etc/pacman.d/mirrorlist
}

config_pac_sync(){
	out_action "Synchronize database..."
	if [[ ! -d "${NEWROOT}"/var/lib/pacman/sync ]]; then 
		pacman -r "${NEWROOT}" -Syy
	else
		pacman -r "${NEWROOT}" -Sy
	fi
}
config_resolv(){
	
	out_action "Define resolv.conf"
	if [[ -e "${NEWROOT}"/etc/resolv.conf.pacorig ]]; then 
		mv "${NEWROOT}"/etc/resolv.conf.pacorig "${NEWROOT}"/etc/resolv.conf
	fi
}
config_pac(){
	out_action "Change pacman.conf configuration"
	sed -i "s:SigLevel = Never.*#:SigLevel = Required DatabaseOptional:" "${NEWROOT}"/etc/pacman.conf
	sed -i "s:#SigLevel = PackageRequired:SigLevel = PackageRequired:" "${NEWROOT}"/etc/pacman.conf
}
config_gpg(){
	
	out_action "Check if gpg key exist"	
	chroot "${NEWROOT}" pacman-key -u &>/dev/null
	
	if (( $? ));then
		out_notvalid "Gpg doesn't exist, create it..."
		out_action "Start pacman-key"
		chroot "${NEWROOT}" haveged -w 1024
		chroot "${NEWROOT}" pacman-key --init ${gpg_opts}
	
		for named in archlinux obarun;do
			out_action "populate $named"
			chroot "${NEWROOT}" pacman-key --populate "$named" 
		done
	else
		out_valid "Gpg key exist, Refresh it..."
		pacman-key -u 
	fi
}
config_syslinux(){
	out_action "Do you want to install ${green}[syslinux]${reset}${bold} bootloader [y|n] :"
	reply_answer 
	if (( ! $? )); then
		syslinux_menu
	fi
}
