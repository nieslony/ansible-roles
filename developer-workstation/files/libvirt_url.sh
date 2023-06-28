if groups | tr ' ' '\n' | grep -q 'libvirt' && groups | tr ' ' '\n' | grep -q 'qemu'
then
    export LIBVIRT_DEFAULT_URI="qemu:///system"
fi
