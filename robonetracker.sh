#!/bin/bash

# This script is intended to setup robonetracker in ~/source/robonetracker
# with dependencies on homebrew or linuxbrew depending on the OS being used
# @author Andrew Hundt <ATHundt@gmail.com>
#
# 
# One step setup command for robonetracker:
# bash <(curl -fsSL https://raw.githubusercontent.com/ahundt/homebrew-robotics/master/robonetracker.sh)

echo ""
echo "###############################################################################################"
echo "# Make sure you have access to https://github.com/ahundt/robonetracker                        #"
echo "# Also, ensure you have your ssh key configured, if you don't you'll have to finish manually! #"
echo "###############################################################################################"
echo ""


# stop on errors
set -e
set -u
set -x


# source: https://gist.github.com/phatblat/1713458
# Save script's current directory
DIR=$(pwd)

#
# Check if Homebrew is installed
#
which brew
if [[ $? != 0 ]] ; then

    OS=`uname`
    case $OS in
      'Linux')
        OS='Linux'
        alias ls='ls --color=auto'
        curl -fsSL https://raw.githubusercontent.com/ahundt/homebrew-robotics/master/linuxbrew.sh | bash /dev/stdin
        # This param lets robonetracker build with the native linux dependencies
        # For details see: https://github.com/Homebrew/linuxbrew/issues/13
        OSPARAM="--env=inherit"
        ;;
      'FreeBSD')
        OS='FreeBSD'
        alias ls='ls -G'
        ;;
      'WindowsNT')
        OS='Windows'
        ;;
      'Darwin') 
        OS='Mac'
        /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/gist/323731)"
        ;;
      'SunOS')
        OS='Solaris'
        ;;
      'AIX') ;;
      *) ;;
    esac    
else
    brew update
fi

#
# Check if Git is installed
#
type git >/dev/null 2>&1 || { brew install git }


cd $HOME

# lots of scientific libraries and developer tools
brew tap homebrew/science
brew install cmake --with-docs  $OSPARAM
brew install doxygen flatbuffers  $OSPARAM

# install boost
if [ -d $HOME/.linuxbrew ] ; then
  # temporary until https://github.com/Homebrew/homebrew/issues/45954
  # is resolved in both homebrew and linuxbrew
  brew install https://raw.githubusercontent.com/ahundt/linuxbrew/f3158287defedf2067d701af13f586997a244256/Library/Formula/boost.rb --c++11  $OSPARAM
else
  brew install boost --c++11 $OSPARAM
fi
# brew install pcl --with-qt5 --with-openni2 --with-examples



# Mac & Linux TODO:
# This needs to be fit into the OSTYPE case statement, or a new way to do this
# with multiple lines needs to be worked out. 
#  https://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script

# Mac OSX TODO:

# Enable --with cuda if you have an nvidia graphics card and cuda 7.0 or greater installed
# install caskroom application manager
# brew casks are only supported on mac, not linux

# http://docs.nvidia.com/cuda/index.html
#brew cask install cuda
#brew cask install vrep
brew install opencv3 --with-contrib --c++11 --without-python3 --without-python $OSPARAM -v # --with-cuda
brew link opencv3 --force

# from https://github.com/ahundt/homebrew-robotics
# robotics related libraries
brew tap ahundt/robotics
brew install cmake-basis $OSPARAM
brew install tbb protobuf suite-sparse gflags glog openblas ceres-solver $OSPARAM
brew install cisstnetlib $OSPARAM # --cc=clang 
brew install cisst $OSPARAM
brew install sawconstraintcontroller $OSPARAM
brew install azmq $OSPARAM

cd $DIR

if [ ! -d $DIR/robonetracker ] ; then
    git clone git@github.com:ahundt/robonetracker.git
fi

cd robonetracker; 

if [ ! -d `pwd`/build ] ; then
    mkdir build;
fi

cd build;

if [ -d $HOME/.linuxbrew ] ; then
#    cmake .. -DCisstNetlib_DIR=$HOME/.linuxbrew/Cellar/cisstnetlib/HEAD/cmake  -DBUILD_ALL_MODULES=ON -DBUILD-TESTING=ON -DsawConstraintController_DIR=$HOME/.linuxbrew/Cellar/sawconstraintcontroller/HEAD/share/cisst-1.0/cmake/saw/ -DBLAS_LIBRARIES_DIR=~/.linuxbrew/lib -DLAPACK_LIBRARIES_DIR=~/.linuxbrew/lib -DLibrt_LIBRARIES=~/.linuxbrew/lib/librt.so
    cmake .. -DCisstNetlib_DIR=$HOME/.linuxbrew/Cellar/cisstnetlib/HEAD/cmake  -DBUILD_ALL_MODULES=ON -DBUILD-TESTING=ON -DsawConstraintController_DIR=$HOME/.linuxbrew/Cellar/sawconstraintcontroller/HEAD/share/cisst-1.0/cmake/saw/ -DBLAS_LIBRARIES_DIR=~/.linuxbrew/lib -DLAPACK_LIBRARIES_DIR=~/.linuxbrew/lib -DLibrt_LIBRARIES=~/.linuxbrew/lib/librt.so
    
else
   cmake .. -DBUILD_ALL_MODULES=ON -DBUILD-TESTING=ON -DCisstNetlib_DIR=/usr/local/Cellar/cisstnetlib/HEAD/cmake -DLAPACK_LIBRARIES_DIR=~/usr/local/Cellar/lib -DsawConstraintController_DIR=usr/local/Cellar/sawconstraintcontroller/HEAD/share/cisst-1.0/cmake/saw/

fi

# Build as much as possible, ignoring errors
make -j4 -i


