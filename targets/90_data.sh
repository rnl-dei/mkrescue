NAME="Data partition"
PART_NAME="data"

function run() {
	check_previous_install "$PARTITION" "$PART_MOUNT_DIR"

	if [[  "$INSTALLED_VERSION" == "0" ]]; then

		remove_partitions_since $PART_NUM

		create_partition_MiB "$PART_NAME" -1

		format $PARTITION "$PART_NAME"

		mount $PARTITION $PART_MOUNT_DIR 2>&1 | quote_output
		echo "$PART_NAME" > "${PART_MOUNT_DIR}/${VERSION_FILE}"
		umount $PART_MOUNT_DIR
	fi
}
