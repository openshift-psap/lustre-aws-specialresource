#!/bin/bash

# The MIT License

# Copyright (c) 2019 Dusty Mabe

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

set -eu

# This library is to be sourced in as part of the kmods-via-containers
# framework. There are some environment variables that are used in this
# file that are expected to be defined by the framework already:
# - KVC_CONTAINER_ENVIRONMENT
#   - The container runtime to use (example: podman|docker)
# - KVC_SOFTWARE_NAME
#   - The name of this module software bundle
# - KVC_KVER
#   - The kernel version we are targeting

# There are other environment variables that come from the config file
# delivered alongside this library. The expected variables are:
# - KMOD_CONTAINER_BUILD_CONTEXT
#   - A string representing the location of the build context
# - KMOD_CONTAINER_BUILD_FILE
#   - The name of the file in the context with the build definition
#     (i.e. Dockerfile)
# - KMOD_SOFTWARE_VERSION
#   - The version of the software bundle
# - KMOD_NAMES
#   - A space separated list kernel module names that are part of the
#     module software bundle and are to be checked/loaded/unloaded
source "/etc/kvc/${KVC_SOFTWARE_NAME}.conf"

# The name of the container image to consider. It will be a unique
# combination of the module software name/version and the targeted
# kernel version.
IMAGE="${KVC_SOFTWARE_NAME}-${KMOD_SOFTWARE_VERSION}:${KVC_KVER}"

build_kmod_container() {
    echo "Building ${IMAGE} kernel module container..."
    kvc_c_build -t ${IMAGE}                              \
        --file ${KMOD_CONTAINER_BUILD_FILE}          \
        --label="name=${KVC_SOFTWARE_NAME}"          \
        --build-arg KVER=${KVC_KVER}                 \
        --build-arg KMODVER=${KMOD_SOFTWARE_VERSION} \
        ${KMOD_CONTAINER_BUILD_CONTEXT}

    # get rid of any dangling containers if they exist
    echo "Checking for old kernel module images that need to be recycled"
    rmi1=$(kvc_c_images -q -f label="name=${KVC_SOFTWARE_NAME}" -f dangling=true)
    # keep around any non-dangling images for only the most recent 3 kernels
    rmi2=$(kvc_c_images -q -f label="name=${KVC_SOFTWARE_NAME}" -f dangling=false | tail -n +4)
    if [ ! -z "${rmi1}" -o ! -z "${rmi2}" ]; then
        echo "Cleaning up old kernel module container builds"
        kvc_c_rmi -f $rmi1 $rmi2
    fi
}

is_kmod_loaded() {
    module=${1//-/_} # replace any dashes with underscore
    if lsmod | grep "${module}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

build_kmods() {

    if [ $(kvc_c_env) == "kubernetes" ]; then
        return 0
    fi

    # Check to see if it's already built
    if [ ! -z "$(kvc_c_images $IMAGE --quiet 2>/dev/null)" ]; then
        echo "The ${IMAGE} kernel module container is already built"
    else
        build_kmod_container
    fi

    # Sanity checks for each module to load
    for module in ${KMOD_NAMES}; do
        module=${module//_/-} # replace any underscores with dash
        # Sanity check to make sure the built kernel modules were really
        # built against the correct module software version
        # Note the tr to delete the trailing carriage return
        x=$(kvc_c_run $IMAGE modinfo -F version "/lib/modules/${KVC_KVER}/${module}.ko" | \
                                                                            tr -d '\r')
        if [ "${x}" != "${KMOD_SOFTWARE_VERSION}" ]; then
            echo "Module version mismatch within container. rebuilding ${IMAGE}"
            build_kmod_container
        fi
        # Sanity check to make sure the built kernel modules were really
        # built against the desired kernel version
        x=$(kvc_c_run $IMAGE modinfo -F vermagic "/lib/modules/${KVC_KVER}/${module}.ko" | \
                                                                        cut -d ' ' -f 1)
        if [ "${x}" != "${KVC_KVER}" ]; then
            echo "Module not built against ${KVC_KVER}. rebuilding ${IMAGE}"
            build_kmod_container
        fi
    done
}

load_kmods() {
    echo "Loading kernel modules using the kernel module container..."
    if [ ! -f /usr/bin/dracut ]; then
      touch /usr/bin/dracut
    fi
    chmod +x /usr/bin/dracut

    module="lustre"
    if is_kmod_loaded ${module}; then
        echo "Kernel module ${module} already loaded"
    else
        KO_FILES=$(find /lib/modules/*/extra/lustre-client -type f -name "*.ko")
        echo "$KO_FILES" | weak-modules --add-modules --verbose --no-initramfs
        modprobe -v lnet
        modprobe -v ksocklnd
        modprobe -v mgc
        modprobe -v osc
        lnetctl lnet configure --all
        modprobe -v lustre
    fi
}

unload_kmods() {
    echo "Unloading kernel modules..."
    module="lustre"
    if is_kmod_loaded ${module}; then
        modprobe -r lustre
        modprobe -r osc
        modprobe -r mgc
        lnetctl lnet unconfigure
        modprobe -r ksocklnd
        modprobe -r lnet
        lustre_rmmod
    else
        echo "Kernel module ${module} already unloaded"
    fi
}

wrapper() {
    echo "Running userspace wrapper using the kernel module container..."
    # TODO kvc_c_run --privileged $IMAGE $@
}
