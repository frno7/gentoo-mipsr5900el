# Gentoo tooling for the PlayStation 2 Linux kernel

Scripts to install `mipsr5900el` target cross-compilers, with both
[GNU libc](https://en.wikipedia.org/wiki/Glibc) and
[Musl](https://en.wikipedia.org/wiki/Musl),
[QEMU/R5900](https://github.com/frno7/qemu), and essential tools and
programs for a [Linux/R5900](https://github.com/frno7/linux) kernel
[initramfs](https://en.wikipedia.org/wiki/Initial_ramdisk).

QEMU/R5900 is statically linked, to be easy to install with
[`binfmt_misc`](https://en.wikipedia.org/wiki/Binfmt_misc). Enable it in
Gentoo with `rc-update add qemu-mipsr5900el-binfmt`. Programs intended for
initramfs, such as Busybox and Dropbear, are also statically linked.

A Docker image is built as a package at Github.
