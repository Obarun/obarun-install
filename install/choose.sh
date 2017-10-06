#!@BINDIR@/bash
# Copyright (c) 2015-2017 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

## 		Select, check editor

choose_editor(){
	
	local old_editor _editor
	local -a editor_list
	
	old_editor="$EDITOR"
	
	editors_list=("nano" "vi" "mcedit" "Exit");
	out_action "Select your editor :"
	select _editor in "${editors_list[@]}"; do
		case "$_editor" in
			Exit)EDITOR="$old_editor"
				break;;
			*)if check_elements "$_editor" "${editors_list[@]}"; then
					out_valid "Your editor is now : $_editor"
					sed -i "s,EDITOR=.*$,EDITOR=\"$_editor\",g" /etc/obarun/install.conf
					#source /etc/obarun/install.conf
					break
			  else 
					out_notvalid "Invalid number, retry :"
			  fi
		esac
	done
	
	unset old_editor _editor editor_list
}

## 		Select config directory

choose_config(){
	
	local _directory
	
	dir_list=$(ls -U $GENERAL_DIR)
	out_action "Select the configuration directory that you want to use :"
	select _directory in ${dir_list[@]}; do
		if check_elements "$_directory" ${dir_list[@]}; then
			CONFIG_DIR="$_directory"	 
			break
		else 
			out_notvalid "Invalid number, retry :"
		fi
	done
	out_valid "You chose $_directory"
	sed -i "s,CONFIG_DIR=.*$,CONFIG_DIR=\"$_directory\",g" /etc/obarun/install.conf
	#source /etc/obarun/install.conf

	unset _directory
}

## 		Edit pacman.conf

edit_pacman(){
	check_editor
	edit_file "pacman.conf" "$GENERAL_DIR/$CONFIG_DIR" "$EDITOR"	
}

##		Choose cache directory for pacman

choose_cache(){
	
	local _cache_dir
	out_action "Enter the path for your own cache directory"
	read -e _cache_dir
	while [[ ! -d "$_cache_dir" ]]; do
		out_notvalid "$_cache_dir is not a directory, please retry:"
		read -e _cache_dir
	done
	
	out_valid "Your cache directory is now : $_cache_dir"
	sed -i "s,CACHE_DIR=.*$,CACHE_DIR=\"$_cache_dir\",g" /etc/obarun/install.conf
	#source /etc/obarun/install.conf
	
	unset _cache_dir
}

## 		Select root directory

choose_rootdir(){	
	local _directory
		
	out_action "Enter your root directory :"
	read -e _directory
		
	until [[ -d "$_directory" ]]; do
		out_notvalid "This is not a directory, please retry :"
		read -e _directory
	done
	
	while ! mountpoint -q "$_directory"; do
		out_notvalid "This is not a valide mountpoint, please retry :"
		read -e _directory
	done

	out_valid "Your root directory for installation is now : $_directory"
	NEWROOT="${_directory}"
	sed -i "s,NEWROOT=.*$,NEWROOT=\"$_directory\",g" /etc/obarun/install.conf
	#source /etc/obarun/install.conf
	
	unset _directory
}

