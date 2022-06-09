#!/bin/bash

attrs="mail displayname"

CFG_DIR="$HOME/.thunderbird"

if [ ! -e "$CFG_DIR" ]; then
    mkdir -v "$CFG_DIR"
fi

ldapsearch -LLLQ uid=$USER $attrs 2> /dev/null |
    awk -v attrs="$attrs" -F ": " '
        function has_value(arr, val) {
            for (i in arr) {
                if (arr[i] == val) {
                    return 1;
                }
            }
            return 0;
        }

        BEGIN {
            split(attrs, split_attrs, " +");
            for (i in split_attrs) {
                key = split_attrs[i];
                user_attr[key] = "";
            }

            found = 0;
        }

        /^[a-zA-Z]+/ {
            found = 1;

            if (has_value(split_attrs, $1))
                user_attr[$1] = $2;
        }

        END {
            if (found) {
                fn = ENVIRON["HOME"] "/.thunderbird/user_attrs.cfg";
                timestamp = strftime("%F %T", systime());
                print("Writing " fn);
                print("// Auto generated on " timestamp) > fn;
                print("lockPref(\"mail.identity.id1.useremail\", \"" user_attr["mail"] "\");") > fn;
                print("lockPref(\"mail.identity.id1.fullName\", \"" user_attr["displayname"] "\");") > fn;
            }
        }
        '
