# i.MXn Debian Root Generator

From an existing boot filesystem provided by the i.MXn Yocto Linux tree, this
makefile and related scripts will create an sdcard.img file which will boot into
Debian proper.

This set of scripts currently has the ability to apply a simple overlay to the
generated rootfs before creating the sdcard image.

## Building

First, install any required packages for the scripts to do their jobs by doing
the following at a shell prompt:

```
host:~/Projects/imx-debian$ make prereqs
```

This will call out to `apt-get` to install any required packages. Once this is
done, a simple

```
host:~/Projects/imx-debian$ make
```

Will suffice to build the sdcard.img file.

## Examining the results

The `make mount` target will happily open up the generated sdcard.img file and
mount it in the `mount` subdirectory. To unmount simply `make unmount`.
