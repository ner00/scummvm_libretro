#!/bin/bash

 # Copyright (C) 2022 Giovanni Cascione <ing.cascione@gmail.com>
 #
 # This program is free software: you can redistribute it and/or modify
 # it under the terms of the GNU General Public License as published by
 # the Free Software Foundation, either version 3 of the License, or
 # (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 # GNU General Public License for more details.
 #
 # You should have received a copy of the GNU General Public License
 # along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

function get_firmware_entry(){
	echo "
firmware$1_desc = \"$2\"
firmware$1_path = \"$3/$2\"
firmware$1_opt = \"true\"
"
}

function process_group(){
	local dirname="$1"
	shift
	local arr=("$@")
	for item in "${arr[@]}"; do
		cp $item "${TMP_PATH}/${dirname}/"
		fragment=$(get_firmware_entry $count $(echo "$item" | sed "s|^.*/||g") "$dirname")
		CORE_INFO_DATS="$CORE_INFO_DATS $fragment"
		count=$(expr $count + 1)
	done
}

# Set variables
BUILD_PATH=$(pwd)
SRC_PATH="${BUILD_PATH}/../../../.."
TMP_PATH="${BUILD_PATH}/tmp_data"
BUNDLE_DIR="scummvm"
BUNDLE_DATAFILES_DIR="${BUNDLE_DIR}/extra"
BUNDLE_THEME_DIR="${BUNDLE_DIR}/theme"
BUNDLE_ZIP_FILE="${BUNDLE_DIR}.zip"
BUNDLE_LOCAL_DATAFILES_DIR="${BUILD_PATH}/../dist"

# Retrieve data file info from ScummVM source
THEMES_LIST=$(cat "${SRC_PATH}/dists/scummvm.rc" | grep FILE.*gui/themes.*\.zip | sed "s|.*\"\(.*\)\"|${SRC_PATH}/\1|g")
DATAFILES_LIST=$(cat "${SRC_PATH}/dists/scummvm.rc" | grep FILE.*dists/engine-data | sed "s|.*\"\(.*\)\"|${SRC_PATH}/\1|g")

# Put retrieved data into arrays
set +e
read -a THEME_ARRAY -d '' -r <<< "${THEMES_LIST}"
read -a DATAFILES_ARRAY -d '' -r <<< "$DATAFILES_LIST"
set -e

# Make sure target folders exist
mkdir -p "${TMP_PATH}/${BUNDLE_THEME_DIR}/"
mkdir -p "${TMP_PATH}/${BUNDLE_DATAFILES_DIR}/"

count=0
# Process themes
	process_group "$BUNDLE_THEME_DIR" ${THEME_ARRAY[@]}

# Process datafiles
	process_group "$BUNDLE_DATAFILES_DIR" ${DATAFILES_ARRAY[@]}

# Process additional local bundle files
if [ -d "$BUNDLE_LOCAL_DATAFILES_DIR" -a ! -z "$(ls -A ${BUNDLE_LOCAL_DATAFILES_DIR} 2>/dev/null)" ] ; then
	for item in $BUNDLE_LOCAL_DATAFILES_DIR/*; do
		[ ! $(echo "$item" | sed "s|^.*/||g") = "README.md" ] && LOCAL_EXTRA_ARRAY+=("$item")
	done
	process_group "$BUNDLE_DATAFILES_DIR" ${LOCAL_EXTRA_ARRAY[@]}
fi

# Create core.info file
set +e
read -d '' CORE_INFO_CONTENT <<EOF
# Software Information
display_name = "ScummVM"
authors = "SCUMMVMdev"
supported_extensions = "scummvm"
corename = "ScummVM"
categories = "Game"
license = "GPLv2"
permissions = ""
display_version = $(cat $SRC_PATH/base/internal_version.h | grep SCUMMVM_VERSION | sed "s|^.*SCUMMVM_VERSION *||g")

# Hardware Information
manufacturer = "Various"
systemname = "Game engine"
systemid = "scummvm"

# Libretro Features
database = "ScummVM"
supports_no_game = "true"
savestate = "false"
savestate_features = "null"
cheats = "false"
input_descriptors = "true"
memory_descriptors = "false"
libretro_saves = "false"
core_options = "true"
core_options_version = "1.3"
load_subsystem = "false"
hw_render = "false"
needs_fullpath = "true"
disk_control = "false"
is_experimental = "false"

# Firmware / BIOS
firmware_count = $count

EOF
set -e

CORE_INFO_CONTENT="$CORE_INFO_CONTENT $CORE_INFO_DATS"
echo "$CORE_INFO_CONTENT" > "$BUILD_PATH/scummvm_libretro.info"

# Create archive
zip -rq "${BUILD_PATH}/$BUNDLE_ZIP_FILE" "$TMP_PATH/$BUNDLE_DIR"

# Remove temporary directories
rm -rf "$TMP_PATH"

echo 0
