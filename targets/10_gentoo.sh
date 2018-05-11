#!/bin/bash

NAME="Gentoo Minimal Live CD"

PART_NAME="gentoo"

DOWNLOAD_URL="http://ftp.rnl.tecnico.ulisboa.pt/pub/gentoo/gentoo-distfiles/releases/amd64/autobuilds"

function update_iso() {
	msg "Updating ISO (custom handler)..."
	local iso_path=$(curl -s "${DOWNLOAD_URL}/latest-install-amd64-minimal.txt" | awk '/^[^#]/{print $1}')
	ISO_FILE="${DATA_DIR}/$(basename $iso_path)"
	download_file "${DOWNLOAD_URL}/$iso_path" "$ISO_FILE"
}
