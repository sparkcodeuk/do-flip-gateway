# do-flip-gateway - Digital Ocean Floating IP Gateway

A quick & easy way to get your droplet's outbound traffic going through your
floating IP rather than its default assigned IP address.


## Why would you want to do this?

If you're running something like a VPN on Digital Ocean, it's better if you
just have everything running from & to a single known address.

Personal VPNs (those accessed by one or a few users) are very useful for
accessing private networks & systems that are locked down to specific IPs,
especially when you're travelling or do not have a static IP address at work or
home.


## Installation

NOTE: I've only tested this on rancher OS but should work on other linuxes with
docker installed.

* [Setup your OpenVPN container and check you can connect to it ok](https://hub.docker.com/r/kylemanna/openvpn/)

* Check you have assigned a floating IP to your VPN droplet

* Hit a site which will show you your current IP address
(http://ipv4.sparkcode.co.uk/), this should show the default droplet IP and
*not* the floating IP you assigned to it

* Pull down this docker image and run a quick test on your instance. I would
recommend taking a backup of your droplet first just for safety

```
docker pull sparkcode/do-flip-gateway
docker run --rm --name do-flip-gateway --cap-add=NET_ADMIN --privileged --network host sparkcode/do-flip-gateway
```

* You should see some output like this:

```
Setting floating IP as the default gateway: Done.
```

* Check what the outbound IP address is show up as now, it should if working
correctly, be your assigned floating IP

* If you're using RancherOS you can set this command to run on boot along with
OpenVPN automatically:

**/var/lib/rancher/conf/do-flip-gateway.yml**:
```
---
do-flip-gateway:
  image: sparkcode/do-flip-gateway
  privileged: true
  net: "host"
  restart: "no"
```

```
sudo ros service enable /var/lib/rancher/conf/do-flip-gateway.yml
sudo ros service list
```

(it should report as an entry in the list `enabled  /var/lib/rancher/conf/do-flip-gateway.yml`)

* You will want to setup OpenVPN to start on boot as well:

**/var/lib/rancher/conf/openvpn.yml**:
```
---
openvpn:
  image: kylemanna/openvpn
  name: openvpn
  cap_add:
    - "NET_ADMIN"
  ports:
    - "1194:1194/udp"
  volumes:
    - "/home/rancher/openvpn/openvpn-data:/etc/openvpn"
  restart: always
```

NOTE: The host volume location `/home/rancher/openvpn/openvpn-data` will depend
on where your openvpn data directory is located on your droplet.

```
sudo ros service enable /var/lib/rancher/conf/openvpn.yml
sudo ros service list
```

* Once that's all setup, reboot your droplet and after it's back up, check your
networking sorted itself out automatically, OpenVPN launched ok and that your
IP address is that of your floating IP
