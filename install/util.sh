#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

## 		Clean on exit

clean_install(){
	
	out_action "Cleaning up"
	# make sure that all process are killed
	# before umounting
	out_valid "Killing process" 
	kill_process "haveged gpg-agent dirmngr"
	
	out_valid "Umount $NEWROOT"
	mount_umount "$NEWROOT" "umount"
	umount_one "${NEWROOT}/${CACHE_DIR}" "${NEWROOT}/${CACHE_DIR}"
	
	#if [[ $(awk -F':' '{ print $1}' /etc/passwd | grep usertmp) >/dev/null ]]; then
	#	out_valid "Removing user usertmp"
	#	user_del "usertmp" &>/dev/null
	#fi
		
	# keep the configuration variable from install.conf
	if [[ -f "$NEWROOT$SOURCES_FUNC"/install.conf ]]; then
		out_valid "Keeping the configuration from $NEWROOT$SOURCES_FUNC/install.conf"
		cp -f "$NEWROOT$SOURCES_FUNC"/install.conf /etc/obarun/install.conf
	fi
	
	if [[ -d "$NEWROOT$SOURCES_FUNC" ]]; then
		out_valid "Remove directory $SOURCES_FUNC"
		rm -r "$NEWROOT$SOURCES_FUNC"
	fi
	
	out_valid "Restore your shell options"
	shellopts_restore
	
	exit
}

##		Customize NEWROOT



check_editor(){
	if [[ -z "$EDITOR" ]]; then
		EDITOR="mcedit"
	fi
}


##		Copying file needed

copy_file(){
	
	local tidy_loop
	
	out_action "Check needed files in ${NEWROOT}"
	if [[  ! -e "$NEWROOT/etc/resolv.conf" ]]; then 
		cp /etc/resolv.conf "$NEWROOT/etc/resolv.conf" || die " Impossible to copy the file resolv.conf" "clean_install"
	else
		out_valid "File resolv.conf already exist"
	fi
	if [[ ! -d "$NEWROOT$SOURCES_FUNC" ]]; then
		out_action "Create $NEWROOT$SOURCES_FUNC directory"
		mkdir -p "$NEWROOT$SOURCES_FUNC" || die " Impossible to create $NEWROOT$SOURCES_FUNC directory" "clean_install"
	fi
	
	for tidy_loop in /etc/obarun/install.conf $GENERAL_DIR/$CONFIG_DIR/customizeChroot; do
		out_notvalid "Copying $tidy_loop"
		cp -f "$tidy_loop" "$NEWROOT$SOURCES_FUNC/" || die " Impossible to copy the file $tidy_loop" "clean_install"
	done
	unset tidy_loop
}

##		Copy directory rootfs in $NEWROOT

copy_rootfs(){
	
	out_action "Copying configuration files in ${NEWROOT}"
	
	cp -af "$GENERAL_DIR/$CONFIG_DIR/rootfs/"* "$NEWROOT"/ || die " Impossible to copy files" "clean_install"
}

## 		Create needed directory

create_dir(){
	out_action "Check for needed directory"
	for id in var/cache/pacman/pkg var/lib/pacman var/log dev run etc etc/pacman.d/;do
		if ! [ -d "$NEWROOT/$id" ]; then 
			out_notvalid "Create ${NEWROOT}/$id directory"
			mkdir -m 0755 -p "$NEWROOT/$id"
		else
			out_valid "${NEWROOT}/$id directory already exist"
		fi
	done
	for id in dev/{pts,shm};do
		if ! [ -d "$NEWROOT/$id" ]; then
			out_notvalid "Create ${NEWROOT}/$id directory"
			mkdir -m 0755 -p "$NEWROOT/$id"
		else
			out_valid "${NEWROOT}/$id directory already exist"
		fi
	done
	for id in sys proc;do
		if ! [ -d "$NEWROOT/$id" ]; then
			out_notvalid "Create ${NEWROOT}/$id directory"
			mkdir -m 0555 -p "$NEWROOT"/{sys,proc}
		else
			out_valid "${NEWROOT}/$id directory already exist"
		fi
	done
	if ! [ -d "$NEWROOT/tmp" ]; then
		out_notvalid "Create ${NEWROOT}/tmp directory"
		mkdir -m 1777 -p "$NEWROOT"/tmp
	else
		out_valid "${NEWROOT}/tmp directory already exist"
	fi
}
##		Select packages list

select_list(){
	local list
	local -a pac_list
	check_editor
	pac_list=$(ls "$GENERAL_DIR"/"$CONFIG_DIR"/package_list/)
	pac_list+=" Exit"
	out_action "Select the list you want to edit then select Exit number to return at main menu :"
	select list in ${pac_list[@]}; do
		case "$list" in
			Exit)break;;
			*)if check_elements "$list" ${pac_list[@]}; then
				"$EDITOR" "$GENERAL_DIR/$CONFIG_DIR/package_list/$list"
			  else 
				out_notvalid "Invalid number, retry :"
			  fi
		esac
	done
	
	unset list pac_list
}

## 		Edit customizeChroot file

edit_customize_chroot(){
	check_editor
	edit_file "customizeChroot" "$GENERAL_DIR/$CONFIG_DIR" "$EDITOR" || die " File customizeChroot not exist, you need to choose number 7 first" "clean_install"
	if [[ -d "$NEWROOT/etc" ]]; then
		out_action "Copying customizeChroot to $NEWROOT/etc/customizeChroot"
		cp -f "$GENERAL_DIR/$CONFIG_DIR/customizeChroot" "$NEWROOT/etc/customizeChroot" 
	fi
}
	
pass_root(){
	
	passwd -R "$NEWROOT" root

	while [[ $? -ne 0 ]]; do
		out_notvalid "Password do not match, please retry"
		passwd -R "$NEWROOT" root
	done
}



##		Enter in $NEWROOT with mc

mc_newroot(){
	
	check_mountpoint "$NEWROOT"
	if (( $? )); then
		out_notvalid "This is not a valid mountpoint"
		out_notvalid "You need to mount a device on $NEWROOT or choose another directory"
		(sleep 4) && out_info "Returning to the main_menu" && (sleep 1) && main_menu
	fi
	
	
	create_dir
	mount_umount "$NEWROOT" "mount"
	mount_one "${CACHE_DIR}" "${CACHE_DIR}" "$NEWROOT/var/cache/pacman/pkg" -o bind
	SHELL=/bin/sh chroot "$NEWROOT" /usr/bin/mc
}

##		Open an interactive shell on NEWROOT

call_shell(){
	
	check_mountpoint "$NEWROOT"
	if (( $? )); then
		out_notvalid "This is not a valid mountpoint"
		out_notvalid "You need to mount a device on $NEWROOT or choose another directory"
		(sleep 4) && out_info "Returning to the main_menu" && (sleep 1) && main_menu
	fi
		
	create_dir
	mount_umount "$NEWROOT" "mount"
	mount_one "${CACHE_DIR}" "${CACHE_DIR}" "$NEWROOT/var/cache/pacman/pkg" -o bind
	out_info "Tape exit when you have finished"
	if [[ -e "$NEWROOT/usr/bin/zsh" ]]; then
		SHELL=/bin/sh chroot "$NEWROOT" /usr/bin/zsh 
	else
		SHELL=/bin/sh chroot "$NEWROOT"
	fi
}

##		Edit rc.conf

edit_s6_conf(){
	
	edit_file "s6.conf" "${NEWROOT}/etc/s6" "$EDITOR"
}



##		Remove once_file

clean_once_file(){
	
	local action dir f_ file
	local -a file_list
	
	action="${1}"
	dir="${2}"
	
	if [[ -d "${SOURCES_FUNC}" ]]; then
		file_list=$(ls $dir/ | uniq) 
		file_list+=" Remove_all_files"
		file_list+=" Exit"
		select file in ${file_list[@]}; do
			case $file in 
				Exit)break;;
				Remove_all_files) 	for f_ in ${file_list[@]}; do
										if [[ ! "$f_" = @(Exit|Remove_all_files) ]]; then
											eval "$action" "$dir/$f_"
										fi
									done;;
				*)if check_elements "$file" ${file_list[@]}; then
						eval "$action" "${dir}/${file}"
						clean_once_file "$action" "$dir"				
				else 
					out_notvalid "Invalid number, retry :"
					clean_once_file "$action" "$dir"
				fi
			esac
			break
		done
	else
		out_info "Directory ${SOURCES_FUNC} does not exist"
	fi

	unset action dir f_ file file_list
}
custo_once() {
	local _tmp cmd
	cmd="${1}"
	_tmp="${SOURCES_FUNC}"
	
	if [[ ! -d $_tmp ]]; then
		mkdir -p -m0755 $_tmp || die "Impossible to create $_tmp"
	fi
    if [[ ! -e $_tmp/customize.${cmd} ]]; then
        "${cmd}" || die "Cannot execute $_"
        touch $_tmp/customize.${cmd}
    else
		return
	fi
    unset _tmp
}
warm_msg_start(){
	out_void 
	out_menu_title "***************************************************************************************" 
}
warm_msg_end(){
	out_menu_title "***************************************************************************************"
	out_void 
}

warm_msg(){
	
	local -a msg=( "${@}" )
	local _msg cmd
	
	warm_msg_start
	for _msg in "${msg[@]}";do
		out_menu_title "     ${_msg}"
	done
	warm_msg_end
	
	out_info "Press any key to continue"
	out_info "Press e to exit"
	read cmd
	if [[ $cmd == "e" ]];then
		die "" "clean_install"
	fi
		
	unset msg _msg cmd
}
