<?php

/* Local configuration for Roundcube Webmail */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite, mssql, sqlsrv, oracle
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// Note: for SQLite use absolute path (Linux): 'sqlite:////full/path/to/sqlite.db?mode=0646'
//       or (Windows): 'sqlite:///C:/full/path/to/sqlite.db'
// Note: Various drivers support various additional arguments for connection,
//       for Mysql: key, cipher, cert, capath, ca, verify_server_cert,
//       for Postgres: application_name, sslmode, sslcert, sslkey, sslrootcert, sslcrl, sslcompression, service.
//       e.g. 'mysql://roundcube:@localhost/roundcubemail?verify_server_cert=false'
$config['db_dsnw'] = 'mysql://roundcube_user:{{ roundcube_password }}@localhost/roundcube_db';

// ----------------------------------
// IMAP
// ----------------------------------
// The IMAP host chosen to perform the log-in.
// Leave blank to show a textbox at login, give a list of hosts
// to display a pulldown menu or set one host as string.
// Enter hostname with prefix ssl:// to use Implicit TLS, or use
// prefix tls:// to use STARTTLS.
// Supported replacement variables:
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %s - domain name after the '@' from e-mail address provided at login screen
// For example %n = mail.domain.tld, %t = domain.tld
// WARNING: After hostname change update of mail_host column in users table is
//          required to match old user data records with the new host.
$config['default_host'] = 'tls://{{ ansible_fqdn }}';

// ----------------------------------
// SMTP
// ----------------------------------
// SMTP server host (for sending mails).
// Enter hostname with prefix ssl:// to use Implicit TLS, or use
// prefix tls:// to use STARTTLS.
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
// For example %n = mail.domain.tld, %t = domain.tld
// To specify different SMTP servers for different IMAP hosts provide an array
// of IMAP host (no prefix or port) and SMTP server e.g. ['imap.example.com' => 'smtp.example.net']
$config['smtp_server'] = 'tls://{{ ansible_fqdn }}';

$config['smtp_log'] = true;

// SMTP port. Use 25 for cleartext, 465 for Implicit TLS, or 587 for STARTTLS (default)
$config['smtp_port'] = 587;

// SMTP username (if required) if you use %u as the username Roundcube
// will use the current username for login
$config['smtp_user'] = '%u';

// SMTP password (if required) if you use %p as the password Roundcube
// will use the current user's password for login
$config['smtp_pass'] = '%p';

$config['smtp_auth_type'] = 'PLAIN';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
$config['support_url'] = '';

// check client IP in session authorization
$config['ip_check'] = true;

// This key is used for encrypting purposes, like storing of imap password
// in the session. For historical reasons it's called DES_key, but it's used
// with any configured cipher_method (see below).
// For the default cipher_method a required key length is 24 characters.
$config['des_key'] = 'TZTZD3IDJnFnBPcKQpY7zuCy';

// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
$config['plugins'] = ['attachment_reminder', 'emoticons', 'krb_authentication', 'vcard_attachments', 'zipdownload', 'new_user_identity'];

// Set the spell checking engine. Possible values:
// - 'googie'  - the default (also used for connecting to Nox Spell Server, see 'spellcheck_uri' setting)
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, the default settings
// connect to http://spell.roundcube.net which is a hosted service provided by Roundcube.
// You can connect to any other googie-compliant service by setting 'spellcheck_uri' accordingly.
$config['spellcheck_engine'] = 'enchant';

// compose html formatted messages by default
//  0 - never,
//  1 - always,
//  2 - on reply to HTML message,
//  3 - on forward or reply to HTML message
//  4 - always, except when replying to plain text message
$config['htmleditor'] = 2;

// Encoding of long/non-ascii attachment names:
// 0 - Full RFC 2231 compatible
// 1 - RFC 2047 for 'name' and RFC 2231 for 'filename' parameter (Thunderbird's default)
// 2 - Full 2047 compatible
$config['mime_param_folding'] = 0;

$config['debug_level'] = 2;




$config['ldap_public']['global_addressbook'] = [
  'name'          => '{{ organization }}',
  // Replacement variables supported in host names:
  // %h - user's IMAP hostname
  // %n - hostname ($_SERVER['SERVER_NAME'])
  // %t - hostname without the first part
  // %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
  // %z - IMAP domain (IMAP hostname without the first part)
  // For example %n = mail.domain.tld, %t = domain.tld
  // Note: Host can also be a full URI e.g. ldaps://hostname.local:636 (for SSL)
  'hosts'         => array('{{ ldap_servers | join("', '") }}'),
  'port'          => 389,
  'use_tls'       => false,
  'ldap_version'  => 3,       // using LDAPv3
  'network_timeout' => 10,    // The timeout (in seconds) for connect + bind attempts. This is only supported in PHP >= 5.3.0 with OpenLDAP 2.x
  'user_specific' => true,   // If true the base_dn, bind_dn and bind_pass default to the user's IMAP login.
  // When 'user_specific' is enabled following variables can be used in base_dn/bind_dn config:
  // %fu - The full username provided, assumes the username is an email
  //       address, uses the username_domain value if not an email address.
  // %u  - The username prior to the '@'.
  // %d  - The domain name after the '@'.
  // %dc - The domain name hierarchal string e.g. "dc=test,dc=domain,dc=com"
  // %dn - DN found by ldap search when search_filter/search_base_dn are used
  'base_dn'       => '{{ ldap_base_dn }}',
  'bind_dn'       => 'uid=%u,cn=users,cn=accounts,{{ ldap_base_dn }}',
  'bind_pass'     => '',
  // It's possible to bind for an individual address book
  // The login name is used to search for the DN to bind with
  'search_base_dn' => '',
  'search_filter'  => '',   // e.g. '(&(objectClass=posixAccount)(uid=%u))'
  // DN and password to bind as before searching for bind DN, if anonymous search is not allowed
  'search_bind_dn' => '',
  'search_bind_pw' => '',
  // Base DN and filter used for resolving the user's domain root DN which feeds the %dc variables
  // Leave empty to skip this lookup and derive the root DN from the username domain
  'domain_base_dn' => '',
  'domain_filter'  => '',
  // Optional map of replacement strings => attributes used when binding for an individual address book
  'search_bind_attrib' => [],  // e.g. ['%udc' => 'ou']
  // Default for %dn variable if search doesn't return DN value
  'search_dn_default' => '',
  // Optional authentication identifier to be used as SASL authorization proxy
  // bind_dn need to be empty
  'auth_cid'       => '',
  // SASL authentication method (for proxy auth), e.g. DIGEST-MD5
  'auth_method'    => '',
  // Indicates if the addressbook shall be hidden from the list.
  // With this option enabled you can still search/view contacts.
  'hidden'        => false,
  // Indicates if the addressbook shall not list contacts but only allows searching.
  'searchonly'    => false,
  // Indicates if we can write to the LDAP directory or not.
  // If writable is true then these fields need to be populated:
  // LDAP_Object_Classes, required_fields, LDAP_rdn
  'writable'       => false,
  // To create a new contact these are the object classes to specify
  // (or any other classes you wish to use).
  'LDAP_Object_Classes' => ['top', 'inetOrgPerson'],
  // The RDN field that is used for new entries, this field needs
  // to be one of the search_fields, the base of base_dn is appended
  // to the RDN to insert into the LDAP directory.
  'LDAP_rdn'       => 'cn',
  // The required fields needed to build a new contact as required by
  // the object classes (can include additional fields not required by the object classes).
  'required_fields' => ['cn', 'sn', 'mail'],
  'search_fields'   => ['mail', 'cn', 'sn', 'displayName'],  // fields to search in
  // mapping of contact fields to directory attributes
  //   1. for every attribute one can specify the number of values (limit) allowed.
  //      default is 1, a wildcard * means unlimited
  //   2. another possible parameter is separator character for composite fields
  //   3. it's possible to define field format for write operations, e.g. for date fields
  //      example: 'birthday:date[YmdHis\\Z]'
  'fieldmap' => [
    // Roundcube  => LDAP:limit
    'name'        => 'cn',
    'surname'     => 'sn',
    'firstname'   => 'givenName',
    'jobtitle'    => 'title',
    'email'       => 'mail:*',
    'phone:home'  => 'homePhone',
    'phone:work'  => 'telephoneNumber',
    'phone:mobile' => 'mobile',
    'phone:pager' => 'pager',
    'phone:workfax' => 'facsimileTelephoneNumber',
    'street'      => 'street',
    'zipcode'     => 'postalCode',
    'region'      => 'st',
    'locality'    => 'l',
    // if you country is a complex object, you need to configure 'sub_fields' below
    'country'      => 'c',
    'organization' => 'o',
    'department'   => 'ou',
    'jobtitle'     => 'title',
    'notes'        => 'description',
    'photo'        => 'jpegPhoto',
    // these currently don't work:
    // 'manager'       => 'manager',
    // 'assistant'     => 'secretary',
  ],
  // Map of contact sub-objects (attribute name => objectClass(es)), e.g. 'c' => 'country'
  'sub_fields' => [],
  // Generate values for the following LDAP attributes automatically when creating a new record
  'autovalues' => [
    // 'uid'  => 'md5(microtime())',               // You may specify PHP code snippets which are then eval'ed
    // 'mail' => '{givenname}.{sn}@mydomain.com',  // or composite strings with placeholders for existing attributes
  ],
  'sort'           => 'cn',         // The field to sort the listing by.
  'scope'          => 'sub',        // search mode: sub|base|list
  'filter'         => '(objectClass=inetOrgPerson)',      // used for basic listing (if not empty) and will be &'d with search queries. example: status=act
  'fuzzy_search'   => true,         // server allows wildcard search
  'vlv'            => false,        // Enable Virtual List View to more efficiently fetch paginated data (if server supports it)
  'vlv_search'     => false,        // Use Virtual List View functions for autocompletion searches (if server supports it)
  'numsub_filter'  => '(objectClass=organizationalUnit)',   // with VLV, we also use numSubOrdinates to query the total number of records. Set this filter to get all numSubOrdinates attributes for counting
  'config_root_dn' => 'cn=config',  // Root DN to search config entries (e.g. vlv indexes)
  'sizelimit'      => '0',          // Enables you to limit the count of entries fetched. Setting this to 0 means no limit.
  'timelimit'      => '0',          // Sets the number of seconds how long is spend on the search. Setting this to 0 means no limit.
  'referrals'      => false,        // Sets the LDAP_OPT_REFERRALS option. Mostly used in multi-domain Active Directory setups
  'dereference'    => 0,            // Sets the LDAP_OPT_DEREF option. One of: LDAP_DEREF_NEVER, LDAP_DEREF_SEARCHING, LDAP_DEREF_FINDING, LDAP_DEREF_ALWAYS
                                    // Used where addressbook contains aliases to objects elsewhere in the LDAP tree.

  // definition for contact groups (uncomment if no groups are supported)
  // for the groups base_dn, the user replacements %fu, %u, %d and %dc work as for base_dn (see above)
  // if the groups base_dn is empty, the contact base_dn is used for the groups as well
  // -> in this case, assure that groups and contacts are separated due to the concerning filters!
  'groups'  => [
    'base_dn'           => '',
    'scope'             => 'sub',       // Search mode: sub|base|list
    'filter'            => '(objectClass=groupOfNames)',
    'object_classes'    => ['top', 'groupOfNames'],   // Object classes to be assigned to new groups
    'member_attr'       => 'member',   // Name of the default member attribute, e.g. uniqueMember
    'name_attr'         => 'cn',       // Attribute to be used as group name
    'email_attr'        => 'mail',     // Group email address attribute (e.g. for mailing lists)
    'member_filter'     => '(objectclass=*)',  // Optional filter to use when querying for group members
    'vlv'               => false,      // Use VLV controls to list groups
    'class_member_attr' => [      // Mapping of group object class to member attribute used in these objects
      'groupofnames'       => 'member',
      'groupofuniquenames' => 'uniquemember'
    ],
  ],
  // this configuration replaces the regular groups listing in the directory tree with
  // a hard-coded list of groups, each listing entries with the configured base DN and filter.
  // if the 'groups' option from above is set, it'll be shown as the first entry with the name 'Groups'
  'group_filters' => [
    'departments' => [
      'name'    => 'Company Departments',
      'scope'   => 'list',
      'base_dn' => 'ou=Groups,{{ ldap_base_dn }}',
      'filter'  => '(|(objectclass=groupofuniquenames)(objectclass=groupofurls))',
      'name_attr' => 'cn',
    ],
    'customers' => [
      'name'    => 'Customers',
      'scope'   => 'sub',
      'base_dn' => 'ou=Customers,{{ ldap_base_dn }}',
      'filter'  => '(objectClass=inetOrgPerson)',
      'name_attr' => 'sn',
    ],
  ],
];

$config['autocomplete_addressbooks'] = ['sql', 'global_addressbook'];
