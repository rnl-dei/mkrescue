NAME="GRUB 2"
#PART_NAME=""

KBD="pt"

function run() {

	# Copy standard files
	grub-install ${BOOT_PART} --no-bootsector \
		--boot-directory ${BOOT_MOUNT_DIR} 2>&1 | quote_output

	# Needed to chainload GRUB from syslinux
	cp /usr/lib/grub/i386-pc/lnxboot.img ${BOOT_MOUNT_DIR}/grub/i386-pc/

	if which ckbcomp &>/dev/null; then
		msg "Generating $KBD keyboard layout..."
		mkdir -p ${BOOT_MOUNT_DIR}/grub/layouts
		ckbcomp $KBD | grub-mklayout -o ${BOOT_MOUNT_DIR}/grub/layouts/KBD.gkb 2>/dev/null

		cat <<EOF >> ${BOOT_MOUNT_DIR}/grub/grub.cfg
terminal_input at_keyboard
keymap $KBD

EOF
	else
		msg "Not generating $KBD keyboard layout, ckbcomp script not found."
	fi

	# Set boot menu entry
	cat <<EOF >> $BOOT_CONFIG

MENU SEPARATOR

LABEL grub
      MENU LABEL $NAME
      LINUX /grub/i386-pc/lnxboot.img
      INITRD /grub/i386-pc/core.img
EOF


	# Set useful defaults for the GRUB shell
	cat <<EOF >> ${BOOT_MOUNT_DIR}/grub/grub.cfg
insmod part_msdos
insmod part_gpt

set default=0

menuentry 'Boot first disk' {
	set root=(hd1)
	chainloader +1
	boot
}

menuentry 'Return to syslinux' {
	chainloader +1
	boot
}

EOF
}
