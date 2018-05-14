NAME="System Rescue CD"

PART_NAME="sysrescd"

DOWNLOAD_URL="https://sourceforge.net/projects/systemrescuecd/files/latest/download?source=files"

SYSLINUX_BIN=${ISO_MOUNT_DIR}/usb_inst/syslinux

function customize() {
	msg "Setting default keymap to PT"
	sed -i "s/scandelay/setkmap=pt scandelay/g" ${PART_MOUNT_DIR}/syslinux/syslinux.cfg
}
