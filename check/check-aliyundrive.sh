#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
tmpFile="./action.tmp"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

function getLatestYmlVersion() {
    # @SpecterShell https://github.com/vedantmgoyal2009/winget-pkgs-automation/issues/150#issue-1045542166
    local versionUrl="https://www.aliyundrive.com/desktop/version/update.json"
    userAgent="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) 阿里云盘/2.2.9 Chrome/89.0.4389.128 Electron/12.0.9 Safari/537.36"
    curl -s -A "$userAgent" "$versionUrl" | grep -Po 'version/[\d.]+"' | grep -Po '[\d.]+'
    return $?
}

function getGeneratedVersionInfo() {

    local ymlVersion="$(getLatestYmlVersion)"
    local userAgent="electron-builder"
    local versionUrl="https://g.alicdn.com/aliyun-drive-fe/aliyun-drive-desktop-version/$ymlVersion/win32/ia32/latest.yml"

    info="$(curl -s -A "$userAgent" "$versionUrl")"
    latestVersion="$(echo "$info" | grep -Po "version:.*" | grep -Po "[\d.]+")"
    localVersion="$(cat ../aliyundrive | jq -r ".version")"
    echo "Latest version:  ${latestVersion}"
    echo "Local version:  ${localVersion}"

    # Compare Version
    if [[ "${latestVersion}" == "${localVersion}" ]]; then
        echo -e "${Green_font_prefix}[Info] aliyundrive is the latest version!${Font_color_suffix}"
    else
        echo -e "${Green_font_prefix}[Info] Update aliyundrive!${Font_color_suffix}"

        url="$(echo "$info" | grep -Po "url:.*" | grep -Po "http.*" | sed -e 's/[]&\/$*.^[]/\\&/g')"
        size="$(echo "$info" | grep -Po "size:.*" | grep -Po "[\d]+")"
        releaseDate="$(echo "$info" | grep -Po "releaseDate:.*" | grep -Po "20.*Z")"
        base64="$(echo "$info" | grep -Po "[\s]+sha512:.*" | grep -Po "([a-zA-Z0-9+\/=]{24,88})" | sed -e 's/\//\\&/g')"

        # SHA512 HMAC -> SHA512
        sha512Arr=($(echo "$info" | grep -Po "[\s]+sha512:.*" | grep -Po "([a-zA-Z0-9+\/=]{24,88})" | base64 -d | xxd -p))
        sha512=$(echo "${sha512Arr[*]}" | sed 's/ //g')

        # https://stackoverflow.com/a/2686369/17233489
        # oldDestination="$(sed -e '/aliyundrive/,/destination/!d' | grep -o 'http.*exe')"
        # oldDestination="$(sed -n '/aliyundrive/,/destination/p' | grep -o 'http.*exe')"
        # sed -e "s|${oldDestination}|${url}|g" -i now.json

        cp aliyundrive.src.json aliyundrive.json
        sed -e "s|aliyundrive-checkTime|${DATE}|g" \
            -e "s|aliyundrive-version|${latestVersion}|g" \
            -e "s|aliyundrive-url|${url}|g" \
            -e "s|aliyundrive-base64|${base64}|g" \
            -e "s|aliyundrive-sha512|${sha512}|g" \
            -e "s|aliyundrive-size|${size}|g" \
            -e "s|aliyundrive-releaseDate|${releaseDate}|g" \
            -i \
            aliyundrive.json
        # do not prompt before overwriting
        mv -f aliyundrive.json ../aliyundrive
        echo "$info" >aliyundrive-latest.yml
        mv -f aliyundrive-latest.yml ../aliyundrive-latest.yml
    fi
}

# sudo apt install curl jq xxd -y
getGeneratedVersionInfo
