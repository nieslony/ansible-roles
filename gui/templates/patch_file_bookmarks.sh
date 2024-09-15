USER_PLACES="$HOME/.local/share/user-places.xbel"
BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
LOG_FILE="/tmp/create-bookmarks.$USER.log"
STARTED_AS="bash $0 $@"

debug() {
    if [ -n "$debug" ]; then
        echo $@ >> /dev/stderr
    fi
}

while [ -n "$1" ]; do
    case "$1" in
        "-d")
            debug=yes
            ;;
        "-f")
            force=yes
            ;;
        "-s")
            shift
            sleep=$1
            ;;
        "-r")
            dont_retry=yes
            ;;
        "*")
            echo "Invalid parameter: $1"
            exit 1
    esac
    shift
done

function find_icon {
    folder=$1
    utl=$2

    timeout 2 stat --printf "" "$folder/.directory"
    ret=$?
    case "$ret" in
        124)
            debug "stat $folder/.directory failed with timeout"
            has_errors=yes
            icon=$(
                cat $USER_PLACES |
                    sed -e 's/bookmark:icon/icon/' |
                    xmlstarlet sel -t -v 'xbel/bookmark[@href="$url"]/info/metadata/icon/@name'
            )
            debug "Found icon in $USER_PLACES for $url: $icon"
            ;;
        1)
            debug "stat $folder/.directory failed"
            # stat failed
            has_errors=yes
            ;;
        0)  icon=$(
                cat "$folder/.directory" |
                    awk -F= '/^Icon=[a-zA-Z0-9\-/-_.]+$/ { print $2; }'
            )
            debug "Found icon in $folder/.directory: $icon"
            ;;
        *)
            echo "Unhandled return code: $?"
            has_errors=yes
            ;;
    esac
    if [ -n "$icon" ]; then
        echo $icon
    else
        echo folder-remote
    fi
    debug "Set icon $icon for bookmark $folder"

    if [ -n "$has_errors" ]; then
        return 1
    fi
}

function find_title {
    folder=$1

    timeout 2 stat --printf "" "$folder/.directory"
    ret=$?
    case "$ret" in
        124)
            debug "stat $folder/.directory failed with timeout"
            has_errors=yes
            title=$(
                cat $USER_PLACES |
                    sed -e 's/bookmark:icon/icon/' |
                    xmlstarlet sel -t -v 'xbel/bookmark[@href="$url"]/title'
            )
            debug "Found title in $USER_PLACES for $url: $title"
            ;;
        1)
            debug "stat $folder/.directory failed"
            # stat failed
            has_errors=yes
            ;;
        0)  title=$(
                cat "$folder/.directory" |
                    awk -F= '/^Comment=.+$/ { print $2; }'
            )
            debug "Found title in $folder/.directory: $title"
            ;;
        *)
            echo "Unhandled return code: $?"
            has_errors=yes
    esac
    if [ -n "$title" ]; then
        echo $title
    else
        echo "$folder"
    fi
    if [ -n "$has_errors" ]; then
        return 1
    fi
}

function create_bookmarks {
    # Create default Dolphin Bookmarks
    #
    if [ -n "$DISPLAY" -a ! -e "$USER_PLACES" ];  then
        dolphin & sleep 0.5 ; killall dolphin
    fi

    has_errors=""
    # Create Dolphin Bookmarks
    #
    if [ -e "$USER_PLACES" ]; then
        DOLPHIN_BOOKMARKS=""
        {% for bookmark in file_bookmarks -%}
        title="$( find_title {{ bookmark.url[7:] }} )" || has_errors="yes"
        icon="$( find_icon {{ bookmark.url[7:] }} {{ bookmark.url }} )" || has_errors="yes"
        DOLPHIN_BOOKMARKS="
            $DOLPHIN_BOOKMARKS
            <bookmark href=\"{{ bookmark.url }}\">
                <title>Remote folder: $title</title>
                <info>
                    <metadata owner=\"http://freedesktop.org\">
                        <bookmark:icon name=\"{%- if bookmark.icon == "folder-remote" -%}
                        $icon
                        {%- else -%}
                        {{ bookmark.icon }}
                        {%- endif -%}\"/>
                    </metadata>
                    <metadata owner=\"http://www.kde.org\">
                        <ID>1661791353/{{ loop.index }}</ID>
                    </metadata>
                </info>
            </bookmark>
            "
        {% endfor %}

        TMP_FILE=$( mktemp )
        cat "$USER_PLACES" | awk -v bookmarks="$DOLPHIN_BOOKMARKS" '
            BEGIN {
                inblock = 0;
                replaced = 0;
                begin_block = "<!-- BEGIN ansible -->";
                end_block = "<!-- END ansible -->";
            }
            index($0, begin_block) > 0 {
                inblock=1;
                print;
                next;
            }
            index($0, end_block) > 0 {
                inblock=0;
                replaced=1;
                print bookmarks;
                print;
                next;
            }
            /<.xbel>/ {
                if (replaced == 0) {
                    print begin_block;
                    print bookmarks;
                    print end_block;
                    print;
                    next;
                }
            }
            inblock != 1 {
                print;
            }
            ' > "$TMP_FILE"

        mv "$TMP_FILE" "$USER_PLACES"
    else
        debug "$USER_PLACES doesn't exits, don't update Dolphin bookmarks."
    fi

    # Create GTK bookmarks
    #
    GTK_BOOKMARKS='{%- for bookmark in file_bookmarks -%}
    {{ bookmark.url }} {{ bookmark.name }}
    {% endfor %}'

    if [ ! -e "$BOOKMARKS" ]; then
        debug "No GTK bookmarks yet, creating new ones"
        mkdir -pv $( dirname "$BOOKMARKS" )
        touch "$BOOKMARKS"
    fi

    TMP_FILE=$( mktemp )
    cat "$BOOKMARKS" | awk -v bookmarks="$GTK_BOOKMARKS" '
        /file:.* .*/ {
            next;
        }
        $0 != "" { print; }
        END {
            print bookmarks;
        }
    ' > "$TMP_FILE"

    mv "$TMP_FILE" "$BOOKMARKS"

    #
    #
    {% for bookmark in file_bookmarks %}
    if [ -e "{{ bookmark.url[7:] }}/.smb-preexec-hint" ]; then
        share=$( cat "{{ bookmark.url[7:] }}/.smb-preexec-hint" | awk '/^\/\/[a-z]/ { print $0; }' )
        smbclient --no-pass "$share" -c quit || has_errors="yes"
    fi
    {% endfor %}

    if [ -n "$has_errors" ]; then
        echo create_bookmarks has errors
        return 1
    fi
}

function have_keytab {
    if klist > /dev/null 2>&1 ; then
        debug "Have keytab"
        return 0
    else
        debug "Dont't have keytab"
        return 1
    fi
}

function is_login_shell {
    if [ "${0:0:1}" = "-" ]; then
        debug "Login Shell"
        return 0
    else
        debug "Not login shell"
        return 1
    fi
}

function is_not_system_user {
    if [ "$UID" -ge 1000 ]; then
        debug "No system user"
        return 0
    else
        debug "System user"
        return 1
    fi
}

if [ -n "$force" ] || ( is_login_shell && is_not_system_user && have_keytab ) ; then
    debug "Create bookmarks"
    if [ -n "$sleep" ]; then
        sleep $sleep
    fi
    (
        echo "--- $(date) --- Create Filemanager Bookmarks ---"
        create_bookmarks
        echo "ret=$?"
        if [ "$?" = "0" ]; then
            if [ -z "$dont_retry" ]; then
                echo "Some errors occured. Retry in ~5min"
                echo "scheduling >>$STARTED_AS -r<<"
                echo $STARTED_AS -r | at now+5minutes
            else
                echo "Retry failed. Giving up."
            fi
        else
            echo "No errors occured. :-)"
        fi
        echo "--- $(date) --- Done ---"
    ) >> $LOG_FILE 2>&1
else
    debug "Skip creating bookmarks"
fi

