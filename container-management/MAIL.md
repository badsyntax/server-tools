http://ubuntuguide.org/wiki/Mail_Server_setup

We first need to update the MX records of the domain to point to the host server:

```
HOST         MAILSERVER HOSTNAME          MAIL TYPE        PRIORITY
@            mail.example.com             MX               1
mail         mail.example.com             MX               1
```

We also need create an A record for the mail subdomain:

```
mail         IN A       <x.x.x.x>
```

Forward ports:

```
iptables -t nat -A PREROUTING -p tcp -d <EXTERNAL_HOST_IP> -j DNAT --dport 1000 --to-destination <CONTAINER_IP>:25
```

Now we need to install postfix and dovcot in the container:

```bash
sudo apt-get install dovecot-postfix
```

Create cert links

```bash
sudo ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/ssl-mail.pem
sudo ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/ssl-mail.key
```

Ensure certs and keys are used by postfix:

Open up `/etc/postfix/main.cf` and ensure the following exists:

```
# TLS parameters
smtpd_tls_cert_file = /etc/ssl/certs/ssl-mail.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-mail.key
``` 

Adjust the following:

```
myhostname = example.com
mydestination = localhost, example.com
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
inet_interfaces = all
```

Open up `/etc/dovecot/conf.d/01-mail-stack-delivery.conf ` and sure `ssl = yes` exists

Check dovecot config:

```
dovecot -n
```

Which should show:

```
# 2.0.19: /etc/dovecot/dovecot.conf
# OS: Linux 3.11.0-19-generic x86_64 Ubuntu 12.04.5 LTS 
mail_location = maildir:~/Maildir
managesieve_notify_capability = mailto
managesieve_sieve_capability = fileinto reject envelope encoded-character vacation subaddress comparator-i;ascii-numeric relational regex imap4flags copy include variables body enotify environment mailbox date ihave
passdb {
  driver = pam
}
plugin {
  sieve = ~/.dovecot.sieve
  sieve_dir = ~/sieve
}
protocols = imap pop3 sieve
service auth {
  unix_listener /var/spool/postfix/private/dovecot-auth {
    group = postfix
    mode = 0660
    user = postfix
  }
}
ssl_cert = </etc/ssl/certs/dovecot.pem
ssl_cipher_list = ALL:!LOW:!SSLv2:ALL:!aNULL:!ADH:!eNULL:!EXP:RC4+RSA:+HIGH:+MEDIUM
ssl_key = </etc/ssl/private/dovecot.pem
userdb {
  driver = passwd
}
protocol imap {
  imap_client_workarounds = delay-newmail
  mail_max_userip_connections = 10
}
protocol pop3 {
  mail_max_userip_connections = 10
  pop3_client_workarounds = outlook-no-nuls oe-ns-eoh
}
protocol lda {
  deliver_log_format = msgid=%m: %$
  mail_plugins = sieve
  postmaster_address = postmaster
  quota_full_tempfail = yes
  rejection_reason = Your message to <%t> was automatically rejected:%n%r
}
```

Check postfix config:

```
postconf -n
```

Which should show:

```
alias_database = hash:/etc/aliases
alias_maps = hash:/etc/aliasess
append_dot_mydomain = no
biff = no
broken_sasl_auth_clients = yes
config_directory = /etc/postfix
home_mailbox = Maildir/
inet_interfaces = all
inet_protocols = all
mailbox_command = /usr/lib/dovecot/deliver -c /etc/dovecot/conf.d/01-mail-stack-delivery.conf -m "${EXTENSION}"
mailbox_size_limit = 0
mydestination = milos, localhost.localdomain, localhost, example.com
myhostname = example.com
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
myorigin = /etc/mailname
readme_directory = no
recipient_delimiter = +
relayhost =
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
smtp_use_tls = yes
smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
smtpd_recipient_restrictions = reject_unknown_sender_domain, reject_unknown_recipient_domain, reject_unauth_pipelining, permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
smtpd_sasl_auth_enable = yes
smtpd_sasl_authenticated_header = yes
smtpd_sasl_local_domain = $myhostname
smtpd_sasl_path = private/dovecot-auth
smtpd_sasl_security_options = noanonymous
smtpd_sasl_type = dovecot
smtpd_sender_restrictions = reject_unknown_sender_domain
smtpd_tls_auth_only = yes
smtpd_tls_cert_file = /etc/ssl/certs/ssl-mail.pem
smtpd_tls_key_file = /etc/ssl/private/ssl-mail.key
smtpd_tls_mandatory_ciphers = medium
smtpd_tls_mandatory_protocols = SSLv3, TLSv1
smtpd_tls_received_header = yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtpd_use_tls = yes
tls_random_source = dev:/dev/urandom
```


Troubleshooting

Check logs: `tail -f  /var/log/mail.log`
