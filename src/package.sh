#!/bin/bash
# shellcheck enable=require-variable-braces
# file name: package.sh
################################################################################
# License                                                                      #
################################################################################
function license() {
    # On MAC update bash: https://scriptingosx.com/2019/02/install-bash-5-on-macos/
    printf '%s\n' ""
    printf '%s\n' " GPL-3.0-only or GPL-3.0-or-later"
    printf '%s\n' " Copyright (c) 2021 BMC Software, Inc."
    printf '%s\n' " Author: Volker Scheithauer"
    printf '%s\n' " E-Mail: orchestrator@bmc.com"
    printf '%s\n' ""
    printf '%s\n' " This program is free software: you can redistribute it and/or modify"
    printf '%s\n' " it under the terms of the GNU General Public License as published by"
    printf '%s\n' " the Free Software Foundation, either version 3 of the License, or"
    printf '%s\n' " (at your option) any later version."
    printf '%s\n' ""
    printf '%s\n' " This program is distributed in the hope that it will be useful,"
    printf '%s\n' " but WITHOUT ANY WARRANTY; without even the implied warranty of"
    printf '%s\n' " MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
    printf '%s\n' " GNU General Public License for more details."
    printf '%s\n' ""
    printf '%s\n' " You should have received a copy of the GNU General Public License"
    printf '%s\n' " along with this program.  If not, see <https://www.gnu.org/licenses/>."
}

# Get current script folder
DIR_NAME=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
SCRIPT_SETTINGS="${DIR_NAME}/config/setup.settings.ini"
SCRIPT_DATA_FILE="${DIR_NAME}/config/data.json"
DIR_NAME_PROJECT=$(cd $(dirname "${DIR_NAME[0]}") && pwd)

# Bash Script Colors
# Reset
Color_Off='\033[0m' # Text Reset

# Regular Colors
Black='\033[0;30m'  # Black
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m'   # Blue
Purple='\033[0;35m' # Purple
Cyan='\033[0;36m'   # Cyan
White='\033[0;37m'  # White

# import bash colors
if [[ -f "${SCRIPT_SETTINGS}" ]]; then
    source <(grep = "${SCRIPT_SETTINGS}")
fi

# Script defaults
retcode=0
SETUP_DIR="${DIR_NAME}"
SUDO_STATE="false"

# hostname is assumed to be a FQDN set during installation.
# shellcheck disable=SC2006 disable=SC2086# this is intentional
HOST_FQDN=$(cat /etc/hostname)
# shellcheck disable=SC2006 disable=SC2086# this is intentional
HOST_NAME=$(echo ${HOST_FQDN} | awk -F "." '{print $1}')
# shellcheck disable=SC2006 disable=SC2086# this is intentional
DOMAIN_NAME=$(echo ${HOST_FQDN} | awk -F "." '{print $2"."$3}')
# shellcheck disable=SC2006 disable=SC2086# this is intentional
HOST_IPV4=$(ip address | grep -v "127.0.0" | grep "inet " | awk '{print $2}' | awk -F "/" '{print $1}')

DATE_TODAY="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_DATE=$(date +%Y%m%d.%H%M%S)
LOG_DIR="/var/logs/mps"
# shellcheck disable=SC2006 disable=SC2086# this is intentional
LOG_NAME=$(basename $0)
LOG_FILE="${LOG_DIR}/${LOG_NAME}.txt"
SCRIPT_NAME="${LOG_NAME}"

# Linux Distribution
DISTRIBUTION=$(sudo cat /etc/*-release | uniq -u | grep "^NAME" | awk -F "=" '{ gsub("\"", "",$2); print $2}')
DISTRIBUTION_PRETTY_NAME=$(sudo cat /etc/*-release | uniq -u | grep "^PRETTY_NAME" | awk -F "=" '{ gsub("\"", "",$2); print $2}')

SCRIPT_PURPOSE="Package BMC Managed File Transfer scripts"

# Show license
license

# create log dir
if [ ! -d "${LOG_DIR}" ]; then
    sudo mkdir -p "${LOG_DIR}"
    sudo chown ${USER}:${GROUP} "${LOG_DIR}" -R
fi

sh -c "echo ' -----------------------------------------------' >> '${LOG_FILE}'"
sh -c "echo ' Start date: ${DATE_TODAY}' >> '${LOG_FILE}'"
sh -c "echo ' User Name : ${USER}' >> '${LOG_FILE}'"
sh -c "echo ' Host FDQN : ${HOST_FQDN}' >> '${LOG_FILE}'"
sh -c "echo ' Host Name : ${HOST_NAME}' >> '${LOG_FILE}'"
sh -c "echo ' Host IPv4 : ${HOST_IPV4}' >> '${LOG_FILE}'"

echo " "
echo " Manage System Packages"
echo " -----------------------------------------------"
echo -e " ${Cyan}Date         : ${Yellow}${DATE_TODAY}${Color_Off}"
echo -e " ${Cyan}Distribution : ${Yellow}${DISTRIBUTION_PRETTY_NAME}${Color_Off}"
echo -e " ${Cyan}Current User : ${Yellow}${USER}${Color_Off}"
echo -e " ${Cyan}Sudo Mode    : ${Yellow}${SUDO_STATE}${Color_Off}"
echo -e " ${Cyan}Domain Name  : ${Yellow}${DOMAIN_NAME}${Color_Off}"
echo -e " ${Cyan}Host FDQN    : ${Yellow}${HOST_FQDN}${Color_Off}"
echo -e " ${Cyan}Host Name    : ${Yellow}${HOST_NAME}${Color_Off}"
echo -e " ${Cyan}Host IPv4    : ${Yellow}${HOST_IPV4}${Color_Off}"
echo -e " ${Cyan}Data File    : ${Yellow}${SCRIPT_DATA_FILE}${Color_Off}"

echo " -----------------------------------------------"
SCRIPT_ACTION="Copy Files and Folders"
echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

SOURCE_DIR="${DIR_NAME_PROJECT}/src/scripts"
RELEASE_DIR="${DIR_NAME_PROJECT}/release"
PROJECT_TOML="${DIR_NAME_PROJECT}/project.toml"

RELEASE_TEMP_A=$(cat ${PROJECT_TOML} | grep version | awk -F "=" '{print $2}' | awk '{gsub(/^ +| +$/,"")} {print $0}')
RELEASE_VERSION=$(sed -e 's/^"//' -e 's/"$//' <<<"${RELEASE_TEMP_A}")

RELEASE_TEMP_B=$(cat ${PROJECT_TOML} | grep name | awk -F "=" '{print $2}' | awk '{gsub(/^ +| +$/,"")} {print $0}')
RELEASE_NAME=$(sed -e 's/^"//' -e 's/"$//' <<<"${RELEASE_TEMP_B}")

RELEASE_TEMP_C=$(cat ${PROJECT_TOML} | grep description | awk -F "=" '{print $2}' | awk '{gsub(/^ +| +$/,"")} {print $0}')
RELEASE_DESCRIPTION=$(sed -e 's/^"//' -e 's/"$//' <<<"${RELEASE_TEMP_C}")

DATA_DIR="${DIR_NAME_PROJECT}/data"

# in ${DIR_NAME_PROJECT}/src/scripts
FILES_REQUIRED=(
    "mps.export.metrics.sh"
)

# in ${DIR_NAME_PROJECT}/src/scripts
FOLDERS_REQUIRED=(
    "ignore test"

)

DATA_FILES_REQUIRED=(
    "ignore test"
)

DATA_FOLDERS_REQUIRED=(
    "ignore test"
)

echo " "
echo " Manage BMC MPS Packages"
echo " -----------------------------------------------"
echo -e " ${Cyan}Version      : ${Yellow}${RELEASE_VERSION}${Color_Off}"
echo -e " ${Cyan}Base Dir     : ${Yellow}${DIR_NAME_PROJECT}${Color_Off}"
echo -e " ${Cyan}Source Dir   : ${Yellow}${SOURCE_DIR}${Color_Off}"
echo -e " ${Cyan}Release Dir  : ${Yellow}${RELEASE_DIR}${Color_Off}"
echo " -----------------------------------------------"

if [ ! -d "${RELEASE_DIR}" ]; then
    mkdir -p "${RELEASE_DIR}"
else
    rm -rf "${RELEASE_DIR}"
    mkdir -p "${RELEASE_DIR}"
fi

# Source Code
for FOLDER in "${FOLDERS_REQUIRED[@]}"; do
    FOLDER_PATH_SOURCE="${SOURCE_DIR}/${FOLDER}"
    FOLDER_PATH_TARGET="${RELEASE_DIR}"

    echo " Process Folder \"${FOLDER}\""

    if [ -d "${FOLDER_PATH_SOURCE}" ]; then
        echo -e " ${Cyan}Source Dir   : ${Green}${FOLDER_PATH_SOURCE}${Color_Off}"
        echo -e " ${Cyan}Target Dir   : ${Yellow}${FOLDER_PATH_TARGET}${Color_Off}"

        # if [ ! -d "${FOLDER_PATH_TARGET}" ]; then
        #     mkdir -p "${FOLDER_PATH_TARGET}"
        # fi
        cp -r -u ${FOLDER_PATH_SOURCE}/* ${FOLDER_PATH_TARGET}/
    else
        echo -e " ${Cyan}No Folder    : ${Red}${FOLDER_PATH_SOURCE}${Color_Off}"
    fi
    echo " -----------------------------------------------"

done

for FILE in "${FILES_REQUIRED[@]}"; do
    FILE_PATH_SOURCE="${SOURCE_DIR}/${FILE}"
    FILE_PATH_TARGET="${RELEASE_DIR}"

    echo " Process File \"${FILE}\""

    if [ -f "${FILE_PATH_SOURCE}" ]; then
        echo -e " ${Cyan}Base Dir     : ${Green}${FILE_PATH_SOURCE}${Color_Off}"
        echo -e " ${Cyan}Source Dir   : ${Yellow}${FILE_PATH_TARGET}${Color_Off}"

        cp -r -u ${FILE_PATH_SOURCE} ${FILE_PATH_TARGET}
    else
        echo -e " ${Cyan}No File      : ${Red}${FILE_PATH_SOURCE}${Color_Off}"
    fi
    echo " -----------------------------------------------"
done

# Data
for FOLDER in "${DATA_FOLDERS_REQUIRED[@]}"; do
    FOLDER_PATH_SOURCE="${DATA_DIR}/${FOLDER}"
    FOLDER_PATH_TARGET="${RELEASE_DIR}/data/${FOLDER}"

    echo " Process Folder \"${FOLDER}\""

    if [ -d "${FOLDER_PATH_SOURCE}" ]; then
        echo -e " ${Cyan}Source Dir   : ${Green}${FOLDER_PATH_SOURCE}${Color_Off}"
        echo -e " ${Cyan}Target Dir   : ${Yellow}${FOLDER_PATH_TARGET}${Color_Off}"

        if [ ! -d "${FOLDER_PATH_TARGET}" ]; then
            mkdir -p "${FOLDER_PATH_TARGET}"
        fi
        cp -r -u ${FOLDER_PATH_SOURCE}/* ${FOLDER_PATH_TARGET}/
    else
        echo -e " ${Cyan}No Folder    : ${Red}${FOLDER_PATH_SOURCE}${Color_Off}"
    fi
    echo " -----------------------------------------------"

done

for FILE in "${DATA_FILES_REQUIRED[@]}"; do
    FILE_PATH_SOURCE="${DATA_DIR}/${FILE}"
    FILE_PATH_TARGET="${RELEASE_DIR}/data/"

    echo " Process File \"${FILE}\""

    if [ -f "${FILE_PATH_SOURCE}" ]; then
        echo -e " ${Cyan}Base Dir     : ${Green}${FILE_PATH_SOURCE}${Color_Off}"
        echo -e " ${Cyan}Source Dir   : ${Yellow}${FILE_PATH_TARGET}${Color_Off}"

        cp -r -u ${FILE_PATH_SOURCE} ${FILE_PATH_TARGET}
    else
        echo -e " ${Cyan}No File      : ${Red}${FILE_PATH_SOURCE}${Color_Off}"
    fi
    echo " -----------------------------------------------"
done

FOLDER_PATH_SCRIPTS="${RELEASE_DIR}"
if [ -d "${FOLDER_PATH_SCRIPTS}" ]; then
    sudo chmod +x "${FOLDER_PATH_SCRIPTS}"/*.sh
fi

echo " -----------------------------------------------"
SCRIPT_ACTION="Archive Files and Folders"
echo -e " Script Status: ${Purple}${SCRIPT_ACTION}${Color_Off}"

if [ -d "${RELEASE_DIR}" ]; then
    RELEASE_TARGET_TAR="${DIR_NAME_PROJECT}/${RELEASE_NAME}_${RELEASE_VERSION}.tar.gz"
    RELEASE_LATEST_TAR="${DIR_NAME_PROJECT}/${RELEASE_NAME}_latest.tar.gz"

    RELEASE_TARGET_ZIP="${DIR_NAME_PROJECT}/${RELEASE_NAME}_${RELEASE_VERSION}.zip"

    echo -e " ${Cyan}Log File         : ${Yellow}${LOG_FILE}${Color_Off}"
    echo -e " ${Cyan}Base Dir         : ${Yellow}${DIR_NAME_PROJECT}${Color_Off}"
    echo -e " ${Cyan}Release Name     : ${Yellow}${RELEASE_NAME}${Color_Off}"
    echo -e " ${Cyan}Release Version  : ${Yellow}${RELEASE_VERSION}${Color_Off}"
    echo -e " ${Cyan}Release Comment  : ${Yellow}${RELEASE_DESCRIPTION}${Color_Off}"
    echo -e " ${Cyan}Release Dir      : ${Yellow}${RELEASE_DIR}${Color_Off}"
    echo -e " ${Cyan}Release Tar      : ${Yellow}${RELEASE_TARGET_TAR}${Color_Off}"
    echo -e " ${Cyan}Release Zip      : ${Yellow}${RELEASE_TARGET_ZIP}${Color_Off}"

    if [ -f "${RELEASE_TARGET_TAR}" ]; then
        rm ${RELEASE_TARGET_TAR} -Rf
    fi

    if [ -f "${RELEASE_TARGET_ZIP}" ]; then
        rm ${RELEASE_TARGET_ZIP} -Rf
    fi

    rm -f ${DIR_NAME_PROJECT}/${RELEASE_NAME}_*.tar.gz
    rm -f ${DIR_NAME_PROJECT}/${RELEASE_NAME}_*.zip
    tar -czf ${RELEASE_TARGET_TAR} -C ${RELEASE_DIR} .
    cp ${RELEASE_TARGET_TAR} ${RELEASE_LATEST_TAR}
    zip -rq ${RELEASE_TARGET_ZIP} ${RELEASE_DIR}/*

fi
