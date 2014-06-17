# zisofs-tools-native OE build file
# Copyright (C) 1989, 1991 Free Software Foundation, Inc. 
SUMMARY = "A set of tools for iso file compression"
DESCRIPTION = "A set of tools for iso file compression"
HOMEPAGE = "http://http://freecode.com/projects/zisofs-tools"
SECTION = "console/utils"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=94d55d512a9ba36caa9b7df079bae19f"
PR = "r0"

SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/zisofs-tools/zisofs-tools-${PV}.tar.bz2/2d0ed8c9a1f60b45f949b136f9be1f6c/zisofs-tools-${PV}.tar.bz2"

SRC_URI[md5sum] = "2d0ed8c9a1f60b45f949b136f9be1f6c"
SRC_URI[sha256sum] = "ae4e53e4914934d41660248fb59d3c8761f1f1fd180d5ec993c17ddb3afd04f3"

inherit native

STAGE_TEMP = "${WORKDIR}/image-temp"

DEPENDS = "zlib-native"

do_install() {
	install -d ${STAGE_TEMP}
	make install INSTALLROOT=${STAGE_TEMP}

	install -d ${D}${bindir}/
	install ${STAGE_TEMP}/usr/bin/* ${D}${bindir}/
}
