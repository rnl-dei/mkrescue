   RED="\e[0;31m"
 GREEN="\e[0;32m"
YELLOW="\e[0;33m"
  CYAN="\e[0;36m"
  GRAY="\e[0;90m"
NORMAL="\e[0m"

function msg() {
	if [[ ${SH_FILE+x} ]]; then
		echo -e "  ${CYAN}>>> $1 ${NORMAL}"
	else
		echo -e "${GREEN}>>> $1 ${NORMAL}"
	fi
}

function warning() {
	echo -e "  ${YELLOW}>>> $1 ${NORMAL}"
}

function error() {
	echo -e "${RED}Error: $1${NORMAL}"
	exit 1
}

function quote_output() {
        while read line; do
                echo -e " ${GRAY}${line}${NORMAL}"
        done
}

function file_size() {
	local bytes=$(stat --printf="%s" "$1")
	echo $(( bytes / 1024 / 1024))
}

function download_name() {
	URL=$(curl -sI "$1" | awk 'BEGIN{RS="\r"} $1 == "Location:"{print $2}')
	[[ ! "$URL" ]] && URL="$1"
	FILE=$(basename ${URL%\?*})
	echo -n "$FILE"
}

function download_file() {
	local url="$1" file="$2"
	if [ -f "$file" ]; then
		msg "File already exists, skiping download."
	else
		wget --no-clobber --no-verbose "$url" -O "$file" 2>&1 | quote_output
	fi
}

function update_iso() {
	if [[ "${DOWNLOAD_URL+x}"  ]]; then
		msg "Updating ISO..."
		ISO_FILE="${DATA_DIR}/$(download_name $DOWNLOAD_URL)"
		download_file "$DOWNLOAD_URL" "$ISO_FILE"
	else
		msg "No download URL configured for this ISO."
	fi
}

function update_file_always() {
	local url="$1"
	local file="${2:-}"
	msg "Updating file from $url..."
	[[ ! "$file" ]] && file="${DATA_DIR}/$(download_name $url)"
	rm -f $file
	download_file "$url" "$file"
}

function mount_iso() {
	if [ ! -f "$ISO_FILE" ]; then
		error "Could not find ISO '$ISO_FILE'."
	fi

	msg "Mouting ISO..."
	mount -o loop,exec --read-only "$ISO_FILE" $ISO_MOUNT_DIR 2>&1 | quote_output
	[[ $? != 0 ]] && error "Could not mount ISO for some reason."

	LAST_VERSION="$(basename $ISO_FILE)"
	ISO_SIZE=$(file_size $ISO_FILE) # MiB
	ISO_NEEDED_SIZE=$(echo $ISO_SIZE | awk '{print int($1*1.1)}')
}

function autodetect_iso() {
	if [ -f ${ISO_MOUNT_DIR}/bootmgr ]; then
		ISO_TYPE="windows"
	elif [ "${SYSLINUX_DIR+x}" -o -d ${ISO_MOUNT_DIR}/isolinux -o -d ${ISO_MOUNT_DIR}/syslinux ]; then
		ISO_TYPE="isolinux"
	else
		ISO_TYPE="unknown"
	fi
	msg "Detecting ISO as '$ISO_TYPE'"
}

function is_windows() {
	[[ "$ISO_TYPE" == "windows" ]]
}

function is_isolinux() {
	[[ "$ISO_TYPE" == "isolinux" ]]
}

function customize() {
	msg "No customizations to do..."
}

function check_previous_install() {
	local partition=$1
	local mount_dir=$2

	msg "Checking existing $partition..."

	umount $partition 2>/dev/null

	if mount $partition $mount_dir; then

		if [ -f ${mount_dir}/${VERSION_FILE} ]; then
			read INSTALLED_VERSION < ${mount_dir}/${VERSION_FILE}
		else
			warning "$partition is partitioned but does not have a $NAME installation."
			warning "Press Ctrl+C to cancel or Enter to continue."
			read
			INSTALLED_VERSION=0
		fi
		umount $mount_dir
	else
		INSTALLED_VERSION=0
		msg "Could not mount $partition. Probably good to go..."
	fi
}

function format() {
	local part=$1
	local name="${2:-unnamed}"
	mkfs.vfat -n "$name" $part 2>&1 | quote_output
}

function do_parted() {
	# Really make sure you do not bork your system
	[[ "$DEV" == /dev/sda ]] && return
	parted -s $DEV "$1"
}

function create_partition_MiB() {
	local name=$1
	local size=$2

	local start_mib=$(do_parted "unit MiB print" |
	              awk '$1 ~ /[[:digit:]]/{gsub("(MiB|,00)",""); end = $3} END{print end}')
	[[ ! "$start_mib" ]] && start_mib=1

	# Parted only accept logical partitions if starting 1MiB after the previous one end
	local start="$(( start_mib + 1 ))MiB"

	if [[ "$size" == -1 ]]; then
		local end="-1"
	else
		local end="$(( start + size ))MiB"
	fi

	# TODO: Get the partition number automatically?
	# TODO: Or verify that we are creating the next unused?
	if (( PART_NUM < 4 )); then
		do_parted "mkpart primary ${start} ${end}"
	else
		if (( PART_NUM == 5 )); then
			do_parted "mkpart extended ${start} -1"
		fi
		do_parted "mkpart logical ${start} ${end}"
	fi
}

function get_partition_size_MiB() {
	local num=$1
	do_parted "unit kib print" | awk '$1 == '$num'{sub("kiB","");print $4/1024}'
}

function get_partitions_count() {
	do_parted "print" | awk '$1 ~ /[[:digit:]]/{last=$1} END{print last}'
}

function remove_partitions_since() {
	local start=$1
	local end=$(get_partitions_count)
	for i in $(seq $end -1 $start); do
		do_parted "rm $i"
	done
}

function install_iso() {

	if [[ "$LAST_VERSION" != "$INSTALLED_VERSION" ]]; then

		if [ ! -b "$PARTITION" ]; then
			msg "Creating partition..."
			create_partition_MiB $PART_NAME $ISO_NEEDED_SIZE
		else
			local current_size=$(get_partition_size_MiB $PART_NUM)

			msg "Partition already exists ($current_size MiB)..."

			if (( current_size < ISO_NEEDED_SIZE )); then
				msg "Partition is smaller than the ISO, recreating..."
				remove_partitions_since $PART_NUM
				create_partition_MiB $PART_NAME $ISO_NEEDED_SIZE
			fi
		fi

		[[ ! "$PARTITION" ]] && error "Oops, could not find created partition"

		msg "Formatting..."
		format $PARTITION "$PART_NAME"

		msg "Mouting partition..."
		mount $PARTITION $PART_MOUNT_DIR 2>&1 | quote_output

		msg "Copying files..."
		$IONICE cp -r ${ISO_MOUNT_DIR}/* ${PART_MOUNT_DIR}/

		if [ -d ${PART_MOUNT_DIR}/isolinux ]; then
			msg "Fixing names..."
			mv -v ${PART_MOUNT_DIR}/isolinux/isolinux.cfg \
			      ${PART_MOUNT_DIR}/isolinux/syslinux.cfg | quote_output
			mv -v ${PART_MOUNT_DIR}/isolinux \
			      ${PART_MOUNT_DIR}/syslinux | quote_output
		else
			msg "No names need fixing..."
		fi

		echo $(basename $ISO_FILE) > ${PART_MOUNT_DIR}/${VERSION_FILE}

		customize

		msg "Unmouting partition (may take a while)..."
		umount $PART_MOUNT_DIR

		if is_isolinux; then
			local sysdir=${SYSLINUX_DIR:-syslinux}
			local sysbin=${SYSLINUX_BIN:-syslinux}

			msg "Installing syslinux on VBR ($sysbin, $PARTITION, $sysdir)..."
			$sysbin --install --directory $sysdir $PARTITION
		fi
	else
		msg "Partition already with the last ISO, skiping installation."
	fi

	if is_windows; then
		msg "Copying bootmgr to boot partition"
		cp ${ISO_MOUNT_DIR}/bootmgr ${BOOT_MOUNT_DIR}/
	fi

	umount $ISO_MOUNT_DIR  2>/dev/null
	umount $PART_MOUNT_DIR 2>/dev/null
}

function generate_bootloader_chain_entry() {
	local options=""

	is_windows && options="ntldr=/bootmgr"

	# This must be run after creating the partition, to
	# make sure we have the right partition number
	cat <<EOF >> $BOOT_CONFIG

LABEL $PART_NAME
      MENU LABEL $NAME
      COM32 chain.c32
      APPEND boot $PART_NUM $options
EOF
}

function install_auto() {
	update_iso
	mount_iso
	autodetect_iso
	check_previous_install "$PARTITION" "$PART_MOUNT_DIR"
	install_iso
	generate_bootloader_chain_entry

}

function run() {
	install_auto
}
