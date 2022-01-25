#!/bin/bash

BUILD_PX4="true"

echo -e "\e[1;33m Do you want to build PX4 v1.10.1? (y) for simulation (n) if setting this up on on-barod computer \e[0m"
read var
if [ "$var" != "y" ] && [ "$var" != "Y" ] ; then
    echo -e "\e[1;33m Skipping PX4 v1.10.1 \e[0m"
    BUILD_PX4="false"
    sleep 1
else
    echo -e "\e[1;33m PX4 v1.10.1 will be built \e[0m"
    BUILD_PX4="true"
    sleep 1
fi

# set paths
CATKIN_WS=${HOME}/catkin_ws_fastplanner_unity
CATKIN_SRC=${CATKIN_WS}/src
PROJECT_NAME=e2e_navigation
PROJECT_DIR=${CATKIN_SRC}/${PROJECT_NAME}

if [ ! -d "$CATKIN_WS" ]; then
	echo "Creating $CATKIN_WS ... "
	mkdir -p $CATKIN_SRC
fi

if [ ! -d "$CATKIN_SRC" ]; then
	echo "Creating $CATKIN_SRC ..."
fi

# Configure catkin_Ws
cd $CATKIN_WS
catkin init
catkin config --merge-devel
catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release

####################################### Setup PX4 v1.10.1 #######################################
if [ "$BUILD_PX4" != "false" ]; then

    echo -e "\e[1;33m Setting up Px4 v1.10.1 \e[0m"
    # Installing initial dependencies
    sudo apt --quiet -y install \
        ca-certificates \
        gnupg \
        lsb-core \
        wget \
        ;
    # script directory
    cd ${CATKIN_SRC}/px4_fast_planner/install
    DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

    echo -e "\e[1;33m Installing PX4 general dependencies \e[0m"

    sudo apt-get update -y --quiet
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
        astyle \
        build-essential \
        ccache \
        clang \
        clang-tidy \
        cmake \
        cppcheck \
        doxygen \
        file \
        g++ \
        gcc \
        gdb \
        git \
        lcov \
        make \
        ninja-build \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        rsync \
        shellcheck \
        unzip \
        xsltproc \
        zip \
        ;

    echo "arrow" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get -y --quiet --no-install-recommends install \
            gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-base \
            gstreamer1.0-plugins-good \
            gstreamer1.0-plugins-ugly \
            libeigen3-dev \
            libgazebo9-dev \
            libgstreamer-plugins-base1.0-dev \
            libimage-exiftool-perl \
            libopencv-dev \
            libxml2-utils \
            pkg-config \
            protobuf-compiler \
            ;


    #Setting up PX4 Firmware
    if [ ! -d "${HOME}/Firmware" ]; then
        cd ${HOME}
        git clone https://github.com/PX4/Firmware
    else
        echo "Firmware already exists. Just pulling latest upstream...."
        cd ${HOME}/Firmware
        git pull
    fi
    cd ${HOME}/Firmware
    make clean && make distclean
    git checkout v1.10.1 && git submodule init && git submodule update --recursive
    cd ${HOME}/Firmware/Tools/sitl_gazebo/external/OpticalFlow
    git submodule init && git submodule update --recursive
    cd ${HOME}/Firmware/Tools/sitl_gazebo/external/OpticalFlow/external/klt_feature_tracker
    git submodule init && git submodule update --recursive
    # NOTE: in PX4 v1.10.1, there is a bug in Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h:43:18
    # #define HAS_GYRO TRUE needs to be replaced by #define HAS_GYRO true
    sed -i 's/#define HAS_GYRO.*/#define HAS_GYRO true/' ${HOME}/Firmware/Tools/sitl_gazebo/include/gazebo_opticalflow_plugin.h
    cd ${HOME}/Firmware
    DONT_RUN=1 make px4_sitl gazebo

    # Copy PX4 SITL param file
    cp ${PROJECT_DIR}/px4_fast_planner/config/10017_iris_depth_camera ${HOME}/Firmware/ROMFS/px4fmu_common/init.d-posix/

    # Install MAVROS
    sudo apt install ros-melodic-mavros ros-melodic-mavros-extras -y

fi

# Setting up GAZEBO model paths and plugin paths
SRC_DIR=${HOME}/Firmware
BUILD_DIR=${SRC_DIR}/build/px4_sitl_default
grep -xF 'export GAZEBO_PLUGIN_PATH='${BUILD_DIR}'/build_gazebo' ${HOME}/.bashrc || echo "export GAZEBO_PLUGIN_PATH=${BUILD_DIR}/build_gazebo" >> ${HOME}/.bashrc
grep -xF 'export GAZEBO_PLUGIN_PATH=$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins' ${HOME}/.bashrc || echo "export GAZEBO_PLUGIN_PATH=\$GAZEBO_PLUGIN_PATH:/usr/lib/x86_64-linux-gnu/gazebo-9/plugins" >> ${HOME}/.bashrc
grep -xF 'export GAZEBO_MODEL_PATH='${SRC_DIR}'/Tools/sitl_gazebo/models' ${HOME}/.bashrc || echo "export GAZEBO_MODEL_PATH=${SRC_DIR}/Tools/sitl_gazebo/models" >> ${HOME}/.bashrc
grep -xF 'export GAZEBO_MODEL_PATH=$GAZEBO_MODEL_PATH:'${PROJECT_DIR}'/px4_fast_planner/models' ${HOME}/.bashrc || echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:${PROJECT_DIR}/px4_fast_planner/models" >> ${HOME}/.bashrc
grep -xF 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'${BUILD_DIR}'/build_gazebo' ${HOME}/.bashrc || echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${BUILD_DIR}/build_gazebo" >> ${HOME}/.bashrc

# Setting ROS package path
grep -xF 'source '${CATKIN_WS}'/devel/setup.bash' ${HOME}/.bashrc || echo "source $CATKIN_WS/devel/setup.bash" >> $HOME/.bashrc
grep -xF 'export ROS_PACKAGE_PATH='$ROS_PACKAGE_PATH':~/Firmware:~/Firmware/Tools/sitl_gazebo' ${HOME}/.bashrc || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:~/Firmware:~/Firmware/Tools/sitl_gazebo" >> ${HOME}/.bashrc

# uncomment this if you need to install dependencies for Fast-Planner
# sudo apt install ros-melodic-nlopt libarmadillo-dev -y

####################################### Building catkin_ws #######################################

cd $CATKIN_WS
catkin build multi_map_server
catkin build
source ${HOME}/.bashrc
