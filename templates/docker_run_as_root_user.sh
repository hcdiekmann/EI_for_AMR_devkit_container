#!/bin/bash

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

set -Eu -o pipefail
shopt -s extdebug
IFS=$'\n\t'
set -x

CONTAINER_NAME="${1:?ERROR: CONTAINER_NAME is expected as 1st parameter.}"
TYPE="${2:?ERROR:Allowed values for 2nd parameter: interactive or non-interactive.}"
PARAM=${3:-''}
IFS=' ' read -r -a EXTRA_PARAMS <<< "${PARAM}"

if [ "${TYPE}" == "interactive" ]; then
    SET_TYPE="true"
elif [ "${TYPE}" == "non-interactive" ]; then
    SET_TYPE="false"
else
    echo -e "ERROR: Allowed values for 2nd parameter: interactive or non-interactive."
    exit 1
fi

# shellcheck disable=SC2034
DOCKER_BASE_CMD=(docker run  "--interactive=${SET_TYPE}" -t --rm                    \
    --name "${CONTAINER_NAME}"                                                      \
    --hostname "$(hostname)"                                                        \
    --env "DISPLAY=$DISPLAY"                                                        \
    --env "QT_X11_NO_MITSHM=1"                                                      \
    --network "host"                                                                \
    --security-opt apparmor:unconfined                                              \
    --env "USER=root"                                                               \
    --user "root"                                                                   \
    --group-add "$(id --group)"                                                     \
    --volume /tmp/.X11-unix:/tmp/.X11-unix                                          \
    --volume /etc/group:/etc/group:ro                                               \
    --volume "${HOME}":/home/"$(whoami)":rw                                         \
    --volume "${HOME}"/.cache:/.cache:rw                                            \
    --volume /etc/ssh/:/etc/ssh/:ro                                                 \
    --volume /etc/ssl/certs/:/etc/ssl/certs/:rw                                     \
    --volume /usr/share/ca-certificates:/usr/share/ca-certificates:ro               \
    --volume /usr/local/share/ca-certificates:/usr/local/share/ca-certificates:ro   \
    --volume /dev:/dev:ro                                                           \
    --volume /lib/modules:/lib/modules:ro                                           \
    --volume /run/user:/run/user:ro                                                 \
    --volume /var/run/nscd/socket:/var/run/nscd/socket:ro                           \
    --volume /tmp:/tmp:rw                                                           \
    "${EXTRA_PARAMS[@]}"                                                            \
    --privileged)
