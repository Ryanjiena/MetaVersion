#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
tmpFile="./action.tmp"
userAgent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36'

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

idm_lrepacks_name="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://onedrive.xiazai.de/IDM/IDM-lrepacks%E7%A0%B4%E8%A7%A3%E7%89%88/" | grep -Po "internet.*.zip" | tail -n 1)"
idm_lrepacks_ver="$(echo "${idm_lrepacks_name}" | grep -Po "[\d.]+\d")"

latestVersion="${idm_lrepacks_ver}"
localVersion=($(cat ../idm | jq -r ".version"))
echo "Latest version: ${latestVersion}"
echo "Local version: ${localVersion}"

# Compare Version
if [[ "${latestVersion}" == "${localVersion}" ]]; then
    echo -e "${Green_font_prefix}[Info] IDM is the latest version!${Font_color_suffix}"
else
    echo -e "${Green_font_prefix}[Info] Update IDM!${Font_color_suffix}"
    wget --user-agent="${userAgent}" --no-check-certificate -q "https://onedrive.xiazai.de/IDM/IDM-lrepacks%E7%A0%B4%E8%A7%A3%E7%89%88/${idm_lrepacks_name}"
    hash="$(sha256sum ${idm_lrepacks_name} | awk '{print $1}')"
    echo -e "{\"time\": \"${DATE}\",\"version\": \"${idm_lrepacks_ver}\",\"name\": \"${idm_lrepacks_name}\",\"hash\": \"${hash}\"}" | jq >../idm
    rm -f *.zip
fi
