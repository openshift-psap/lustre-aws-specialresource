ARG IMAGE=image-registry.openshift-image-registry.svc:5000/openshift/driver-toolkit:latest
FROM $IMAGE

WORKDIR /build/

# Expecting kmod software version as an input to the build
ARG KMODVER

# Grab the software from upstream

# Expecting kernel version as an input to the build
ARG KVER

# Note, your host must have access to repos where kernel developement
# packages can be installed. If it doesn't the following steps will
# fail

# Install kernel module
ARG RELEASEVER
RUN yum -y install --releasever=${RELEASEVER} wget git make sudo --setopt=install_weak_deps=False --best
      
RUN wget https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -O /tmp/fsx-rpm-public-key.asc \
          && rpm --import /tmp/fsx-rpm-public-key.asc \
          && wget https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/fsx-lustre-client.repo -O /etc/yum.repos.d/aws-fsx.repo
RUN yum -y install --releasever=${RELEASEVER} kmod-lustre-client lustre-client --setopt=install_weak_deps=False --best

# Add the helper tools
WORKDIR /root/kvc-lustre-client
ADD Makefile . 
ADD lustre-client-lib.sh . 
ADD lustre-client-wrapper.sh . 
ADD lustre-client.conf .
RUN mkdir -p /usr/lib/kvc/
RUN mkdir -p /etc/kvc/
RUN make install

RUN systemctl enable kmods-via-containers@lustre-client
