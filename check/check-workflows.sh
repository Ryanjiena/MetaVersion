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

checktime="$(cat ../workflow.json | jq -r '.checktime')"
nameArr=($(cat ../workflow.json | jq -r '.[] | .name'))
workflowArr=($(cat ../workflow.json | jq -r '.[] | .workflow'))
branchArr=($(cat ../workflow.json | jq -r '.[] | .branch'))

sed -e "s|${checktime}|${DATE}|g" -i ../workflow.json
for ((i = 0; i < ${#nameArr[@]}; i++)); do

    # source_name="/${nameArr[i]}"
    # artifacts_url="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://api.github.com/repos/${nameArr[i]}/actions/workflows/${workflowArr[i]}.yml/runs?branch=${branchArr[i]}&status=success" | grep -o '"artifacts_url": ".*"' | head -n 1 | sed 's/"//g;s/-//g;s/artifacts_url: //g')"
    # artifacts_old_url="$(cat ../vercel.json | jq -r ".redirects[] | select(.source == \"${source_name}\") | .destination")"
    # sed -e "s|${artifacts_old_url}|${artifacts_url}|g" -i ../vercel.json

    # remote_ver="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://api.github.com/repos/${nameArr[i]}/actions/workflows/${workflowArr[i]}.yml/runs?branch=${branchArr[i]}&status=success" | grep -o '"created_at": ".*"' | head -n 1 | sed 's/"//g;s/-//g;s/://g' | sed 's/created_at //g;s/T/./g;s/Z//g')"
    # local_ver="$(cat ../workflow.json | jq -r ".[] | select(.name == \"${nameArr[i]}\") | .version")"
    # sed -e "s|${local_ver}|${remote_ver}|g" -i ../workflow.json

    workflow_run_url="$(wget --user-agent="${userAgent}" --no-check-certificate -qO- "https://api.github.com/repos/${nameArr[i]}/actions/workflows/${workflowArr[i]}.yml/runs?branch=${branchArr[i]}&status=success" | jq -r ".workflow_runs | .[] | select(.event == \"push\") | .html_url" | head -1)"
    
    [[ -z "${workflow_run_url}" ]] && echo -e "${Error}${nameArr[i]} url: null " && continue 1
    echo -e "${Green_font_prefix}${nameArr[i]}${Font_color_suffix} -> ${workflow_run_url}"

    source_name="/${nameArr[i]}"
    workflow_run_old_url="$(cat ../vercel.json | jq -r ".redirects[] | select(.source == \"${source_name}\") | .destination")"
    sed -e "s|${workflow_run_old_url}|${workflow_run_url}|g" -i ../vercel.json
done
