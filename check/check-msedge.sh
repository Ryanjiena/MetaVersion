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

function getLatestVersion() {
    local versionUrl="https://www.microsoftedgeinsider.com/api/versions"
    curl -s -A "$userAgent" "$versionUrl" | jq -r ".stable, .beta, .dev, .canary"
    return $?
}

function getLocalVersion() {
    # local versionUrl="https://raw.githubusercontent.com/JaimeZeng/scoop-apps-version/main/msedge"
    # curl -s -A "$userAgent" "$versionUrl" | jq -r '.[].Version'
    cat ../msedge | jq -r '.[].Version'
    return $?
}

function getGeneratedVersionInfo() {

    archArr=("X64" "X86" "ARM64")
    productArr=("stable" "beta" "dev" "canary")
    versionArr=($(getLatestVersion ".stable" ".beta" ".dev" ".canary"))
    # first run
    cp msedge.src.json msedge.json
    cp link.src.json link.json
    sed -e "s|check-time|${DATE}|g" -i msedge.json
    for ((i = 0; i < ${#productArr[@]}; i++)); do
        sed -e "s|msedge-${productArr[i]}-win-ver|${versionArr[i]}|g" -i msedge.json
        for arch in ${archArr[@]}; do
            edgeUrl="https://msedge.api.cdp.microsoft.com/api/v1.1/internal/contents/Browser/namespaces/Default/names/msedge-${productArr[i]}-win-$arch/versions/${versionArr[i]}/files?action=GenerateDownloadInfo&foregroundPriority=true"
            fileName="MicrosoftEdge_${arch}_${versionArr[i]}.exe"
            request=$(curl -k -s -A "${userAgent}" "${edgeUrl}" -X POST -d "{\"targetingAttributes\":{}}" | jq --arg NAME ${fileName} '.[] | select(.FileId==$NAME)' | jq 'del(.Hashes.Sha1, .DeliveryOptimization)')

            releaseInfo=($(echo "$request" | jq '.Hashes = .Hashes.Sha256'))
            releaseInfoFileId=$(echo "$request" | jq -r '.FileId')
            # & is special in the replacement text: it means “the whole part of the input that was matched by the pattern”
            # https://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern/2705678#2705678
            # https://unix.stackexchange.com/questions/296705/using-sed-with-ampersand/296732#296732
            releaseInfoUrl=$(echo "$request" | jq -r '.Url' | sed -e 's/[]&\/$*.^[]/\\&/g')
            # SHA256 HMAC -> SHA256
            releaseInfoHashes=($(echo "$request" | jq -r '.Hashes.Sha256'))
            releaseInfoSha256HashesArr=($(echo "$releaseInfoHashes" | base64 -d | xxd -p))
            releaseInfoSha256Hashes=$(echo "${releaseInfoSha256HashesArr[*]}" | sed 's/ //g')
            releaseInfoSizeInBytes=$(echo "$request" | jq -r '.SizeInBytes')

            sed -e "s|msedge-${productArr[i]}-win-${arch}-filename|${releaseInfoFileId}|g" \
                -e "s|msedge-${productArr[i]}-win-${arch}-url|${releaseInfoUrl}|g" \
                -e "s|msedge-${productArr[i]}-win-${arch}-hash|${releaseInfoHashes}|g" \
                -e "s|msedge-${productArr[i]}-win-${arch}-sha256|${releaseInfoSha256Hashes}|g" \
                -e "s|msedge-${productArr[i]}-win-${arch}-size|${releaseInfoSizeInBytes}|g" \
                -i \
                msedge.json

            # sed -e "s|msedge-${productArr[i]}-win-${arch}-url|${releaseInfoUrl}|g" -i link.json
            source_name="/msedge-${productArr[i]}-win-${arch}"
            old_url="$(cat ../vercel.json | jq -r ".rewrites[] | select(.source == \"${source_name}\") | .destination" | sed -e 's/[]&\/$*.^[]/\\&/g')"
            sed -e "s|${old_url}|${releaseInfoUrl}|g" -i ../vercel.json
            sleep 2
        done
        sleep 10
    done
    # do not prompt before overwriting
    mv -f msedge.json ../msedge
    mv -f link.json ../now.json
}

function compareVersion() {
    latestVersionArr=($(getLatestVersion ".stable" ".beta" ".dev" ".canary"))
    localVersionArr=($(getLocalVersion))
    echo "Latest version:  ${latestVersionArr[*]}"
    echo "Local version:  ${localVersionArr[*]}"

    # Compare Version
    if [[ "${latestVersionArr[0]}" == "${localVersionArr[0]}" ]] && [[ "${latestVersionArr[1]}" == "${localVersionArr[1]}" ]] && [[ "${latestVersionArr[2]}" == "${localVersionArr[2]}" ]] && [[ "${latestVersionArr[3]}" == "${localVersionArr[3]}" ]]; then
        echo -e "${Green_font_prefix}[Info] MSEdge is the latest version!${Font_color_suffix}"
    else
        echo -e "${Green_font_prefix}[Info] Update MSEdge!${Font_color_suffix}"
        getGeneratedVersionInfo
    fi
}

# sudo apt install curl jq xxd -y
# compareVersion

latestVersionArr=($(getLatestVersion ".stable" ".beta" ".dev" ".canary"))
localVersionArr=($(getLocalVersion))
echo "Latest version:  ${latestVersionArr[*]}"
echo "Local version:  ${localVersionArr[*]}"
echo -e "${Green_font_prefix}[Info] Update MSEdge!${Font_color_suffix}"
getGeneratedVersionInfo
