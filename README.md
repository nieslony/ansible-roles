# Ansible Roles

A collection of ansible roles. Most of the roles require a membership in a FreeIPA
domain. The can be applied in _The Foreman_ or in a
[Vagrant based Test Environment](https://github.com/nieslony/test_environment).

- [802.1x_Network](802.1x_Network/README.md) creates a wifi connection with
  certificate based radius authentification for NetworkManager

- [arachnecdl](arachnecdl/README.md) installs and configures ArachneConfigDownloader. See
  https://github.com/nieslony/arachne and
  https://github.com/nieslony/arachne-config-downloader

- [autofs](autofs/README.md) activates and configures automounter with FreeIPA
  source

- [cockpit](cockpit/README.md) installs and configures cockpit with Kerberos
  authentication

- [default_packages](decault_packages) installs packages useful for servers and
  desktops

- [developer-workstation](developer-workstation/README.md) installs a lot of
  developer packages and configures libvirt as a extension for [gui](gui)

- [etckeeper](etckeeper/README.md) installs etckeeper

- [evolution](evolution/README.md) installs evolution as client for
  [mailserver](mailserver) with preconfigured connections

- [fileserver](fileserver/README.md) installs a fileserver with SMB and NFSv4
  access

- [gerbera](gerbera/README.md) installs a media server with gerbera

- [gui](gui/README.md) installs a desktop with Gnome and KDE Plasma. You should
  also add [zzz-finished](zzz-finished) as the very last role to start the
  display manager

- [mailserver](mailserver/README.md) installs a mailserver with postfix, amavis,
  Cyrus Imapd, nextcloud

- [minidlna](minidlna/README.md) installs a media server with minidlna

- [printserver](printserver/README.md) installs a CUPS based print server with
  SSL certificates and Kerberos authentication

- [radiusserver](radiusserver/README.md) installs a radius server for
  [802.1x_Network](802.1x_Network)

- [thunderbird](thunderbird/README.md) installs thunderbird as a client for
  [mailserver](mailserver) with preconfigured connections. Please note:
  thunderbird does __not__ support Kerberos authentication for CardDAV and
  CalDAV, so evolution is preferred

- [webserver](webserver/README.md) install Apache as webserver with certificates
  provides by FreeIPA and Kerberos authentication

- [zzz-finished](zzz-finished/README.md) the very last step in a foreman based
  desktop installation
