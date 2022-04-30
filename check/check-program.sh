#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
set -euxo pipefail

DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
USER="$(whoami)"
tmpFile="./action.tmp"
userAgent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.4987.0 Safari/537.36'

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

nameArr=($(cat ../program | jq -r '.[] | .name'))
regexArr=($(cat ../program | jq -r '.[] | .regex'))
urlArr=($(cat ../program | jq -r '.[] | .url'))
verArr=($(cat ../program | jq -r '.[] | .version'))

pip install -r requirements.txt

for ((i = 0; i < ${#nameArr[@]}; i++)); do
    echo -e "${Info} Check ${nameArr[i]} ..."
    if [[ \"${urlArr[i]}\" =~ \".*lanzout.com.*\" ]]; then
        if [[ "${urlArr[i]}" =~ \".*lanzout.com.*\#.*\" ]]; then
            # url=$(echo "${urlArr[i]}" | sed 's/#.*//')
            # pwd=$(echo "${urlArr[i]}" | sed 's/.*#//')
            url=$(echo "${urlArr[i]}" | awk -F '#' '{print $1}')
            pwd=$(echo "${urlArr[i]}" | awk -F '#' '{print $2}')
            result=$(python ./lanzoudisk.py --url "${url}" --pwd "${pwd}")
        else
            result=$(python ./lanzoudisk.py --url "${urlArr[i]}")
        fi
    elif [[ \"${urlArr[i]}\" =~ \".*ysepan.*\" ]]; then
        result=$(curl -s 'http://cb.ysepan.com/f_ht/ajcx/wj.aspx?cz=dq&jsq=0&mlbh=1931898&wjpx=1&_dlmc=iyoung&_dlmm=' -H 'Accept: */*' -H 'Accept-Language: zh-CN,zh;q=0.9' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Cookie: __yjs_duid=1_0f44ae36cbba42cacae2690ef19763e41648221396050; ASP.NET_SessionId=d4srotp24czv3eltf0rmfx3d' -H 'Referer: http://cb.ysepan.com/f_ht/ajcx/000ht.html?bbh=1163' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.4987.0 Safari/537.36' --compressed --insecure)
    fi

    remote_ver=$(echo "${result}" | grep -oP "${regexArr[i]}[\d.a-z]+" | sed "s|${regexArr[i]}||g;s|.exe||g" | head -1)
    if [[ "${remote_ver}" != "${verArr[i]}" ]]; then
        echo "- [ ] **[${nameArr[i]}](${urlArr[i]})** ${verArr[i]} -> ${remote_ver}" >>IBody
        sed -i "s|${verArr[i]}|${remote_ver}|g" ../program
    else
        echo "${Info} ${nameArr[i]} is latest version!"
    fi
done

if [ -s "IBody" ]; then
    # gh login with token
    echo "${AuthToken}" | gh auth login --with-token

    # create issue
    gh issue create --title "Program update! ${DATE}" --body-file IBody --label program-update --assignee "@me"

    # gh logout
    echo "Y" | gh auth logout

    # clean
    rm -f IBody
fi
