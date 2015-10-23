#
# Copyright (C) 2012 Wind River Systems, Inc.
#
SUMMARY = "A plain ASCII to PostScript converter"
DESCRIPTION = "GNU enscript is a free replacement for Adobe''s Enscript \
program. Enscript converts ASCII files to PostScript(TM) and spools generated \
PostScript output to the specified printer or saves it to a file. Enscript can \
be extended to handle different output media and includes many options for \
customizing printouts."
HOMEPAGE = "http://www.gnu.org/software/enscript/"
SECTION = "console/utils"

LICENSE = "GPLv3+"
LIC_FILES_CHKSUM = "file://COPYING;md5=f27defe1e96c2e1ecd4e0c9be8967949"

PR = "r0"
SRC_URI = "${GNU_MIRROR}/enscript/enscript-${PV}.tar.gz \
	   file://enscript-autoconf.patch"

inherit autotools gettext

SRC_URI[md5sum] = "3acc242b829adacabcaf28533f049afd"
SRC_URI[sha256sum] = "6d56bada6934d055b34b6c90399aa85975e66457ac5bf513427ae7fc77f5c0bb"

RDEPENDS_${PN} = "perl"
