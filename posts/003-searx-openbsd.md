### Introduction

A metasearch engine queries other web search engines to produce its results. It allows users to use multiple search engines simultaneously with privacy. Searx is one of the best and actively developing metasearch engines. It uses Morty as a web content sanitizer proxy and Filtron for reverse HTTP proxy.

This tutorial presents how to host a running Searx instance using Gunicorn and Nginx on OpenBSD.

### 1. Create DNS Records

#### Make Sure Domain Points to Server

Replace corresponding parts with your server's IPv4 and IPv6 addresses. If IPv6 is disabled on the server, do not create **AAAA** (or **A** if your server is only IPv6). If both IPv6 and IPv4 addresses are present on the server and these records are not already existent in the domain's DNS zone, create both **A** and **AAAA** records.

```
A <ipv4-adress-of-server> <ttl> <priority>
AAAA <ipv6-adress-of-server> <ttl> <priority>
```

#### Create a Subdomain (optional)

It is common to host Searx instance under a subdomain (e.g., `subdomain.example.com` or `searx.example.com` **instead of** `example.com`), specifically if the main domain serves something else (e.g., your main website).

Let's create DNS records for the subdomain, don't forget to replace the corresponding parts.

```
A <subdomain> <ipv4-adress-of-server> <ttl> <priority>
AAAA <subdomain> <ipv6-adress-of-server> <ttl> <priority>
```

Remember, it can take a while for DNS records to get active.

### 2. Configure Doas

If Doas configuration and a **non-root** user are already present on the server, skip this part.

```
# echo "permit keepenv :wheel" > /etc/doas.conf
```

This configuration allows users in the `wheel` group to run shell commands as root while maintaining their environment variables.

### 3. Add a User

It is not advisable to use a root account while following this tutorial. Create a non-root user if not already present. If a non-root account already exists, please skip this section.

```
# useradd -m example_user
# user mod -G wheel example_user
# passwd example_user
```

These commands create a user named `example_user`, add that user to a group `wheel`, and set a password for user `example_user`. It suggested continuing the tutorial with this user or any other user without root privileges.

Login as `example_user`:

```
# su example_user && cd
```

cd command without argument changes directory to `example_user`'s home directory.

### 4. Install Required Software

Set up the package repository for OpenBSD.

```
$ echo "https://cdn.openbsd.org/pub/OpenBSD" | doas tee /etc/installurl
```

Install required packages as root.

```
$ doas pkg_add nginx python-3.8.12 py3-pip git py3-lxml go
```

Use pip 3.8 as default pip:

```
$ doas ln -s /usr/local/bin/pip3.8 /usr/local/bin/pip
```

Use python-3.8.12 as default python:

```
$ doas ln -s /usr/local/bin/python3.8 /usr/local/bin/python
```

Install Gunicorn using pip.

```
$ doas pip install gunicorn
```

Install Filtron and Morty.

```
$ go get github.com/asciimoo/filtron
$ go get github.com/asciimoo/morty
$ doas ln -sf $HOME/go/bin/filtron /usr/local/bin/
$ doas ln -sf $HOME/go/bin/morty /usr/local/bin/
```

### 5. Configure Filtron

Create `/etc/filtron` directory if not present and copy default configuration to `/etc/filtron`.

    $ doas mkdir -p /etc/filtron
    $ doas cp $HOME/go/pkg/mod/github.com/asciimoo/filtron@v0.2.0/example_rules.json /etc/filtron/rules.json

Check the section below of this tutorial for information about further configuration. This tutorial uses the default configuration for the sake of simplicity.

### 6. Add _searx, _filtron, and _morty Users

Create user `_searx`.

```
$ doas mkdir /usr/local/searx
$ doas useradd -d /usr/local/searx/ -s /sbin/nologin -u 10000 _searx
$ doas chown -R _searx:_searx /usr/local/searx/
```

Create user `_filtron`.

```
$ doas useradd -s /sbin/nologin -u 10001 _filtron
```


Create user `_morty`.

```
$ doas useradd -s /sbin/nologin -u 10002 _morty
```

Add login class for Morty below of `/etc/login.conf`:

```
morty:\
	:setenv=DEBUG=false,MORTY_ADDRESS=127.0.0.1\c3000,MORTY_KEY=<key generated with `openssl rand -base64 33`>:\
	:tc=daemon:
```

### 7. Install Searx

Clone Searx repo as `_searx` user and install its requirements via pip.

```
$ doas -u _searx git clone "https://github.com/searx/searx.git" \
  "/usr/local/searx/searx-src"
$ doas pip install -r /usr/local/searx/searx-src/requirements.txt
```

### 8. Configure Searx

Create a Searx configuration file and generate a secret key.

```
$ doas mkdir -p /etc/searx/
$ doas cp /usr/local/searx/searx-src/utils/templates/etc/searx/use_default_settings.yml /etc/searx/settings.yml
$ doas sed -i -e "s/ultrasecretkey/$(openssl rand -hex 16)/g" "/etc/searx/settings.yml"
```

See the section below of this article for information on further configuration. This tutorial uses the default configuration for the sake of simplicity.

### 9. Daemonize Searx, Morty, and Filtron

Let's create services to control metasearch engine, reverse proxy, and web content sanitizer.

Create `/etc/rc.d/gunisearx`:

```
#!/bin/ksh

RUN_DIR="/var/run/gunisearx"
daemon="/usr/local/bin/gunicorn"
gunisearx_flags="-b 127.0.0.1:8001 --chdir /usr/local/searx/searx-src/searx --pythonpath /usr/local/searx/searx-src -p /var/run/gunisearx/gunisearx.pid -D searx.webapp"
gunisearx_user="_searx"

. /etc/rc.d/rc.subr

pexp="/usr/local/bin/python.*${pexp}"

# For the PID file.
rc_pre() {
	if [[ ! -d /var/run/gunisearx ]]; then
		mkdir $RUN_DIR
		chown -R _searx:_searx $RUN_DIR
	fi
}

rc_stop() {
	if [[ -f $RUN_DIR/gunisearx.pid ]]; then
		kill $(cat $RUN_DIR/gunisearx.pid)
		rm $RUN_DIR/gunisearx.pid
	fi
}

rc_cmd $1
```

Create `/etc/rc.d/filtron`:

```
#!/bin/ksh

daemon="/usr/local/bin/filtron"
filtron_flags="-api '127.0.0.1:4005' -listen '127.0.0.1:4004' -rules '/etc/filtron/rules.json' -target '127.0.0.1:8001'"
filtron_user="_filtron"

rc_bg=YES

. /etc/rc.d/rc.subr

rc_cmd $1
```

Create `/etc/rc.d/morty`:

```
#!/bin/ksh

daemon="/usr/local/bin/morty"
morty_user="_morty"

rc_bg=YES

. /etc/rc.d/rc.subr

rc_cmd $1
```

Make them executable:

```
$ doas chmod +x /etc/rc.d/gunisearx /etc/rc.d/morty /etc/rc.d/filtron
```

### 10. Configure Firewall

Let's allow only TCP ports for **gunisearx**, **filtron**, and **morty** services and block rest for security.

Save the current configuration file of the firewall.

```
$ doas cp /etc/pf.conf /etc/pf.conf.bak && doas rm /etc/pf.conf
```

Create `/etc/pf.conf`:

```
# declare tcp ports enabled services use
tcp_services = "{ sshd, http, https }"

# skip on local network
set skip on { lo }

# blocks all
block all

# only lets in from specified tcp ports
pass in on egress proto tcp to port $tcp_services

# allow all out
pass out
```

### 11. Enable and Start Created Services

```
$ doas rcctl enable filtron morty gunisearx
$ doas rcctl start filtron morty gunisearx
```

### 12. Configure Nginx and Get an SSL Certificate

Let's get an SSL certificate for the subdomain using Let's Encrypt and OpenBSD's acme-client. While following this section, don't forget to replace `<subdomain>`; with the desired subdomain, and `<example.com>`; with your domain and its extension (e.g., .com, .net, .org).

Delete existing server block and create a temporary HTTP server block entry for your subdomain in `/etc/nginx.conf`.

```
[... simplified for demonstration ...]

http {

	[... simplified for demonstration ...]

    server {
      listen 80;
      listen [::]:80;
      server_name <subdomain>.<example.com>;

	  location /.well-known/acme-challenge/ {
          rewrite ^/.well-known/acme-challenge/(.*) /$1 break;
          root /acme;
      }

    }

	[... simplified for demonstration ...]
}
```

Start nginx service.

```
$ doas rcctl start nginx
```

Create `/etc/acme-client.conf` as follows:

```
authority letsencrypt {
  api url "https://acme-v02.api.letsencrypt.org/directory"
  account key "/etc/ssl/private/letsencrypt.key"
}

domain <subdomain>.<example.com> {
  alternative names { <subdomain>.<example.com> }
  domain key "/etc/ssl/private/<subdomain>.<example.com>.key"
  domain certificate "/etc/ssl/<subdomain>.<example.com>.crt"
  domain full chain certificate "/etc/ssl/<subdomain>.<example.com>.pem"
  sign with letsencrypt
}
```

Request certificates and keys of the subdomain from the Let's Encrypt authority.

```
$ doas acme-client -v <subdomain>.<example.com>
```

After successfully getting certificates, delete server block again and add this server block `/etc/nginx.conf`:

```
[... simplified for demonstration ...]

http {

	[... simplified for demonstration ...]

    server {
      listen 443 ssl;
      listen [::]:443 ssl;
      server_name <subdomain>.<example.com>;

        location / {
            proxy_pass         http://127.0.0.1:4004/;

            proxy_set_header   Host             $host;
            proxy_set_header   Connection       $http_connection;
            proxy_set_header   X-Real-IP        $remote_addr;
            proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
            proxy_set_header   X-Scheme         $scheme;
            proxy_set_header   X-Script-Name    /searx;
        }

        location /static/ {
                alias /usr/local/searx/searx-src/searx/static/;
        }

        location /morty {
                proxy_pass http://127.0.0.1:3000/;

                proxy_set_header   Host             $host;
                proxy_set_header   Connection       $http_connection;
                proxy_set_header   X-Real-IP        $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_set_header   X-Scheme         $scheme;
        }

        ssl_certificate /etc/ssl/<subdomain>.<example.com>.pem;
        ssl_certificate_key /etc/ssl/private/<subdomain>.<example.com>.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
	    ssl_ciphers ECDHE+AESGCM:DHE+AESGCM:ECDHE+ECDSA+AES+SHA256;

    }

    [... simplified for demonstration ...]
}
```

For security, it suggested migrating all HTTP traffic to HTTPS. Add this server block entry to `/etc/nginx.conf`.

```
server {
    listen 80 default_server;
    listen [::]:80;
    server_name _; # This matches with every domain.
    return 301 https://$host$request_uri;
}
```

Enable and restart nginx service.

```
$ doas rcctl enable nginx
$ doas rcctl restart nginx
```

All done! Searx instance now should be up and running. More information about OpenBSD's firewall, Filtron, Morty, and Searx is obtainable in the following section.

### More Information
* https://www.openbsd.org/faq/pf/
* https://searx.github.io/searx/admin/index.html
* https://searx.github.io/searx/admin/filtron.html
* https://github.com/asciimoo/morty
