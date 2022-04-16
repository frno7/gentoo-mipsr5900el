# MIPS R5900 (PS2) Toolchain Docker Gentoo Image

This docker image contains a precompiled `mipsr5900el-unknown-linux-gnu` for building a modern kernel & userspace for a Sony PlayStation 2. It is based on a Gentoo stage 3 image and uses `crossdev` to build the toolchain.

It contains several layers compiled for target `mipsr5900el-unknown-linux-gnu`:

- [qemu](https://github.com/frno7/qemu)
- crossdev
- busybox
- [iopmod](https://github.com/frno7/iopmod) - working directory `/srv/iopmod`
- simple initramfs with [iopmod modules](https://github.com/frno7/iopmod) and [kernel modules](https://github.com/frno7/linux) - working directory `/srv/initramfs/ps2`
- [kernel](https://github.com/frno7/linux) - working directory `/srv/linux`
