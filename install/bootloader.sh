#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

syslinux_install(){
	
	local opts="$1"
	
	out_action "Installing bootloader: syslinux"
	chroot "${NEWROOT}" syslinux-install_update $opts
	
	out_action "Maybe the partition name in the root parameter needs to be replaced."
	out_action "Be sure to point the root partition in the line APPEND."
	syslinux_edit
	
	out_valid "Syslinux install terminate"
}

syslinux_edit(){
	
	out_action "Do you want edit syslinux.cfg [y|n]"
	
	reply_answer
	if (( ! $? )); then
		check_editor
		"$EDITOR" "${NEWROOT}/boot/syslinux/syslinux.cfg"
	fi
}

syslinux_menu(){

	local step=100 options=""

	while [[ "$step" != 5 ]]; do
		clear
		out_void
		out_void
		out_menu_title "**************************************************************"
		out_menu_title "                      Assumptions"
		out_menu_title "**************************************************************"
		out_menu_list " Be aware that the boot partition need to be partitionned"
		out_menu_list " with ext2 format. If it's not the case the boot installation"
		out_menu_list " with syslinux will fail. Install and configure grub instead."
		out_void
		out_menu_title "**************************************************************"
		out_menu_title "              Syslinux configuration menu"
		out_menu_title "**************************************************************"
		out_void
		out_menu_list " 1 - Install files, set boot flag, install MBR ${green}[-iam]"
		out_menu_list " 2 - Install files, set boot flag ${green}[-ia]"
		out_menu_list " 3 - Install only MBR ${green}[-m]"
		out_menu_list " 4 - Only set boot flag ${green}[-a]"
		out_void
		out_menu_list "${red}5 - Exit"
		out_void
		out_void
		out_menu_list "Enter your choice :";read step

			case "$step" in
				1)	options="-iam"
					break;;
				2) 	options="ia"
					break;;
				3) 	options="-m"
					break;;
				4) 	options="-a"
					break;;
				5) 	out_info "Exiting"
					return 1;;
				*) 	out_notvalid "Invalid number, please retry:"
					out_action "Press enter to return to syslinux configuration menu"
					read enter;;
			esac
			out_info "Press enter to return to the main menu"
			read enter	
	done
	
	syslinux_install "$options"
}
