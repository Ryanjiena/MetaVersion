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

office_iso_zh_cn_ver="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://download.coolhub.top/Office_ISO/en-US/Current/" | grep -Po ">Office_Tool_Plus.*_x64_en-us.iso</a>" | grep -Po "[\d.]+" | head -n 1)"
office_iso_zh_tw_ver="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://download.coolhub.top/Office_ISO/zh-CN/Current/" | grep -Po ">Office_Tool_Plus.*_x64_zh-cn.iso</a>" | grep -Po "[\d.]+" | head -n 1)"
office_iso_en_us_ver="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://download.coolhub.top/Office_ISO/zh-TW/Current/" | grep -Po ">Office_Tool_Plus.*_x64_zh-tw.iso</a>" | grep -Po "[\d.]+" | head -n 1)"

latestVersionArr=("${office_iso_zh_cn_ver}" "${office_iso_zh_tw_ver}" "${office_iso_en_us_ver}")
localVersionArr=($(cat ../office-iso | grep -Po "[\d.]+"))
echo "Latest version:  ${latestVersionArr[*]}"
echo "Local version:  ${localVersionArr[*]}"

# Compare Version
if [[ "${latestVersionArr[0]}" == "${localVersionArr[0]}" ]] && [[ "${latestVersionArr[1]}" == "${localVersionArr[1]}" ]] && [[ "${latestVersionArr[2]}" == "${localVersionArr[2]}" ]]; then
    echo -e "${Green_font_prefix}[Info] Office_ISO is the latest version!${Font_color_suffix}"
else
    echo -e "${Green_font_prefix}[Info] Update Office_ISO!${Font_color_suffix}"
    title="Office Tool Plus Offline Installer\n\n"
    content="zh_CN version = ${office_iso_zh_cn_ver}\nzh_TW version = ${office_iso_zh_tw_ver}\nen_US version = ${office_iso_en_us_ver}"
    echo -e "${title}${content}" >Office_ISO
    mv -f Office_ISO ../office-iso
fi
