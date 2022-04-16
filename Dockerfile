FROM gentoo/portage:latest as portage
FROM gentoo/stage3:latest as gentoo
ENV ARCH=mips CROSS_COMPILE=mipsr5900el-unknown-linux-gnu-

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

# qemu, croosdev and clean
COPY crossdev.conf /etc/portage/repos.conf/
RUN \
	mkdir -p /var/db/repos/localrepo-crossdev/{profiles,metadata} && \
	echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name && \
	echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf && \
	chown -R portage:portage /var/db/repos/localrepo-crossdev && \
	emerge bc crossdev dev-vcs/git && \
	crossdev --stage4 --target mipsr5900el-unknown-linux-gnu && \
	emerge -v app-eselect/eselect-repository && \
	eselect repository add frno7 git https://github.com/frno7/gentoo.overlay && \
	emaint sync -r frno7 && \
	emerge -v dev-libs/glib && \
	emerge -v app-emulation/qemu-mipsr5900el && \
	emerge -v app-portage/gentoolkit && \
	eclean distfiles

WORKDIR /srv
# busybox
RUN \
	USE="prefix-guest static" emerge-mipsr5900el-unknown-linux-gnu -v sys-apps/busybox

# iopmod
RUN \
	git clone https://github.com/frno7/iopmod --depth 1 && \
	cd iopmod && make
	# make clean && git checkout gamepad && make && \
	# cp module/*.irx ../initramfs/ps2/lib/firmware/ps2/

# initramfs
COPY initramfs/ps2/init ./initramfs/ps2/
COPY initramfs/ps2/sbin/init ./initramfs/ps2/sbin/
RUN \
	mkdir -p initramfs/ps2/{lib/firmware/ps2,bin,dev,etc,mnt,proc,root,sbin,sys,tmp,usr,usr/bin,usr/sbin,var} && \
	cp /usr/mipsr5900el-unknown-linux-gnu/bin/busybox initramfs/ps2/bin/ && \
	cp iopmod/module/*.irx initramfs/ps2/lib/firmware/ps2/

# Kernel layer: This takes 1.72 Gb
ENV INSTALL_MOD_PATH=../initramfs/ps2/ INSTALL_MOD_STRIP=1
RUN git clone https://github.com/frno7/linux --depth 1 && cd linux && \
	make -j $(getconf _NPROCESSORS_ONLN) ps2_defconfig && \
	make -j $(getconf _NPROCESSORS_ONLN) oldconfig && \
	make -j $(getconf _NPROCESSORS_ONLN) vmlinux && \
	make -j $(getconf _NPROCESSORS_ONLN) modules && \
	make -j $(getconf _NPROCESSORS_ONLN) modules_install && \
	make -j $(getconf _NPROCESSORS_ONLN) vmlinuz

WORKDIR /
CMD ["/bin/bash"]
