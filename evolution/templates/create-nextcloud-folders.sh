CALENDAR_URL="https://{{ evolution_dav_server }}/nextcloud/remote.php/dav/calendars/${USER}/personal/"
TASKS_URL="https://{{ evolution_dav_server }}/nextcloud/remote.php/dav/calendars/${USER}/tasks/"
ADDRESS_URL="https://{{ evolution_dav_server }}/nextcloud/remote.php/dav/addressbooks/users/${USER}/contacts"

CURL_OPTS="--negotiate -u: -w %{http_code} -o /dev/null -Ss"

failed=""

MK_ADDRESSBOK_PROPS='<?xml version="1.0"?>
<d:mkcol xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
    <d:set>
        <d:prop>
            <d:resourcetype>
                <d:collection/>
                <card:addressbook/>
            </d:resourcetype>
            <d:displayname>Contacts</d:displayname>
        </d:prop>
    </d:set>
</d:mkcol>
'

# Create personal calendar
echo "--- Private Calendar ---"
echo "Connecting to $CALENDAR_URL ..."
status=$( curl -X PROPFIND $CURL_OPTS $CALENDAR_URL )
case "$status" in
    2??)
        echo "Private calendar already exists."
        ;;
    404)
        echo "Private calendar not found. Creating it."
        status=$( curl -X MKCALENDAR $CURL_OPTS $CALENDAR_URL )
        if [[ "$status" =~ 2.. ]]; then
            echo "Calendar created."
        else
            echo "Error creating calendar: $status"
            failed="yes"
        fi

        ;;
    000)
        echo "Connection to $CALENDAR_URL failed."
        failed="yes"
        ;;
    *)
        echo "Unhandled status code: >>$status<<"
        failed="yes"
        ;;
esac

# Create tasks
echo "--- Tasks ---"
echo "Connecting to $TASKS_URL"
status=$( curl -X PROPFIND $CURL_OPTS $TASKS_URL )
case "$status" in
    2??)
        echo "Tasks already exists."
        ;;
    404)
        echo "Tasks not found. Creating it."
        status=$( curl -X MKCALENDAR $CURL_OPTS $TASKS_URL )
        if [[ "$status" =~ 2.. ]]; then
            echo "Tasks created."
        else
            echo "Error creating tasks: $status"
            failed="yes"
        fi

        ;;
    000)
        echo "Connection to $TASKS_URL failed."
        failed="yes"
        ;;
    *)
        echo "Unhandled status code: >>$status<<"
        failed="yes"
        ;;
esac

# Create address book
echo "--- Address book ---"
echo "Connecting to $ADDRESS_URL ..."
status=$( curl -X PROPFIND $CURL_OPTS $ADDRESS_URL )
case "$status" in
    2??)
        echo "Address book already exists."
        ;;
    404)
        echo "Address book not found. Creating it."
        status=$( curl -X MKCOL -H 'Content-type: text/xml' --data "$MK_ADDRESSBOK_PROPS" $CURL_OPTS $ADDRESS_URL )
        if [[ "$status" =~ 2.. ]]; then
            echo "Address book created."
        else
            echo "Error creating Address book: $status"
            failed="yes"
        fi

        ;;
    000)
        echo "Connection to $ADDRESS_URL failed."
        failed="yes"
        ;;
    *)
        echo "Unhandled status code: >>$status<<"
        failed="yes"
        ;;
esac

if [ -n "$failed" ]; then
    echo "--- Failed ---"
else
    echo "Removing ~/.bashrc.d/create-nextcloud-folders.sh"
    rm -v "$HOME/.bashrc.d/create-nextcloud-folders.sh"
    echo "--- Success ---"
fi
