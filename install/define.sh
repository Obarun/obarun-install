#!@BINDIR@/bash
# Copyright (c) 2015-2018 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-install/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

## 		Define hostname

define_hostname(){
	
	local _hostname
	out_action "Enter your hostname"
	
	read _hostname
	
	out_valid "hostname is now : $_hostname"
	
	sed -i "s,HOSTNAME=.*$,HOSTNAME=\"$_hostname\",g" "${CONFIG}"
	
	unset _hostname
}

##		Define locale

define_locale(){
	
	local enter _locale list_ 
	local -a list_locale
	
	while read -r list_;do
		case $list_ in
			\#' '*) continue ;;
			\#"") continue ;;
			*) 	list_locale+=( "${list_##*#}" ) 
				;;
		esac
	done < locale.gen
	list_locale+=( "Exit" )
	
	out_action "Define your main local"
	select _locale in "${list_locale[@]}"; do
		case "$_locale" in
			Exit)unset _locale
				break;;
			*)if check_elements "$_locale" "${list_locale[@]}"; then
				_locale="${_locale%%' '*}"
				out_valid "Your main locale is now : ${_locale}"
				break
			  else 
				out_notvalid "Invalid number, retry :"
			  fi
		esac
	done
	if [[ -z "${_locale}" ]]; then
		out_notvalid "Locale is not set, pick en_US.UTF-8 by default"
		_locale="en_US.UTF-8"
	fi
	out_action "Do you want to generate other locale?[y|n]"
	reply_answer
	if (( ! $? )); then
		sed -i "s:^#${_locale}:${_locale}:g" "${NEWROOT}"/etc/locale.gen
		out_action "Define your locale by uncomment the desired lines"
		out_info "Press enter to continue"
		read enter
		"$EDITOR" "${NEWROOT}"/etc/locale.gen
	fi
	
	sed -i "s,LOCALE=.*$,LOCALE=\"$_locale\",g" "${CONFIG}"

	unset enter _locale list_ list_locale
}

##		Define localtime

define_localtime(){

	zone_list=$(ls -d --group-directories-first ${NEWROOT}/${LOCALTIME}/* | awk -F "${NEWROOT}/${LOCALTIME}/" '{ print $2 }' | uniq)
	zone_list+=" Exit"
	select _zone in ${zone_list[@]}; do
		case $_zone in 
			Exit)customizeChroot_menu
			break;;
			*)if check_elements "$_zone" ${zone_list[@]}; then
				if [[  -d "${NEWROOT}/${LOCALTIME}/$_zone" ]]; then
					sub_zone_list=$(ls ${NEWROOT}/${LOCALTIME}/$_zone/* | awk -F "${NEWROOT}/${LOCALTIME}/$_zone/" '{ print $2 }') 
					sub_zone_list+=" Exit"
					select _subzone in ${sub_zone_list[@]}; do
						case $_subzone in
							Exit)define_localtime
								break;;
							*)if check_elements "$_subzone" ${sub_zone_list[@]}; then
								break
							else
								out_notvalid "Invalid number, retry :"
							fi
						esac
					done
				fi
			break	
			else 
				out_notvalid "Invalid number, retry :"
			fi
		esac
	done
}
call_localtime(){
	
	local _zone _subzone
	
	unset ZONE SUBZONE
	
	out_action "Choose your country/department"
	
	define_localtime
	
	out_valid "Your localtime is now : $_zone/$_subzone"
	
	sed -i "s,ZONE=.*$,ZONE=\"$_zone\",g" "${CONFIG}"
	sed -i "s,SUBZONE=.*$,SUBZONE=\"$_subzone\",g" "${CONFIG}"
	
	unset _zone _subzone
}

##		Define keymap

define_keymap(){
	
	local _keymap
	local -a key_list
		
	out_action "Choose your console keymap"

	key_list=$(ls -R ${NEWROOT}/usr/share/kbd/keymaps | grep "map.gz" | sed 's/\.map\.gz//g' | sort | less)
	key_list+=" Exit"
	select _keymap in ${key_list[@]}; do
		case "$_keymap" in
			Exit)unset _keymap
				break;;
			*)if check_elements "$_keymap" ${key_list[@]}; then
				out_valid "Your keymap is now : $_keymap"
				break
			  else 
				out_notvalid "Invalid number, retry :"
			  fi
		esac
	done

	sed -i "s,^KEYMAP=.*$,KEYMAP=\"$_keymap\"," "${CONFIG}"
	
	unset key_list _keymap
}

##		Define xkeymap

define_xkeymap(){
	
	local _xkeymap
	local -a key_list
	
	out_action "Choose your Desktop environment keymap"
	
	key_list="af al am at az ba bd be bg br bt bw by ca cd ch cm cn cz de dk ee es et eu fi fo fr gb ge gh gn gr hr hu ie il in iq ir is it jp ke kg kh kr kz la lk lt lv ma md me mk ml mm mn mt mv ng nl no np pc ph pk pl pt ro rs ru se si sk sn sy tg th tj tm tr tw tz ua us uz vn za"
	key_list+=" Exit"
	select _xkeymap in ${key_list[@]}; do
		case "$_xkeymap" in
			Exit)unset _xkeymap
				break;;
			*)if check_elements "$_xkeymap" ${key_list[@]}; then
				out_valid "Your Desktop keymap is now : $_xkeymap"
				break
			  else 
				out_notvalid "Invalid number, retry :"
			  fi
		esac
	done
	
	sed -i "s,XKEYMAP=.*$,XKEYMAP=\"$_xkeymap\"," "${CONFIG}"
	
	unset key_list _xkeymap
}

##		Define a new user

define_user(){
	
	local _newuser f
	local -a user_exist
	
	out_action "Enter the name for the user"
	read _newuser
	
	user_exist=$(grep "$_newuser" ${NEWROOT}/etc/passwd | awk -F":" '{print $1}')
	
	for f in ${user_exist[@]}; do
		if [[ $f == $_newuser ]]; then			
			out_notvalid "$_newuser already exit, please enter another name :"
			define_user
		fi
	done
	
	if [[ ${#_newuser} -eq 0 ]] || [[ $_newuser =~ \ |\' ]] || [[ $_newuser =~ [^a-z0-9\ ] ]]; then
		out_notvalid "Invalid user name. Please retry :"
		define_user
	fi
	
	out_valid "Name of the new account user is now : $_newuser"
	
	sed -i "s,NEWUSER=.*$,NEWUSER=\"$_newuser\",g" "${CONFIG}"
	
	unset _newuser user_exist f
}

##		Define root user

define_root(){
	
	local pass_exist
	pass_exist=$(grep "root" $NEWROOT/etc/shadow | awk -F':' '{print $2}')
	
	if [[ ! $(grep "root::" $NEWROOT/etc/shadow) ]]; then
		out_action "Create root user on $NEWROOT"
		usermod -R "$NEWROOT" -s /usr/bin/zsh root
	fi
	
	out_action "Copy skeleton to $NEWROOT/root/"
	cp -rT "$NEWROOT/etc/skel/" "$NEWROOT/root/"
		
	chmod 0750 "$NEWROOT/root"
	
	if [[ -z "${pass_exist}" ]]; then
		out_action "You need to define root password"
		pass_root
		out_valid "root user was modified successfully"
	fi
	
	if [[ -e "$NEWROOT/root/.zlogin" ]]; then
		out_action "Removing auto-login for root"
		rm "$NEWROOT/root/.zlogin"
	fi
	
	unset pass_exist
}
