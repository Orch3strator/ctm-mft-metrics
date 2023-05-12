#!/bin/bash
# shellcheck enable=require-variable-braces
# file name: mps.export.metrics.sh
################################################################################
# License                                                                      #
################################################################################
function license() {
    # On MAC update bash: https://scriptingosx.com/2019/02/install-bash-5-on-macos/
    printf '%s\n' ""
    printf '%s\n' " GPL-3.0-only or GPL-3.0-or-later"
    printf '%s\n' " Copyright (c) 2023 BMC Software, Inc."
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

function ctmLogo() {
    printf '%s\n' ""
    printf '%s\n' "  @@@@@@@   @@@@@@   @@@  @@@  @@@@@@@  @@@@@@@    @@@@@@   @@@                  @@@@@@@@@@   "
    printf '%s\n' " @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@  @@@@@@@@  @@@@@@@@  @@@                  @@@@@@@@@@@  "
    printf '%s\n' " !@@       @@!  @@@  @@!@!@@@    @@!    @@!  @@@  @@!  @@@  @@!                  @@! @@! @@!  "
    printf '%s\n' " !@!       !@!  @!@  !@!!@!@!    !@!    !@!  @!@  !@!  @!@  !@!                  !@! !@! !@!  "
    printf '%s\n' " !@!       @!@  !@!  @!@ !!@!    @!!    @!@!!@!   @!@  !@!  @!!       @!@!@!@!@  @!! !!@ @!@  "
    printf '%s\n' " !!!       !@!  !!!  !@!  !!!    !!!    !!@!@!    !@!  !!!  !!!       !!!@!@!!!  !@!   ! !@!  "
    printf '%s\n' " :!!       !!:  !!!  !!:  !!!    !!:    !!: :!!   !!:  !!!  !!:                  !!:     !!:  "
    printf '%s\n' " :!:       :!:  !:!  :!:  !:!    :!:    :!:  !:!  :!:  !:!   :!:                 :!:     :!:  "
    printf '%s\n' "  ::: :::  ::::: ::   ::   ::     ::    ::   :::  ::::: ::   :: ::::             :::     ::   "
    printf '%s\n' "  :: :: :   : :  :   ::    :      :      :   : :   : :  :   : :: : :              :      :    "
    printf '%s\n' ""
}

set -o errexit -o nounset -o pipefail
IFS=$'\n\t'

# Get current script folder
# shellcheck disable=SC2155 # this is intentional
readonly DIR_NAME=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# compute working dir
readonly WORKING_DIR="${DIR_NAME}/data"

# compute config dir
readonly CONFIG_DIR="${DIR_NAME}/config"
readonly SCRIPT_SETTINGS="${CONFIG_DIR}/setup.settings.ini"
readonly SCRIPT_DATA_FILE="${WORKING_DIR}/data.json"

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
SETUP_DIR="${DIR_NAME}"

# hostname is assumed to be a FQDN set during installation.
# shellcheck disable=SC2155 # this is intentional
readonly HOST_FQDN=$(cat /etc/hostname)
# shellcheck disable=SC2155 # this is intentional
readonly HOST_NAME=$(echo "${HOST_FQDN}" | awk -F "." '{print $1}')
# shellcheck disable=SC2155 # this is intentional
readonly DOMAIN_NAME=$(echo "${HOST_FQDN}" | awk -F "." '{print $2"."$3}')
# shellcheck disable=SC2155 # this is intentional
readonly HOST_IPV4=$(ip address | grep -v "127.0.0" | grep "inet " | awk '{print $2}' | awk -F "/" '{print $1}')

DATE_TODAY="$(date '+%Y-%m-%d %H:%M:%S')"
LOG_DATE=$(date +%Y%m%d)
LOG_DIR="${SETUP_DIR}/logs"
if [ ! -d "${LOG_DIR}" ]; then
    mkdir -p "${LOG_DIR}"
fi

# ctm extract data folder
readonly MPS_WORKING_DIR="${DIR_NAME}/metrcis/${LOG_DATE}"
if [ ! -d "${MPS_WORKING_DIR}" ]; then
    mkdir -p "${MPS_WORKING_DIR}"
fi

readonly MPS_LOG_DIR="${MPS_WORKING_DIR}/log"
if [ ! -d "${MPS_LOG_DIR}" ]; then
    mkdir -p "${MPS_LOG_DIR}"
fi

readonly MPS_LOG_NAME="mps"
readonly MPS_LOG_FILE="${MPS_LOG_DIR}/${MPS_LOG_NAME}.log"

if [[ ! -f "${MPS_LOG_FILE}" ]]; then
    touch "${MPS_LOG_FILE}"
fi

# shellcheck disable=SC2155 disable=SC2086 # this is intentional
readonly LOG_NAME=$(basename $0)
readonly LOG_FILE="${LOG_DIR}/${LOG_NAME}.${LOG_DATE}.txt"
if [[ ! -f "${LOG_FILE}" ]]; then
    echo ' .' | tee -a "${LOG_FILE}"
fi

readonly SCRIPT_NAME="${LOG_NAME}"
readonly SCRIPT_PURPOSE="extract mft data from postgresl"

for arg in "$@"; do
    shift
    # shellcheck disable=SC2250 # this is intentional
    case "$arg" in
    '--credentials') set -- "$@" '-c' ;;
    '--database') set -- "$@" '-d' ;;
    '--environment') set -- "$@" '-e' ;;
    '--past') set -- "$@" '-p' ;;
    '--server') set -- "$@" '-s' ;;
    '--start') set -- "$@" '-x' ;;
    '--end') set -- "$@" '-y' ;;
    '--help') set -- "$@" '-h' ;;

    *) set -- "$@" "$arg" ;;
    esac
done

# call script:
usage() {
    # shellcheck disable=SC2154 # this is intentional
    echo -e "${Purple}Example:${Color_Off} "
    # shellcheck disable=SC2154 disable=SC2086 # this is intentional
    echo -e "${Cyan}./$(basename $0)${Color_Off} ${Yellow}--credentials${Color_Off} ctmem:ctmPr3Zales ${Yellow} --environment${Color_Off} TryBMC${Yellow} --server${Color_Off} ctmcore.trybmc.local:5432${Yellow} --database${Color_Off} emdb${Yellow} --start${Color_Off} '2023-03-15 11:00:00'${Yellow} --end${Color_Off} '2023-03-15 12:00:00'"
    # shellcheck disable=SC2154 disable=SC2086 # this is intentional
    echo -e "${Cyan}./$(basename $0)${Color_Off} ${Yellow}--credentials${Color_Off} ctmem:ctmPr3Zales ${Yellow} --environment${Color_Off} TryBMC${Yellow} --server${Color_Off} ctmcore.trybmc.local:5432${Yellow} --database${Color_Off} emdb"
    # shellcheck disable=SC2154 disable=SC2086 # this is intentional
    echo -e "${Cyan}./$(basename $0)${Color_Off} ${Yellow}--credentials${Color_Off} ctmem:ctmPr3Zales ${Yellow} --environment${Color_Off} TryBMC${Yellow} --server${Color_Off} ctmcore.trybmc.local:5432${Yellow} --database${Color_Off} emdb${Yellow} --past${Color_Off} 1"
}

log() {
    echo " -----------------------------------------------" | tee -a "${LOG_FILE}"
    echo " Start date          : ${DATE_TODAY}" | tee -a "${LOG_FILE}"
    echo " User Name           : ${USER}" | tee -a "${LOG_FILE}"
    echo " Domain Name         : ${DOMAIN_NAME}" | tee -a "${LOG_FILE}"
    echo " Host FDQN           : ${HOST_FQDN}" | tee -a "${LOG_FILE}"
    echo " Host Name           : ${HOST_NAME}" | tee -a "${LOG_FILE}"
    echo " Host IPv4           : ${HOST_IPV4}" | tee -a "${LOG_FILE}"
    echo " CTM Working Dir     : ${MPS_WORKING_DIR}" | tee -a "${LOG_FILE}"
    echo " CTM Environment     : ${ENVIRONMENT}" | tee -a "${LOG_FILE}"
    echo " ---------------------" | tee -a "${LOG_FILE}"
    echo " CTM Database Name   : ${DATABASE_NAME}" | tee -a "${LOG_FILE}"
    echo " CTM Database Server : ${DATABASE_SERVER}" | tee -a "${LOG_FILE}"
    echo " CTM Database Port   : ${DATABASE_PORT}" | tee -a "${LOG_FILE}"
    echo " CTM Database User   : ${DATABASE_USER_NAME}" | tee -a "${LOG_FILE}"
    echo " CTM Database Pwd    : ********" | tee -a "${LOG_FILE}"
    echo " CTM DB Connection   : ${DATABASE_CONNECTION}" | tee -a "${LOG_FILE}"
    echo " ---------------------" | tee -a "${LOG_FILE}"
    echo " Current Date Time   : ${DATE_TODAY}" | tee -a "${LOG_FILE}"
    echo " DB Export Interval  : ${TIME_INTERVAL} Hours" | tee -a "${LOG_FILE}"
    echo " DB Export Start     : ${MFT_DATE_TIME_START}" | tee -a "${LOG_FILE}"
    echo " DB Export End       : ${MFT_DATE_TIME_END}" | tee -a "${LOG_FILE}"
    echo " ---------------------" | tee -a "${LOG_FILE}"
    echo " CTM MFT Entries     : ${PSQL_ROW_COUNT}" | tee -a "${LOG_FILE}"
    echo " CTM Data Export CSV : ${CSV_FILE_NAME}" | tee -a "${LOG_FILE}"
    echo "  " | tee -a "${LOG_FILE}"

}

# evaluate script options

DATABASE_CREDENTIALS=
DATABASE_NAME=
ENVIRONMENT=
DATABASE_PORT="5432"
DATABASE_SERVER=
DATE_TIME_START=
DATE_TIME_END=
TIME_INTERVAL=

while getopts ":c:d:e:p:s:x:y:h" OPTION; do
    # shellcheck disable=SC2250  disable=SC2236 # this is intentional
    case "$OPTION" in
    c)
        DATABASE_CREDENTIALS="$OPTARG"
        ;;
    d)
        DATABASE_NAME="$OPTARG"
        ;;
    e)
        ENVIRONMENT="$OPTARG"
        ;;
    p)
        TIME_INTERVAL="$OPTARG"
        ;;
    s)
        DATABASE_SERVER="$OPTARG"
        ;;
    x)
        DATE_TIME_START="$OPTARG"
        ;;
    y)
        DATE_TIME_END="$OPTARG"
        ;;
    ?)
        log
        usage
        exit 1
        ;;
    esac

done

shift "$((OPTIND - 1))"

# exit script if no ctm orderid provided
# shellcheck disable=SC2250  disable=SC2236 # this is intentional

if [ -z "$DATABASE_CREDENTIALS" ]; then
    usage
    exit 1
fi

# compute credentials for database login
# shellcheck disable=SC2155 # this is intentional
readonly DATABASE_USER_NAME=$(echo "${DATABASE_CREDENTIALS}" | awk -F ":" '{print $1}')
# shellcheck disable=SC2155 # this is intentional
readonly DATABASE_USER_PASSWORD=$(echo "${DATABASE_CREDENTIALS}" | awk -F ":" '{print $2}')

# compute databse server name and port
# shellcheck disable=SC2155 # this is intentional
readonly DATABASE_SERVER_NAME=$(echo "${DATABASE_SERVER}" | awk -F ":" '{print $1}')
# shellcheck disable=SC2155 # this is intentional
readonly DATABASE_SERVER_PORT=$(echo "${DATABASE_SERVER}" | awk -F ":" '{print $2}')

# compute export file names
readonly CSV_FILE_NAME="${MPS_WORKING_DIR}/mps.mft.entries.csv"

# assign default dates and times
# shellcheck disable=SC2250  disable=SC2236 # this is intentional
if [[ -z "$TIME_INTERVAL" ]]; then
    TIME_INTERVAL="1"
fi

DATE_TODAY="$(date +%s)"
# shellcheck disable=SC2004 # this is intentional
TIME_SEC="$((${TIME_INTERVAL} * 3600))"
# shellcheck disable=SC2004 # this is intentional
DATE_HOURS_AGO="$((${DATE_TODAY} - ${TIME_SEC}))"
DATE_TODAY="$(date -d "@${DATE_TODAY}" '+%Y-%m-%d %H:%M:%S')"
DATE_HOURS_AGO="$(date -d "@${DATE_HOURS_AGO}" '+%Y-%m-%d %H:%M:%S')"

# default for entry count
PSQL_ROW_COUNT="0"

# this is the date time now. if no date is specified use the current date
# shellcheck disable=SC2250  disable=SC2236 # this is intentional
if [[ ! -z "$DATE_TIME_END" ]]; then
    MFT_DATE_TIME_END="${DATE_TIME_END}"
else
    MFT_DATE_TIME_END="${DATE_TODAY}"
fi

# this is the date of the last collection, if no date is specified use the current date minus one hour
# shellcheck disable=SC2250  disable=SC2236 # this is intentional
if [[ ! -z "$DATE_TIME_START" ]]; then
    MFT_DATE_TIME_START="${DATE_TIME_START}"
else
    MFT_DATE_TIME_START="${DATE_HOURS_AGO}"
fi

function test_db_login() {
    local psql_output
    psql_output=$(PGPASSWORD="${DATABASE_USER_PASSWORD}" psql -h "${DATABASE_SERVER_NAME}" -p "${DATABASE_SERVER_PORT}" -d "${DATABASE_NAME}" -U "${DATABASE_USER_NAME}" -c "SELECT status FROM add_ons WHERE name = 'Control-M Managed File Transfer';" 2>&1)

    if [[ $? -eq 0 ]]; then
        if [[ "${psql_output}" == *"E"* ]]; then
            echo "true"
            return 0
        else
            echo "false"
            return 1
        fi
    else
        echo "false"
        return 1
    fi
}

function get_mft_column_names() {
    local column_names
    column_names=$(PGPASSWORD="${DATABASE_USER_PASSWORD}" psql -h "${DATABASE_SERVER_NAME}" -p "${DATABASE_SERVER_PORT}" -d "${DATABASE_NAME}" -U "${DATABASE_USER_NAME}" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'mft' ORDER BY column_name" 2>&1)

    if [[ "${column_names}" == *"ERROR:"* ]]; then
        echo "Error: ${column_names}" >&2
        return 1
    fi
    echo "${column_names}" | sed '1,3d' | tr '\n' ',' | sed 's/,$// ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

function select_from_mft() {
    local LOCAL_MFT_DATE_TIME_START="$1"
    local LOCAL_MFT_DATE_TIME_END="$2"
    local LOCAL_MFT_TABLE_COLUMNS="$3"

    local TEMP_RESULT
    local PSQL_OUTPUT
    local PSQL_ROW_COUNT="0"

    # don't add headers to the csv file, if we already created it
    if [[ ! -f "${CSV_FILE_NAME}" ]]; then
        TEMP_RESULT=$(echo "${LOCAL_MFT_TABLE_COLUMNS}" | tee "${CSV_FILE_NAME}")
    fi

    PSQL_CMD="psql -h '${DATABASE_SERVER_NAME}' -p '${DATABASE_SERVER_PORT}' -d '${DATABASE_NAME}' -U '${DATABASE_USER_NAME}' -t -A -F',' -c \"SELECT ${LOCAL_MFT_TABLE_COLUMNS} FROM mft WHERE end_time_update BETWEEN '${LOCAL_MFT_DATE_TIME_START}' AND '${LOCAL_MFT_DATE_TIME_END}';\""

    # log psql statements for debugging
    TEMP_RESULT=$(echo " -----------------------------------------------" | tee -a "${MPS_LOG_FILE}")
    TEMP_RESULT=$(echo " - DB PSQL Cmd          : ${PSQL_CMD}" | tee -a "${MPS_LOG_FILE}")
    TEMP_RESULT=$(echo " - DB Export Start      : ${MFT_DATE_TIME_START}" | tee -a "${MPS_LOG_FILE}")
    TEMP_RESULT=$(echo " - DB Export End        : ${MFT_DATE_TIME_END}" | tee -a "${MPS_LOG_FILE}")

    PSQL_OUTPUT=$(PGPASSWORD="${DATABASE_USER_PASSWORD}" psql -h "${DATABASE_SERVER_NAME}" -p "${DATABASE_SERVER_PORT}" -d "${DATABASE_NAME}" -U "${DATABASE_USER_NAME}" -t -A -F";" -c "SELECT ${LOCAL_MFT_TABLE_COLUMNS} FROM mft WHERE end_time_update BETWEEN '${LOCAL_MFT_DATE_TIME_START}' AND '${LOCAL_MFT_DATE_TIME_END}';")

    # Count the number of rows in PSQL_OUTPUT
    # shellcheck disable=SC2250  disable=SC2236 # this is intentional
    if [[ ! -z "$PSQL_OUTPUT" ]]; then
        PSQL_ROW_COUNT=$(echo "${PSQL_OUTPUT}" | grep -c ";")
    fi
    TEMP_RESULT=$(echo " - DB Export Row Count  : ${PSQL_ROW_COUNT}" | tee -a "${MPS_LOG_FILE}")

    if [ "${PSQL_ROW_COUNT}" -gt 0 ]; then

        # some fields have "," within them
        # Replace commas with pound signs
        PSQL_OUTPUT="${PSQL_OUTPUT//,/\#}"

        # Replace semicolons with commas
        PSQL_OUTPUT="${PSQL_OUTPUT//;/,}"

        # Write to CSV file
        TEMP_RESULT=$(echo "${PSQL_OUTPUT}" | tee -a "${CSV_FILE_NAME}")

        # log psql statements for debugging
        TEMP_RESULT=$(echo " - DB Export Headers CSV: ${LOCAL_MFT_TABLE_COLUMNS}" | tee -a "${MPS_LOG_FILE}")
        TEMP_RESULT=$(echo " - DB Export Data:" | tee -a "${MPS_LOG_FILE}")
        # shellcheck disable=SC2034 # this is intentional
        TEMP_RESULT=$(echo "${PSQL_OUTPUT}" | tee -a "${MPS_LOG_FILE}")
    fi

}

DATABASE_CONNECTION_STATUS=$(test_db_login)

# extract mft data from database
if [[ ${DATABASE_CONNECTION_STATUS} == "true" ]]; then
    # The login was successful
    DATABASE_CONNECTION="true"
    MFT_COLUMNS=$(get_mft_column_names)
    select_from_mft "${MFT_DATE_TIME_START}" "${MFT_DATE_TIME_END}" "${MFT_COLUMNS}"

else
    DATABASE_CONNECTION="false"
fi

log
