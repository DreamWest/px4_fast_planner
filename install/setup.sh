#!/bin/bash

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

# Install MAVROS
sudo apt install ros-$ROS_DISTRO-mavros ros-$ROS_DISTRO-mavros-extras -y

# Setting up GAZEBO model paths and plugin paths
SRC_DIR=${HOME}/Firmware
BUILD_DIR=${SRC_DIR}/build/px4_sitl_default
grep -xF 'export GAZEBO_PLUGIN_PATH='${BUILD_DIR}'/build_gazebo' ${HOME}/.bashrc || echo "export GAZEBO_PLUGIN_PATH=${BUILD_DIR}/build_gazebo" >> ${HOME}/.bashrc
grep -xF 'export GAZEBO_MODEL_PATH='${SRC_DIR}'/Tools/sitl_gazebo/models' ${HOME}/.bashrc || echo "export GAZEBO_MODEL_PATH=${SRC_DIR}/Tools/sitl_gazebo/models" >> ${HOME}/.bashrc
grep -xF 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:'${BUILD_DIR}'/build_gazebo' ${HOME}/.bashrc || echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${BUILD_DIR}/build_gazebo" >> ${HOME}/.bashrc

# Setting ROS package path
grep -xF 'source '${CATKIN_WS}'/devel/setup.bash' ${HOME}/.bashrc || echo "source $CATKIN_WS/devel/setup.bash" >> $HOME/.bashrc
grep -xF 'export ROS_PACKAGE_PATH='$ROS_PACKAGE_PATH':'${SRC_DIR}':'${SRC_DIR}'/Tools/sitl_gazebo' ${HOME}/.bashrc || echo "export ROS_PACKAGE_PATH=\$ROS_PACKAGE_PATH:\${SRC_DIR}:\${SRC_DIR}/Tools/sitl_gazebo" >> ${HOME}/.bashrc

# uncomment this if you need to install dependencies for Fast-Planner
# sudo apt install ros-$ROS_DISTRO-nlopt libarmadillo-dev -y

####################################### Building catkin_ws #######################################

cd $CATKIN_WS
catkin build multi_map_server
catkin build
source ${HOME}/.bashrc
