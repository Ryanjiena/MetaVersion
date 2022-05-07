#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
USER="$(whoami)"
tmpFile="./action.tmp"
userAgent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.4987.0 Safari/537.36'

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

nameArr=($(cat ../header.json | jq -r '.[] | .name'))
urlArr=($(cat ../header.json | jq -r '.[] | .url'))
redirectArr=($(cat ../header.json | jq -r '.[] | .redirect'))

for ((i = 0; i < ${#nameArr[@]}; i++)); do

    curl -v -k --tls-max 1.2 "${urlArr[i]}" 2>${tmpFile} >/dev/null
    # cat ${tmpFile} && exit 0

    redirect_url=$(cat ${tmpFile} | grep -Poi 'location: .*?\.exe' | sed 's/location: //gi')
    # echo ${result} && exit 0

    if [[ -n "${redirect_url}" ]]; then
        echo -e "${Green_font_prefix}${nameArr[i]}${Font_color_suffix} -> ${redirect_url}"
        sed -e "s|${redirectArr[i]}|${redirect_url}|g" -i ../header.json
    else
        echo -e "${Error} ${nameArr[i]} is not exist!" && exit 1
    fi

    rm -f ${tmpFile}
done
