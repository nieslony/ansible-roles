(
function ldap_search()
{
    search_attr=$1

    ldapsearch -LLLQ \
        $LDAP_OPTS \
        "(|(uid=$SEARCH_USER)(samAccountName=$SEARCH_USER))" \
        $search_attr \
    | awk -F: "
        BEGIN {
            IGNORECASE = 1;
        }
        /^${search_attr}:/ {
            sub(/^ +/, \"\", \$2);
            sub(/ +$/, \"\", \$2);
            print \$2;
        }
        "
}

if [ ! -e "$HOME/.gitconfig" ]; then
    if [[ "$USER" =~ ^[a-z0-9\\-_.]+@ ]]; then
        SEARCH_USER="${USER/@*/}"
        USER_DOMAIN="${USER/*@/}"
        SEARCH_HOST=$(
            host -t srv  _ldap._tcp.$USER_DOMAIN \
            | head -1 \
            | awk '{ print substr($NF, 0, length($NF)-1); }'
        )
        BASE_DN="dc=${USER_DOMAIN/./,dc=}"
        LDAP_OPTS="-H ldap://$SEARCH_HOST -b $BASE_DN"
    else
        SEARCH_USER="$USER"
    fi

    DISPLAY_NAME=$( ldap_search displayname ) || exit 1
    EMAIL=$( ldap_search mail ) || exit 1

    git config --global user.name "$DISPLAY_NAME"
    git config --global user.email "$EMAIL"
fi
)
