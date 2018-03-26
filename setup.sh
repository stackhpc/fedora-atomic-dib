#!/bin/bash

# Goal:
# Use a fedora atomic image to deploy a k8s cluster on bare metal
# using magnum @ ocata and the k8s_fedora_atomic_v1 (VM) driver.

# Result:
# Got there in the end...
# Required some small code changes, created some bugs, will push patches.

# Problems:
# - fedora-atomic DIB element doesn't work with latest DIB (https://bugs.launchpad.net/magnum/+bug/1699735)
# - Can't use the 'baremetal' element as fedora-atomic depends on vm element.
# - Can't use dracut-network/dracut-regenerate as fedora-atomic cleanup removes dracut (https://bugs.launchpad.net/magnum/+bug/1699771).
# - Have to manually specify kernel & initrd pattern for dracut-network/dracut-regenerate.
# - Fedora-atomic element instructions build a fedora atomic 24 image by default which doesn't work on ocata magnum (https://bugs.launchpad.net/magnum/+bug/1699765).
# - Specifying DIB_RELEASE=25 does not give you a fedora atomic 25 image (https://bugs.launchpad.net/magnum/+bug/1699766).

# Most image formats require the qemu-img tool which is provided by the qemu-utils package on Ubuntu/Debian or the qemu package on Fedora/RHEL/opensuse/Gentoo.
# When generating images with partitions, the kpartx tool is needed, which is provided by the kpartx package.
sudo yum -y install qemu kpartxg git

# Install python and its dependencies
sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
sudo yum -y install python36u python36u-pip python36u-devel tmux2u
pip3.6 install --user virtualenv
virtualenv ~/dib-virtualenv
source ~/dib-virtualenv/bin/activate

# Clone these repos
git clone https://git.openstack.org/openstack/magnum

git clone https://github.com/brtknr/magnum.git
git clone https://git.openstack.org/openstack/dib-utils.git
git clone https://git.openstack.org/openstack/diskimage-builder

pushd magnum && git fetch https://git.openstack.org/openstack/magnum refs/changes/13/476513/1 && popd

export PATH="${PWD}/dib-utils/bin:$PATH"
export DIB_RELEASE=27
export DIB_IMAGE_SIZE=2.5

# Without these the select-initrd-kernel-image element fails as the
# fedora-atomic ramdisk and kernel are not in /boot. This element is a dependency
# of dracut-network/dracut-regenerate.
export DIB_BAREMETAL_KERNEL_PATTERN='ostree/fedora-atomic-*/vmlinuz*'
export DIB_BAREMETAL_INITRD_PATTERN='ostree/fedora-atomic-*/initramfs-*'


export ELEMENTS_PATH=$(python -c 'import os, diskimage_builder, pkg_resources;print(os.path.abspath(pkg_resources.resource_filename(diskimage_builder.__name__, "elements")))')


export ELEMENTS_PATH="${PWD}/diskimage-builder/diskimage_builder/elements"
export ELEMENTS_PATH="${ELEMENTS_PATH}:${PWD}/magnum/magnum/drivers/common/image"

ELEMENTS="\
vm \
dhcp-all-interfaces \
enable-serial-console \
dracut-regenerate \
selinux-permissive \
fedora-atomic \
"
export DIB_DEBUG_TRACE

sudo setenforce Permissive

export FEDORA_ATOMIC_TREE_URL="https://kojipkgs.fedoraproject.org/atomic/${DIB_RELEASE}/"
export FEDORA_ATOMIC_TREE_REF="$(curl ${FEDORA_ATOMIC_TREE_URL}/refs/heads/fedora/${DIB_RELEASE}/x86_64/atomic-host)"

export DIB_DEBUG_TRACE=1 
disk-image-create -p python3-PyYAML -p PyYAML $ELEMENTS -o k9s-fedora-atomic-$DIB_RELEASE.qcow2 | tee dib-uuid27.log
