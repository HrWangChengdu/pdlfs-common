#!/bin/sh -e
#
# travis-checkcache.sh  check to make sure travis cache is up to date
# 05-Oct-2016  chuck@ece.cmu.edu
#

# set wanted versions tokens here
masterversion=2       # changing this will reset everything
cmake=1               # for bootstrapping
autopkg=1             # automake, autoconf, libtool
gcc=1                 # used only on linux
misc=1                # snappy gflags glog (small stuff only)
ssio=1                # margo  (pulls in all margo's depends too)
mpich=1               # gets its own version because it is big

# get current set of versions
verdir=${HOME}/cache/versions

# handle master reset first
if [ -f $verdir/masterversion ]; then
    oldmasterversion=`cat $verdir/masterversion`
else
    oldmasterversion=none
fi

if [ x$oldmasterversion = x$masterversion ]; then
    echo "cache master version is OK ($masterversion)."
else
    echo "cache master version changed ($oldmasterversion != $masterversion)"
    echo "dumping cache (resets all versions to none)..."
    rm -rf ${HOME}/cache/bin ${HOME}/cache/lib ${HOME}/cache/lib64
    rm -rf ${HOME}/cache/include ${HOME}/cache/share $verdir
    rm -rf ${HOME}/cache/gcc
    mkdir -p $verdir
    echo $masterversion > $verdir/masterversion
    echo "set master version to $masterversion"
fi

# now load all the other versions
for pkg in cmake gcc autopkg misc ssio mpich
do
    if [ -f $verdir/$pkg ]; then
        old=`cat $verdir/$pkg`
        eval old${pkg}=$old
    else
        eval old${pkg}=none
    fi
done

#
# now walk though each package and update if there is a version mismatch
#

# cmake
if [ x$oldcmake = x$cmake ]; then
    echo "cmake is ok (version $cmake)"
else
    echo "cmake out of date ($oldcmake != $cmake)... rebuilding"
    cd /tmp
    rm -rf cmake
    git clone https://cmake.org/cmake.git
    cd cmake
    git checkout --track -b release origin/release
    ./configure --prefix=${HOME}/cache
    make
    make install
    echo $cmake > $verdir/cmake
    echo "cmake updated to $cmake"
fi

# this is for local testing when XCMAKE isn't set
if [ x${XCMAKE} = x ]; then
    XCMAKE=${HOME}/cache/bin/cmake
    echo "DEBUG: set XCMAKE to ${XCMAKE}"
fi

if [ -f ${XCMAKE} ]; then
    echo "updated cmake version:"
    ${XCMAKE} --version
else
    echo "MISSING ${XCMAKE} ... SHOULD NOT HAPPEN"
    exit 1
fi


#
# now that we have ensured cmake is there, use extern umbrella for the rest...
#
cd /tmp
rm -rf extern-umbrella
git clone https://github.com/pdlfs/extern-umbrella.git
cd extern-umbrella

# hack for debugging this script on chuck's laptop
if [ -d /pkg/include ]; then
    mylocal=/pkg
else
    mylocal=/usr/local
fi

mkdir build
cd build
${XCMAKE} -DCMAKE_PREFIX_PATH=$mylocal -DCMAKE_INSTALL_PREFIX=${HOME}/cache ..

#
# here we go!
#

if [ x${CC} = xgcc -a x${TRAVIS_OS_NAME} = xlinux ]; then
    if [ x${CC} = xgcc -a x$oldgcc = x$gcc ]; then
        echo "gcc is ok ($gcc)"
    else
        echo "gcc is out of date ($oldgcc != $gcc)... rebuilding"
        ${CC} --version
        make gcc
        echo $gcc > $verdir/gcc
        echo "gcc updated to $gcc"
        echo ${CC} --version
        ${CC} --version
    fi
else
    echo "skipping gcc on this platform (CC=$CC, OS=$TRAVIS_OS_NAME)"
fi

if [ x$oldautopkg = x$autopkg ]; then
    echo "autotools packages are ok ($autopkg)"
else
    echo "autotools packages are out of date ($oldautopkg != $autopkg)... rebuilding"
    make automake autoconf libtool
    echo $autopkg > $verdir/autopkg
    echo "autopkg updated to $autopkg"
fi

if [ x$oldmisc = x$misc ]; then
    echo "misc packages are ok ($misc)"
else
    echo "misc packages are out of date ($oldmisc != $misc)... rebuilding"
    make snappy gflags glog
    echo $misc > $verdir/misc
    echo "misc updated to $misc"
fi

if [ x$oldmpich = x$mpich ]; then
    echo "mpich packages are ok ($mpich)"
else
    echo "mpich packages are out of date ($oldmpich != $mpich)... rebuilding"
    make mpich
    echo $mpich > $verdir/mpich
    echo "mpich updated to $mpich"
fi

if [ x$oldssio = x$ssio ]; then
    echo "ssio packages are ok ($ssio)"
else
    echo "ssio packages are out of date ($oldssio != $ssio)... rebuilding"
    make margo
    echo $ssio > $verdir/ssio
    echo "ssio updated to $ssio"
fi

exit 0
