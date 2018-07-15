# mkrescue

Collection of scripts to generate a bootable [USB stick](https://en.wikipedia.org/wiki/USB_flash_drive) with multiple boot choices.

The main purpose is to install bootable ISO files,
currently supporting systems based on [ISOLINUX](https://en.wikipedia.org/wiki/Isolinux)
or Windows installation disks.

## Quick How-To

To install one of the pre-configured choices, just run the desired script with
the USB device as argument.
Most of the included targets automatically download the required images.

To create a generic USB stick with rescue and Linux systems:

```sh
$ ./create-generic-usb-stick /dev/sdX
```

To create an RNL-specific USB stick, including *Labs bootstrap* and Windows install ISO entries:
```sh
$ ./create-rnl-usb-stick /dev/sdX
```
Warning: The Windows ISO is not distributed here, nor is it automatically downloaded.
You must manually acquire it through your available legal channel.

To create other combinations just run `mkrescue` with the desired scripts, for example:
```sh
$ ./mkrescue /dev/sdX targets/05_sysrescd.sh targets/06_ubcd.sh 90_data.sh
```

## How to add new targets

The core functionality is abstracted from the actual details of each boot entry. Each
entry and/or partition is created by one of the scripts in the `targets` directory.

A standard ISOLINUX/Windows ISO can be installed using the following script:
```sh
NAME="Boot menu title"

PART_NAME="filesystem_name"

DOWNLOAD_URL="generic ISO download URL"
# or
ISO_FILE="${DATA_DIR}/some_file.iso"
```

By only defining these variables, the type of ISO (ISOLINUX or Windows)
is automatically detected and the default procedures for each are executed.

Certain functions can also be defined in the script, overriding the default behaviour
of the pre-defined functions.

### Required variables

| Variable        | Description                                                 |
| ---             | ---                                                         |
| `NAME`          | The name used on the boot menu and script output            |

### Optional variables

| Variable        | Description                                                 |
| ---             | ---                                                         |
| `PART_NAME`     | If defined, a partition with this name will be created      |
| `DOWNLOAD_URL`  | URL to update an ISO file                                   |
| `ISO_FILE`      | Local ISO file to use instead of download                   |
| `SYSLINUX_DIR`  | Override the default `syslinux` top-level directory         |
| `SYSLINUX_BIN`  | Override the system `syslinux` binary                       |

### Functions that may be overridden

| Function     | Default behaviour                                              |
| ---          | ---                                                            |
| `run`        | Auto detect and install an ISOLINUX or Windows ISO             |
| `customize`  | Nothing                                                        |
| `update_iso` | Updates ISO from URL in `DOWNLOAD_URL`                         |

### Available functions for use

| Function                  | Arguments                  | Description                                                     |
| ---                       | ---                        | ---                                                             |
| `update_file_always`      | URL, File name             | Always download the URL given                                   |
| `download_file`           | URL, File name             | Download file if not yet present                                |
| `check_previous_install`  | Partition, Mount directory | Set `INSTALLED_VERSION` to the version present on the partition |
| `remove_partitions_since` | Partition number           | Removes all partitions equal to or above the given partition number |
| `create_partition_MiB`    | Name, Size                 | Creates a new partition with the given name and size            |
| `format`                  | Device, Name               | Format the device/partition with vfat                           |

### Accessory functions for use

| Function       | Description                                                           |
| ---            | ---                                                                   |
| `quote_output` | Pipe output to this to show in the terminal with a different color    |
| `msg`          | Print text for normal running output with nice formatting and colors  |
| `error`        | Print an error message and abort the script                           |
| `warning`      | Print a non-fatal warning message using noticeable text               |
