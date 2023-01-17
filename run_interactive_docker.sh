#!/usr/bin/env bash

# INTEL CONFIDENTIAL

# Copyright 2021 Intel Corporation.

# This software and the related documents are Intel copyrighted materials, and
# your use of them is governed by the express license under which they were
# provided to you ("License"). Unless the License provides otherwise, you may
# not use, modify, copy, publish, distribute, disclose or transmit this
# software or the related documents without Intel's prior written permission.

# This software and the related documents are provided as is, with no express
# or implied warranties, other than those that are expressly stated in the
# License.
set -E -o pipefail
shopt -s extdebug
IFS=$'\n\t'

usage()
{
    printf "\nusage:\n
Interactive-Mode:
    %s <docker_image:tag> <user> [-c|--container_name <container_name>] [-e|--extra_params <extra_params_to_docker_run_cmd>]
Non-Interactive-Mode:
    ${0} <docker_image:tag> <user> [-s|--script_to_run <script_to_run>] [-c|--container_name <container_name>] [-e|--extra_params <extra_params_to_docker_run_cmd>]

user:
    eiforamr =  default user pre-defined inside docker images - sudo access: without passord is already enabled.
    root     =  by default all commands should work as root.
    local    =  current user is forwarded to docker. sudo access: if given by sys-admin.
                To avoid password need for sudo commands: /etc/sudoers file should have below entry:
                   <local-user>        ALL=(ALL) NOPASSWD:ALL
script_to_run:  the script to run inside the container (default: interactive bash prompt)
                If user provides script, it will run in non-interactive mode, i.e. container will exit after running script.
container_name: the name of the container (default: amr_sdk_docker)
extra_params:   User can provide extra parameters to docker run cmd. Example: \"--volume \mnt\sdb:\mnt\sdb\ --volume abc:xyz:ro\" etc \n\n" "${0}"
    exit 1
}
[[ -z "$DISPLAY" ]] && { echo $'\n\n\n\n!!!!!!!!ERROR\n There are AMR-SDK use-cases in which GUI apps are launched.\n For those apps, DISPLAY should be set properly beforehand.\n If it is not set, GUI apps will not launch inside container. \n If your use-case does not need GUI apps, then please run command export DISPLAY=0:0 to set a dummy value\n and then please run the script again.\n\n Exiting!!!!!!!!!!!!!!\n\n\n\n\n'; exit 1; }
if [[ ! "${IMAGE_WITH_TAG:=${1}}" || ! "${DKR_USER:=${2}}" ]]; then
    usage
fi

shift; shift
while [ $# -gt 0 ]; do
    case $1 in
        -c|--container_name)
            CONTAINER_NAME="${2}"
            shift; shift
        ;;
        -s|--script_to_run)
            SCRIPT_TO_RUN="${2}"
            MODE=non-interactive
            shift; shift
        ;;
        -e|--extra_params)
            EXTRA_PARAMS="${2}"
            shift; shift
        ;;
        *)
            echo -e "\nERROR: parameter not allowed: ${1}.\n"
            usage
        ;;
    esac
done

if [ "${DKR_USER}" == "root" ] || [ "${DKR_USER}" == "eiforamr" ] || [ "${DKR_USER}" == "local" ]; then 
    TEMPLATE="$(dirname "${0}")/templates/docker_run_as_${DKR_USER}_user.sh"
else
    echo -e "\nERROR: Allowed values for 2nd parameter: root, eiforamr, local.\n"
    usage
fi


xhost +local:docker
# remove old running container with same name
# shellcheck disable=SC2030,SC2031
cmd="docker rm -f $(docker ps -aq --filter name="${CONTAINER_NAME:=amr_sdk_docker}") 2>/dev/null"
eval "${cmd}" || true

# shellcheck disable=SC1091,SC1090,SC2031
source "${TEMPLATE}" "${CONTAINER_NAME:=amr_sdk_docker}" "${MODE:=interactive}" "${EXTRA_PARAMS}"
DOCKER_BASE_CMD="${DOCKER_BASE_CMD:?ERROR: variable 'DOCKER_BASE_CMD' must be set.}"
DOCKER_RUN_CMD=("${DOCKER_BASE_CMD[@]}" "${IMAGE_WITH_TAG}" "${SCRIPT_TO_RUN:=bash}")
echo -e "\n!!!Executing docker run command!!!\n\n"
"${DOCKER_RUN_CMD[@]}"
