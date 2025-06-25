---
title: Live disk
weight: 1
type: docs
toc: true
---

Installing the operating system onto a computer involves creating a portal media, often a USB drive, that contains a full, bootable operating system (OS).

> [!IMPORTANT] Use Linux!
> We assume you are using a Linux-based operating system for this step.

## Download

You can go to the [Ubuntu website to download the server operating system](https://ubuntu.com/download/server).
We always recommend using the Long-Term Support (LTS) release because of its extensive testing and reliability.
LTS releases are provided every two years and are supported (i.e., security updates and bug fixes) for five years.

### ISO file

An [ISO file](https://en.wikipedia.org/wiki/Optical_disc_image) is commonly used to store the operating system.

> [!INFO] Fun fact
> ISO files originate from the [ISO 9660](https://en.wikipedia.org/wiki/ISO_9660) file system for optical disks.

## Mount USB

> [!TIP]
> You can find more information about this on the [Arch wiki](https://wiki.archlinux.org/title/USB_flash_installation_medium).

We need to prepare our USB to copy the ISO file over which contains specific partitions.
Plug in your USB and determine the disk name with the following command.

```bash
$ ls -l /dev/disk/by-id/usb-*
lrwxrwxrwx 1 root root  9 Jun 23 21:19 /dev/disk/by-id/usb-SanDisk_Ultra_4C530001210902121330-0:0 -> ../../sda
lrwxrwxrwx 1 root root 10 Jun 23 21:19 /dev/disk/by-id/usb-SanDisk_Ultra_4C530001210902121330-0:0-part1 -> ../../sda1
lrwxrwxrwx 1 root root 10 Jun 23 21:19 /dev/disk/by-id/usb-SanDisk_Ultra_4C530001210902121330-0:0-part2 -> ../../sda2
lrwxrwxrwx 1 root root 10 Jun 23 21:19 /dev/disk/by-id/usb-SanDisk_Ultra_4C530001210902121330-0:0-part3 -> ../../sda3
lrwxrwxrwx 1 root root 10 Jun 23 21:19 /dev/disk/by-id/usb-SanDisk_Ultra_4C530001210902121330-0:0-part4 -> ../../sda4
```

On my system, the USB is named `sda`.
We can check if it's mounted with `lsblk`.

```bash
$ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    1  28.6G  0 disk
├─sda1        8:1    1   5.9G  0 part
├─sda2        8:2    1     5M  0 part
├─sda3        8:3    1   300K  0 part
└─sda4        8:4    1  22.7G  0 part
```

Since the `MOUNTPOINTS` column is empty, our USB is not mounted.
If yours is, you can unmount it by using the command `sudo umount /dev/sda1` (if the `sda1` partition was mounted).


We have to remove all partitions of the USB drive and put one for FAT32 for the OS.
Ensure that your FAT32 partition is large enough for the whole ISO.
In our case, we use 5G.

```bash
$ sudo parted /dev/sda --script \
  mklabel msdos \
  mkpart primary fat32 1MiB 5GiB \
  set 1 boot on
```

Now we need to format the partition for the ISO with FAT32.

```bash
$ sudo mkfs.vfat -F32 /dev/sda1
```

> [!important]
> Make sure you have [`dosfstools`](https://github.com/dosfstools/dosfstools) installed.
> On arch, this would be
>
> ```bash
> $ sudo pacman -Syu dosfstools
> ```

Now we can mount the USB.

```bash
$ sudo mkdir -p /mnt/usb
$ sudo mount /dev/sda1 /mnt/usb
```

## Mount ISO

We first have to mount the ISO file.

```bash
$ sudo mkdir -p /mnt/iso
$ sudo mount -o loop path/to/os.iso /mnt/iso
```

## Write ISO

Copy everything from the ISO to the USB.

```bash
$ sudo cp -aT /mnt/iso/. /mnt/usb/
```

## Done!

At this stage, you are all set to boot into Ubuntu from the USB!
However, we recommend setting up [autoinstall](../autoinstall) to make setting up new computers a breeze.
