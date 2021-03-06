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

chrome_plus_remote_ver="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://api.github.com/repos/shuax/chrome_plus/actions/workflows/build.yml/runs?branch=main&status=success" | grep -o '"created_at": ".*"' | head -n 1 | sed 's/"//g;s/-//g;s/://g' | sed 's/created_at //g;s/T/./g;s/Z//g')"
edge_plus_remote_ver="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://api.github.com/repos/shuax/edge_plus/actions/workflows/build.yml/runs?branch=main&status=success" | grep -o '"created_at": ".*"' | head -n 1 | sed 's/"//g;s/-//g;s/://g' | sed 's/created_at //g;s/T/./g;s/Z//g')"

chrome_plus_local_ver="$(cat ../shuax | jq -r .chrome_plus.version)"
edge_plus_local_ver="$(cat ../shuax | jq -r .edge_plus.version)"

echo "Latest version:  ${chrome_plus_remote_ver}  ${edge_plus_remote_ver}"
echo "Local version:  ${chrome_plus_local_ver}  ${edge_plus_local_ver}"

# Compare Version
if [[ "${chrome_plus_remote_ver}" == "${chrome_plus_local_ver}" ]] && [[ "${edge_plus_remote_ver}" == "${edge_plus_local_ver}" ]]; then
    echo -e "${Green_font_prefix}[Info] chrome_plus and edge_plus are up-to-date.${Font_color_suffix}"
else
    echo -e "${Green_font_prefix}[Info] Update chrome_plus and edge_plus!${Font_color_suffix}"
    cp shuax.src.json shuax.json

    for bit in "x64" "x86"; do
        filename1="chrome_plus-${bit}-v${chrome_plus_remote_ver}.zip"
        filename2="edge_plus-${bit}-v${edge_plus_remote_ver}.zip"
        wget --user-agent="${userAgent}" --quiet "https://nightly.link/shuax/chrome_plus/workflows/build/main/windows_${bit}.zip" -O "${filename1}"
        wget --user-agent="${userAgent}" --quiet "https://nightly.link/shuax/edge_plus/workflows/build/main/windows_${bit}.zip" -O "${filename2}"
        sha256sum1="$(sha256sum "${filename1}" | awk '{print $1}')"
        sha256sum2="$(sha256sum "${filename2}" | awk '{print $1}')"

        sed -e "s|Check-Time|${DATE}|g" \
            -e "s|chrome_plus-Version|${chrome_plus_remote_ver}|g" \
            -e "s|edge_plus-Version|${edge_plus_remote_ver}|g" \
            -e "s|chrome_plus-${bit}-Filename|${filename1}|g" \
            -e "s|chrome_plus-${bit}-Hash|${sha256sum1}|g" \
            -e "s|edge_plus-${bit}-Filename|${filename2}|g" \
            -e "s|edge_plus-${bit}-Hash|${sha256sum2}|g" \
            -i \
            shuax.json
    done

    # upload to onedrive
    mkdir shuax && mv chrome_plus* edge_plus* shuax/
    cd shuax/ && wget --user-agent="${userAgent}" --no-check-certificate --quiet -O "sha256sum" "https://pan.jiemi.workers.dev/?file=/scoop/shuax/sha256sum"
    sha256sum chrome_plus* edge_plus* >> sha256sum
    awk ' { t = $1; $1 = $2; $2 = t; print; } ' sha256sum | sort -f | awk ' { t = $1; $1 = $2; $2 = t; print; } ' > sha256sum1
    mv sha256sum1 sha256sum -f && cd ..
    wget --user-agent="${userAgent}" --no-check-certificate --quiet "https://github.com/gaowanliang/LightUploader/releases/download/v2.0.2-fix/LightUploader_Linux_x86_64.tar.gz"
    tar -xzf LightUploader_Linux_x86_64.tar.gz && sudo chmod +x ./LightUploader
    echo ${CONFIG} >config.json
    ./LightUploader -c config.json -f shuax -r "public/scoop/" -t 6 -b 20 > ${tmpFile}

    mv -f shuax.json ../shuax
    rm -rf shuax/ LICENSE LightUploader LightUploader_Linux_x86_64.tar.gz config.json en.toml
fi
