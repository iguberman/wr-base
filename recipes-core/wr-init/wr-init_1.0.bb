DESCRIPTION = "Basic rc.local facility for wrlinux"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690"

SRC_URI = "file://rc.local.example \
           file://rcinit" 

PR = "r0"

S = "${WORKDIR}"

inherit update-rc.d

INITSCRIPT_NAME = "rcinit"
INITSCRIPT_PARAMS = "start 999 2 3 4 5 ."

do_install () {
    install -d ${D}/${sysconfdir}/
    install -m 755 ${S}/rc.local.example ${D}/${sysconfdir}/rc.local
    if ${@base_contains('DISTRO_FEATURES','sysvinit','true','false',d)}; then
        install -d ${D}/${sysconfdir}/init.d
        install -m 755 ${S}/rcinit ${D}/${sysconfdir}/init.d/rcinit
    fi
} 
