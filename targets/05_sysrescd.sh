NAME="System Rescue CD"

PART_NAME="SYSRESCD"

DOWNLOAD_URL="https://sourceforge.net/projects/systemrescuecd/files/latest/download?source=files"

function customize() {
	msg "Setting default keymap to PT"
	msg "Fixing archisolabel"
	for f in ${PART_MOUNT_DIR}/**/boot/**/*.cfg; do
		sed -i -E "s/archisolabel=SYSRCD[0-9]+/archisolabel=$PART_NAME setkmap=pt-latin1/g" $f
	done
}
