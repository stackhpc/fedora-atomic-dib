# Usage

To build the image:

```
INSTALL_DEPS=1 DIB_RELEASE=27 ./fedora_atomic_dib/[setup.sh](setup.sh)
```

`INSTALL DEPS=1` installs all the required packages to run diskimage-builder. It is only necessary to include it the first time.

To boot into the image:

```
./fedora-atomic-dib/gencloudinitiso.sh
DIB_RELEASE=27 sudo -E ./fedora-atomic-dib/qemu.sh
```

# Goal:
- building Fedora Atomic 27 image
- using diskimage-builder 2.12.2
- on Centos 7

# Result:
- modified [existing instructions][existing] for diskimage-builder 2.3.3 to build Fedora Atomic 25 image

# Problems:
- Still need to put selinux into permissive mode on grub config in order to successfully boot into the image.
- Can't use the 'baremetal' element as fedora-atomic depends on vm element.
- Can't use dracut-network/dracut-regenerate as fedora-atomic cleanup removes dracut (https://bugs.launchpad.net/magnum/+bug/1699771).
- Have to manually specify kernel & initrd pattern for dracut-network/dracut-regenerate.
- Specifying DIB_RELEASE=25 does not give you a fedora atomic 25 image (https://bugs.launchpad.net/magnum/+bug/1699766).

[existing]: http://paste.openstack.org/show/613376 
