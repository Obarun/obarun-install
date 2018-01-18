#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

# ${1} name of the package
aur_deps(){
	
	local named tidy_loop rc
	local -a dps dps_parsed
	
	named="${1}"
	dps=$(cower -i $named --format=%D) # Depends
	dps+=($(cower -i $named --format=%M)) # Makedepends
	
	# parse each element of the array to remove any <>= characters
	for tidy_loop in ${dps[@]}; do
		#echo tidy_loop :: $tidy_loop
		tidy_loop=${tidy_loop%%@(>|<|=)*}
		#echo tidy_loop parsed :: $tidy_loop
		dps_parsed+=("$tidy_loop")
	done
	unset tidy_loop
	
	# loop through dependencies recursively
	for tidy_loop in ${dps_parsed[@]}; do
		
		choose_installer "${tidy_loop}"
		
		rc=$?
		
		if [[ "$rc" == 11 ]];then
			aur_deps "${tidy_loop}"
			aur_install "${tidy_loop}"
		fi
	done
	
	unset named rc dps dps_parsed
}

# ${1} name of the package
# ${2} working directory
aur_get_pkgbuild(){
	
	local named work_dir
	
	named="${1}"
	work_dir="${2}"
		
	cower -df "${named}" -t "${work_dir}" --ignorerepo

	unset named work_dir
}

# ${1} name of the package
# ${2} variable to change by pkgver-pkgrel value
aur_get_pkgver_pkgrel(){
	
	local named
	named="${1}"
	return_value="${2}"
	
	ver_rel=$(cower -s ${named} --format=%v)
	
	eval "$return_value=$ver_rel"
	
	unset named return_value
}

# ${1} name of the package
# ${2} working directory
aur_build(){
	
	local named work_dir _oldpwd
	_oldpwd=$(pwd)
	named="${1}"
	work_dir="${2}"
	
	cd "${work_dir}"
	
	su "${OWNER}" -c "makepkg -Cs --noconfirm --needed --nosign"
	
	cd "${_oldpwd}"
	
	unset named work_dir _oldpwd
}

# ${1} name of the package
aur_install(){

	local work_dir named _oldpwd pkg_ver_rel real_name
	local -a installed_yet
	
	_oldpwd=$(pwd)
	named="${1}"
	
	installed_yet=($(pacman -r ${NEWROOT} -Qsq ${named}))
	
	if [[ -z ${installed_yet[@]} ]]; then
		rc=1
	else
		check_elements "${named}" ${installed_yet[@]}
		rc=$?
	fi
	
	if (( "${rc}" )); then
		unset rc
		
		work_dir=$(mktemp -d /tmp/$named.XXXXXX)
	
		out_action "Install $named from AUR"
	
		out_action "Get pkgbuild for ${named}"	
		aur_get_pkgbuild "${named}" "${work_dir}"
		
		real_name=$(ls -A "${work_dir}")
		
		cd "${work_dir}/${real_name}"
		out_action "Resolve dependencies for ${named}"
		aur_deps "${named}"

		out_action "Build the package ${named}"
		chmod -R 0777 ${work_dir}
		aur_build "${named}" "${work_dir}/${real_name}"
	
		out_action "Installing package ${named}"
	
		pacman -r "$NEWROOT" -U ${named}-*.pkg.tar.xz --config "$GENERAL_DIR/$CONFIG_DIR/pacman.conf" --cachedir "$CACHE_DIR" --noconfirm || die " Failed to install packages $named" "clean_install"
	
		cd "${_oldpwd}"
	fi
	
	unset work_dir named _oldpwd pkg_ver_rel installed_yet real_name
}
