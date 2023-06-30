TMP_FILE=$( mktemp )

cat "$HOME/.local/share/user-places.xbel" | envsubst > $TMP_FILE
mv $TMP_FILE "$HOME/.local/share/user-places.xbel"
