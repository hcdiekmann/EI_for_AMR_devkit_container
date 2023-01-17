#!/usr/bin/env bash
# INTEL CONFIDENTIAL

# Copyright 2022 Intel Corporation.

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

DEFAULT_GIT_MIRROR='https://github.com.cnpmjs.org'
DEFAULT_RAWFILE_MIRROR='https://raw.staticdn.net'
DEFAULT_APT_MIRROR='http://mirrors.bfsu.edu.cn'
DEFAULT_PIP_MIRROR='https://opentuna.cn/pypi/web/simple/'

usage() {
    echo "Usage: $0 -d <docker_sdk_dir>

This script will tweak the dockerfiles in order to build the
docker images on the People's Republic of China (PRC) network.
It will replace the download links for Git, Apt, Pip with mirrors
available in PRC.

These changes can be applied once, you will have reinstall the
EI for AMR package before applying them again.

  -d  directory containg the Docker SDK build env
  -h  display this help and exit

Eg: $0 -d 01_docker_sdk_env"
}

opt_searchdir=
opt_gitmirror=
opt_rawfilemirror=
opt_aptmirror=
opt_pipmirror=
while getopts "hd:" opt; do
    case "$opt" in
        d)
            opt_searchdir="${OPTARG}"
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            echo "Inavlid option ${opt}"
            usage
            exit 1
    esac
done
shift $((OPTIND-1))
if [ -z "${opt_searchdir}" ] || [ ! -d "${opt_searchdir}" ]; then
    usage
    exit 1
fi

echo -e "Enter mirror server ('https://example.com' format) or leave empty to use the default value.\n"
read -rp "Git mirror [${DEFAULT_GIT_MIRROR}]: " opt_gitmirror
read -rp "Apt mirror [${DEFAULT_APT_MIRROR}]: " opt_aptmirror
read -rp "Pip mirror [${DEFAULT_PIP_MIRROR}]: " opt_pipmirror
read -rp "Raw files mirror [${DEFAULT_RAWFILE_MIRROR}]: " opt_rawfilemirror
[[ -z "${opt_gitmirror}" ]] && opt_gitmirror="${DEFAULT_GIT_MIRROR}"
[[ -z "${opt_rawfilemirror}" ]] && opt_rawfilemirror="${DEFAULT_RAWFILE_MIRROR}"
[[ -z "${opt_aptmirror}" ]] && opt_aptmirror="${DEFAULT_APT_MIRROR}"
[[ -z "${opt_pipmirror}" ]] && opt_pipmirror="${DEFAULT_PIP_MIRROR}"

echo
echo "Folder to scan: ${opt_searchdir}"
echo "Using Git mirror: ${opt_gitmirror}"
echo "Using Apt mirror: ${opt_aptmirror}"
echo "Using Pip mirror: ${opt_pipmirror}"
echo "Using raw files mirror: ${opt_rawfilemirror}"
echo

set -x

find "${opt_searchdir}" -type f -name 'dockerfile.stage.opencv' -print0 | xargs -0 sed -i "s|https://github.com/opencv/opencv|https://github.com.cnpmjs.org/opencv/opencv|g"

find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i  -r 's/wget\s*([-h$])/wget --tries=5 \1/g'
find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i  -r 's/curl\s*([-h$])/curl --retry 5 \1/g'

find "${opt_searchdir}" -type f -name 'dockerfile.stage.openvino.post' -print0 | xargs -0 sed -i 's/^RUN curl.*INTEL_COMPUTE_RUNTIME_VERSION.*\.deb.*$/RUN : \\/g'
find "${opt_searchdir}" -type f -name 'dockerfile.stage.openvino.post' -print0 | xargs -0 sed -i '/curl.*INTEL_COMPUTE_RUNTIME_VERSION.*\.deb/d'
find "${opt_searchdir}" -type f -name 'dockerfile.stage.openvino.post' -print0 | xargs -0 sed -i "/dpkg -i \${TEMP_DIR}\/\*\.deb/d"

find "${opt_searchdir}" -type f -print0 | xargs -0 sed -i -r '/rosdep (init|update)/d'

find "${opt_searchdir}" -type f -print0 | xargs -0 sed -i "s|pip3 install|pip3 install -i ${opt_pipmirror}|g"
find "${opt_searchdir}" -type f -print0 | xargs -0 sed -i "s|pip install|pip install -i ${opt_pipmirror}|g"
find "${opt_searchdir}" -type f -path '*/openvino/requirements_tf.txt' -print0 | xargs -0 sed -i -r "s|^([^#]+)$|-i ${opt_pipmirror} \1|g"
find "${opt_searchdir}" -type f -name 'dockerfile.stage.kobuki' -print0 | xargs -0 sed -i "s#source ./venv.bash#sed -i '/-i/\!s|^pip3 install|pip3 install -i ${opt_pipmirror} |g' venv.bash \&\& source ./venv.bash#g"

find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i -r "s#apt-get update#sed -r 's|http[s]?://(archive\\\|security)\.ubuntu\.com|${opt_aptmirror}|g' -i /etc/apt/sources.list \&\& apt-get update#g"
find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i "s|apt-get install|apt-get install -o=Acquire::Retries=3|g"

find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i "s|https://github.com/|${opt_gitmirror}/|g"
find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i "s|https://raw.githubusercontent.com|${opt_rawfilemirror}/|g"

find "${opt_searchdir}" -type f -name 'dockerfile\.*' -print0 | xargs -0 sed -i "s|git clone|git config --global url.\"${opt_gitmirror}/\".insteadof \"https://github.com/\" \&\& git clone|g"
