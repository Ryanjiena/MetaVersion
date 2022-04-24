#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

userAgent="Microsoft Edge Update/1.3.139.59;winhttp"
DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

function getGeneratedInfo() {

    osArr=("win" "mac")
    archArr=("x64" "x86")
    productArr=("stable" "beta" "dev" "canary")
    macApArr=("" "betachannel" "devchannel" "")
    ap86Arr=("-multi-chrome" "1.1-beta" "2.0-dev" "")
    ap64Arr=("x64-stable-multi-chrome" "x64-beta-multi-chrome" "x64-dev-multi-chrome" "x64-canary")
    macAppidArr=("com.google.Chrome" "com.google.Chrome" "com.google.Chrome" "com.google.Chrome.Canary")
    winAppidArr=("{8A69D345-D564-463C-AFF1-A69D9E530F96}" "{8A69D345-D564-463C-AFF1-A69D9E530F96}" "{8A69D345-D564-463C-AFF1-A69D9E530F96}" "{4EA16AC7-FD5A-47C3-875B-DBF4A2008C20}")
    # first run
    cp chrome.src.json chrome.json

    sed -e "s|check-time|${DATE}|g" -i chrome.json
    for ((i = 0; i < ${#productArr[@]}; i++)); do
        for os in ${osArr[@]}; do
            for arch in ${archArr[@]}; do
                if [[ "${os}" == "mac" ]] && [[ "${arch}" == "x86" ]]; then
                    continue
                elif [[ "${os}" == "mac" ]] && [[ "${arch}" == "x64" ]]; then
                    ap="${macApArr[i]}"
                    appid="${macAppidArr[i]}"
                    ver="46.0.2490.86"
                elif [[ "${os}" == "win" ]] && [[ "${arch}" == "x86" ]]; then
                    ap="${ap86Arr[i]}"
                    appid="${winAppidArr[i]}"
                    ver="6.3"
                elif [[ "${os}" == "win" ]] && [[ "${arch}" == "x64" ]]; then
                    ap="${ap64Arr[i]}"
                    appid="${winAppidArr[i]}"
                    ver="6.3"
                fi

                postUrl="https://tools.google.com/service/update2"
                postData="<?xml version='1.0' encoding='UTF-8'?>
<request protocol='3.0' version='1.3.23.9' shell_version='1.3.21.103' ismachine='0'
    sessionid='{3597644B-2952-4F92-AE55-D315F45F80A5}' installsource='ondemandcheckforupdate'
    requestid='{CD7523AD-A40D-49F4-AEEF-8C114B804658}' dedup='cr'>
<hw sse='1' sse2='1' sse3='1' ssse3='1' sse41='1' sse42='1' avx='1' physmemory='12582912' />
<os platform='${os}' version='${ver}' arch='${arch}'/>
<app appid='${appid}' ap='${ap}' version='' nextversion='' lang='' brand='GGLS' client=''><updatecheck/></app>
</request>"
                request=$(curl -k -s -A "$userAgent" "${postUrl}" -X POST -d "${postData}")

                version=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/manifest/@version)" -)
                releaseName=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/manifest/actions/action[@event='install']/@run)" -)
                url0=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/urls/url[starts-with(@codebase,'https://redirector.gvt1.com')]/@codebase)" -)
                url1=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/urls/url[starts-with(@codebase,'https://dl.google.com')]/@codebase )" -)
                url2=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/urls/url[starts-with(@codebase,'https://www.google.com')]/@codebase )" -)
                url3=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/urls/url[starts-with(@codebase,'http://redirector.gvt1.com')]/@codebase)" -)
                url4=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/urls/url[starts-with(@codebase,'http://dl.google.com')]/@codebase )" -)
                url5=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/urls/url[starts-with(@codebase,'http://www.google.com')]/@codebase )" -)
                hash=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/manifest/packages/package/@hash_sha256)" -)
                size=$(echo "${request}" | xmllint --xpath "string(/response/app/updatecheck/manifest/packages/package/@size)" -)

                sed -e "s|chrome-${productArr[i]}-${os}-${arch}-ver|${version}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-releasename|${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-url0|${url0}${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-url1|${url1}${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-url2|${url2}${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-url3|${url3}${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-url4|${url4}${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-url5|${url5}${releaseName}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-hash|${hash}|g" \
                    -e "s|chrome-${productArr[i]}-${os}-${arch}-size|${size}|g" \
                    -i \
                    chrome.json
                sleep 6
            done
        done
    done
    mv -f chrome.json ../chrome
}

# sudo apt install curl libxml2-utils -y
echo -e "${Green_font_prefix}[Info] Update Chrome!${Font_color_suffix}"
getGeneratedInfo
