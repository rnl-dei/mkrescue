NAME="Arch Live CD"

PART_NAME="ARCH"

DOWNLOAD_URL="http://ftp.rnl.tecnico.ulisboa.pt/pub/archlinux/iso/latest/"

function update_iso() {
	msg "Updating ISO (custom handler)..."
	local iso_path=$(curl -s "${DOWNLOAD_URL}/md5sums.txt" | awk '/.iso$/{print $2}')
	ISO_FILE="${DATA_DIR}/$(basename $iso_path)"
	download_file "${DOWNLOAD_URL}/$iso_path" "$ISO_FILE"
}

function customize() {
	msg "Fixing archisolabel"
	for f in ${PART_MOUNT_DIR}/**/boot/**/*.cfg ${PART_MOUNT_DIR}/loader/entries/*.conf; do
		sed -i -E "s/archisolabel=ARCH_[0-9]+/archisolabel=$PART_NAME/g" $f
	done
}
