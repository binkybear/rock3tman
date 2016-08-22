#!/bin/bash
#
#
# Made by @_binkybear to more easily set up a reverse VPN
#
# Instructions:
#
# To run: chmod +x && ./doom.sh [argument]
# 0) Edit the variables in this file.  You must know private IP range on reverse vpn side.
# 1) Generate the server by running ./doom.sh -s
# 2) Start server (must have ip/port open to internet): ./doom.sh --start-server
# 3) Copy ovpn file to device 
# 4) Load ovpn using openvpn or app
#
#####################
#     VARIABLES     #
#####################
INSTALLDIR=$HOME                            # Install dir for client keys (default is OK)

SERVER_IP="127.0.0.1"                       # Put in public IP of OpenVPN server (should not be localhost)
SERVER_PORT="443"                           # Port for OpenVPN server to listen on
SERVER_PROTOCOL="tcp"                       # tcp or udp
SERVER_INTERFACE="eth0"                     # Interface of OpenVPN server

CLIENT_KEYNAME="doom"                       # Generate client OVPN file (filename).ovpn [default: doom.ovpn]
CLIENT_IP="10.8.0.200"                      # Specify Client IP in 10.8.0.0/24 range (10.8.0.1-10.8.0.254) [default: 10.8.0.200]

TARGET_CIDR="192.168.1.0/24"                # CIDR of target network
TARGET_RANGE="192.168.1.0 255.255.255.0"    # Specify CIDR (should match above)

NETHUNTER_INTERFACE="wlan0"                 # Interface used to connect to internet on Nethunter

#####################
#     PRECHECK      #
#####################
#
# 5532686C494842685932746C5A434274655342695957647A4947786863335167626D6C6E614851734948427
# 95A575A736157646F644170615A584A76494768766458497349473570626D5567595335744C677042626D51
# 675353647449476476626D356849474A6C494768705A32674B51584D67595342726158526C49474A3549485
# 26F5A57344B

# Make sure we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "** Please run this as root **"
   exit
fi

def_help(){
    echo "Usage: $0 [-arg]"
    echo ""
    echo ' _  __       _  _  __      __ _____   _   _           __   _____    ____    ____   __  __  '
    echo ' | |/ /      | |(_) \ \    / /|  __ \ | \ | |         / _| |  __ \  / __ \  / __ \ |  \/  |'
    echo ' | ^ /  __ _ | | _   \ \  / / | |__) ||  \| |   ___  | |_  | |  | || |  | || |  | || \  / |'
    echo ' |  <  / _` || || |   \ \/ /  |  ___/ | . ` |  / _ \ |  _| | |  | || |  | || |  | || |\/| |'
    echo ' | . \| (_| || || |    \  /   | |     | |\  | | (_) || |   | |__| || |__| || |__| || |  | |'
    echo ' |_|\_\\__,_||_||_|     \/    |_|     |_| \_|  \___/ |_|   |_____/  \____/  \____/ |_|  |_|'
    echo ""                                                                               
    echo ""                                                                               
    echo "Don't forget to edit variables in file $0 before running!"
    echo ""
    echo "-s, --server     : Build a OpenVPN Server with client ovpn"
    echo "-c, --client     : Build a client OVPN file only"
    echo "-r, --reverse    : Set up your routes/iptables for reverse VPN on server"
    echo "-f, --flush      : Stop OpenVPN. Flush your IPTables and clear routes"
    echo "-n, --nethunter  : Set up iptables for Nethunter Reverse VPN"
    echo "-h, --help       : Help Menu (this)"
    echo "--start-server   : Start OpenVPN server"
    exit 0
}

# Default help if no arguments are supplied
if [[ $# -eq 0 ]] ; then
    def_help
fi

# Help menu
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    def_help
fi 

# Dependency checks
dep_check(){
DEPS=(openvpn easy-rsa curl)

for i in "${DEPS[@]}"
do
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' ${i}|grep "install ok installed")
  echo "[+] Checking for installed dependency: ${i}"
  if [ "" == "$PKG_OK" ]; then
    echo "[-] Missing dependency: ${i}"
    echo "[+] Attempting to install...."
    sudo apt-get -y install ${i}
  fi
done
echo "[+] All done! Creating hidden file .dep_check so we don't have preform check again."
touch .dep_check
}

# Run dependency check once (see above for dep check)
if [ ! -f ".dep_check" ]; then
  dep_check
else
  echo "[+] Dependency check previously conducted. To rerun remove file .dep_check"
fi

#####################
#   GENERATE KEYS   #
#####################
if [ "$1" == "--server" ] || [ "$1" == "-s" ]; then

    if [ -f "/etc/openvpn/server.crt" ] || [ -f "/etc/openvpn/server.key" ]; then
        read -p "[?] Found existing keys/certs in /etc/openvpn.  Remove? (y/n) : " remove_keys
        if [ $remove_keys == "y" ] || [ $remove_keys == "yes" ]; then
            rm -f /etc/openvpn/{server.crt,server.key,dh2048.pem,ca.crt,ta.key}
        else
            "[!] Let's not overwrite previous keys"
            exit
        fi
    fi

    # Get external IP
    read -p "[?] Current configured IP is $SERVER_IP. Get external IP from internet? (y/n) : " GET_IP
    if [ $GET_IP == "y" ] || [ $GET_IP == "yes" ]; then
        SERVER_IP=`curl ifconfig.me`
        if [ $? -eq 0 ]; then
            echo "[+] Got external IP from ifconfig.me: $SERVER_IP"
            sleep 5
        else
            echo "[-] Failed to get external IP"
            exit
        fi
    fi
    if [ $GET_IP == "n" ] || [ $GET_IP == "no" ]; then
        read -p "[?] Current configured IP is $SERVER_IP. Change IP or domain? (y/n): " SET_IP

        if [ $SET_IP == "y" ] || [ $SET_IP == "yes" ]; then
            read -p "[!] Enter IP or domain: " SERVER_IP
        fi
    fi

    # Generate the master CA certificate and key
    cd $INSTALLDIR
    cp -rf /usr/share/easy-rsa .
    echo "[+] Copying easy-rsa to $INSTALLDIR"
    cd easy-rsa
    sed -i 's/ --interact//' build-ca
    sed -i 's/ --interact//' build-key-server
    sed -i 's/ --interact//' build-key
    . ./vars
    echo "[+] Source vars"
    ./clean-all
    echo "[+] Clean all"
    ./build-ca
    echo "[+] Building CA"

    # Generate certificate & key for server
    ./build-key-server server
    echo "[+] Generate certificate & key for server"

    # Build certificate for one client
    ./build-key client
    echo "[+] Generate certificate for client"

    # Build TLS key
    openvpn --genkey --secret keys/ta.key
    echo "[+] Making TLS key"

    # Generate Diffie Hellman parameters
    ./build-dh
    echo "[+] Generate Diffie Hellman parameters"

    # Copy all our keys for OpenVPN
    cp -rf keys/{server.crt,server.key,dh2048.pem,ca.crt,ta.key} /etc/openvpn/
    echo "[+] Copying all generated keys/certificates to /etc/openvpn"

    # Generate the OpenVPN server configuration file
    cat << EOF > /etc/openvpn/doom_server.conf
# OPENVPN SERVER CONFIG FILE
port $SERVER_PORT
proto $SERVER_PROTOCOL

# Use Tunnel instead of TAP (android support)
dev tun

# net30 breaks routing:  http://serverfault.com/a/623673
topology subnet

# Server Keys
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-auth ta.key 0

# Contains client(s) ip and iroute
client-config-dir static

# Override the Client default gateway by using 0.0.0.0/1 and
# 128.0.0.0/1 rather than 0.0.0.0/0. This has the benefit of
# overriding but not wiping out the original default gateway.
push "redirect-gateway def1 bypass-dhcp"

# See other clients
client-to-client

# Network Settings
server 10.8.0.0 255.255.255.0

# Additional Settings
keepalive 10 120
comp-lzo
user nobody
group nogroup
ping-timer-rem
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

    # Check for successful server.conf file
    if [ -f "/etc/openvpn/doom_server.conf" ]; then
        echo "[+] Created server configuration file at /etc/openvpn/doom_server.conf"
    else
        echo "[-] Something went wrong!  No doom_server.conf file found!"
        exit
    fi

    mkdir -p /etc/openvpn/static
    if [ -d "/etc/openvpn/static" ]; then
        echo "[+] Created dir /etc/openvpn/static"
    else
        echo "[-] Nothing found at dir /etc/openvpn/static"
    fi

    # Assigns .200 to client. We can have more than one
    touch /etc/openvpn/static/client
    echo "ifconfig-push $CLIENT_IP 255.255.255.0" > /etc/openvpn/static/client
    echo "iroute $TARGET_RANGE" >> /etc/openvpn/static/client
    echo "[+] Created static client IP file /etc/openvpn/static/client"
fi

if [ "$1" == "--server" ] || [ "$1" == "-s" ] || [ "$1" == "--client" ] || [ "$1" == "-c" ]; then
    # Generate OVPN file for client to use. 
    cd $INSTALLDIR/easy-rsa/keys
    cat << EOF > "$INSTALLDIR/$CLIENT_KEYNAME.ovpn"
client
dev tun
ns-cert-type server
proto $SERVER_PROTOCOL
keepalive 10 120
remote $SERVER_IP $SERVER_PORT
resolv-retry infinite
push-peer-info
nobind
ping-timer-rem
persist-key
persist-tun
ca [inline]
cert [inline]
key [inline]
tls-auth [inline] 1
comp-lzo
verb 3
<ca>
EOF
cat ca.crt >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
cat << EOF >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
</ca>
<cert>
EOF
cat client.crt >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
cat << EOF >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
</cert>
<key>
EOF
cat client.key >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
cat << EOF >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
</key>
<tls-auth>
EOF
cat ta.key >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
cat << EOF >> $INSTALLDIR/$CLIENT_KEYNAME.ovpn
</tls-auth>
EOF

    if [ -f "$INSTALLDIR/$CLIENT_KEYNAME.ovpn" ]; then
        echo "[+] Client keys installed to $INSTALLDIR/$CLIENT_KEYNAME.ovpn"
    else
        echo "[-] Client keys not found!"
    fi
fi


######################
# Interface/Forward  #
######################
def_route(){
    echo "1" > /proc/sys/net/ipv4/ip_forward
    echo "[+] Enable IP forwarding"

    read -p "[?] Change network interface from $SERVER_INTERFACE? (y/n) : " select_interface
    if [ $select_interface == "y" ] || [ $select_interface == "yes" ]; then
        cd /sys/class/net
        select INTERFACE in *;
        do
            SERVER_INTERFACE=$INTERFACE
            echo "[+] Interface $SERVER_INTERFACE selected"
            break
        done
    fi
}

    # This is needed to allow client to access internet 
    sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $SERVER_INTERFACE -j MASQUERADE
    #echo "[+] DEBUG: IPTables set for VPN subnet:"
    #echo "      -   iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $SERVER_INTERFACE -j MASQUERADE"

if [ "$1" == "-r" ] || [ "$1" == "--reverse" ]; then
    def_route
fi

#####################
#  Flush IPTABLES   #
#####################
def_flush(){

    pkill openvpn
    echo "[!] Killing OpenVPN!"

    sleep 3

    # Make sure we don't get disconnected
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT

    # Flush iptables
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -F
    sudo iptables -X
    for i in $( iptables -t nat --line-numbers -L | grep ^[0-9] | awk '{ print $1 }' | tac )
    do
        iptables -t nat -D POSTROUTING $i
    done
    echo "[+] Iptables flushed!" 

    # Delete route 
    sudo route del -host 10.8.0.200 dev tun0
    sudo route del -net $TARGET_CIDR gw 10.8.0.200 dev tun0
}

if [ "$1" == "-f" ] || [ "$1" == "--flush" ]; then
    def_flush
fi

#####################
#   Start Server    #
#####################
if [ "$1" == "--start-server" ]; then
    def_flush
    echo "[+] Flushing IP Tables"

    sleep 5
    echo "[+] Setting server routes"
    def_route
    
    openvpn --cd /etc/openvpn --config /etc/openvpn/doom_server.conf &
    echo "[+] Starting openvpn server"

    # Create route (requires tun0 to be present...let's sleep on it)
    sleep 10
    echo "[+] Setting routes to private subnet"
    sudo route add -host 10.8.0.200 dev tun0
    sudo route add -net $TARGET_CIDR gw 10.8.0.200 dev tun0

fi

#####################
#    Nethunter      #
#####################
#
# Transfer $CLIENT_KEYNAME.ovpn to your /sdcard on device.  
# Open ovpn file using https://f-droid.org/repository/browse/?fdid=de.blinkt.openvpn

if [ "$1" == "-n" ] || [ "$1" == "--nethunter" ]; then

    # Turn the server into the client's gateway
    sudo echo "1" > /proc/sys/net/ipv4/ip_forward
    # Allow traffic initiated from VPN to access LAN
    iptables -t nat -I POSTROUTING -o wlan0 -s 10.8.0.0/24 -j MASQUERADE
fi