# Kali VPN of DOOM
Quick script to set up VPN server and reverse VPN for Nethunter

## Usage
```bash
Usage: ./doom.sh [-arg]

 _  __       _  _  __      __ _____   _   _           __   _____    ____    ____   __  __  
 | |/ /      | |(_) \ \    / /|  __ \ | \ | |         / _| |  __ \  / __ \  / __ \ |  \/  |
 | ^ /  __ _ | | _   \ \  / / | |__) ||  \| |   ___  | |_  | |  | || |  | || |  | || \  / |
 |  <  / _` || || |   \ \/ /  |  ___/ | . ` |  / _ \ |  _| | |  | || |  | || |  | || |\/| |
 | . \| (_| || || |    \  /   | |     | |\  | | (_) || |   | |__| || |__| || |__| || |  | |
 |_|\_\\__,_||_||_|     \/    |_|     |_| \_|  \___/ |_|   |_____/  \____/  \____/ |_|  |_|


Don't forget to edit variables in ./doom.sh!

-s, --server     : Build a OpenVPN Server with client ovpn
-c, --client     : Build a client OVPN file only
-r, --reverse    : Set up your routes/iptables for reverse VPN on server
-f, --flush      : Flush your IPTables
-n, --nethunter  : Set up iptables for Nethunter Reverse VPN
-h, --help       : Help Menu (this)
--start-server   : Start OpenVPN server
```

## Instructions

```bash
cd ~
wget https://raw.githubusercontent.com/binkybear/rock3tman/master/doom.sh
chmod +x doom.sh
# Edit doom.sh with either nano/vi/leafpad/etc
./doom.sh
```

### Server Side

Before starting, make sure to set up variables in script. Using a publicly routable server (e.g. VPS), set up the VPN server:

```bash
./doom.sh -s
```

After OpenVPN is installed you can run the server with:
```bash
./doom.sh --start-server
```
This will set up your iptables/routes and start OpenVPN.

### Nethunter Side

Download and install OpenVPN client for Android.  You can get from either Google Play store or Fdroid:

https://f-droid.org/repository/browse/?fdid=de.blinkt.openvpn
or
https://play.google.com/store/apps/details?id=de.blinkt.openvpn&hl=en

Get ovpn file off the server and download it to your phone/tablet.  Inside application add the ovpn file and connect.

For additional routing inside kali chroot:

Download script using instructions above.  
```bash
./doom.sh --nethunter 
```
### TODO

Fix routing!  Right now it can only see private IP of client (not subnet).
