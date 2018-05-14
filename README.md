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

| Variable        | Description                                                |
| ---             | ---                                                        |
| `NAME`          | he name used on the boot menu and script output log        |

### Optional variables

| Variable        | Description                                                |
| ---             | ---                                                        |
| `PART_NAME`     | If defined a partition with this name will be created      |
| `DOWNLOAD_URL`  | URL to update an ISO file                                  |
| `ISO_FILE`      | Local ISO file to use instead of download                  |
| `SYSLINUX_DIR`  | Override the default `syslinux` top-level directory        |
| `SYSLINUX_BIN`  | Override the system syslinux binary                        |

### Functions that may be overridden

| Function     | Default behaviour                                              |
| ---          | ---                                                            |
| `run`        | Auto-detect and install an ISOLINUX or Windows ISO             |
| `customize`  | Nothing                                                        |
| `update_iso` | Updates ISO from URL in `DOWNLOAD_URL`                         |

### Available functions for use

| Function                  | Arguments                  | Description                                                     |
| ---                       | ---                        |                                                                 |
| `update_file_always`      | URL, File name             | Always download the URL given                                   |
| `download_file``          | URL, File name             | Download file if not yet present                                |
| `check_previous_install`  | Partition, Mount directory | Set `INSTALLED_VERSION` to the version present on the partition |
| `remove_partitions_since` | Partition number           | Removes all partitions equal or above the number given          | 
| `create_partition_MiB`    | Name, Size                 | Creates a new partition with the given name and size            |
| `format`                  | Device, Name               | Format the device/partition with vfat                           |

### Accessory functions for use

| Function       | Description                                                           |
| ---            | ---                                                                   |
| `quote_output` | Pipe output to this to show in the terminal with a differente color   | 
| `msg`          | Print text for normal running output with nice formatting and colors  |
| `error`        | Print text for an error condidtion and exits the script               |
| `warning`      | Print noticiable text for non-fatal conditions                        |
