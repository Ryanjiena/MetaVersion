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

function getLatestVersion() {
    local userAgent="MouseInc/2.11.6"
    local versionUrl="https://update.shuax.com/MouseInc/update.json"
    curl -s -A "$userAgent" "$versionUrl" | jq -r ".version"
    return $?
}

function getLocalVersion() {
    # local userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"
    # local versionUrl="https://raw.githubusercontent.com/JaimeZeng/scoop-apps-version/main/MouseInc"
    # curl -s -A "$userAgent" "$versionUrl" | grep -o 'Version=.*$' | sed 's/Version=//g'
    # curl -s -A "$userAgent" "$versionUrl" | jq -r ".version"
    cat ../mouseinc | jq -r ".version"
    return $?
}

function getGeneratedVersionInfo() {

    local userAgent="MouseInc/2.11.6"
    local versionUrl="https://update.shuax.com/MouseInc/update.json"

    # # https://stackoverflow.com/questions/1251999/how-can-i-replace-a-newline-n-using-sed/1252191#1252191
    # echo "${request}" | sed ':a;N;$!ba;s/\n//g' >${tmpFile}
    # releaseVersion=($(echo "${request}" | grep -o '"version": ".*"' | head -n 1 | sed 's/"//g;s/version:.//g'))
    # echo "Version=${releaseVersion}" >${tmpFile}
    # wget "https://update.shuax.com/MouseInc${releaseVersion}.7z"
    # sha256sum MouseInc${releaseVersion}.7z >>${tmpFile}

    info=($(curl -s -A "$userAgent" "$versionUrl" | jq -r ".version, .url, .hash"))
    descriptionArr=($(curl -s -A "$userAgent" "$versionUrl" | jq -r ".description"))
    description=$(echo "${descriptionArr[*]}" | sed 's/ /- /g')
    url=$(echo ${info[1]} | sed -e 's/[]&\/$*.^[]/\\&/g')

    cp mouseinc.src.json mouseinc.json
    sed -e "s|Check-Time|${DATE}|g" \
        -e "s|MouseInc-Version|${info[0]}|g" \
        -e "s|MouseInc-Description|${description}|g" \
        -e "s|MouseInc-Url|${url}|g" \
        -e "s|MouseInc-Hash|${info[2]}|g" \
        -i \
        mouseinc.json
    # do not prompt before overwriting
    mv -f mouseinc.json ../mouseinc
}

function compareVersion() {
    latestVersion=($(getLatestVersion))
    localVersion=($(getLocalVersion))
    echo "Latest version:  ${latestVersion}"
    echo "Local version:  ${localVersion}"

    # Compare Version
    if [[ "${latestVersion}" == "${localVersion}" ]]; then
        echo -e "${Green_font_prefix}[Info] MouseInc is the latest version!${Font_color_suffix}"
    else
        echo -e "${Green_font_prefix}[Info] Update MouseInc!${Font_color_suffix}"
        getGeneratedVersionInfo
    fi

}

# sudo apt install curl jq xxd -y
compareVersion
