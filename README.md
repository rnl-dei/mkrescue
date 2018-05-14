# mkrescue

Collection of scripts to generate an USB bootable stick with multiple boot choices.

The main purpose is to install bootable ISO files, currently supporting systems
based on ISOLINUX or Windows installation disks.

## Quick How-To

To install one of the pre-configured choices, just run the desired script with
the USB device as argument.

To create a generic USB stick with rescue and Linux systems:

```sh
$ ./mk-generic-usb-stick /dev/sdX
```

To create a RNL-specific USB stick with also a Labs bootstrap entry and Windows install ISO:
```sh
$ ./mk-rnl-usb-stick /dev/sdX
```

To create other combinations just run `mkrescue` with the desired scripts, for example:
```sh
$ ./mkrescue /dev/sdX targets/05_sysrescd.sh targets/06_ubcd.sh 90_data.sh
```

## How to add new targets

The core is separated from the actual details from each boot entry, with each
entry and/or partition being created by on of the scripts in the `targets` directory.

A standard ISOLINUX/Windows ISO can be installed with the following script:
```sh
NAME="Boot menu title"

PART_NAME="filesystem_name"

DOWNLOAD_URL="generic ISO download URL"
# or
ISO_FILE="${DATA_DIR}/some_file.iso"
```

By only defining this variables, it auto-detects the type of ISO between ISOLINUX
or Windows, and executes the default procedures for each.

It is possible to define here certain functions to override the default behaviour
of the pre-defined functions.

### Required variables

`NAME`

### Optional variables

`PART_NAME`
`DOWNLOAD_URL`
`ISO_FILE`
`SYSLINUX_DIR`
`SYSLINUX_BIN`

### Functions that may be overridden

`run`
`customize`
`update_iso`


### Available functions for use

`update_file_always`
`download_file`
`check_previous_install`
`remove_partitions_since`
`create_partition_MiB`
`format`

### Accessory functions for use

`quote_output`
`msg`
`error`
`warning`
