# fschl dotfiles


**Notice:** this repository is not maintained on Github! For a more recent version check https://gitlab.com/fschl/dotfiles

some stuff that makes my linux life more portable and comfortable.
for debian, or debian-based distros. using i3wm.org on the desktop.
also uses containers.

strongly inspired by awesome work by https://github.com/jessfraz

## Notes


### Security

#### Hardening ssh

- https://blog.g3rt.nl/upgrade-your-ssh-keys.html
- https://stribika.github.io/2015/01/04/secure-secure-shell.html
- https://wiki.mozilla.org/Security/Guidelines/OpenSSH#OpenSSH_client
- see `/etc/ssh/ssh_config` and `.ssh/config`

add this to `~/.ssh/config`:

```bash
# Ensure KnownHosts are unreadable if leaked - it is otherwise easier to know which hosts your keys have access to.
HashKnownHosts yes
# Host keys the client accepts - order here is honored by OpenSSH
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa,ecdsa-sha2-nistp521-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256

KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
```

*generating keys*

```bash
# RSA keys are favored over ECDSA keys when backward compatibility ''is required'',
# thus, newly generated keys are always either ED25519 or RSA (NOT ECDSA or DSA).
$ ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_host_$(date +%Y-%m-%d) -C "Key to HOST for user-xyz"

# ED25519 keys are favored over RSA keys when backward compatibility ''is not required''.
# This is only compatible with OpenSSH 6.5+ and fixed-size (256 bytes).
$ ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_host_$(date +%Y-%m-%d) -C "Key to HOST for user-xyz"
```

#### GnuPG

- https://wiki.mozilla.org/Security/Key_Management

`~/.gnupg/gpg.conf`:

```
# from https://wiki.mozilla.org/Security/Key_Management
personal-digest-preferences SHA512 SHA384
cert-digest-algo SHA256
default-preference-list SHA512 SHA384 AES256 ZLIB BZIP2 ZIP Uncompressed
keyid-format 0xlong
```

## TODO

- [ ] explain setup, ideas, practises
- [ ] add HOWTO
- [ ] seperate sources.list setup for server/desktop
