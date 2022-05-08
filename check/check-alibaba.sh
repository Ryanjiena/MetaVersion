#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
tmpFile="./action.tmp"
userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5028.0 Safari/537.36"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

# https://gist.github.com/pkuczynski/8665367
function parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function checkAdrive() {

    # @SpecterShell https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues/150#issue-1045542166
    local versionUrl="https://www.aliyundrive.com/desktop/version/update.json"
    local userAgent="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) 阿里云盘/2.2.9 Chrome/89.0.4389.128 Electron/12.0.9 Safari/537.36"
    local info=$(curl -s -A "$userAgent" "$versionUrl" | jq -r '.url')

    local yamlUrl="${info}/win32/ia32/latest.yml"

    local response="$(curl -s -A "$userAgent" "$yamlUrl")"
    local version="$(echo "${response}" | grep -Po "version:.*" | grep -Po "[\d.]+")"

    # echo -e "${Green_font_prefix}aDrive${Font_color_suffix} -> ${version}"

    local url="$(echo "${response}" | grep -Po "url:.*" | grep -Po "http.*" | sed -e 's/[\/&]/\\&/g')"
    local base64="$(echo "${response}" | grep -Po "[\s]+sha512:.*" | grep -Po "([a-zA-Z0-9+\/=]{24,88})")"
    # SHA512 HMAC -> SHA512
    local hashArr=($(echo "${base64}" | base64 -d | xxd -p))
    local hash=$(echo "${hashArr[*]}" | sed 's/ //g')

    sed -e "s|adrive-version|${version}|g" \
        -e "s|adrive-url|${url}|g" \
        -e "s|adrive-hash|${hash}|g" \
        -i \
        alibaba.json
}

function checkAlipayDevelopmentAssistant() {
    local response="$(curl -ksS 'https://ideservice.alipay.com/ide/api/pluginVersion.json?platform=win&clientType=assistant' \
        -H 'Referer: https://openhome.alipay.com' \
        -H 'User-Agent: ${userAgent}' \
        -X GET)"
    local releaseInfoArr=($(echo "${response}" | jq -r ".baseResponse.data.versionName, .baseResponse.data.downloadUrl"))
    sed -e "s|alipaydevelopmentassistant-version|${releaseInfoArr[0]}|g" \
        -e "s|alipaydevelopmentassistant-url|${releaseInfoArr[1]}|g" \
        -i \
        alibaba.json
}

function checkDingTalk() {
    local response="$(curl -ksS 'https://im.dingtalk.com/manifest/new/website/vista_later.json' \
        -H 'User-Agent: ${userAgent}' \
        -X GET)"
    local releaseInfoArr=($(echo "${response}" | jq -r ".win.install.version, .win.install.url, .win.install.md5"))
    sed -e "s|dingtalk-version|${releaseInfoArr[0]}|g" \
        -e "s|dingtalk-url|${releaseInfoArr[1]}|g" \
        -e "s|dingtalk-hash|${releaseInfoArr[2]}|g" \
        -i \
        alibaba.json
}

function checkTeambition() {
    local response="$(curl -ksS 'https://im.dingtalk.com/manifest/dtron/Teambition/win32/ia32/latest.yml' \
        -H 'User-Agent: ${userAgent}' \
        -X GET)"

    # eval $(parse_yaml "${tmpFile}" "config_")
    # local url="$config_path"
    # local version="$config_version"
    # local hash="$config_sha512"

    local version="$(echo "${response}" | grep -Po "version:.*" | grep -Po "[\d.]+")"
    # echo -e "${Green_font_prefix}Teambition${Font_color_suffix} -> ${version}"

    local url="$(echo "${response}" | grep -Po "url:.*" | grep -Po "http.*" | sed -e 's/[\/&]/\\&/g')"
    local base64="$(echo "${response}" | grep -Po "[\s]+sha512:.*" | grep -Po "([a-zA-Z0-9+\/=]{24,88})")"
    # SHA512 HMAC -> SHA512
    local hashArr=($(echo "${base64}" | base64 -d | xxd -p))
    local hash=$(echo "${hashArr[*]}" | sed 's/ //g')
    sed -e "s|teambition-version|${version}|g" \
        -e "s|teambition-url|${url}|g" \
        -e "s|teambition-hash|${hash}|g" \
        -i \
        alibaba.json
}

function checkYuque() {
    local response="$(curl -ksS 'https://app.nlark.com/yuque-desktop/v2/latest-lark.json' \
        -H 'User-Agent: ${userAgent}' \
        -X GET)"
    local stableReleaseInfoArr=($(echo "${response}" | jq ".stable | .[] | select(.platform==\"win32\")" | jq -r ".version,.exe_url"))
    local insidersReleaseInfoArr=($(echo "${response}" | jq ".insiders | .[] | select(.platform==\"win32\")" | jq -r ".version,.exe_url"))
    sed -e "s|yuque-stable-version|${stableReleaseInfoArr[0]}|g" \
        -e "s|yuque-stable-url|${stableReleaseInfoArr[1]}|g" \
        -e "s|yuque-insiders-version|${insidersReleaseInfoArr[0]}|g" \
        -e "s|yuque-insiders-url|${insidersReleaseInfoArr[1]}|g" \
        -i \
        alibaba.json
}

cp alibaba.src.json alibaba.json
sed -e "s|check-Time|${DATE}|g" -i alibaba.json
checkAdrive
checkAlipayDevelopmentAssistant
checkDingTalk
checkTeambition
checkYuque
mv alibaba.json ../alibaba.json
