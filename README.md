# GenymotionJenkinsBuild
Script to build and test android application source with Genymotion device as emulator on a Headless Jenkins server

Usage:
Run this script in a shell on desired Jenkins job

Prerequisites:
1) Genymotion devices must be running on Jenkins server in headless mode
 VBoxManage startvm <VM-UUID> --type headless

2) All required global variables must be set in Jenkins enviroment
GENYMOTION_BUILD_LOCK_DIR : path to directory for creating temporary lock files while running concurrent builds
