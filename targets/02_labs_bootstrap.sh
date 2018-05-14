NAME="Labs bootstrap"

SERVER_URL="https://geminio.rnl.tecnico.ulisboa.pt/"

function run() {

	# Download and copy each file
	for f in labs-bootstrap-{kernel,initramfs}; do
		update_file_always "${SERVER_URL}/$f" "${DATA_DIR}/$f"
		cp "${DATA_DIR}/$f" "${BOOT_MOUNT_DIR}/"
	done

	# Set boot menu entry
	cat <<EOF >> $BOOT_CONFIG

LABEL bootstrap
      MENU LABEL $NAME
      LINUX  /labs-bootstrap-kernel
      INITRD /labs-bootstrap-initramfs

MENU SEPARATOR
EOF

}
