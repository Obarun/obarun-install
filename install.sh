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
	out_menu_list "	- Defaults options are specified in brackets"
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
	out_menu_list " 4  -  Install the system or resume an aborted installation"
	out_menu_list " 5  -  Customize the fresh installation"
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
				if [[ -n $DISPLAY ]];then
					setxkbmap "${mK}";;
				else
					loadkeys fr
				fi
			2)	choose_rootdir;; # Never comment this options
			3)	choose_config;; # Never comment this options
			4)	install_system;;
			5)	customize_newroot;;
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

while [[ "$step" !=  8 ]]; do
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
	out_menu_list " 5  - Edit the script customizeChroot"
	out_menu_list " 6 -  Launch a shell on ${green}[$NEWROOT]${reset}${bold} directory"
	out_menu_list " 7 -  Browse ${green}[$NEWROOT]${reset}${bold} with Midnight Commander"
	out_void 
	out_void 
	out_menu_list " ${red}8 -  Return to the main menu"
	out_void 
	out_void 
	out_menu_list "Enter your choice :";read  step
	
		case "$step" in
			1)	choose_editor;;
			2)	edit_pacman;;
			3)	choose_cache;;
			4)	select_list;;
			5)	edit_customize_chroot;;
			6)	call_shell;;
			7)	mc_newroot;;
			8)	return 1;;
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
	out_menu_title "**************************************************************"
	out_menu_title "              CustomizeChroot menu"
	out_menu_title "**************************************************************"
	out_void 
	out_menu_list " 1  -  Define hostname ${green}[$HOSTNAME]"
	out_menu_list " 2  -  Define locale ${green}[$LOCALE]"
	out_menu_list " 3  -  Define localtime ${green}[$ZONE/$SUBZONE]"
	out_menu_list " 4  -  Define a new user ${green}[$NEWUSER]"
	out_menu_list " 5  -  Define console keymap ${green}[$KEYMAP]"
	out_menu_list " 6  -  Define desktop keymap ${green}[$XKEYMAP]"
	out_void 
	out_menu_list " 7  -  Continue the installation"
	out_void 
	out_menu_title "**************************************************************"
	out_menu_title "                   Expert mode (optionnal)"
	out_menu_title "**************************************************************"
	out_void 
	out_menu_list " 8  -  Edit s6.conf file"
	out_menu_list " 9  -  Browse with Midnight Commander"
	out_menu_list " 10 -  Delete custo_once files"
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
	rsync -a --progress /run/archiso/sfs/airootfs/ "${NEWROOT}"/
	out_action "Remove Obarun user"
	userdel -R "${NEWROOT}" -r obarun
	out_action "Remove root user"
	userdel -R "${NEWROOT}" -r root
	out_action "Copy kernel"
	cp /run/archiso/bootmnt/arch/boot/x86_64/vmlinuz "${NEWROOT}"/boot/vmlinuz-linux 
	out_action "Remove mkinitcpio-archiso.conf"
	rm -f "${NEWROOT}"/etc/mkinitcpio-archiso.conf
	out_action "Build initramfs"
	chroot "${NEWROOT}" mkinitcpio -p linux
	
}
start_from(){
	
	if [[ -d /run/archiso/sfs/airootfs/ ]];then
		copy_airootfs
		mount_umount "$NEWROOT" "mount"
		check_gpg "$GPG_DIR"
		sync_data
		install_package
		update_newroot
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
	define_root
	config_syslinux
	config_virtualbox
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
