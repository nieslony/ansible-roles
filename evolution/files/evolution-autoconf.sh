#!/bin/bash

gsettings set org.gnome.evolution-data-server autoconfig-directory /usr/local/etc/evolution

autoconf_vars=$( ldapsearch -LLLQ uid=$USER mail displayName | awk -F ':\\s*' -v quote="'" '
        BEGIN {
                evo_var
        }

        /mail:/ { evo_vars["email"] = $2; }
        /displayName:/ { evo_vars["display_name"] = $2; }

        END {
                vars = "[";
                first = 0;
                for (key in evo_vars) {
                        if (first == 0)
                                first = 1;
                        else
                                vars = vars ",";
                        vars = vars quote key "=" evo_vars[key] quote;
                }
                vars = vars "]";
                print(vars);
        }
'
)

gsettings set org.gnome.evolution-data-server autoconfig-variables "$autoconf_vars"

if [ ! -e "~/.config/evolution" ]; then
        /usr/libexec/evolution-source-registry & sleep 10 ; killall evolution-source-registry
fi
