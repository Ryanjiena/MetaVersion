#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# set -euxo pipefail

cur_dir=$(
    cd "$(dirname "$0")"
    pwd
)
DATE="$(echo $(TZ=UTC date '+%Y-%m-%d %H:%M:%S'))"
check_dir="${cur_dir}/check"
tmpFile="./action.tmp"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[Info]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"

for item in "alibaba" "header" "chrome" "msedge" "shuax-new" "workflows" "sarasa-gothic"; do
    cd ${check_dir}
    echo -e "${Green_font_prefix}[Info] Check ${item}...${Font_color_suffix}"
    sed -i 's/\r$//' check-${item}.sh
    bash check-${item}.sh
done

# oneindex
userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36"
cd ${cur_dir}
wget --user-agent="${userAgent}" --no-check-certificate --quiet -O "oneindex.txt" "https://pan.jiemi.workers.dev/?file=/scoop/tree.txt"


