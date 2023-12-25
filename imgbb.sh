#!/bin/bash

# Title: imgbb
# Author: Sabbir <sabbir@disroot.org>
# Version: 0.1
# Date: 2023-12-14 (Last Updated: 2023-12-14)
# Description: A simple CLI based tool to host images on IMGBB
#
# License:
#   This script is licensed under the GNU General Public License v3.0 or later.
#   For more details, see: https://www.gnu.org/licenses/gpl-3.0.html
#
# GitHub Repository:
#   https://github.com/shmVirus/imgbb


#: sets API key from environment variables
api_key="$IMGBB_API_KEY"

#: checking if API key is set correctly
if [ -z "$api_key" ]; then
    echo "Error: No API Key found. Get and Configure your own key!"
    exit 1
fi

#: checking required dependencies
dependencies=("curl" "jq" "bc")
for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "Error: $dep is not installed, install it before using the program!"
        exit 1
    fi
done

#: shows usage information
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$#" -eq 0 ]; then
    echo "Usage: imgbb file1 ... fileN [-e <expiration_time>]"
    echo "Options:"
    echo "   -e <expiration_time>   Set expiration time in minutes"
    echo "                          default: 10, use 0 for account default"
    echo "   -h, --help             Display this help message"
    echo "Shows: Viewer, Direct, Full, Thumb, Delete urls"
    exit 0
fi

#: default expiration time in seconds
default_expiration=600

#: uploads image to IMGBB
upload_image() {
    if [ -z "$expiration_time" ]; then
        #: if expiration time is not provided, uses default expiration
        expiration_time=$default_expiration
    fi

    local expiration_param="--form expiration=$expiration_time"
    if [ "$expiration_time" -eq 0 ]; then
        #: if expiration time is 0, set expiration_param to empty string
        expiration_param="" #: empty to use account default expiration
    fi

    curl -s --location --request POST "https://api.imgbb.com/1/upload?key=$api_key" --form "image=$1" $expiration_param
}

#: parses commands from arguments
if [ "${@: -2:1}" == "-e" ]; then
    expiration_time=$(("${!#}" * 60))
    files="${@:1:$#-2}"  #: exclude last two arguments as they are not files
else
    expiration_time=$default_expiration
    files="$@"
fi

#: calculates expiration time
if [ "$expiration_time" -eq 0 ]; then
    expires_at="after Account Default Expiration!"
else
    expires_at=$(echo "$(date +%s) + $expiration_time" | bc)
    expires_at=$(date -d @$expires_at +"%Y-%m-%d %H:%M:%S")
fi

#: uploads N images
for file in $files; do
    # Upload the image
    if [[ "$file" =~ ^https?:// ]]; then
        response=$(upload_image "$file")
    else
        response=$(upload_image "@$file")
    fi

    jq_filter='
    .data | {
      url_viewer,
      url,
      thumb_url: .thumb.url,
      medium_url: .medium.url,
      delete_url
    }'

    result=$(echo "$response" | jq -r "$jq_filter")

    if [ $(echo "$result" | jq -r '.url_viewer') == "null" ]; then
        err_code=$(jq -r '.error.code' <<< "$response")
        err_msg=$(jq -r '.error.message' <<< "$response")
        err_status=$(jq -r '.status_txt' <<< "$response")
        echo -e "\nError\t: Upload failed for $file\nCode\t: $err_code ($err_status)\nMessage\t: $err_msg\n" >&2
    else
        #: formatting output, comment out for exclusion
        formatted_result="Viewer\t: $(echo "$result" | jq -r '.url_viewer')\n"
        formatted_result+="Direct\t: $(echo "$result" | jq -r '.url')\n"
        formatted_result+="--\n"
        formatted_result+="Thumb URL\t: $(echo "$result" | jq -r '.thumb_url')\n"
        formatted_result+="Medium URL\t: $(echo "$result" | jq -r '.medium_url // .url')\n"
        formatted_result+="Delete URL\t: $(echo "$result" | jq -r '.delete_url')\n"
        formatted_result+="--\n"
        formatted_result+="Expires at\t: $expires_at\n"

        echo -e "\n$formatted_result"
    fi
done
