# rock3tman
Quick script to set up VPN server and reverse VPN for Nethunter


## Usage
```bash
root@kali:~# ./rocketman.sh 
Usage: rocketman.sh
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
oiP9rrk22W2KsD98PMxZ9g/3XpgNLOWrmNMQzNyeG7I11nlNhlfAKBFpQBionmvBjinGEVm/9Gr08ctvPpi+LroIxT4wdNk9zddLfDQ8fVg=
Don't forget to edit variables in rocketman.sh!

-s, --server     : Build a OpenVPN Server with client ovpn
-c, --client     : Build a client OVPN file only
-r, --reverse    : Set up your routes/iptables for reverse VPN on server
-f, --flush      : Flush your IPTables
-n, --nethunter  : Set up Nethunter Reverse VPN
--start-server   : Start OpenVPN server
```

Edit rocketman.sh variables to customize to your needs.

### Server Side

Set up a VPN on server, such as a VPS, using ./rocketman --server.  This will install openvpn/easy-rsa and generate keys and client ovpn file.  If you just want to build a client ovpn file ./rocketman --client.

### Nethunter

Add the ovpn file your android device and rocketman.sh inside Kali (chroot).  Run ./rocketman --nethunter and it will set up your VPN connection.

### TODO

Make sure it works!  Routing is the biggest issue.
