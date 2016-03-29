#!/bin/sh /etc/rc.common

START=99

PRG_REDIR="/usr/bin/ssr-redir"
PRG_TUNNEL="/usr/bin/ssr-tunnel"
PRG_SERVER="/usr/bin/ssr-server"
PRG_LOCAL="/usr/bin/ssr-local"
PID_REDIR="/var/run/ssr-redir.pid"
PID_TUNNEL="/var/run/ssr-tunnel.pid"
PID_SERVER="/var/run/ssr-server.pid"
PID_LOCAL="/var/run/ssr-local.pid"

CONFIG_DIR="/etc/shadowsocks-rss"
CONFIG_FILE="/etc/shadowsocks-rss/config.json"
C_FORBID="/etc/shadowsocks-rss/gfwlist/china-forbidden"
TMP_DIR="/tmp/etc/shadowsocks-rss"
DNSMASQ_DIR="/tmp/etc/dnsmasq.d"
TMP_REDIR="/tmp/etc/shadowsocks-rss/ssr-redir.json"
TMP_SERVER="/tmp/etc/shadowsocks-rss/ssr-server.json"
GFWLIST="/etc/shadowsocks-rss/gfwlist/china_forbidden"
GFWLIST_URL="https://raw.githubusercontent.com/wongsyrone/domain-block-list/master/domains.txt"

ipset_F() {
	local proxy_mod
	local local_port
	local dns_server_addr
	local other_dns
	local other_dns_overall

	config_get proxy_mod $1 proxy_mod
	config_get local_port $1 local_port
	config_get dns_server_addr $1 dns_server_addr
	config_get other_dns $1 other_dns
	config_get other_dns_overall $1 other_dns_overall

	mkdir -p $DNSMASQ_DIR
	echo "conf-dir=$DNSMASQ_DIR" > /etc/dnsmasq.conf

	case $proxy_mod in
#	GFW List
	G)
	ipset create  hash:ip maxelem 65536
	iptables -t nat -A shadowsocks_pre -s $subnet -p tcp -j REDIRECT --to $local_port
	
	
	awk '!/^$/&&!/^#/{printf("ipset=/%s/'"$vt_gfwlist"'\n",$0)}' \
		$C_FORBID > $DNSMASQ_DIR/ipset.conf
	;;
#	ALL the IP address not China
	C)
	
	
	
	;;
#	All Public IP address
	A)
	
	
	
	;;


	case $DNS_SERVER in
#	Shadowsocks Tunnel
	T)
	awk -vs="$dns_server_addr" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
		$C_FORBID > $DNSMASQ_DIR/server.conf
	;;
#	Other DNS Server
	O)
	if { $other_dns_overall == 1 }
	then
		echo "cache-size=300" > /etc/dnsmasq.conf
		echo "no-resolv" > /etc/dnsmasq.conf
		echo "server=$other_dns" > /etc/dnsmasq.conf
	else
		awk -vs="$other_dns" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
			$C_FORBID > $DNSMASQ_DIR/server.conf
	fi
	;;
#	System Default
	N)
	
	;;
	
	echo '	ipset_Finished. '

}

ssr_redir() {
	local fast_open
	local one_AUT
	local server
	local server_port
	local local_port
	local password
	local method
	local protocol
	local protocol_param
	local obfs
	local obfs_param
	local timeout

	config_get fast_open $1 fast_open
	config_get one_AUT $1 one_AUT
	config_get server $1 server
	config_get server_port $1 server_port
	config_get local_port $1 local_port
	config_get password $1 password
	config_get method $1 method
	config_get protocol $1 protocol
	config_get protocol_param $1 protocol_param
	config_get obfs $1 obfs
	config_get obfs_param $1 obfs_param
	config_get timeout $1 timeout

	[ $fast_open == 1 ] && FAST_OPEN="true" || FAST_OPEN="false"

	# sed -i -e "/server\"\: \"8.8.8.8/c \"server\"\: \"$server\"\," \
		# -e "/server_port/c \"server_port\"\: $server_port\," \
		# -e "/password/c \"password\"\: \"$password\"\," \
		# -e "/method/c \"method\"\: \"$method\"\," \
		# -e "/timeout/c \"timeout\"\: $timeout\," $TMP_REDIR
	# sed -i	-e "/protocol\"\: \"origin/c \"protocol\"\: \"$protocol\"\," \
		# -e "/protocol_param/c \"protocol_param\"\: \"$protocol_param\"\," \
		# -e "/obfs\"\: \"plain/c \"obfs\"\: \"$obfs\"\," \
		# -e "/obfs_param/c \"obfs_param\"\: \"$obfs_param\"\," \
		# -e "/fast_open/c \"fast_open\"\: $FAST_OPEN" $TMP_REDIR

	cat > $TMP_REDIR <<EOF
{
    "server": "$server",
    "server_port": $server_port,
    "password": "$password",
    "method": "$method",
    "timeout": $timeout,
    "protocol": "$protocol",
    "protocol_param": "$protocol_param",
    "obfs": "$obfs",
    "obfs_param": "$obfs_param",
    "fast_open": $FAST_OPEN	
}
EOF
		
	[ $one_AUT -a $one_AUT == 1 ] && ONE_AUT="-A" || ONE_AUT=""

#	service_start $PRG_REDIR -c $TMP_REDIR $ONE_AUT -f $PID_REDIR -u

	echo '	SSR-Redir Loaded. '
}

ssr_tunnel() {
	local tunnel_port
	local dns_server_addr

	config_get tunnel_port $1 tunnel_port
	config_get dns_server_addr $1 dns_server_addr

#	service_start $PRG_TUNNEL -c $TMP_REDIR -b 0.0.0.0 -l $tunnel_port -L $dns_server_addr -f $PID_TUNNEL-u
	echo '	SSR-Redir Loaded. '
}

ssr_server() {
	local ss_srv_fastopen
	local ss_srv_listen
	local ss_srv_port
	local ss_srv_pwd
	local ss_srv_method
	local ss_srv_prot
	local ss_srv_prot_param
	local ss_srv_obfs
	local ss_srv_obfs_param
	local ss_srv_timeout

	config_get ss_srv_fastopen $1 ss_srv_fastopen
	config_get ss_srv_listen $1 ss_srv_listen
	config_get ss_srv_port $1 ss_srv_port
	config_get ss_srv_pwd $1 ss_srv_pwd
	config_get ss_srv_method $1 ss_srv_method
	config_get ss_srv_prot $1 ss_srv_prot
	config_get ss_srv_prot_param $1 ss_srv_prot_param
	config_get ss_srv_obfs $1 ss_srv_obfs
	config_get ss_srv_obfs_param $1 ss_srv_obfs_param
	config_get ss_srv_timeout $1 ss_srv_timeout

	[ $ss_srv_fastopen -a $ss_srv_fastopen == 1 ] && SRV_FAST_OPEN="true" || SRV_FAST_OPEN="false"

	# sed -i -e "/server\"\: \"8.8.8.8/c \"server\"\: \"$ss_srv_listen\"\," \
		# -e "/server_port/c \"server_port\"\: $ss_srv_port\," \
		# -e "/password/c \"password\"\: \"$ss_srv_pwd\"\," \
		# -e "/method/c \"method\"\: \"$ss_srv_method\"\," \
		# -e "/timeout/c \"timeout\"\: $ss_srv_timeout\," $TMP_SERVER
	# sed -i	-e "/protocol\"\: \"origin/c \"protocol\"\: \"$ss_srv_prot\"\," \
		# -e "/protocol_param/c \"protocol_param\"\: \"$ss_srv_prot_param\"\," \
		# -e "/obfs\"\: \"plain/c \"obfs\"\: \"$ss_srv_obfs\"\," \
		# -e "/obfs_param/c \"obfs_param\"\: \"$ss_srv_obfs_param\"\," \
		# -e "/fast_open/c \"fast_open\"\: $SRV_FAST_OPEN" $TMP_SERVER
		
	cat > $TMP_SERVER <<EOF
{
    "server": "$ss_srv_listen",
    "server_port": $ss_srv_port,
    "password": "$ss_srv_pwd",
    "method": "$ss_srv_method",
    "timeout": $ss_srv_timeout,
    "protocol": "$ss_srv_prot",
    "protocol_param": "$ss_srv_prot_param",
    "obfs": "$ss_srv_obfs",
    "obfs_param": "$ss_srv_obfs_param",
    "fast_open": $SRV_FAST_OPEN	
}
EOF
#	service_start $PRG_SERVER -c $TMP_SERVER -f $PID_SERVER $ONE_AUT 

	echo '	SSR-Server Loaded. '

}

ssr_local() {
	local ss_local_port

	config_get ss_local_port $1 ss_local_port 

#	service_start $PRG_LOCAL -c $TMP_REDIR -f $PID_LOCAL -l $ss_local_port $ONE_AUT 
	echo '	SSR-Local Loaded. '

}

ssr_header() {
	local enabled
	local ss_server
	local ss_local
	local dns_server

	config_get enabled $1 enabled
	config_get ss_server $1 ss_server
	config_get ss_local $1 ss_local
	config_get dns_server $1 dns_server

	ENABLE=$enabled
	SS_SERVER=$ss_server
	SS_LOCAL=$ss_local
	DNS_SERVER=$dns_server
}

update_gfwlist() {
#	mkdir -p $TMP_DIR

	while [ -s $TMP_DIR ]
	do
	wget  -p $TMP_DIR $GFWLIST_URL
#	cp $TMP_DIR $GFWLIST
	done

}

start() {
	echo ''
	config_load shadowsocks-rss
	config_foreach ssr_header
#	echo "$ENABLE $DNS_SERVER $SS_SERVER $SS_LOCAL "

	if [ $ENABLE == 1 ]
	then

		mkdir -p $TMP_DIR
		echo 'Starting RSS-Redir server...'
		# cp $CONFIG_FILE $TMP_REDIR
		config_foreach ssr_redir
		config_foreach ipset_F
#		/etc/init.d/dnsmasq restart

		echo 'Starting DNS server...'
		[ $DNS_SERVER == T ] && config_foreach ssr_tunnel

		echo 'Starting Other server...'
		# cp $CONFIG_FILE $TMP_SERVER 
		[ $SS_SERVER == 1 ] && config_foreach ssr_server || echo '	SSR-Server Disabled. '
		[ $SS_LOCAL == 1 ] && config_foreach ssr_local || echo '	SSR-Server Disabled. '
		echo 'Shadowsocks-RSS Start Finished. '
		echo ''

		echo 'Checking... '
		[ $(ps|grep ${PRG_REDIR}|grep -v grep|wc -l) -ge 1 ] && echo '	Shadowsocks-RSS Runing. ' || echo '	Shadowsocks-RSS start fail. '
		[ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Tunnel Running. ' || echo "		Using Other DNS Server. "
		[ $(ps|grep ${PRG_SERVER}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Server Running. ' || echo '	SSR-Server Disabled. '
		[ $(ps|grep ${PRG_LOCAL}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Local Running. ' || echo '	SSR-Server Disabled. '
 
	else echo "Shadowsocks-RSS Disabled. "
	fi

	# echo "Sdddd "
	# update_gfwlist
	# echo "Sddjjjj "
	echo ' '
}

stop() {
	service_stop $PROGRAM
	[ $(ps|grep ${PROGRAM}|grep -v grep|wc -l) -ge 0 ] && echo "Pcap_DNSProxy Stoped. " || echo "Pcap_DNSProxy NOT Stoped. "
}

restart() {
	stop
#	killall $PROGRAM
	sleep 3
	echo ''
	start

}

status() {

	[ $(ps|grep ${PROGRAM}|grep -v grep|wc -l) -ge 1 ] && echo "Pcap_DNSProxy is running, PID is $(pidof ${PROGRAM##*/})" || echo "Pcap_DNSProxy is NOT running"

}

libver() {

	$PROGRAM --lib-version

}

