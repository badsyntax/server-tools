#NODEJS CONTAINER

Create a new base container based off our ubuntu-base container:

```
lxc-clone -s -o ubuntu-base -n ubuntu-nodejs
```

Check the zfs partitions have been created correctly:

```
zfs list
```

Now start and log into the ubunt-nodejs container:

```
lxc-start -n ubuntu-nodejs -d
lxc-console -n ubuntu-nodejs
```

Start new shell as root user:

```
sudo -s
```

Install node.js:

```
add-apt-repository ppa:chris-lea/node.js
apt-get update
apt-get install nodejs -y
```

It's a good idea to install nginx to proxy requests to different ports. This allows you to run multiple node.js applications within the same container. Nginx is also better at serving static files.

```
apt-get install nginx -y
```

Create a new nginx host:

```
vi /etc/nginx/sites-available/myapp
```

Add the following:

```
upstream app_myapp {

  server 127.0.0.1:9000 max_fails=0 fail_timeout=10s weight=1;

  # Send visitors back to the same server each time.
  ip_hash;

  # Enable number of keep-alive connections.
  keepalive 512;
}

server {

  listen 80;

  # Index files.
  index index.html;

  # Domain names.
  # Make sure to set the A Record on your domain's DNS settings to your server's IP address.
  # You can test if was set properly by using the `dig` command: dig yourdomain.com
  server_name myapp.tld www.myapp.tld;

  access_log /var/log/nginx/myapp.access.log;
  error_log /var/log/nginx/myapp.error.log;

  # Timeout for closing keep-alive connections.
  keepalive_timeout 10;

  # Enable gzip compression.
  gzip on;
  gzip_http_version 1.1;
  gzip_vary on;
  gzip_comp_level 6;
  gzip_proxied any;
  gzip_buffers 16 8k;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";

  # Max upload size.
  # client_max_body_size 16M;

  # Custom error page.
  # error_page 404 maintenance.html;
  # error_page 500 502 503 504 maintenance.html;

  # location /maintenance.html {
  #  root /var/www;
  # }

  location / {
    # Set this to your upstream module.
    proxy_pass http://app_myapp;
    # Proxy headers.
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $host;
    proxy_set_header X-NginX-Proxy true;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_cache_bypass $http_upgrade;
    proxy_http_version 1.1;
    proxy_redirect off;
    # Go to next upstream after if server down.
    proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
    proxy_connect_timeout 5s;
    # Gateway timeout.
    proxy_read_timeout 20s;
    proxy_send_timeout 20s;
    # Buffer settings.
    proxy_buffers 8 32k;
    proxy_buffer_size 64k;
  }

  # Enable caching of static files.
  # location ~* \.(css|js|gif|jpe?g|png)$ {
  #  expires 168h;
  #  add_header Pragma public;
  #  add_header Cache-Control "public, must-revalidate, proxy-revalidate";
  # }

  # Don't cache html files.
  # location ~* \.html$ {
  #  expires -1;
  # }

  # Serve static files without going through upstreams
  #location ~ ^/(images/|img/|javascript/|js/|css/|stylesheets/|flash/|media/|static/|robots.txt|humans.txt|favicon.ico) {
  #  root /home/edwin/projects/sites/edwin.proxima.cc/public;
  #  access_log off;
  #  expires 1h;
  #}

}
```

Symlink the host to enable it:

```
ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
```

Test the config:

```
nginx -t
```

Restart nginx:

```
service nginx restart
```

##Container config

###Auto-start node.js apps on boot

Create a new upstart file:

```
vi /etc/init/node_apps.conf
```

Add the following (change <user>):

```
start on startup

script
        su <user> -c "forever start /home/<user>/Projects/myapp.co/app.js"
        su <user> -c "forever start /home/<user>/Projects/myotherapp.co/app.js"
end script
```
