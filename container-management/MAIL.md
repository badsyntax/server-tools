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

Open up `/etc/dovecot/conf.d/10-ssl.conf` and sure `ssl = yes` exists

Troubleshooting

Check logs: `tail -f  /var/log/mail.log`
