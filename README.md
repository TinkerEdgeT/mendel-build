# i.MXn Debian System

These files comprise the build system to produce both an eMMC and SD card image
of Debian Squeeze for the i.MX8M SoC.

## Building

The first step to using this build system is to source the environment setup
script:

```
host:~/Projects/imx-debian$ source build/setup.sh
```

This will add the host tool binaries directory to your path, add the build
directory to your path, and setup some helpful environment variables as well.
Once this is done, you'll have a new `m` script to run to build the system.

First, install any required packages for the scripts to do their jobs by doing
the following at a shell prompt:

```
host:~/Projects/imx-debian$ m prereqs
```

This will call out to `apt-get` to install any required packages via `sudo`.
Once this is done, a simple

```
host:~/Projects/imx-debian$ m
```

Will suffice to build the sdcard.img file. Note that you may want to provide a
`-j` option with as many cores as you have in your system.

## Examining the results

Output files are located in the `out/` directory by default, and it's super easy
to get to that location by typing in `cd $PRODUCT_OUT` or `j product`.
