#!/bin/bash
qemu-system-x86_64 -nographic -cdrom cidata.iso baremetal-${DIB_RELEASE}.qcow2 -m 2048 -net user,hostfwd=tcp::1234-:22 -net nic --enable-kvm
