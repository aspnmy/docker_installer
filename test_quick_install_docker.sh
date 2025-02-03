#!/bin/bash

# Include the script to be tested
source ./quick_install_docker.sh

# Mock functions and variables
CURRENT_DIR="/tmp"
log_file="${CURRENT_DIR}/install.log"

# Create a mock log function to capture output
function log() {
    message="[Aspnmy Log]: $1 "
    echo -e "${message}" >> "${log_file}"
}

# Test function for logging installation message
function test_log_install_docker() {
    # Clear the log file
    true > "${log_file}"

    # Call the log function with the test message
    log "... 在线安装 docker"

    # Check if the log file contains the expected message
    if grep -q "[Aspnmy Log]: ... 在线安装 docker" "${log_file}"; then
        echo "Test passed: log function correctly logs the installation message."
    else
        echo "Test failed: log function did not log the installation message correctly."
    fi
}

# Run the test
test_log_install_docker