#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
TMP_DIR="${TMP_DIR:-$(mktemp -d /tmp/check.XXXXXX)}"
LOG_FILE="${LOG_FILE:-${TMP_DIR}/build.log}"
userAgent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5028.0 Safari/537.36'

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

function check() {
    local versionurl="https://api.github.com/repos/be5invis/Sarasa-Gothic/releases?per_page=1"
    local latestversion=$(curl -sSL -H "User-Agent: ${userAgent}" ${versionurl} | grep -Po '"tag_name": "\K.*?(?=")' | head -1 | sed 's/v//')
    local localinfo=($(cat ../program.json | jq -r ".sarasa.name, .sarasa.version, .sarasa.ttc, .sarasa.ttf"))
    if [[ "${latestversion}" != "${localinfo[1]}" ]]; then
        local ttcurl="https://github.com/be5invis/Sarasa-Gothic/releases/download/v${latestversion}/sarasa-gothic-ttc-${latestversion}.7z"
        local ttfurl="https://github.com/be5invis/Sarasa-Gothic/releases/download/v${latestversion}/sarasa-gothic-ttf-${latestversion}.7z"
        local ttchash=$(curl -sSL -H "User-Agent: ${userAgent}" ${ttcurl} | sha256sum | awk '{print $1}')
        local ttfhash=$(curl -sSL -H "User-Agent: ${userAgent}" ${ttfurl} | sha256sum | awk '{print $1}')

        sed -e "s|${localinfo[1]}|${latestversion}|g" -e "s|${localinfo[2]}|${ttchash}|g" -e "s|${localinfo[3]}|${ttfhash}|g" -i ../program.json
    fi

}

check
