#!/bin/bash

NAME="Arch Live CD"

PART_NAME="arch"

DOWNLOAD_URL="http://ftp.rnl.tecnico.ulisboa.pt/pub/archlinux/iso/latest/"

function update_iso() {
	msg "Updating ISO (custom handler)..."
	local iso_path=$(curl -s "${DOWNLOAD_URL}/md5sums.txt" | awk '/.iso$/{print $2}')
	ISO_FILE="${DATA_DIR}/$(basename $iso_path)"
	download_file "${DOWNLOAD_URL}/$iso_path" "$ISO_FILE"
}
