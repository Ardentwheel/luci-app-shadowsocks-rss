#!/bin/sh /etc/rc.common

START=99

EXTRA_COMMANDS="status update_list"
EXTRA_HELP=<<EOF
	Available Commands: 
		status
		udate_list
EOF

PRG_REDIR="/usr/bin/ssr-redir"
PRG_TUNNEL="/usr/bin/ssr-tunnel"
PRG_SERVER="/usr/bin/ssr-server"
PRG_LOCAL="/usr/bin/ssr-local"
PID_REDIR="/var/run/ssr-redir"
PID_TUNNEL="/var/run/ssr-tunnel"
PID_SERVER="/var/run/ssr-server"
PID_LOCAL="/var/run/ssr-local"

TMP_DIR="/tmp/etc/shadowsocks-rss"
TMP_REDIR="/tmp/etc/shadowsocks-rss/ssr-redir.json"
TMP_SERVER="/tmp/etc/shadowsocks-rss/ssr-server.json"

DNSMASQ_CACHE=900
DNSMASQ_DIR="/tmp/etc/dnsmasq.d"
CONFIG_DIR="/etc/shadowsocks-rss"
LIST_DIR="/etc/shadowsocks-rss/list"
GFWLIST="$LIST_DIR/GFWList"
GFWLIST_USER="$LIST_DIR/UserList"
CHINALIST="$LIST_DIR/ChinaList"
BYPASSLIST="$LIST_DIR/BypassList"
GFWLIST_URL="https://raw.githubusercontent.com/wongsyrone/domain-block-list/master/domains.txt"
CHINALIST_URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"


ipset_F() {
	local proxy_mod
	local local_port
	local tunnel_port
	local other_dns
	local other_dns_overall

	config_get proxy_mod $1 proxy_mod
	config_get local_port $1 local_port
	config_get tunnel_port $1 tunnel_port
	config_get other_dns $1 other_dns
	config_get other_dns_overall $1 other_dns_overall

	DNS_OVERALL=0
	[ $other_dns_overall ] && DNS_OVERALL=$other_dns_overall
	TUNNEL_ADDR="127.0.0.1#$tunnel_port"
	
	rm -f $DNSMASQ_DIR/ipset.conf
	rm -f $DNSMASQ_DIR/server.conf
	mkdir -p $DNSMASQ_DIR
	
	sed -i '/conf-dir=/d' /etc/dnsmasq.conf
	echo "conf-dir=$DNSMASQ_DIR" >> /etc/dnsmasq.conf
#	echo "proxy_mod: $proxy_mod DNS_OVERALL: $DNS_OVERALL"
	
	case $proxy_mod in
	G)
#	GFW List
	echo "proxy_mod: $proxy_mod"
#	ipset destroy GFWList -!
	ipset create GFWList hash:ip -!
	ipset flush GFWList -!
	iptables -t nat -A PREROUTING -p tcp -m set --match-set GFWList dst -j REDIRECT --to-port $local_port
	iptables -t nat -A OUTPUT -p tcp -m set --match-set GFWList dst -j REDIRECT --to-port $local_port
	awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"GFWList"'\n",$0)}' $GFWLIST > $DNSMASQ_DIR/ipset.conf
	awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"GFWList"'\n",$0)}' $GFWLIST_USER >> $DNSMASQ_DIR/ipset.conf
	;;
	C)
#	ALL the IP address not China
	awk '!/^$/&&!/^#/{printf("add ChinaList %s''\n",$0)}' $CHINALIST > $TMP_DIR/ChinaList.ipset
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
#	ipset destroy ChinaList -!
	ipset create ChinaList hash:net -!
	ipset flush ChinaList -!
	ipset restore -f $TMP_DIR/ChinaList.ipset 
#	ipset destroy BypassList -!
	ipset create BypassList hash:net -!
	ipset flush BypassList -!
	ipset restore -f $TMP_DIR/BypassList.ipset
	iptables -t nat -I PREROUTING -p tcp -j REDIRECT --to-port $local_port
	iptables -t nat -I PREROUTING -p tcp -m set --match-set ChinaList dst -j RETURN
	iptables -t nat -I PREROUTING -p tcp -m set --match-set BypassList dst -j RETURN
	iptables -t nat -I PREROUTING -p tcp -d $SERVER_ADDR -j RETURN
	;;
	A)
#	All Public IP address
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
#	ipset destroy BypassList -!
	ipset create BypassList hash:net
	ipset flush BypassList -!
	ipset restore -f $TMP_DIR/BypassList.ipset
	iptables -t nat -I PREROUTING -p tcp -j REDIRECT --to-port $local_port
	iptables -t nat -I PREROUTING -p tcp -m set --match-set BypassList dst -j RETURN
	iptables -t nat -I PREROUTING -p tcp -d $SERVER_ADDR -j RETURN
	;;
	esac

	case $DNS_SERVER in
	T)
#	Shadowsocks Tunnel
	[ $proxy_mod == G ] && {
		rm -f $DNSMASQ_DIR/server.conf
		sed -i -e "/cache-size=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" /etc/dnsmasq.conf
		echo "cache-size=$DNSMASQ_CACHE" >> /etc/dnsmasq.conf

		awk -vs="$TUNNEL_ADDR" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
			$GFWLIST > $DNSMASQ_DIR/server.conf
		}
	[ $proxy_mod == C ] && {
		rm -f $DNSMASQ_DIR/server.conf
		sed -i -e "/cache-size=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" /etc/dnsmasq.conf
		echo "cache-size=$DNSMASQ_CACHE" >> /etc/dnsmasq.conf
		echo "no-resolv" >> /etc/dnsmasq.conf
		echo "server=$TUNNEL_ADDR" >> /etc/dnsmasq.conf

		[ "awk '/^nameserver/{print $2}' /etc/resolv.conf" == "127.0.0.1" ] && DNS_RESOLV="awk '/^nameserver/{print $2}' /etc/resolv.conf" || DNS_RESOLV="114.114.114.114"
		awk -vs="$DNS_RESOLV" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
			$CHINALIST > $DNSMASQ_DIR/server.conf
			}
	[ $proxy_mod == A ] && {
			rm -f $DNSMASQ_DIR/server.conf
			sed -i -e "/cache-size=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" /etc/dnsmasq.conf
		echo "cache-size=$DNSMASQ_CACHE" >> /etc/dnsmasq.conf
		echo "no-resolv" >> /etc/dnsmasq.conf
		echo "server=$TUNNEL_ADDR" >> /etc/dnsmasq.conf
		}
	;;
	O)
#	Other DNS Server
	if [ $DNS_OVERALL == 1 -o $proxy_mod == A ]
	then
		rm -f $DNSMASQ_DIR/server.conf
		sed -i -e "/cache-size=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" /etc/dnsmasq.conf
		echo "cache-size=$DNSMASQ_CACHE" >> /etc/dnsmasq.conf
		echo "no-resolv" >> /etc/dnsmasq.conf
		echo "server=$other_dns" >> /etc/dnsmasq.conf
	else
		[ $proxy_mod == G ] && {
			rm -f $DNSMASQ_DIR/server.conf
			sed -i -e "/cache-size=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" /etc/dnsmasq.conf
			echo "cache-size=$DNSMASQ_CACHE" >> /etc/dnsmasq.conf

			awk -vs="$other_dns" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
				$GFWLIST > $DNSMASQ_DIR/server.conf
			}
		[ $proxy_mod == C ] && {
		rm -f $DNSMASQ_DIR/server.conf
		sed -i -e "/cache-size=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" /etc/dnsmasq.conf
		echo "cache-size=$DNSMASQ_CACHE" >> /etc/dnsmasq.conf
		echo "no-resolv" >> /etc/dnsmasq.conf
		echo "server=$other_dns" >> /etc/dnsmasq.conf

		[ "awk '/^nameserver/{print $2}' /etc/resolv.conf" == "127.0.0.1" ] && DNS_RESOLV="awk '/^nameserver/{print $2}' /etc/resolv.conf" || DNS_RESOLV="114.114.114.114"
		awk -vs="$DNS_RESOLV" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
			$CHINALIST > $DNSMASQ_DIR/server.conf
#		echo "DNS_RESOLV: $DNS_RESOLV"
		}
	fi
	;;
	esac
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
		
	[ $one_AUT -a $one_AUT == 1 ] && REDIR_ONE_AUT="-A" || REDIR_ONE_AUT=""

#	echo "service_start $PRG_REDIR -b 0.0.0.0 -l $local_port -c $TMP_REDIR $ONE_AUT "
	sleep 1
	service_start $PRG_REDIR -c $TMP_REDIR -b 0.0.0.0 -l $local_port $REDIR_ONE_AUT -f $PID_REDIR

	SERVER_ADDR=$server
	REDIR_LOCAL=$local_port

	echo '	SSR-Redir Loaded. '
}

ssr_tunnel() {
	local tunnel_port
	local dns_server_addr

	config_get tunnel_port $1 tunnel_port
	config_get dns_server_addr $1 dns_server_addr

#	echo "service_start $PRG_TUNNEL -c $TMP_REDIR -b 0.0.0.0 -l $tunnel_port -L $dns_server_addr -u "
	sleep 1
	service_start $PRG_TUNNEL -c $TMP_REDIR -b 0.0.0.0 -l $tunnel_port -L $dns_server_addr -u -f $PRG_TUNNEL

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

	sleep 1
	service_start $PRG_SERVER -c $TMP_SERVER $ONE_AUT -f $PID_SERVER

	echo '	SSR-Server Loaded. '

}

ssr_local() {
	local ss_local_port

	config_get ss_local_port $1 ss_local_port 

	sleep 1
	service_start $PRG_LOCAL -c $TMP_REDIR -l $ss_local_port $ONE_AUT -f $PID_LOCAL
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

start() {
	echo ''
	config_load shadowsocks-rss
	config_foreach ssr_header
#	echo "$ENABLE $DNS_SERVER $SS_SERVER $SS_LOCAL "

	if [ $ENABLE -a $ENABLE == 1 ]
	then

		mkdir -p $TMP_DIR
		echo 'Starting RSS-Redir server...'
		config_foreach ssr_redir
		config_foreach ipset_F

		echo 'Starting DNS server...'
		[ $DNS_SERVER == T ] && config_foreach ssr_tunnel || echo "	SSR-Tunnel	Disabled. Using Other DNS Server. "
		/etc/init.d/dnsmasq restart

		echo 'Starting Other server...'
#		echo "SS_SERVER:$SS_SERVER SS_LOCAL:$SS_LOCAL"
		[ $SS_SERVER == 1 ] && config_foreach ssr_server || echo '	SSR-Server Disabled. '
		[ $SS_LOCAL == 1 ] && config_foreach ssr_local || echo '	SSR-Server Disabled. '

		echo 'Shadowsocks-RSS Start Finished. '
		echo ''
		echo 'Checking... '

		[ $(ps|grep ${PRG_REDIR}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Redir	Running. ' || echo '	SSR-Redir	start fail. '
		[ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Tunnel	Running. ' || echo "	SSR-Tunnel	Disabled. Using Other DNS Server. "
		[ $(ps|grep ${PRG_SERVER}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Server	Running. ' || {
			[ $SS_SERVER == 1 ] && echo '	SSR-Server	start fail. ' || echo '	SSR-Server	Disabled. ' 
			}
		[ $(ps|grep ${PRG_LOCAL}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Local	Running. ' || {
			[ $SS_LOCAL == 1 ] && echo '	SSR-Local	start fail. ' || echo '	SSR-Local	Disabled. ' 
			}
 
	else if [ $SS_SERVER == 1 -o $SS_LOCAL == 1 ]
		then
			echo 'Shadowsocks-RSS SSR-Redir Disabled. Starting Other server...'
			[ $SS_SERVER == 1 ] && config_foreach ssr_server || echo '	SSR-Server Disabled. '
			[ $SS_LOCAL == 1 ] && config_foreach ssr_local || echo '	SSR-Server Disabled. '
		else echo "Shadowsocks-RSS Disabled. "
		fi
	fi

	echo ' '
}

stop() {
	echo ''
	echo 'Stopping Shadowsocks-RSS Server... '
	while [ $(ps|grep ${PRG_REDIR}|grep -v grep|wc -l) -ge 1 ]
	do
	service_stop $PRG_REDIR
	done
	echo '	SSR-Redir	Stoped. '
	
	while [ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ]
	do
		service_stop $PRG_TUNNEL
	done
	echo '	SSR-Tunnel	Stoped. '

	sed -i -e "/cache-size=/d " \
		-e "/no-resolv/d" \
		-e "/server=/d" /etc/dnsmasq.conf 
		
	rm -f $DNSMASQ_DIR/ipset.conf
	rm -f $DNSMASQ_DIR/server.conf
	rm -f -R $TMP_DIR
	
	while [ $(ps|grep ${PRG_SERVER}|grep -v grep|wc -l) -ge 1 ]
	do
	service_stop $PRG_SERVER
	done
	echo '	SSR-Server	Stoped. '
	
	while [ $(ps|grep ${PRG_LOCAL}|grep -v grep|wc -l) -ge 1 ]
	do
	service_stop $PRG_LOCAL
	done
	echo '	SSR-Local	Stoped. '

	iptables -F
	iptables -X
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	iptables -t raw -F
	iptables -t raw -X
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	
	ipset flush gfwlist -!
	ipset flush ChinaList -!
#	ipset flush BypassList -!

	/etc/init.d/firewall restart
	/etc/init.d/dnsmasq restart

	echo 'Shadowsocks-RSS Server Stoped. '
}

restart() {
	stop
	sleep 3
	echo ''
	start

}

status() {
	echo 'Shadowsocks-RSS Server Status: '
	[ $(ps|grep ${PRG_REDIR}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Redir	Running. ' || echo '	SSR-Redir	start fail. '
	[ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Tunnel	Running. ' || echo '	SSR-Tunnel	Disabled. Using Other DNS Server. '
	[ $(ps|grep ${PRG_SERVER}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Server	Running. ' || echo '	SSR-Server	Disabled. ' 
	[ $(ps|grep ${PRG_LOCAL}|grep -v grep|wc -l) -ge 1 ] && echo '	SSR-Local	Running. ' || echo '	SSR-Local	Disabled. ' 
}

update_list() {
	mkdir -p $TMP_DIR

	echo 'GFWList Updating...'
	cp $GFWLIST $LIST_DIR/GFWList.backup

	wget --no-check-certificate -b -q -P $TMP_DIR $GFWLIST_URL
	[ -e $TMP_DIR/domains.txt ] && cp $TMP_DIR/domains.txt $GFWLIST && echo '	GFWList Updated. '|| echo '	Download GFWList Fail. '
	rm -f $TMP_DIR/domains.txt
	echo ''

	echo 'ChinaList Updating...'
	cp $CHINALIST $LIST_DIR/ChinaList.backup
	curl --progress-bar $CHINALIST_URL \
		| grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_DIR/ChinaList.txt 
	[ -e $TMP_DIR/ChinaList.txt ] && cp $TMP_DIR/ChinaList.txt $CHINALIST && echo '	ChinaList Updated. ' || echo '	Download ChinaList Fail. '
	rm -f $TMP_DIR/ChinaList.txt
}

