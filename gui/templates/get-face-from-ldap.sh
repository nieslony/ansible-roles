#!/bin/bash

filename=$( ldapsearch -tt -Q uid=$USER jpegphoto 2>/dev/null |
    awk '
        /jpegphoto:</ {
            url = $2;
            gsub(/^file:../, "", url);
            print url;
        }
    '
)

if [ "$?" = "0" -a -s "$filename" ]; then
    if ! cmp --silent $filename ~/.face.icon ; then
        mv $filename ~/.face.icon
    else
        rm $filename
    fi
fi
