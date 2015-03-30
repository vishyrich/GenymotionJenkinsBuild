#!/bin/sh

#### Common Functions
# Release adb resources
disconnectAttachedDevice() {
    adb disconnect $VM_IP
}

killAdbServer() {
    adb kill-server
}

# Cleanup temp lock files
cleanLockDirectories() {
    if [ -d ${GENYMOTION_BUILD_LOCK_DIR}/.$VM_SELECTED ]
        then
        rm -rf ${GENYMOTION_BUILD_LOCK_DIR}/.$VM_SELECTED
    fi

    if [ -d ${GENYMOTION_BUILD_LOCK_DIR}/.$ADB_PORT ]
        then
        rm -rf ${GENYMOTION_BUILD_LOCK_DIR}/.$ADB_PORT
    fi
}

#### Setup trap signal handling for build aborts
trap cleanLockDirectories INT TERM EXIT
trap killAdbServer INT TERM EXIT

#### Get a random port number to start adb server
for random_port in $(shuf -i 5038-6000 -n 1) ; do
    # Check if lock file exists to confirm port is not in use already
    if  mkdir ${GENYMOTION_BUILD_LOCK_DIR}/.$random_port
    then
        echo "Found free port = " $random_port
        ADB_PORT=$random_port
        break
    else
        echo "Port already in use" $random_port
        continue
    fi
done

#### Get available VMS for text execution
for vm_name in $(VBoxManage list runningvms | awk -F'[{}]' '{print $2}') ; do
    # Check if lock file exists to determine free VM
    if  mkdir ${GENYMOTION_BUILD_LOCK_DIR}/.$vm_name
    then
        echo "Found free Genymotion device =" $vm_name
        VM_SELECTED=$vm_name
        break
    else
        echo "Genymotion device already locked for build" $vm_name
        continue
    fi
done

echo "Selected Genymotion Device = " $VM_SELECTED
echo "Selected Port for ADB =" $ADB_PORT


if [ -z "$VM_SELECTED" ]
    then
    echo "ERROR : Could not find Genymotion device for test execution. Build will abort"
    cleanLockDirectories
    exit 1
fi

if [ -z "ADB_PORT" ]
    then
    echo "ERROR : Could not find suitable ADB port. Build will abort"
    cleanLockDirectories
    exit 1
fi

#### Set env variable for default adb port, start adb server and create lock file
export ANDROID_ADB_SERVER_PORT=$ADB_PORT

adb start-server
if [ $? -ne 0 ]
then
    echo "Error : Could not start ADB server. Build will abort"
    cleanLockDirectories
    exit 1
fi

#### Get IP address of selected VM
VM_IP=`VBoxManage guestproperty get $VM_SELECTED androvm_ip_management | awk -F ": " '{print $2}'`


#### Connect to target VM and create lock file
if [ -z "$VM_IP" ]
then
    echo "Error : Could not retrieve IP address of Genymotion device. Build will abort"
    killAdbServer
    cleanLockDirectories
    exit 1
fi

adb connect $VM_IP
if [ $? -ne 0 ]
then
    echo "Error : Could not connect to Genymotion device. Build will abort"
    killAdbServer
    cleanLockDirectories
fi

#### Set serial name of VM as test target with 5555 as default port
VM_SERIAL_NAME="$VM_IP:5555"
export ANDROID_SERIAL=$VM_SERIAL_NAME

#### Execute Gradle build and tests
echo "********* Starting build ********* "
./gradlew clean build connectedCheck --info


#### Post build clean up process
disconnectAttachedDevice
killAdbServer
cleanLockDirectories
