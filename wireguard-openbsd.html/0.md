### Introduction

WireGuard is a new, widely supported, and performant VPN connection protocol. WireGuard has proven to be simpler, more efficient (particularly in topics ping time and bandwidth), and more lightweight than its competitors. This tutorial shows how to set up a running WireGuard VPN server on OpenBSD.

* WireGuard is a peer-to-peer (site-to-site) protocol, this tutorial creates client configuration (which specifies server) on client and server configuration (which defines peers) on the server-side.
* WireGuard uses UDP ports to transmit encrypted IP packets, this tutorial creates firewall UDP rules using OpenBSD's default firewall PF (Packet Filter) for security on the server-side.

### 2. Configure Doas

If Doas configuration and a **non-root** user are already present on the server, skip this part.

    # echo "permit keepenv :wheel" > /etc/doas.conf

This configuration allows users in the **wheel** group to run shell commands as root while maintaining their environment variables.

### 3. Add a User

It is not advisable to use a root account while following this tutorial. Create a **non-root** user if not already present. If a **non-root** account already exists, please skip this section.

    # useradd -m example_user
    # user mod -G wheel example_user
    # passwd example_user

These commands create a user named `example_user`, add that user to a group `wheel`, and set a password for user `example_user`. It is suggested continuing the tutorial with this user or any other user without root privileges.

### 3. Install Required Software

Set up the package repository for OpenBSD.

    $ echo "https://cdn.openbsd.org/pub/OpenBSD" | doas tee /etc/installurl

Install required packages as root.

    $ doas pkg_add wireguard-tools

### 4. Enable IP Forwarding

Enable IPv4 and IPv6 forwarding.

    $ doas sysctl net.inet.ip.forwarding=1
    $ doas sysctl net.inet6.ip6.forwarding=1

To make them persistent on reboot:

    $ echo "net.inet.ip.forwarding=1" | doas tee -a /etc/sysctl.conf
    $ echo "net.inet6.ip6.forwarding=1" | doas tee -a /etc/sysctl.conf

### 5. Create Secret and Public Keys on Server

Create `/etc/wireguard` directory.

Make a directory in `/etc/wireguard` if not exist.

    $ doas mkdir -p /etc/wireguard

Generate keys:

1. Generate secret key and write that key to `/etc/wireguard/server-secret.key`

        $ wg genkey | doas tee -a /etc/wireguard/server-secret.key

2. Generate public key related to the secret key and write that key to `/etc/wireguard/server-public.key`

        $ doas cat /etc/wireguard/server-secret.key | wg pubkey | doas tee -a /etc/wireguard/server-public.key

Adjust permissions of secret key:

Set the permissions for `/etc/wireguard/server-secret.key` to `600`, so only the owner has complete read and write access to that file. Since the `root` created this file, only the `root` will access the secret key.

    $ doas chmod 600 /etc/wireguard/server-secret.key

### 6. Configure WireGuard on Server

Create `/etc/wireguard/wg0.conf`:

    # server
    [Interface]
    PrivateKey = <server-secret-key>
    ListenPort = 51820 # UPD listen port, it is welcome to specify other than this one.

    # first peer (client)
    [Peer]
    PublicKey = <client-public-key>
    AllowedIPs = 10.0.0.2/24

Replace `<server-secret-key>` with key we saved in `/etc/wireguard/server-secret.key` file, leave `<client-public-key>` for now until we create client public key.

It is possible to define the desired number of peers in this file with different IPs and keys.

Remember to replace `<client-public-key>` after you've generated the first client's public key in section 9. Otherwise, WireGuard will not accept this invalid configuration.

### 7. Configure wg0 Device on Server

Create `/etc/hostname.wg0`:

    inet 10.0.0.1 255.255.255.0 NONE
    up

    !/usr/local/bin/wg setconf wg0 /etc/wireguard/wg0.conf

WireGuard device wg0 with IP **10.0.0.1**. Ping this IP from client machines for testing when we set up clients.

### 8. Configure Firewall on Server Side

Ensure that the default firewall configuration file is saved.

    $ doas cp /etc/pf.conf /etc/pf.conf.bak

Create `/etc/pf.conf`:

    # declare tcp ports we use
	tcp_services = "{ ssh }"

    # add wireguard UDP port specified on server configuration
	udp_services = "{ 51820 }"

	# skip on wg0 device and local network
    set skip on { lo wg0 }

	# first block all
    block all

	# then pass on TCP and UDP service ports we specified
    pass in on egress proto tcp to port $tcp_services
    pass in on egress proto udp to port $udp_services

    # below line allows peers to access the internet, remove to prevent this.
    pass out quick on egress from wg0:network to any nat-to (egress)

    # allow all out
    pass out

### 9. Client Set up

WireGuard is available on a range of platforms, such as; iOS, Linux, Android, Windows, OpenBSD, and FreeBSD. A client can be on one of these. For the sake of the simplicity of this tutorial, we will not be too specific while configuring the client, but we recommend adjusting the client's firewall for security. Consider checking your client's operating system documentation.

#### 1. Client Key Generation

Generating a private and public key is identical to generating a server key. But this time we name keys as `client-secret.key` and `client-public.key`.

1. Generate secret key and write that key to `/etc/wireguard/client-secret.key`.

        # wg genkey | tee -a /etc/wireguard/client-secret.key

2. Generate public key related to the secret key and write that key to `/etc/wireguard/client-public.key`

        # cat /etc/wireguard/client-secret.key | wg pubkey | tee -a /etc/wireguard/client-public.key

#### 2. Client Configuration

Replace `<client-secret-key>` with secret client key, `<server-public-key>` with the key saved in `/etc/wireguard/server-public.key`, `<server-IPv4>` with server's IPv4 address, and `<server-port>` with UDP port we specified in firewall and `wg0` configuration on the server machine.

    # this is the client.
    [Interface]
    PrivateKey = <client-secret-key>
    Address = 10.0.0.2/24

    # this is server
    [Peer]
    PublicKey = <server-public-key>
    Endpoint = <server-IPv4>:<server-port>
    AllowedIPs = 0.0.0.0/0, ::/0

### 10. Final

Set up wg0 device on the server.

    $ doas sh /etc/netstart wg0

Reload our firewall on the server.

    $ doas pfctl -f /etc/pf.conf

Set up and enable wg0 device on the client.

    # wg-quick up wg0

Let's try to ping the server from the client machine.

    $ ping 10.0.0.1

All done! If packets are transmitting and receiving, that means everything works fine! Otherwise, review the configurations and issued commands and their arguments carefully again. For more information, check the section below of this article.

### Extra: Create QR Code Configuration For Mobile Clients

It could be useful to create QR codes for easy deploying ideals, especially for mobile clients. Use **qrencode** (available as **libqrencode** package on OpenBSD) to convert WireGuard configurations into QR codes.

    $ doas echo /etc/wireguard/wg0.conf | qrencode -t ansiutf8

This prints out configuration as a QR code to **stdout**. Since official mobile WireGuard clients support QR code reading for adding configurations, you can use this QR code to configure the client quickly.

### Extra: DNS

To prevent DNS leaks on the client-side, we recommend using a local DNS resolver (e.g., unbound, unwind, etc.).

On the server-side:

Install unbound DNS resolver.

    $ doas pkg_add unbound

Configure unbound DNS:

	server:

	    # Logging
	    verbosity: 1
	    log-queries: yes

	    # Respond to DNS requests on all interfaces
	    interface: 0.0.0.0

	    # IP Authorization
	    access-control: 0.0.0.0/0 refuse
	    access-control: ::/0 refuse

	    access-control: 127.0.0.1 allow
	    access-control: ::1 allow

		    # WireGuard Peer
	    access-control: 10.0.0.2/24 allow

	    # Hide DNS Server info
	    hide-identity: yes
	    hide-version: yes

	    # Limit DNS Fraud and use DNSSEC
	    harden-glue: yes
	    harden-dnssec-stripped: yes
	    harden-referral-path: yes

	    # Add an unwanted reply threshold to clean the cache and avoid when possible a DNS Poisoning
	    unwanted-reply-threshold: 10000000

	    # Have the validator print validation failures to the log.
	    val-log-level: 1

	    # Minimum lifetime of cache entries in seconds
	    cache-min-ttl: 1800

	    # Maximum lifetime of cached entries
	    cache-max-ttl: 14400
	    prefetch: yes
	    prefetch-key: yes

On the client-side:

Adjust client nameserver to WireGuard server.

    $ cat /etc/resolv.conf
	nameserver 10.0.0.1

### Extra: Post-Quantum Security

Clients and servers exchange public and secret keys in the WireGuard protocol handshake. The problem is that WireGuard key encryption can be vulnerable to quantum computer attacks. Unfortunately, post-quantum resistance for WireGuard handshaking is still under development and consideration. However, adding a shared key to both client and server configurations protects servers and clients from post-quantum attacks.

On the server-side:

    $ wg genpsk | doas tee /etc/wireguard/shared.key

Add this key to server and client configuration:

Server-side:

    # this is the server
    [Interface]
    PrivateKey = <server-secret-key>
    ListenPort = 51820 # This is the UPD port to which WireGuard will listen. It is welcome to specify other than this one.

    # this is first peer (client)
    [Peer]
    PublicKey = <client-public-key>
    AllowedIPs = 10.0.0.2/24
	PreSharedKey = <shared-key>

Client-side:

    # this is the client.
    [Interface]
    PrivateKey = <client-secret-key>
    Address = 10.0.0.2/24

    # this is the server
    [Peer]
    PublicKey = <server-public-key>
    Endpoint = <server-IPv4>:<server-port>
    AllowedIPs = 0.0.0.0/0, ::/0
	PreSharedKey = <shared-key>

Replace `<shared-key>` with the key we saved in `/etc/wireguard/shared.key`.

Now servers and clients are not vulnerable to post-quantum attacks.

### More Information

* https://www.wireguard.com/
* https://www.openbsd.org/faq/pf/
* https://eprint.iacr.org/2020/379.pdf
