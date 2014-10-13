Setting up virtual mail forwarding.

On the host OS:

Install postfix and setup mail forwarding:

http://www.binarytides.com/postfix-mail-forwarding-debian/

Open up port 25:

```
iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
iptables-save > /etc/iptables.conf
```

Example /etc/postfix/main.cf

```
myhostname = domain.tld
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = domain.tld, localhost, otherdomain.tld
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = localhost

virtual_alias_domains = otherdomain.tld
virtual_alias_maps = hash:/etc/postfix/virtual
inet_protocols = all
```

Final step is to check mail server is not an open relay!
