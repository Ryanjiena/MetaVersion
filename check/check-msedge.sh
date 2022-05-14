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

function getGeneratedVersionInfo() {

    archArr=("X64" "X86" "ARM64")
    productArr=("stable" "beta" "dev" "canary")
    versionArr=($(getLatestVersion ".stable" ".beta" ".dev" ".canary"))

    for ((i = 0; i < ${#productArr[@]}; i++)); do

        cp msedge.src.json msedge-${productArr[i]}.json
        sed -e "s|check-time|${DATE}|g;s|product-name|${productArr[i]}|g;s|msedge-product-win-ver|${versionArr[i]}|g" -i msedge-${productArr[i]}.json

        for arch in ${archArr[@]}; do

            edgeUrl="https://msedge.api.cdp.microsoft.com/api/v1.1/internal/contents/Browser/namespaces/Default/names/msedge-${productArr[i]}-win-$arch/versions/${versionArr[i]}/files?action=GenerateDownloadInfo&foregroundPriority=true"
            fileName="MicrosoftEdge_${arch}_${versionArr[i]}.exe"
            response=$(curl -k -s -A "${userAgent}" "${edgeUrl}" -X POST -d "{\"targetingAttributes\":{}}" | jq --arg NAME ${fileName} '.[] | select(.FileId==$NAME)' | jq 'del(.Hashes.Sha1, .DeliveryOptimization)')

            releaseInfoFileId=$(echo "$response" | jq -r '.FileId')
            releaseInfoHashes=($(echo "$response" | jq -r '.Hashes.Sha256'))
            releaseInfoSha256HashesArr=($(echo "$releaseInfoHashes" | base64 -d | xxd -p))
            releaseInfoSha256Hashes=$(echo "${releaseInfoSha256HashesArr[*]}" | sed 's/ //g')
            releaseInfoSizeInBytes=$(echo "$response" | jq -r '.SizeInBytes')

            # & is special in the replacement text: it means “the whole part of the input that was matched by the pattern”
            # https://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern/2705678#2705678
            # https://unix.stackexchange.com/questions/296705/using-sed-with-ampersand/296732#296732
            releaseInfoUrl=$(echo "$response" | jq -r '.Url' | sed -e 's/[\/&]/\\&/g')

            [[ -z "${releaseInfoUrl}" ]] && echo -e "${Error} ${fileName} url: null " && continue 2
            echo -e "${Green_font_prefix}${fileName}${Font_color_suffix} -> ${releaseInfoUrl}"

            sed -e "s|msedge-product-win-${arch}-filename|${releaseInfoFileId}|g" \
                -e "s|msedge-product-win-${arch}-url|${releaseInfoUrl}|g" \
                -e "s|msedge-product-win-${arch}-hash|${releaseInfoSha256Hashes}|g" \
                -e "s|msedge-product-win-${arch}-size|${releaseInfoSizeInBytes}|g" \
                -i \
                msedge-${productArr[i]}.json

            # replace vercel link
            source_name="/msedge-${productArr[i]}-win-${arch}"
            old_url="$(cat ../vercel.json | jq -r ".redirects[] | select(.source == \"${source_name}\") | .destination" | sed -e 's/[]&\/$*.^[]/\\&/g')"
            sed -e "s|${old_url}|${releaseInfoUrl}|g" -i ../vercel.json

        done
        mv -f msedge-${productArr[i]}.json ../msedge-${productArr[i]}.json
    done

}

latestVersionArr=($(getLatestVersion ".stable" ".beta" ".dev" ".canary"))
echo "Latest version:  ${latestVersionArr[*]}"
getGeneratedVersionInfo
