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

## 		Some global variables needed

HOME_PATH="/var/lib/obarun/obarun-install"
GENERAL_DIR="$HOME_PATH/config"
SOURCES_FUNC="/tmp/obarun-install-tmp"
LOCALTIME="/usr/share/zoneinfo/right"
CONFIG="/etc/obarun/install.conf"

## 		Main menu

main_menu(){

local step=100 enter

while [[ "$step" !=  12 ]]; do
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
	out_menu_list "	- Defaults for the options are specified in brackets"
	out_void ""
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Configuration"
	out_menu_title "***************************************************************************************"
	out_void 
	out_menu_list " 1  -  Select Editor ${green}[$EDITOR]"
	out_menu_list " 2  -  Choose your Desktop environment ${green}[$CONFIG_DIR]"
	out_menu_list " 3  -  Edit pacman.conf file used by the script"
	out_menu_list " 4  -  Define cache directory for pacman ${green}[$CACHE_DIR]"
	out_menu_list " 5  -  Edit the list of packages that will be installed (AUR including)"
	out_menu_list " 6  -  Enter root directory for installation ${green}[$NEWROOT]"
	out_void
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Installation"
	out_menu_title "***************************************************************************************"
	out_void
	out_menu_list " 7  -  Install the system or resume an aborted installation"
	out_menu_list " 8  -  Customize the fresh installation"
	out_void 
	out_menu_title "***************************************************************************************"
	out_menu_title "                            Expert mode"
	out_menu_title "  Assumptions : the base system must be installed at least before using this mode"
	out_menu_title "***************************************************************************************"
	out_void 
	out_menu_list " 9  -  Edit the script customizeChroot"
	out_menu_list " 10 -  Launch a shell on ${green}[$NEWROOT]${reset}${bold} directory"
	out_menu_list " 11 -  Browse ${green}[$NEWROOT]${reset}${bold} with Midnight Commander"
	out_void 
	out_void 
	out_menu_list " ${red}12 -  Exit installation script"
	out_void 
	out_void 
	out_menu_list "Enter your choice :";read  step

		case "$step" in 
			1)	choose_editor;;
			2)	choose_config;; # Never comment this options
			3)	edit_pacman;;
			4)	choose_cache;;
			5)	select_list;;
			6)	choose_rootdir;; # Never comment this options
			7)	install_system;;
			8)	enter_chroot;;
			9)	edit_customize_chroot;;
			10) call_shell;;
			11)	mc_newroot;;
			12) out_action "Exiting"
				clean_install;;
			*) out_notvalid "Invalid number, Please retry: "
		esac
		out_info "Press enter to return to the Main menu"
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
	out_menu_title "                   Expert mode"
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

##		Start the installation

install_system(){
	
	check_mountpoint "$NEWROOT"
	if (( $? )); then
		out_notvalid "This is not a valid mountpoint"
		out_notvalid "You need to mount a device on $NEWROOT or choose another directory"
		(sleep 4) && out_info "Returning to the main_menu" && (sleep 1) && main_menu
	fi
		
	create_dir
	mount_umount "$NEWROOT" "mount"
	#user_add "usertmp" || die " Impossible to create user usertmp" "clean_install"
	copy_file
	check_gpg "$GPG_DIR"
	sync_data
	install_package
	gen_fstab "$NEWROOT"
	copy_rootfs
	define_root
}

