#!/bin/bash

if [ INSTALL_DEPS == 1 ]; then
	# Most image formats require the qemu-img tool which is provided by the qemu-utils package on Ubuntu/Debian or the qemu package on Fedora/RHEL/opensuse/Gentoo.
	# When generating images with partitions, the kpartx tool is needed, which is provided by the kpartx package.
	sudo yum -y install qemu kpartxg git

	# Install python and its dependencies
	sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
	sudo yum -y install python36u python36u-pip python36u-devel tmux2u
	pip3.6 install --user virtualenv

	# Clone these repos
	git clone https://git.openstack.org/openstack/magnum

	git clone -b fedora-atomic https://github.com/brtknr/magnum.git 
	git clone https://git.openstack.org/openstack/dib-utils.git
	git clone https://git.openstack.org/openstack/diskimage-builder

	# Install diskimage-builder
	pushd diskimage-builder && pip install -e . && popd

	# The following magnum patch to make dracut-regenerate work has been applied to fedora-atomic branch of brtknr/magnum
	pushd magnum && git fetch https://git.openstack.org/openstack/magnum refs/changes/13/476513/1 && popd
fi

virtualenv ~/dib-virtualenv
source ~/dib-virtualenv/bin/activate

rsync -rp ${PWD}/diskimage-builder/diskimage_builder/elements/fedora-atomic/ ${PWD}/magnum/magnum/drivers/common/image/fedora-atomic/

export PATH="${PWD}/dib-utils/bin:$PATH"
export DIB_RELEASE=${DIB_RELEASE}
export DIB_IMAGE_SIZE=3.0

# Without these the select-initrd-kernel-image element fails as the
# fedora-atomic ramdisk and kernel are not in /boot. This element is a dependency
# of dracut-network/dracut-regenerate.
#export DIB_BAREMETAL_KERNEL_PATTERN='ostree/fedora-atomic-*/vmlinuz*'
#export DIB_BAREMETAL_INITRD_PATTERN='ostree/fedora-atomic-*/initramfs-*'

# This is not currently being used
export ELEMENTS_PATH=$(python -c 'import os, diskimage_builder, pkg_resources;print(os.path.abspath(pkg_resources.resource_filename(diskimage_builder.__name__, "elements")))')

# Overriding venv path with cloned diskimage-builder path
export ELEMENTS_PATH="${PWD}/diskimage-builder/diskimage_builder/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${PWD}/magnum/magnum/drivers/common/image"

# Elements we wantt o include
ELEMENTS="\
dhcp-all-interfaces \
enable-serial-console \
dracut-regenerate \
fedora-atomic \
vm \
"

sudo setenforce Permissive

export DIB_DEBUG_TRACE=1 
#export break=before-root,before-extra-data,before-pre-install,before-install,before-post-install,before-block-device,before-finalise,before-cleanup

export break=after-error

disk-image-create $ELEMENTS -o baremetal-${DIB_RELEASE}.qcow2 | tee baremetal-${DIB_RELEASE}.log
