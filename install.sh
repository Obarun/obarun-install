#!@BINDIR@/bash
# Copyright (c) 2015-2017 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

LIBRARY=${LIBRARY:-'/usr/lib/obarun'}
sourcing(){
	
	local list
	
	for list in ${LIBRARY}/install/*; do
		source "${list}"
	done
	
	unset list
}
sourcing

## 		Some global variables needed

HOME_PATH="/var/lib/obarun/obarun-install"
GENERAL_DIR="$HOME_PATH/config"
SOURCES_FUNC="/tmp/obarun-install-tmp"
LOCALTIME="/usr/share/zoneinfo/right"
CONFIG="/etc/obarun/install.conf"

## 		Main menu

main_menu(){

local step=100 enter mK

mK=$(sed -n 's:^KEYMAP=::p' /etc/s6.conf)

while [[ "$step" !=  8 ]]; do
	# reload the source, this is allow to see the change made on the menu
	source "${CONFIG}"
	clear
	out_void 
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Main menu"
	out_menu_title "***************************************************************************************"
	out_void 
	out_menu_list " Assumptions :"
	out_menu_list "	- User has partitioned, formatted, and mounted partitions on a directory"
	out_menu_list "	- Network is functional"
	out_menu_list "	- A valid mirror appears in /etc/pacman.d/mirrorlist"
	out_menu_list "	- Defaults options are specified in ${green}green${reset} brackets"
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Configuration"
	out_menu_title "***************************************************************************************"
	out_void
	out_menu_list " 1  -  Pick your keymap language for the install process ${green}[$mK]"
	out_menu_list " 2  -  Enter root directory for installation ${green}[$NEWROOT]"
	out_menu_list " 3  -  Choose your Desktop environment ${green}[$CONFIG_DIR]"
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Installation"
	out_menu_title "***************************************************************************************"
	out_void
	out_menu_list " 4  -  Quick install (Copy the ISO as it)"
	out_menu_list " 5  -  Install the system or resume an aborted installation"
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Options"
	out_menu_title "***************************************************************************************"
	out_void
	out_menu_list " 6 -  Use rankmirrors${green}[$RANKMIRRORS]"
	out_menu_list " 7 -  Expert options"
	out_void
	out_void 
	out_menu_list " ${red}8 -  Exit installation script"
	out_void 
	out_void 
	out_menu_list "Enter your choice :";read  step

		case "$step" in
			1)	define_xkeymap
				source "${CONFIG}"
				mK="${XKEYMAP}"
				if [[ -n $DISPLAY ]];then
					setxkbmap "${mK}"
				else
					loadkeys "${mK}"
				fi
				;;
			2)	choose_rootdir;; # Never comment this options
			3)	choose_config;; # Never comment this options
			4)	sed -i "s,CONFIG_DIR=.*$,CONFIG_DIR=\"jwm\",g" /etc/obarun/install.conf
				source "${CONFIG}" 
				install_system;;
			5)	install_system;;
			6)	choose_rankmirrors;;
			7)	expert_menu;;
			8)	out_action "Exiting"
				clean_install;;
			*) out_notvalid "Invalid number, Please retry: "
		esac
		out_info "Press enter to return to the Main menu"
		read enter 
done
unset enter
}

##		Expert mode menu
expert_menu(){

local step=100 enter

while [[ "$step" !=  9 ]]; do
	# reload the source, this is allow to see the change made on the menu
	source "${CONFIG}"
	clear
	out_void
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Expert options"
	out_menu_title "***************************************************************************************"
	out_void 
	out_menu_list " 1  -  Select Editor ${green}[$EDITOR]"
	out_menu_list " 2  -  Edit pacman.conf file used by the script"
	out_menu_list " 3  -  Define cache directory for pacman ${green}[$CACHE_DIR]"
	out_menu_list " 4  -  Edit the list of packages that will be installed (AUR including)"
	out_void
	out_menu_title "***************************************************************************************"
	out_menu_title "  Assumptions : the base system must be installed at least"
	out_menu_title "                before using this following options"
	out_menu_title "***************************************************************************************"
	out_void
	out_menu_list " 5  - Go to the Customize menu"
	out_menu_list " 6  - Edit the script customizeChroot"
	out_menu_list " 7 -  Launch a shell on ${green}[$NEWROOT]${reset}${bold} directory"
	out_menu_list " 8 -  Browse ${green}[$NEWROOT]${reset}${bold} with Midnight Commander"
	out_void 
	out_void 
	out_menu_list " ${red}9 -  Return to the main menu"
	out_void 
	out_void 
	out_menu_list "Enter your choice :";read  step
	
		case "$step" in
			1)	choose_editor;;
			2)	edit_pacman;;
			3)	choose_cache;;
			4)	select_list;;
			5)	customize_newroot;;
			6)	edit_customize_chroot;;
			7)	call_shell;;
			8)	mc_newroot;;
			9)	return 1;;
			*) 	out_notvalid "Invalid number, please retry:"
		esac
		out_info "Press enter to return to the expert menu"
		read enter
done
unset enter
}

#####################################		Functions for customizeChroot script

## 		CustomizeChroot menu

customizeChroot_menu(){

local step=100 enter

while [[ "$step" !=  11 ]]; do
	# reload the source, this is allow to see the change made on the menu
	source "${CONFIG}"
	clear
	out_void 
	out_void
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Customize menu"
	out_void
	out_menu_title "  Assumptions : the base system must be installed at least"
	out_menu_title "                before using this following menu"
	out_menu_title "***************************************************************************************"
	out_void
	out_menu_list " 1  -  Define your hostname ${green}[$HOSTNAME]"
	out_menu_list " 2  -  Define your locale ${green}[$LOCALE]"
	out_menu_list " 3  -  Define your localtime ${green}[$ZONE/$SUBZONE]"
	out_menu_list " 4  -  Define a new user ${green}[$NEWUSER]"
	out_menu_list " 5  -  Define your console keymap ${green}[$KEYMAP]"
	out_menu_list " 6  -  Define your desktop keymap ${green}[$XKEYMAP]"
	out_void 
	out_menu_list " 7  -  Continue the installation"
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Expert mode (optionnal)"
	out_menu_title "***************************************************************************************"
	out_void 
	out_menu_list " 8  -  Edit s6.conf file"
	out_menu_list " 9  -  Browse with Midnight Commander"
	out_menu_list " 10 -  Delete a custo_once file(s)"
	out_void 
	out_void 
	out_menu_list " ${red}11 -  Return to the main menu"
	out_void 
	out_void 
	out_menu_list "Enter your choice :";read  step

		case "$step" in 
			1)	define_hostname;;
			2)	define_locale;; 
			3)	call_localtime;;
			4)	define_user;;
			5)	define_keymap;;
			6)	define_xkeymap;;
			7)	out_action "Continue installation"
				break;;
			8)	edit_s6_conf;;
			9)	mc_newroot;;
			10)	clean_once_file "rm" "${SOURCES_FUNC}";;
			11)	return 1;;
			*) out_notvalid "Invalid number, please retry:"
		esac
		out_info "Press enter to return to the customizeChroot menu"
		read enter 
done
unset enter
}
copy_airootfs(){
	out_action "Copy files from airootfs"
	rsync -a --info=progress2 /run/archiso/sfs/airootfs/ "${NEWROOT}"/ || die "Unable to copy airootfs on ${NEWROOT}" "clean_install"
	out_action "Remove Obarun user"
	userdel -R "${NEWROOT}" -r obarun || die "Unable to delete obarun user" "clean_install"
	out_action "Copy kernel"
	cp /run/archiso/bootmnt/arch/boot/x86_64/vmlinuz "${NEWROOT}"/boot/vmlinuz-linux || die "Unable to copy kernel on ${NEWROOT}" "clean_install"
	out_action "Remove mkinitcpio-archiso.conf"
	rm -f "${NEWROOT}"/etc/mkinitcpio-archiso.conf
	mount_umount "$NEWROOT" "mount"
	out_action "Build initramfs"
	chroot "${NEWROOT}" mkinitcpio -p linux || die "Unable to build initramfs on ${NEWROOT}" "clean_install"
	
}
start_from(){
	
	if [[ "${CONFIG_DIR}" == "jwm" ]];then
		if [[ -d /run/archiso/sfs/airootfs/ ]];then
			copy_airootfs
			mount_umount "$NEWROOT" "mount"
			check_gpg "$GPG_DIR"
			sync_data
			install_package
		else
			die "You start from the ISO to use this mode" "clean_install"
		fi
	else
		create_dir
		mount_umount "$NEWROOT" "mount"
		copy_file
		check_gpg "$GPG_DIR"
		sync_data
		install_package
	fi
}
		
##		Start the installation

install_system(){
	
	check_mountpoint "$NEWROOT"
	if (( $? )); then
		out_notvalid "This is not a valid mountpoint"
		out_notvalid "You need to mount a device on $NEWROOT or choose another directory"
		(sleep 4) && out_info "Returning to the main_menu" && (sleep 1) && main_menu
	fi
	
	start_from
	gen_fstab "$NEWROOT"
	copy_rootfs
	define_root 1
	config_syslinux
	config_virtualbox
	if ! customize_newroot;then
		return
	fi
	update_newroot
	rm -rf "${SOURCES_FUNC}" || out_notvalid "Warning : Unable to remove ${SOURCES_FUNC}"
	out_action "Base system installed successfully"
}

customize_newroot(){
	
	# make sure the necessary is present before enter on chroot
	check_mountpoint "$NEWROOT"
	if (( $? )); then
		out_notvalid "This is not a valid mountpoint"
		out_notvalid "You need to mount a device on $NEWROOT or choose another directory"
		(sleep 4) && out_info "Returning to the main_menu" && (sleep 1) && main_menu
	fi
		
	create_dir
	mount_umount "$NEWROOT" "mount"
	copy_rootfs
	define_root 
	customizeChroot_menu
	if (( $? )); then
		return
	else
		config_custofile
		copy_file
		out_action "Chroot on ${NEWROOT}"	
		chroot "$NEWROOT" "$SOURCES_FUNC"/customizeChroot || die " Failed to enter on ${NEWROOT} or Failed to execute functions customizeChroot" "clean_install"
	fi
}
