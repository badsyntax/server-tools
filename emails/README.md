# Emails

## Overview

The mail server sits on the backup box. I use https://mailinabox.email/

postfix is installed as a satelite system on the main host server and from within the containers.

The following instructions for setting up postfix relay are taken from: https://mailinabox.email/advanced-configuration.html

Run `sudo apt-get install postfix` and choose “Satellite system” when prompted.

Append the following seven lines to `/etc/postfix/main.cf`:

```
mydestination =
smtp_tls_security_level = verify
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/relay_password
smtp_sasl_tls_security_options = 
```

Write credentials in the following form to `/etc/postfix/relay_password` (substitute the second and third values with credentials for a freshly created account on the Mail-in-a-Box, and the first with the hostname of your Mail-in-a-Box):

`yourmailinabox.yourdomain relayusername:relaypassword`

If the remote machine only needs to be able to send mail from one address you should just use that address as the relay username.

If the remote machine needs to be able to send mail from multiple addresses, the relay username can be anything, as you will need to separately authorize it to send from those addresses. This is done by creating mail-forward aliases which include the relay username in the alias's permitted senders field (select the "I’ll enter the mail users that can send mail claiming to be from the alias address." option in the aliases UI).

Create regular mail-forward aliases for each address that the remote machine needs to be able to send from if you know those addresses in advance.
Create catch-all mail-forward aliases for each domain that the remote machine needs to be able to send from if you do not know which addresses on that domain the remote machine will need to send as.
chmod the password file to 600 (`sudo chmod 600 /etc/postfix/relay_password`), run `sudo postmap /etc/postfix/relay_password` and then reload postfix (sudo service postfix reload)
