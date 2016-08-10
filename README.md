# rock3tman
Quick script to set up VPN server and reverse VPN for Nethunter

## Usage
```bash
root@kali:~# ./rocketman.sh 
Usage: rocketman.sh [-arg]
                           *     .--.
                                 / / 
                +               | |
                                 \ \_
                   *          +   --  *
                       +   /\
          +              . .   *
                 *      /======\      +
                       ;:.  _   ;
                       |:. (_)  |
                       |:.  _   |
             +         |:. (_)  |          *
                       ;:.      ;
                      / \:.    /  \.
                    / .---:._./--. \
                    |/    /||\    \|
                 _..--"""````"""--.._
            _.- -._
          - -
oiP9rrk22W2KsD98PMxZ9g/3XpgNLOWrmNMQzNyeG7I11nlNhlfAKBFpQBionmvBjinGEVm/9Gr
08ctvPpi+LroIxT4wdNk9zddLfDQ8fVg=

Don't forget to edit variables in rocketman.sh!

-s, --server     : Build a OpenVPN Server with client ovpn
-c, --client     : Build a client OVPN file only
-r, --reverse    : Set up your routes/iptables for reverse VPN on server
-f, --flush      : Flush your IPTables
-n, --nethunter  : Set up Nethunter Reverse VPN
-h, --help       : Help Menu (this)
--start-server   : Start OpenVPN server
```

## Instructions

```bash
cd ~
wget https://raw.githubusercontent.com/binkybear/rock3tman/master/rocketman.sh
chmod +x rocketman.sh
# Edit rocketman.sh with either nano/vi/leafpad/etc
./rocketman.sh
```

### Server Side

Before starting, make sure to set up variables on server side on something like a VPS, using:

```bash
./rocketman -s
```

After OpenVPN is installed you can run the server with:
```bash
./rocketman --start-server
```
This will set up your iptables and start OpenVPN.  You will need to add a route to the local network using the generated command from script after the client has connected.

### Nethunter Side

Add the ovpn file your android device and rocketman.sh inside Kali (chroot).  Download script using instructions above.  
```bash
./rocketman --nethunter 
```
This SHOULD initiate the VPN connection.

### TODO

Make sure it works!  Routing is the biggest issue.
