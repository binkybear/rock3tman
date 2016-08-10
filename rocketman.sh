#!/bin/bash
#
#
# Made by @_binkybear for reverse VPN on NH
# Feel free to modify script however you like!
#
#
#####################
#     VARIABLES     #
#####################
INSTALLDIR=$HOME                            # Install dir for client keys (default is OK)

SERVER_IP="127.0.0.1"                       # Put in public IP of server
SERVER_PORT="443"                           # Port for VPN server to listen on
SERVER_PROTOCOL="tcp"                       # tcp or udp
SERVER_INTERFACE="eth0"                     # Interface of VPN server

CLIENT_KEYNAME="im_a_rocketman"             # Generate client OVPN file (filename).ovpn
CLIENT_IP="10.8.0.200"                      # Specify IP in /24 range (10.8.0.1-10.8.0.254)

TARGET_GATEWAY="192.168.1.1"                # Gateway of target network
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
    echo "Usage: rocketman.sh [-arg]"
    echo '                           *     .--.'
    echo '                                 / / '
    echo '                +               | |'
    echo '                                 \ \_'
    echo '                   *          +   '--'  *'
    echo '                       +   /\'
    echo '          +              .'  '.   *'
    echo '                 *      /======\      +'
    echo '                       ;:.  _   ;'
    echo '                       |:. (_)  |'
    echo '                       |:.  _   |'
    echo '             +         |:. (_)  |          *'
    echo '                       ;:.      ;'
    echo '                      / \:.    /  \.'
    echo '                    / .---:._./--. \'
    echo '                    |/    /||\    \|'
    echo '                 _..--"""````"""--.._'
    echo '            _.-'                      ``'-._'
    echo '          -'                                '-'
    echo 'oiP9rrk22W2KsD98PMxZ9g/3XpgNLOWrmNMQzNyeG7I11nlNhlfAKBFpQBionmvBjinGEVm/9Gr'
    echo '08ctvPpi+LroIxT4wdNk9zddLfDQ8fVg='
    echo ''
    echo "Don't forget to edit variables in rocketman.sh!"
    echo ""
    echo "-s, --server     : Build a OpenVPN Server with client ovpn"
    echo "-c, --client     : Build a client OVPN file only"
    echo "-r, --reverse    : Set up your routes/iptables for reverse VPN on server"
    echo "-f, --flush      : Flush your IPTables"
    echo "-n, --nethunter  : Set up Nethunter Reverse VPN"
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
# V zvff gur rnegu fb zhpu V zvff zl jvsr Vg'f ybaryl bhg va fcnpr Ba fhpu n gvzryrff syvtug

if [ "$1" == "--server" ] || [ "$1" == "-s" ]; then

    if [ -f "/etc/openvpn/server.crt" ] || [ -f "/etc/openvpn/server.key" ]; then
        read -p "[!] Found existing keys/certs in /etc/openvpn.  Remove? (y/n) : " remove_keys
        if [ $remove_keys == "y" ] || [ $remove_keys == "yes" ]; then
            rm -f /etc/openvpn/{server.crt,server.key,dh2048.pem,ca.crt,ta.key}
        else
            "[!] Let's not overwrite previous keys"
            exit
        fi
    fi

    # Get external IP
    read -p "Get external IP from internet? (y/n) :" GET_IP
    if [ $GET_IP == "y" ] || [ $GET_IP == "yes" ]; then
        SERVER_IP=`curl ifconfig.me`
        if [ $? -eq 0 ]; then
            echo "[+] Got external IP from ifconfig.me: $SERVER_IP"
        else
            echo "[-] Failed to get external IP"
            exit
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
    cat << EOF > /etc/openvpn/server.conf
    # OPENVPN SERVER CONFIG FILE
    port $SERVER_PORT
    proto $SERVER_PROTOCOL

    # Use tunnel instead of TAP
    dev tun

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

    # Network Settings
    server 10.8.0.0 255.255.255.0

    # Client-to-client and route allows network traffic between subnets
    route $TARGET_RANGE
    client-to-client
    push "route $TARGET_RANGE"

    # Additional Settings
    keepalive 10 120
    comp-lzo
    user nobody
    group nogroup
    persist-key
    persist-tun
    status openvpn-status.log
    verb 3
EOF

    # Check for successful server.conf file
    if [ -f "/etc/openvpn/server.conf" ]; then
        echo "[+] Created server configuration file at /etc/openvpn/server.conf"
    else
        echo "[-] Something went wrong!  No server.conf file found!"
        exit
    fi

    mkdir -p /etc/openvpn/static
    if [ -d "/etc/openvpn/static" ]; then
        echo "[+] Created /etc/openvpn/static"
    else
        echo "[-] Nothing found at /etc/openvpn/static"
    fi
fi

if [ "$1" == "--server" ] || [ "$1" == "-s" ] || [ "$1" == "--client" ] || [ "$1" == "-c" ]; then
    # Assigns .200 to client. We can have more than one
    touch /etc/openvpn/static/client
    echo "ifconfig-push $CLIENT_IP 255.255.255.0" > /etc/openvpn/static/client
    echo "iroute $TARGET_RANGE" >> /etc/openvpn/static/client
    echo "[+] Created static client /etc/openvpn/static/client"

    # Generate OVPN file for client to use. 
    cd $INSTALLDIR/easy-rsa/keys
    cat << EOF > "$INSTALLDIR/$CLIENT_KEYNAME.ovpn"
    client
    dev tun
    dev-type tun
    ns-cert-type server
    proto tcp
    keepalive 10 120
    remote $SERVER_IP $SERVER_PORT
    resolv-retry infinite
    nobind
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


#####################
#  Routes/IPTABLES  #
#####################
def_route(){
    echo "1" > /proc/sys/net/ipv4/ip_forward
    echo "[+] Enable IP forwarding"

    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $SERVER_INTERFACE -j MASQUERADE
    echo "[+] IPTables set for VPN subnet"

    route add -net $TARGET_CIDR gw 10.8.0.200
    echo "[+] Added route from $TARGET_CIDR to VPN gateway"
}

if [ "$1" == "-r" ] || [ "$1" == "--reverse" ]; then
    def_route
fi

#####################
#  Flush IPTABLES   #
#####################
def_flush(){
    # Make sure we don't get disconnected
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT

    # Flush iptables
    sudo iptables -t nat -F
    sudo iptables -t mangle -F
    sudo iptables -F
    sudo iptables -X
    echo "[+] Iptables flushed!"    
}

if [ "$1" == "-f" ] || [ "$1" == "--flush" ]; then
    def_flush
fi

#####################
#   Start Server    #
#####################
if [ "$1" == "--start-server" ]; then
    echo "[+] Flushing IP Tables"
    def_flush

    echo "[+] Starting openvpn server"
    cd /etc/openvpn
    openvpn server.conf &

    echo "[+] Setting server routes"
    def_route
fi

#####################
#    Nethunter      #
#####################
#
# Transfer $CLIENT_KEYNAME.ovpn to your /sdcard on device.  

if [ "$1" == "-n" ] || [ "$1" == "--nethunter" ]; then
    if [ -f "/sdcard/$CLIENT_KEYNAME.ovpn" ]; then
        
        # Make tmp dir once
        mkdir -p /data/local/tmp

        # Turn the server into the client's gateway
        sudo echo "1" > /proc/sys/net/ipv4/ip_forward

        # Setup tun
        mkdir -p /dev/net
        mknod /dev/net/tun c 10 200
        chmod 600 /dev/net/tun
        cat /dev/net/tun
        #openvpn --mktun --dev tun0

        # Run ovpn config file
        echo "[+] Starting openvpn with /sdcard/$CLIENT_KEYNAME.ovpn"
        openvpn --config /sdcard/$CLIENT_KEYNAME.ovpn &

        # Set gateway for target network/VPN network
        ip route replace default via $TARGET_GATEWAY dev $NETHUNTER_INTERFACE
        ip rule add from $TARGET_CIDR lookup 61
        ip route add default dev tun0 scope link table 61
        ip route add $TARGET_CIDR dev wlan0 scope link table 61
        ip route add broadcast 255.255.255.255 dev wlan0 scope link table 61
        echo "[+] Adding IP routes"

        iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $NETHUNTER_INTERFACE -j MASQUERADE
        echo "[+] Add NAT IPTABLE"

        echo "Hit enter to kill openvpn"
        read
        pkill openvpn
        echo "[!] Killing OpenVPN"
        def_flush
        echo "[!] Flushing IPTABLES"
    else
        echo "[-] Could not find file $CLIENT_KEYNAME.ovpn on your SDCARD!"
    fi
fi