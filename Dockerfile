# SPDX-License-Identifier: MIT
# Copyright (C) 2020 Tobias Gruetzmacher
# Copyright (C) 2022 Fredrik Noring

FROM gentoo/portage:latest as portage
FROM gentoo/stage3:latest as gentoo

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# sys-devel/crossdev and app-portage/gentoolkit
COPY crossdev.conf /etc/portage/repos.conf/
COPY patches/musl/r5900-ll-sc.patch /etc/portage/patches/cross-mipsr5900el-unknown-linux-musl/musl/
RUN \
	mkdir -p /var/db/repos/crossdev/{profiles,metadata} && \
	echo 'crossdev' >/var/db/repos/crossdev/profiles/repo_name && \
	echo 'masters = gentoo' >/var/db/repos/crossdev/metadata/layout.conf && \
	chown -R portage:portage /var/db/repos/crossdev && \
	emerge sys-devel/bc sys-devel/crossdev dev-vcs/git && \
	crossdev --stage4 --target mipsr5900el-unknown-linux-gnu && \
	crossdev --stage4 --target mipsr5900el-unknown-linux-musl && \
	emerge -v app-portage/gentoolkit && \
	eclean distfiles

# frno7 repo
RUN \
	emerge -v app-eselect/eselect-repository && \
	eselect repository add frno7 git https://github.com/frno7/gentoo.overlay && \
	emaint sync -r frno7 && \
	mkdir /usr/mipsr5900el-unknown-linux-{gnu,musl}/etc/portage/repos.conf && \
	ln -s /etc/portage/repos.conf/eselect-repo.conf /usr/mipsr5900el-unknown-linux-gnu/etc/portage/repos.conf/eselect-repo.conf && \
	ln -s /etc/portage/repos.conf/eselect-repo.conf /usr/mipsr5900el-unknown-linux-musl/etc/portage/repos.conf/eselect-repo.conf

# app-emulation/qemu-mipsr5900el
RUN \
	USE="static-user static-libs" emerge -v app-emulation/qemu-mipsr5900el

# sys-apps/busybox
RUN \
	USE="prefix-guest static" emerge-mipsr5900el-unknown-linux-gnu -v sys-apps/busybox && \
	USE="prefix-guest static" emerge-mipsr5900el-unknown-linux-musl -v sys-apps/busybox

# sys-firmware/iopmod
RUN \
	ACCEPT_KEYWORDS="**" USE="-modules tools static" emerge -v sys-firmware/iopmod && \
	ACCEPT_KEYWORDS="**" USE="modules -tools" mipsr5900el-unknown-linux-gnu-emerge -v sys-firmware/iopmod

WORKDIR /srv

# initramfs
COPY initramfs/ps2/init initramfs/ps2/
COPY initramfs/ps2/sbin/init initramfs/ps2/sbin/
RUN \
	mkdir -p initramfs/ps2/{lib/firmware/ps2,bin,dev,etc,mnt,proc,root,sbin,sys,tmp,usr,usr/bin,usr/sbin,var} && \
	cp /usr/mipsr5900el-unknown-linux-gnu/bin/busybox initramfs/ps2/bin/ && \
	cp /usr/mipsr5900el-unknown-linux-gnu/lib/firmware/ps2/* initramfs/ps2/lib/firmware/ps2/

# The Linux kernel takes about 1.7 GB
ENV ARCH=mips CROSS_COMPILE=mipsr5900el-unknown-linux-gnu-
ENV INSTALL_MOD_PATH=../initramfs/ps2 INSTALL_MOD_STRIP=1
RUN git clone https://github.com/frno7/linux --depth 1 && cd linux && \
	make -j $(getconf _NPROCESSORS_ONLN) ps2_defconfig && \
	make -j $(getconf _NPROCESSORS_ONLN) oldconfig && \
	make -j $(getconf _NPROCESSORS_ONLN) vmlinux && \
	make -j $(getconf _NPROCESSORS_ONLN) modules && \
	make -j $(getconf _NPROCESSORS_ONLN) modules_install && \
	make -j $(getconf _NPROCESSORS_ONLN) vmlinuz

# clean
RUN \
	eclean distfiles

WORKDIR /

CMD ["/bin/bash"]
