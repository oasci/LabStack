---
title: Autoinstall
type: docs
toc: true
weight: 2
---

Manually installing operating systems across many bare-metal servers is a tedious process.
Ubuntu provides an [autoinstall framework](https://canonical-subiquity.readthedocs-hosted.com/en/latest/) [through subiquity](https://github.com/canonical/subiquity) that enables automation of OS installs.

## Configuration

We specify the autoinstall configuration using a YAML file included in the installation media.
This YAML file must contain a root key of `autoinstall` with configuration keys included in this section.
Many of the common errors is forgetting to nest all other keys under `autoinstall` or missing required keys; thus, we will include the root `autoinstall:` key in all examples.

### Version

This [future-proofing key](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#version) is just used in case a new `autoinstall.yaml` formatting is released.
Currently, it must be set to `1`.

```yaml
autoinstall:
  version: 1
```

### Locale

The [locale](https://wiki.archlinux.org/title/Locale) specifies information about user preferences for region-specific formatting such as numbers, currency, paper sizes, etc.
You can find a list of enabled locales on a local linux system using:

```bash
$ locale --all-locales
```

Below is an example for setting United States English with UTF-8 encoding.

```yaml
autoinstall:
  locale: "en_US.UTF-8"
```

### Keyboard

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#keyboard)

```yaml
autoinstall:
  keyboard:
    layout: us
    variant: ""
    toggle: null
```

### Source

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#source)


```yaml
autoinstall:
  source:
    search_drivers: true
    id: ubuntu-server
```

### Proxy

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#proxy)


```yaml
autoinstall:
  proxy: null
```

### ssh

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#ssh)


```yaml
autoinstall:
  ssh:
    install-server: true
    authorized-keys: []
    allow-pw: false
```

### Drivers

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#drivers)


```yaml
autoinstall:
  drivers:
    install: true
```

### OEM

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#oem)


```yaml
autoinstall:
  oem:
    install: false
```

### Packages

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#packages)


```yaml
  packages:
    - build-essential
    - git
    - nfs-common
    - nfs-kernel-server
    - curl
    - wget
    - cmake
```

### Storage

[Setting up the storage](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#storage) for the OS is where the most frustration can occur.
The [Ubuntu installation documentation](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#storage) only provides basic documentation and simple examples.
We recommend reading about [curtin](https://curtin.readthedocs.io/en/latest/topics/storage.html), which is used to specify all steps of block device preparation.


> [!TIP]
> If after a couple of tries of formatting the setup you want, it is much easier to remove this `storage` section and add it to [`interactive-sections`](#interactive-sections).
> This will allow you to use the GUI to setup how you want your storage and you can see how curtin sets up this section.
> You can see this file by doing the following.
>
>  TODO: Check paths
>
>  {{% steps %}}
>
>  ##### Enter shell
>
>  Drop into the shell by going to `Help` in the top right (after finishing the storage section).
>
> ##### Find curtin logs
>
>  Navigate to the curtin configuration directory.
>
>  ```bash
>  $ cd /var/log/installer/curtin-install
>  ```
>
> ##### Open partition configuration
>
>  And open the partition config file.
>
>  ```bash
>  $ nano sububiquity-curtin-partition.conf
>  ```
>
>  {{% /steps %}}

Each item under the storage configuration specifies an action that curtin will take.

```yaml
autoinstall:
  storage:
    config:
      # Action 1
      - key1: value1
        key2: value2
      # Action 2
      - key1: value1
        key2: value2
```

Each action has their set of keys that must be required, but each action requires a `type` and `id`.
The `type` tells curtin the type of action we are describing and we give the result of that action a label called the `id`.
For example, we can create a boot partition with the [`partition`](#partitions) action `type` and refer to this partition action with the `id` of `boot-partition` when we [`format`](#formatting) it.
These `id`s are only ever used with curtin.

> [!WARNING]
> These actions are ran in order as they are specified.
> If you try to [`format`](#formatting) a [`partition`](#partitions) before defining that action, curtin will fail.

#### Disks

Every storage configuration starts by [specifying the disks](https://curtin.readthedocs.io/en/latest/topics/storage.html#dasd-command) we will be working with during the installation.

```yaml
autoinstall:
  storage:
    config:
      - type: disk
        id: disk0
        match:
          size: smallest
        ptable: gpt
        wipe: superblock-recursive
        preserve: false
        grub_device: false
```

#### Partitions

TODO: https://curtin.readthedocs.io/en/latest/topics/storage.html#partition-command

##### `/boot/efi`

```yaml
autoinstall:
  storage:
    config:
      - type: partition
        id: efi-partition
        number: 1
        size: 1G
        device: disk0
        flag: boot
        preserve: false
        grub_device: true
        wipe: superblock
```

##### `/boot`

```yaml
autoinstall:
  storage:
    config:
      - type: partition
        id: boot-partition
        number: 2
        size: 1G
        device: disk0
        preserve: false
        grub_device: false
        wipe: superblock
```

##### `SWAP`

```yaml
autoinstall:
  storage:
    config:
      - type: partition
        id: swap-partition
        number: 3
        size: 8G
        device: disk0
        preserve: false
        grub_device: false
        wipe: superblock

```

###### Logical volume

```yaml
autoinstall:
  storage:
    config:
      - type: partition
        id: pv0
        number: 4
        size: 500G
        device: disk0
        preserve: false
        grub_device: false
        wipe: superblock

```

#### Formatting

TODO: https://curtin.readthedocs.io/en/latest/topics/storage.html#format-command

```yaml
autoinstall:
  storage:
    config:
      - type: format
        id: efi-format
        fstype: fat32
        volume: efi-partition
        preserve: false
```

#### Logical volumes

TODO:

- https://curtin.readthedocs.io/en/latest/topics/storage.html#lvm-volgroup-command
- https://curtin.readthedocs.io/en/latest/topics/storage.html#lvm-partition-command

```yaml
autoinstall:
  storage:
    config:
      - type: lvm_volgroup
        id: vg0
        name: vg0
        devices:
          - pv0
        preserve: false

      # Logical volumes
      - type: lvm_partition
        id: root-lv
        name: root-lv
        volgroup: vg0
        size: 50G
        preserve: false
        wipe: superblock
```

#### Mounting

TODO: https://curtin.readthedocs.io/en/latest/topics/storage.html#mount-command

```yaml
autoinstall:
  storage:
    config:
      - type: mount
        id: efi-mount
        path: /boot/efi
        device: efi-format

      - type: mount
        id: swap-mount
        path: ''
        device: swap-format

      - type: mount
        id: root-mount
        path: /
        device: root-format
```

### Timezone

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#timezone)


```yaml
autoinstall:
  timezone: "US/Eastern"
```

### Updates

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#updates)

```yaml
autoinstall:
  updates: all
```

### Shutdown

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#shutdown)

```yaml
autoinstall:
  shutdown: reboot
```

### Interactive sections

TODO: Fill out from [docs](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html#interactive-sections)

```yaml
autoinstall:
  interactive-sections:
    - network
    - identity
```

