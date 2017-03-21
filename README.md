# Docker-REDHAWK

This repository builds a series of Docker images and scripts for standing up an RPM-based installation of REDHAWK SDR with the exception of `redhawk/usrp` (as of this 2.0.5 release).  For that image, the UHD driver is recompiled to a newer version and the USRP_UHD Device is compiled from source against that newer driver.  The result is access to the latest Ettus Research USRPs from the container.

## Building

To build all images, simply type `make`.  You will end up with the following images that are meant't to be run individually.

* `redhawk/base`: This is the repository installation, omni services (non-running), and an `/etc/omniORB.cfg` update script.
* `redhawk/runtime`: The typical "REDHAWK Runtime" group install.  It is the basis for the `domain` and various device launchers.

The remaining images are derived and come with helper scripts for deploying your system:

 * `redhawk/omniserver`: OmniORB and OmniEvents services wrapped in a single image, intended to be run as a singleton in the network.  If you have an Omni server running elsewhere, you do not need this.  Instead, specify the IP address to, for example, the `domain.sh` script.  Use `make omniserver.sh` to get the utility script if it does not already exist.
 * `redhawk/domain`: Configured to run as a Domain.  Use `make domain.sh` to get the utility script if it does not already exist.
 * `redhawk/gpp`: Configured to run as a GPP -bearing Node.  Use `make gpp.sh` to get the utility script if it does not already exist.
 * `redhawk/rtl2832u`: Configured to run as an RTL2832U -bearing Node.  Use `make rtl2832u.sh` to get the utility script if it does not already exist.
 * `redhawk/usrp`: Configured to run as an USRP_UHD -bearing Node.  Use `make usrp.sh` to get the utility script if it does not already exist.

## Retaining SDRROOT

Use `make sdrroot.sh` to expose a utility script for creating an SDRROOT volume that can be mounted to the Domain and IDE.

    make sdrroot.sh
    ./sdrroot.sh MY_REDHAWK
    ./rhide.sh MY_REDHAWK
    ./domain.sh start MY_DOMAIN MY_REDHAWK

## Running the IDE

 * `redhawk/development`: Use `make rhide.sh` to get a utility script for starting the IDE.

## Device Node Auto-launchers

TBD.  We'll be adding some udev scripts to automatically launch and configure containers for USRPs, etc.

