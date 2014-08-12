http://ubuntuguide.org/wiki/Mail_Server_setup

We first need to update the MX records of the domain to point to the host server.

```
HOST           MAILSERVER HOSTNAME          MAIL TYPE          MX PREF          TTL

 @             mail.example.com              MX                 10               1800
 mail         mail.example.com              MX                 10               1800
```
