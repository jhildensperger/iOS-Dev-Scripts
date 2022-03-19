#!/bin/sh

# Example:
# ./generate-icons.sh -i Artwork/spotlight-icon.png -n AppIcon -o Artwork/ -p 1 -t 1

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
ICON=""
NAME=""
OUTPUT_PATH=""
PHONE=false
TABLET=false
WATCH=false

while getopts "i:n:o:p:t:w:" opt; do
    case "$opt" in
    i)  ICON=${OPTARG}
        ;;
    n)  NAME=${OPTARG}
        ;;
    o)  OUTPUT_PATH=${OPTARG}
        ;;
    p)  PHONE=${OPTARG}
        ;;
    t)  TABLET=${OPTARG}
        ;;
    w)  WATCH=${OPTARG}
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

if [ -z "${OUTPUT_PATH}" ]; then
    OUTPUT_PATH=`pwd`
fi

if [ -z "${NAME}" ]; then
    NAME="AppIcon"
fi

echo "ICON=$ICON, NAME='$NAME', OUTPUT_PATH='$OUTPUT_PATH', PHONE=$PHONE, TABLET=$TABLET"

APPICONSET_NAME="${NAME}.appiconset"
APPICONSET_PATH="${OUTPUT_PATH}/${APPICONSET_NAME}"
mkdir -p $APPICONSET_PATH

ICON_INFO=""

infoForIdiomSizeAndScaleRoleSubtype() {
    [ $3 == 1 ] && suffix="" || suffix="@${3}x"
    info="{\"idiom\":\"${1}\",\"size\":\"${2}x${2}\",\"scale\":\"${3}x\",\"filename\":\"Icon-${2}${suffix}.png\""

    if [[ -n $4 ]]; then
        info="${info},\"role\":\"${4}\""
    fi

    if [[ -n $5 ]]; then
        info="${info},\"subtype\":\"${5}\""
    fi

    echo "${info}},"
}

resizeImageForSizeAndScale() {
    [ $2 == 1 ] && suffix="" || suffix="@${2}x"
    sips -Z "$(echo "${1}*${2}" | bc)" $ICON --out "${APPICONSET_PATH}/Icon-${1}${suffix}.png"
}

generateForPhone() {
    echo ">>>> generateForPhone"

    for size in 20 29 40 60; do
        resizeImageForSizeAndScale $size 2

        if [[ $PHONE ]]; then
            resizeImageForSizeAndScale $size 3
            ICON_INFO+=`infoForIdiomSizeAndScaleRoleSubtype iphone $size 2`
            ICON_INFO+=`infoForIdiomSizeAndScaleRoleSubtype iphone $size 3`
        fi
        
        if [[ $TABLET && $size != 60 ]]; then
            resizeImageForSizeAndScale $size 1
            ICON_INFO+=`infoForIdiomSizeAndScaleRoleSubtype ipad $size 1`
            ICON_INFO+=`infoForIdiomSizeAndScaleRoleSubtype ipad $size 2`
        fi
    done
}

resizeAndAddInfoForIdiomSizeScaleRoleSubtype() {
    resizeImageForSizeAndScale $2 $3
    ICON_INFO+=`infoForIdiomSizeAndScaleRoleSubtype ${1} ${2} ${3} ${4} ${5}`
}

generateForTablet() {
    echo ">>>> generateForTablet"
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype ipad 76 1
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype ipad 76 2
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype ipad 83.5 2
}

generateForWatch() {
    echo ">>>> generateForWatch"
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 24 2 notificationCenter 38mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 27.5 2 notificationCenter 42mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 29 2 companionSettings 
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 29 3 companionSettings 
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 40 2 appLauncher 38mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 44 2 appLauncher 40mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 50 2 appLauncher 44mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 86 2 quickLook 38mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 98 2 quickLook 42mm
    resizeAndAddInfoForIdiomSizeScaleRoleSubtype watch 108 2 quickLook 44mm
}

if [[ $PHONE == 1 ]]; then
    echo "Should gen for PHONE"
    generateForPhone
fi

if [[ $TABLET == 1 ]]; then
    echo "Should gen for TABLET"
    generateForTablet
fi

if [[ $WATCH == 1 ]]; then
    echo "Should gen for WATCH"
    generateForWatch
fi

[ $WATCH == 1 ] && idiom="watch" || idiom="ios"

resizeImageForSizeAndScale 1024 1
ICON_INFO+=`infoForIdiomSizeAndScaleRoleSubtype ${idiom}-marketing 1024 1`

# Note: %? is to trim the trailing ',' for the last item in the array
CONTENTS="{\"images\":[${ICON_INFO%?}],\"info\":{\"version\":1,\"author\":\"xcode\"}}"
echo $CONTENTS > "${APPICONSET_PATH}/Contents.json"