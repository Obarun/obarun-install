#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

# function to find which installer to use for a given package
# return 10 for pacman, 11 for AUR helper
# ${1} name of package
choose_installer(){
	
	local b named group
		
	named="${1}"
		
	for b in $(pacman -Ssq ${named[@]}); do
		if [[ $named =~ $b ]] ; then
			return 10			
		fi
	done
	unset b
	
	for b in $(cower -sq ${named[@]}); do
		if [[ $named =~ $b ]] ; then
			return 11			
		fi
	done
	unset b
	
	# be sure the named are not a group
	# if it's the case return value for pacman
	
	group=( $(pacman -Sgq ${named[@]}) )
	if (( "${#group}" )); then
		return 10
	fi
		
	unset named b group
}

install_package(){
	local item item_base tidy_loop rc
	local -a installed list list_base result result_base pacman_list aur_list
	
	if [[ ! -e $GENERAL_DIR/$CONFIG_DIR/package_list/base ]]; then
		die "The file named base at $GENERAL_DIR/$CONFIG_DIR/package_list/ must exist, please create one." "clean_install"
	fi
	
	# bash is the first package installed by pacman
	# if $NEWROOT/usr/bin/bash doesn't exist means that is the first pass 
	# into the function install_system; so install base package first
	if ! [[ -x "$NEWROOT/usr/bin/bash" ]]; then
		pacman -r "$NEWROOT" -S $(grep -h -v ^# $GENERAL_DIR/$CONFIG_DIR/package_list/base) --config "$GENERAL_DIR/$CONFIG_DIR/pacman.conf" --cachedir "$CACHE_DIR" --noconfirm || die " Failed to install base system" "clean_install"
	fi
	
	installed=($(pacman -r "$NEWROOT" -Qsq))
	
	# check first for base packages
	
	out_action "Check base installed packages"
	
	list_base=" ${installed[@]} " #include blank
	while read item_base; do
		if ! [[ $list_base =~ " $item_base " ]] ; then
			result_base+=($item_base)			
		fi
	done < <(grep -h -v ^# $GENERAL_DIR/$CONFIG_DIR/package_list/base | sed "/^\s*$/d" | sort -du)
		
	if [[ -n "${result_base[@]}" ]]; then
		out_notvalid "Install missing base packages"
		pacman -S ${result_base[@]} -r "$NEWROOT" --config "$GENERAL_DIR/$CONFIG_DIR/pacman.conf" --cachedir "$CACHE_DIR" --noconfirm 2>/dev/null || die " Failed to install packages" "clean_install"
		result_base=()
	else
		out_valid "Nothing to do for base system"
	fi
	
	# check installed packages
	
	out_action "Ckeck installed packages, this may take time..."
	
	list=" ${installed[@]} " #include blank  
	while read item; do
		if ! [[ $list =~ " $item " ]] ; then
			result+=("$item")			
		fi
	done < <(grep -h -v ^# $GENERAL_DIR/$CONFIG_DIR/package_list/* | sed "/^\s*$/d" | sort -du)

	#install missing package if necessary
	if [[ -n "${result[@]}" ]]; then
				
		for tidy_loop in ${result[@]} ; do
		
			choose_installer "${tidy_loop}"
			
			rc=$?
				
			case "$rc" in 
				10) 
					unset rc
					pacman_list+=("$tidy_loop")
					;;
				11)
					unset rc
					aur_list+=("$tidy_loop")
					;;
				*)
					unset rc
					die "$tidy_loop can not be installed by pacman or AUR helper" "clean_install"
					;;
			esac
		done
		
		if [[ -n ${pacman_list[@]} ]]; then
			out_notvalid "Install missing packages coming from repo define in pacman.conf"
			pacman -r "$NEWROOT" -S ${pacman_list[@]} --config "$GENERAL_DIR/$CONFIG_DIR/pacman.conf" --cachedir "$CACHE_DIR" --noconfirm || die " Failed to install packages with pacman" "clean_install"
		fi
	
		if [[ -n ${aur_list[@]} ]]; then
			out_notvalid "Install missing packages coming from AUR"
			unset tidy_loop
			for tidy_loop in ${aur_list[@]}; do
				aur_install "${tidy_loop}"
			done			
		fi
	else
		out_valid "All packages are already installed, nothing to do."
	fi
	
	unset item item_base tidy_loop installed list list_base result result_base pacman_list aur_list
}

##		Sync database

sync_data(){
	
	if [[ "${RANKMIRRORS}" == "yes" ]]; then
		mirrorlist
	fi
	
	out_action "Synchronize database"
	pacman -Sy --config "$GENERAL_DIR/$CONFIG_DIR/pacman.conf" || die " Impossible to synchronize database" "clean_install"
	
	out_action "Copying database on $NEWROOT/var/lib/pacman/sync/"	
	mkdir -p -m0755 "$NEWROOT/var/lib/pacman/sync/"

	cp /var/lib/pacman/sync/*.{db,sig} "$NEWROOT/var/lib/pacman/sync/" || die "/var/lib/pacman/sync/*.db doesn't exit on host" "clean_install"
	cp /var/lib/pacman/sync/*.{db,sig} "$NEWROOT/var/lib/pacman/sync/" || die "/var/lib/pacman/sync/*.{db,sig} doesn't exit on host" "clean_install"
		
}

mirrorlist(){
	
	local country rc
	local -a mirrorlistnew
	
	rc=0
	
	out_info "Copy /etc/pacman.d/mirrorlist to /etc/pacman.d/mirrorlist.backup"
	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
	
	
	out_info "Download a fresh list of mirrors"
	curl -s "https://www.archlinux.org/mirrorlist/?country=all&protocol=http&ip_version=4" -o /etc/pacman.d/mirrorlist.pacnew || die "Unable to download mirrorlist" "clean_install"
	
	mirrorlistnew=$(grep "^## [A-Z]" /etc/pacman.d/mirrorlist.pacnew | sed -e '1,2d' -e 's:^## ::' -e 's: :_:g')
	mirrorlistnew+=" Exit"
	
	out_info "Select your country"
	select country in ${mirrorlistnew[@]}; do
		case "${country}" in
			Exit) rc=1
				break
				;;
			*)	if check_elements "${country}" ${mirrorlistnew[@]}; then
					country=$(echo "${country}"|sed 's:_: :g')
					awk '/^## '"${country}"'$/ {f=1} f==0 {next} /^$/ {exit} {print substr($0, 2)}' \
					/etc/pacman.d/mirrorlist.pacnew | grep -v '#' > /etc/pacman.d/mirrorlist.rank
					break
				else
					out_notvalid "Invalid number, retry :"
				fi
		esac
	done
	
	if (( !"${rc}" )); then
		out_action "Check fastest local mirrors, this may take time..."
		rankmirrors -n 10 /etc/pacman.d/mirrorlist.rank > /etc/pacman.d/mirrorlist
		rm -f /etc/pacman.d/mirrorlist.rank
	fi
	
	unset country mirrorlistnew rc
}
