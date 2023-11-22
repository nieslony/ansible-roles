USER_PLACES="$HOME/.local/share/user-places.xbel"
BOOKMARKS="$HOME/.config/gtk-3.0/bookmarks"
GTK_BOOKMARKS='{%- for bookmark in file_bookmarks -%}
{{ bookmark.url }} {{ bookmark.name }}
{% endfor %}'
DOLPHIN_BOOKMARKS='{%- for bookmark in file_bookmarks -%}
    <bookmark href="{{ bookmark.url }}">
        <title>{{ bookmark.name }}</title>
        <info>
            <metadata owner="http://freedesktop.org">
                <bookmark:icon name="{{ bookmark.icon }}"/>
            </metadata>
            <metadata owner="http://www.kde.org">
                <ID>1661791353/{{ loop.index }}</ID>
            </metadata>
        </info>
    </bookmark>
    {% endfor %}'

if [ -n "$DISPLAY" -a ! -e "$USER_PLACES" ];  then
    dolphin & sleep 0.5 ; killall dolphin
fi

TMP_FILE=$( mktemp )

if [ -e "$USER_PLACES" ]; then
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
fi

if [ ! -e "$BOOKMARKS" ]; then
    touch "$BOOKMARKS"
fi

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
