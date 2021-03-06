#
# Copyright (C) 2012 Wind River Systems, Inc.
#
DESCRIPTION = "A foundational basic image that boots to a console."

LICENSE = "MIT"

PR = "r1"

inherit wrlinux-image

# IMAGE_FEATURE invoked by debug template
# note that it is defined for each image recipe
#
FEATURE_PACKAGES_ssh-sftp-servers = "\
    packagegroup-core-ssh-dropbear \
    openssh-sftp-server \
    "

# allows root login without a password
#
IMAGE_FEATURES += "debug-tweaks"

# We override what gets set in core-image.bbclass
#
IMAGE_INSTALL = "\
    packagegroup-core-boot \
    kernel-modules \
    "
