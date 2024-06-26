<?php

// The id of the address book to use to automatically set a
// user's full name in their new identity. (This should be an
// string, which refers to the $config['ldap_public'] array.)
$config['new_user_identity_addressbook'] = 'global_addressbook';

// When automatically setting a user's full name in their
// new identity, match the user's login name against this field.
$config['new_user_identity_match'] = 'uid';

// Determine whether to import user's identities on each login.
// New user identity will be created for each e-mail address
// present in address book, but not assigned to any identity.
$config['new_user_identity_onlogin'] = true;
