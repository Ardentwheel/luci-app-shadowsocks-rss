#!/bin/sh /etc/rc.common

START=99

EXTRA_COMMANDS="status update_list update_ipsetrules"
EXTRA_HELP=<<EOF
	Available Commands: 
		status
		udate_list
		update_ipsetrules
		help
EOF

SERVICE_USE_PID=1
SERVICE_WRITE_PID=1
SERVICE_DAEMONIZE=1

PRG_DNSMASQ="/usr/sbin/dnsmasq"
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
TMP_LOCAL="/tmp/etc/shadowsocks-rss/ssr-local.json"

DNSMASQ_CACHE=0
DNSMASQ_CACHE_TTL=0
DNSMASQ_DIR="/tmp/etc/dnsmasq.d"
DNSMASQ_CONF="/etc/dnsmasq.conf"
DNSMASQ_SERVER="$DNSMASQ_DIR/01-server.conf"
DNSMASQ_IPSET="$DNSMASQ_DIR/02-ipset.conf"

CONFIG_DIR="/etc/shadowsocks-rss"
LIST_DIR="/etc/shadowsocks-rss/list"
GFWLIST="$LIST_DIR/GFWList"
USER_LIST="$LIST_DIR/UserList"
CHINALIST="$LIST_DIR/ChinaList"
CHINADOMAINLIST="$LIST_DIR/ChinaDomainList"
BYPASSLIST="$LIST_DIR/BypassList"
GFWLIST_URL="https://raw.githubusercontent.com/wongsyrone/domain-block-list/master/domains.txt"
CHINALIST_URL="http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
CHINACDNLIST_URL="https://raw.githubusercontent.com/mawenjian/china-cdn-domain-whitelist/master/china-cdn-domain-whitelist.txt"
CHINADOMAINLIST_URL="https://github.com/mawenjian/china-cdn-domain-whitelist/raw/master/china-top-website-whitelist.txt"

dns_sequence () {
	case $DNS_SERVER in
	T)
#	Shadowsocks Tunnel
	[ $PROXY_MOD == G ] && {
		sed -i -e "/cache-size=/d" \
			-e "/min-cache-ttl=/d" \
			-e "/no-resolv/d" \
			-e "/no-poll/d" \
			-e "/server=/d" $DNSMASQ_CONF
		echo "cache-size=$DNSMASQ_CACHE" >> $DNSMASQ_CONF
		echo "min-cache-ttl=$DNSMASQ_CACHE_TTL" >> $DNSMASQ_CONF
		awk -vs="$TUNNEL_ADDR" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' $GFWLIST > $DNSMASQ_SERVER
		awk -vs="$TUNNEL_ADDR" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' $USER_LIST >> $DNSMASQ_SERVER
		}
	[ $PROXY_MOD == C ] && {
		sed -i -e "/cache-size=/d" \
			-e "/min-cache-ttl=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" $DNSMASQ_CONF
		echo "cache-size=$DNSMASQ_CACHE" >> $DNSMASQ_CONF
		echo "min-cache-ttl=$DNSMASQ_CACHE_TTL" >> $DNSMASQ_CONF
		echo "no-resolv" >> $DNSMASQ_CONF
		echo "no-poll" >> $DNSMASQ_CONF
		echo "server=$TUNNEL_ADDR" >> $DNSMASQ_CONF

		[ "awk '/^nameserver/{print $2}' /tmp/resolv.conf.auto" == "127.0.0.1" ] && { 
			DNS_RESOLV="awk '/^nameserver/{print $2}' /etc/resolv.conf"
			ipset add BypassList $DNS_RESOLV 
			} || DNS_RESOLV="114.114.114.114"
			awk -vs="$DNS_RESOLV" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' $CHINADOMAINLIST > $DNSMASQ_SERVER
			}
	[ $PROXY_MOD == A ] && {
			sed -i -e "/cache-size=/d" \
				-e "/min-cache-ttl=/d" \
				-e "/no-resolv/d" \
				-e "/server=/d" $DNSMASQ_CONF
		echo "cache-size=$DNSMASQ_CACHE" >> $DNSMASQ_CONF
		echo "no-resolv" >> $DNSMASQ_CONF
		echo "no-poll" >> $DNSMASQ_CONF
		echo "server=$TUNNEL_ADDR" >> $DNSMASQ_CONF
		}
	;;
	O)
#	Other DNS Server
	if [ $DNS_OVERALL == 1 -o $PROXY_MOD == A ]
	then
		sed -i -e "/cache-size=/d" \
			-e "/min-cache-ttl=/d" \
			-e "/no-resolv/d" \
			-e "/server=/d" $DNSMASQ_CONF
		echo "cache-size=$DNSMASQ_CACHE" >> $DNSMASQ_CONF
		echo "min-cache-ttl=$DNSMASQ_CACHE_TTL" >> $DNSMASQ_CONF
		echo "no-resolv" >> $DNSMASQ_CONF
		echo "no-poll" >> $DNSMASQ_CONF
		echo "server=$OTHER_DNS" >> $DNSMASQ_CONF
	else
		[ $PROXY_MOD == G ] && {
			sed -i -e "/cache-size=/d" \
				-e "/min-cache-ttl=/d" \
				-e "/no-resolv/d" \
				-e "/server=/d" $DNSMASQ_CONF
			echo "cache-size=$DNSMASQ_CACHE" >> $DNSMASQ_CONF
			echo "min-cache-ttl=$DNSMASQ_CACHE_TTL" >> $DNSMASQ_CONF

			awk -vs="$OTHER_DNS" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' \
				$GFWLIST > $DNSMASQ_SERVER
			}
		[ $PROXY_MOD == C ] && {
		sed -i -e "/cache-size=/d" \
				-e "/min-cache-ttl=/d" \
				-e "/no-resolv/d" \
				-e "/server=/d" $DNSMASQ_CONF
		echo "cache-size=$DNSMASQ_CACHE" >> $DNSMASQ_CONF
		echo "min-cache-ttl=$DNSMASQ_CACHE_TTL" >> $DNSMASQ_CONF
		echo "no-resolv" >> $DNSMASQ_CONF
		echo "no-poll" >> $DNSMASQ_CONF
		echo "server=$OTHER_DNS" >> $DNSMASQ_CONF

		[ "awk '/^nameserver/{print $2}' /tmp/resolv.conf.auto" == "127.0.0.1" ] && { 
			DNS_RESOLV="awk '/^nameserver/{print $2}' /etc/resolv.conf"
			ipset add BypassList $DNS_RESOLV 
			} || DNS_RESOLV="114.114.114.114"
		awk -vs="$DNS_RESOLV" '!/^$/&&!/^#/{printf("server=/%s/%s\n",$0,s)}' $CHINADOMAINLIST > $DNSMASQ_SERVER
		}
	fi
	;;
	esac
	echo -e '	DNS Sequence		\033[40;32;1m Finished \033[0m'
}

ipset_sequence() {	
	rm -f $DNSMASQ_IPSET
	rm -f $DNSMASQ_SERVER
	mkdir -p $DNSMASQ_DIR
	
	sed -i '/conf-dir=/d' $DNSMASQ_CONF
	echo "conf-dir=$DNSMASQ_DIR" >> $DNSMASQ_CONF

	case $PROXY_MOD in
	G)
#	GFW List
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
	awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"gfwlist,gfwlist6"'\n",$0)}' $GFWLIST > $DNSMASQ_IPSET
	awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"gfwlist,gfwlist6"'\n",$0)}' $USER_LIST >> $DNSMASQ_IPSET
	ipset create gfwlist hash:ip -!
	ipset flush gfwlist -!
	ipset create BypassList hash:net -!
	ipset flush BypassList -!
	ipset restore -f $TMP_DIR/BypassList.ipset
	ipset create gfwlist6 hash:ip family inet6 -!
	ipset flush gfwlist6 -!

	# Create new chain
	iptables -t nat -N SHADOWSOCKS
	iptables -t mangle -N SHADOWSOCKS
	iptables -t nat -A SHADOWSOCKS -d $SERVER_ADDR -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set BypassList dst -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-ports $LOCAL_PORT
	iptables -t nat -A SHADOWSOCKS -p udp -m set --match-set gfwlist dst -j REDIRECT --to-ports $LOCAL_PORT
	
	# ip6tables -t nat -N SHADOWSOCKS
	# ip6tables -t nat -A SHADOWSOCKS -d $SERVER_ADDR -j RETURN
	# ip6tables -t nat -A SHADOWSOCKS -p tcp -m set --match-set gfwlist6 dst -j REDIRECT --to-ports $LOCAL_PORT

	# Add any UDP rules
	# ip rule add fwmark 0x01/0x01 table 100
	# ip route add local 0.0.0.0/0 dev lo table 100
	# iptables -t mangle -A SHADOWSOCKS -p udp --dport 53 -j TPROXY --on-port $LOCAL_PORT --tproxy-mark 0x01/0x01

	# Apply the rules
	iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
	iptables -t nat -A PREROUTING -p udp -j SHADOWSOCKS
	ip6tables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
	# iptables -t nat -A OUTPUT -j SHADOWSOCKS
	# ip6tables -t nat -A PREROUTING -p tcp -m set --match-set gfwlist6 dst -j REDIRECT --to-ports 1080
	
	;;
	C)
#	ALL the IP address not China
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
	awk '!/^$/&&!/^#/{printf("add ChinaList %s''\n",$0)}' $CHINALIST > $TMP_DIR/ChinaList.ipset
	ipset create BypassList hash:net -!
	ipset flush BypassList -!
	ipset restore -f $TMP_DIR/BypassList.ipset
	ipset create ChinaList hash:net -!
	ipset flush ChinaList -!
	ipset restore -f $TMP_DIR/RETURN.ipset

	iptables -t nat -N SHADOWSOCKS

	iptables -t nat -A SHADOWSOCKS -d $SERVER_ADDR -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set BypassList dst -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set ChinaList dst -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports $LOCAL_PORT

	iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
	;;
	A)
#	All Public IP address
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
	ipset create BypassList hash:net
	ipset flush BypassList -!
	ipset restore -f $TMP_DIR/BypassList.ipset

	iptables -t nat -N SHADOWSOCKS
	iptables -t mangle -N SHADOWSOCKS

	iptables -t nat -A SHADOWSOCKS -d $SERVER_ADDR -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set BypassList dst -j RETURN
	iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-ports $LOCAL_PORT

	iptables -t nat -A PREROUTING -p tcp -j SHADOWSOCKS
	iptables -t mangle -A PREROUTING -j SHADOWSOCKS
	;;
	esac

	echo -e '	Ipset Sequence		\033[40;32;1m Finished \033[0m'

}

ssr_redir() {
	local server_port
	local password
	local method
	local protocol
	local protocol_param
	local obfs
	local obfs_param
	local timeout

	config_get server_port $1 server_port
	config_get password $1 password
	config_get method $1 method
	config_get protocol $1 protocol
	config_get protocol_param $1 protocol_param
	config_get obfs $1 obfs
	config_get obfs_param $1 obfs_param
	config_get timeout $1 timeout

	cat > $TMP_REDIR <<EOF
{
	"server": "$SERVER_ADDR",
	"server_port": $server_port,
	"local_address": "0.0.0.0",
	"local_port": $LOCAL_PORT,
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

	sleep 1
	service_start $PRG_REDIR -c $TMP_REDIR $REDIR_ONE_AUT -f $PID_REDIR 2>/dev/null

	echo -e '	SSR-Redir		\033[40;32;1m Loaded \033[0m '
}

ssr_tunnel() {
	local tunnel_port
	local dns_server_addr

	config_get tunnel_port $1 tunnel_port
	config_get dns_server_addr $1 dns_server_addr

	sleep 1
	service_start $PRG_TUNNEL -c $TMP_REDIR -b 0.0.0.0 -l $tunnel_port -L $dns_server_addr -u -f $PID_TUNNEL 2>/dev/null

	echo -e '	SSR-Tunnel		\033[40;32;1m Loaded \033[0m '
}

ssr_server() {
	local ss_srv_fastopen
	local ss_srv_listen
	local ss_srv_port
	local ss_srv_pwd
	local srv_one_auth
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
	config_get srv_one_auth $1 srv_one_auth
	config_get ss_srv_method $1 ss_srv_method
	config_get ss_srv_prot $1 ss_srv_prot
	config_get ss_srv_prot_param $1 ss_srv_prot_param
	config_get ss_srv_obfs $1 ss_srv_obfs
	config_get ss_srv_obfs_param $1 ss_srv_obfs_param
	config_get ss_srv_timeout $1 ss_srv_timeout

	[ $srv_one_auth -a $srv_one_auth == 1 ] && SRV_ONE_AUTH="-A" || SRV_ONE_AUTH=""

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
	service_start $PRG_SERVER -c $TMP_SERVER $SRV_ONE_AUTH -f $PID_SERVER 2>/dev/null

	echo -e '	SSR-Server		\033[40;32;1m Loaded \033[0m '

}

ssr_local() {
	local server_port
	local ss_local_listen
	local ss_local_port
	local password
	local method
	local protocol
	local protocol_param
	local obfs
	local obfs_param
	local timeout

	config_get server_port $1 server_port
	config_get ss_local_listen $1 ss_local_listen
	config_get ss_local_port $1 ss_local_port
	config_get password $1 password
	config_get method $1 method
	config_get protocol $1 protocol
	config_get protocol_param $1 protocol_param
	config_get obfs $1 obfs
	config_get obfs_param $1 obfs_param
	config_get timeout $1 timeout
 

	cat > $TMP_LOCAL <<EOF
{
	"server": "$SERVER_ADDR",
	"server_port": $server_port,
	"local_address": "$ss_local_listen",
	"local_port": $ss_local_port,
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

	sed -i "s/\"LOCAL_PORT\": $LOCAL_PORT\,/\"local_port\": $ss_local_port\,/g" $TMP_LOCAL

	sleep 1
	service_start $PRG_LOCAL -c $TMP_LOCAL -u $REDIR_ONE_AUT -f $PID_LOCAL 2>/dev/null
	echo -e '	SSR-Local		\033[40;32;1m Loaded \033[0m '

}

random_port_seq() {
	local server_port=`uci get shadowsocks-rss.@basic[0].server_port 2>/dev/null`
	local random_port_A=`uci get shadowsocks-rss.@basic[0].random_port_A 2>/dev/null`
	local random_port_O=`uci get shadowsocks-rss.@basic[0].random_port_O 2>/dev/null`

	iptables -t nat -I OUTPUT 1 -d $SERVER_ADDR -p tcp --dport $server_port -j DNAT --to-destination $SERVER_ADDR:$random_port_A-$random_port_O --random
	iptables -t nat -I OUTPUT 1 -d $SERVER_ADDR -p udp --dport $server_port -j DNAT --to-destination $SERVER_ADDR:$random_port_A-$random_port_O --random

	echo -e '	Random-Port		\033[40;32;1m Finished \033[0m '
}

ssr_header() {
	local enabled
	local random_port
	local ss_server
	local ss_local
	local server
	local local_port
	local one_auth
	local proxy_mod
	local dns_server
	local with_tunnel
	local tunnel_port
	local other_dns
	local other_dns_overall
	local dns_cache
	local dns_cache_ttl
	local fast_open
	local ss_srv_fastopen
	
	config_get enabled $1 enabled
	config_get random_port $1 random_port
	config_get ss_server $1 ss_server
	config_get ss_local $1 ss_local
	config_get server $1 server
	config_get local_port $1 local_port
	config_get one_auth $1 one_auth
	config_get proxy_mod $1 proxy_mod
	config_get dns_server $1 dns_server
	config_get with_tunnel $1 with_tunnel
	config_get tunnel_port $1 tunnel_port
	config_get other_dns $1 other_dns
	config_get other_dns_overall $1 other_dns_overall
	config_get dns_cache $1 dns_cache
	config_get dns_cache_ttl $1 dns_cache_ttl
	config_get fast_open $1 fast_open
	config_get ss_srv_fastopen $1 ss_srv_fastopen

	ENABLE=$enabled
	RANDOM_PORT=$random_port
	SS_SERVER=$ss_server
	SS_LOCAL=$ss_local

	SERVER_ADDR=$server
	LOCAL_PORT=$local_port
	PROXY_MOD=$proxy_mod
	DNS_SERVER=$dns_server
	WITH_TUNNEL=$with_tunnel
	TUNNEL_ADDR="127.0.0.1#$tunnel_port"
	OTHER_DNS=$other_dns
	[ $one_auth -a $one_auth == 1 ] && REDIR_ONE_AUT="-A" || REDIR_ONE_AUT=""
	[ $dns_cache ] && DNSMASQ_CACHE=$dns_cache || DNSMASQ_CACHE=0
	[ $dns_cache_ttl ] && DNSMASQ_CACHE_TTL=$dns_cache_ttl || DNSMASQ_CACHE_TTL=0

	DNS_OVERALL=0
	[ $other_dns_overall ] && DNS_OVERALL=$other_dns_overall
	
	if [ $fast_open -a $fast_open == 1 ]
	then
		FAST_OPEN="true"
		[[ `grep -qc "net.ipv4.tcp_fastopen" /etc/sysctl.conf` -eq 0 ]] && echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
	else 
		FAST_OPEN="false"
		$fast_open=0
	fi

	if [ $ss_srv_fastopen -a $ss_srv_fastopen == 1 ]
	then
		SRV_FAST_OPEN="true"
		[[ `grep -qc "net.ipv4.tcp_fastopen" /etc/sysctl.conf` -eq 0 ]] && echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
	else 
		SRV_FAST_OPEN="false"
		$ss_srv_fastopen=0
	fi
	
	sysctl -p
}

switches () {
	if [ $ENABLE -a $ENABLE == 1 ]
	then
	/etc/init.d/shadowsocks-rss.sh enable
	else if [ $ENABLE -a $ENABLE == 0 ]
		then
		/etc/init.d/shadowsocks-rss.sh disable
		fi
	fi
}

start() {
	echo ''
	config_load shadowsocks-rss
	config_foreach ssr_header
	mkdir -p $TMP_DIR

	if [ $ENABLE -a $ENABLE == 1 ]
	then
		echo -e '\033[40;33;1m Starting RSS-Redir server... \033[0m'
		config_foreach ssr_redir
		ipset_sequence
		dns_sequence

		echo -e '\033[40;33;1m Starting DNS server... \033[0m'
		case $DNS_SERVER in
		T)
			config_foreach ssr_tunnel
		;;
		O)
			[ $WITH_TUNNEL -a $WITH_TUNNEL  == 1 ] && config_foreach ssr_tunnel
			echo -e "	Other DNS Server	\033[40;32;1m $OTHER_DNS \033[0m"
		;;
		N)
			echo -e '	DNS Server		\033[40;32;1m System Default \033[0m Besure your system DNS is clean.'
		;;
		esac
		/etc/init.d/dnsmasq restart

		echo -e '\033[40;33;1m Starting Other server...\033[0m'
		[ $SS_SERVER == 1 ] && config_foreach ssr_server || echo -e '	SSR-Server		\033[40;31;1m Disabled \033[0m '
		[ $SS_LOCAL == 1 ] && config_foreach ssr_local || echo -e '	SSR-Server		\033[40;31;1m Disabled \033[0m '
		[ $RANDOM_PORT -a $RANDOM_PORT == 1 ] && random_port_seq || echo -e '	Random-Port		\033[40;31;1m Disabled \033[0m '

		echo -e ' Shadowsocks-RSS Start		\033[40;32;1m Finished \033[0m '
		echo ''
		echo -e '\033[40;33;1m Checking... \033[0m '
		status
	else if [ $SS_SERVER == 1 -o $SS_LOCAL == 1 ]
		then
			echo -e '\033[40;33;1m Shadowsocks-RSS SSR-Redir Disabled. Starting Other server... \033[0m'
			
			[ $RANDOM_PORT -a $RANDOM_PORT == 1 ] && random_port_seq || echo -e '	Random-Port		\033[40;31;1m Disabled \033[0m '
			[ $SS_LOCAL == 1 ] && config_foreach ssr_local || echo -e '	SSR-Server		\033[40;31;1m Disabled \033[0m '
			[ $SS_SERVER == 1 ] && config_foreach ssr_server || echo -e '	SSR-Server		\033[40;31;1m Disabled \033[0m '

			echo -e " Shadowsocks-RSS Start \033[40;32;1m Finished \033[0m "
			echo ''
			echo -e '\033[40;33;1m Checking... \033[0m '
			status
		else echo "	Shadowsocks-RSS		\033[40;31;1m Disabled \033[0m "
		fi
	fi

	switches
	echo ' '
}

stop() {
	echo ''
	echo -e '\033[40;33;1m Stopping Shadowsocks-RSS Server... \033[0m '

	for loop in ssr-redir ssr-tunnel ssr-local ssr-server
	do
	echo -e "	$loop		\033[40;31;1m Stoped \033[0m "
	[ $(ps|grep /usr/bin/${loop}|grep -v grep|wc -l) -ge 1 ] && service_stop /usr/bin/$loop || killall $loop 2>/dev/null
	done
	
	# [ $(ps|grep ${PRG_REDIR}|grep -v grep|wc -l) -ge 1 ] && service_stop $PRG_REDIR || echo "no" #
	# echo -e '	SSR-Redir		\033[40;31;1m Stoped \033[0m '
	
	# [ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ] && service_stop $PRG_TUNNEL
	# echo -e '	SSR-Tunnel		\033[40;31;1m Stoped \033[0m '
	
	# [ $(ps|grep ${PRG_SERVER}|grep -v grep|wc -l) -ge 1 ] && service_stop $PRG_SERVER
	# echo -e '	SSR-Server		\033[40;31;1m Stoped \033[0m '
	
	# [ $(ps|grep ${PRG_LOCAL}|grep -v grep|wc -l) -ge 1 ] && service_stop $PRG_LOCAL
	# echo -e '	SSR-Local		\033[40;31;1m Stoped \033[0m '
	
	echo -e '	Ipset			\033[40;31;1m Disabled \033[0m '
	{
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
#	ipset destroy GFWList -!
	}  2>/dev/null

	sed -i -e "/cache-size=/d " \
		-e "/min-cache-ttl=/d" \
		-e "/no-resolv/d" \
		-e "/server=/d" $DNSMASQ_CONF
		
	rm -f $DNSMASQ_IPSET
	rm -f $DNSMASQ_SERVER
	rm -f -R $TMP_DIR

	/etc/init.d/firewall restart 2>/dev/null
	/etc/init.d/dnsmasq restart

	echo -e ' Shadowsocks-RSS Server		\033[40;31;1m Stoped \033[0m '
	echo ''
}

restart() {
	stop
	sleep 3
	start
}

status() {
	local enabled=`uci get shadowsocks-rss.@basic[0].enabled 2>/dev/null`
	local fast_open=`uci get shadowsocks-rss.@basic[0].fast_open 2>/dev/null`
	local proxy_mod=`uci get shadowsocks-rss.@basic[0].proxy_mod 2>/dev/null`
	local local_port=`uci get shadowsocks-rss.@basic[0].local_port 2>/dev/null`
	local with_tunnel=`uci get shadowsocks-rss.@basic[0].with_tunnel 2>/dev/null`
	local tunnel_port=`uci get shadowsocks-rss.@basic[0].tunnel_port 2>/dev/null`
	local ss_srv_port=`uci get shadowsocks-rss.@basic[0].ss_srv_port 2>/dev/null`
	local ss_local_port=`uci get shadowsocks-rss.@basic[0].ss_local_port 2>/dev/null`
	local ss_server=`uci get shadowsocks-rss.@basic[0].ss_server 2>/dev/null`
	local ss_local=`uci get shadowsocks-rss.@basic[0].ss_local 2>/dev/null`
	local dns_server=`uci get shadowsocks-rss.@basic[0].dns_server 2>/dev/null`
	local other_dns=`uci get shadowsocks-rss.@basic[0].other_dns 2>/dev/null`

	echo -e '\033[40;33;1m Shadowsocks-RSS Server Status: \033[0m'
	echo ''
	[ $enabled == 1 ] && echo -e '	Autostarts: 		\033[40;32;1m Enable \033[0m' || echo -e '	Autostarts: 		\033[40;31;1m Disable \033[0m'
	[ $fast_open -a $fast_open == 1 ] && echo -e '	TCP Fast Open: 		\033[40;32;1m Enable \033[0m' || echo -e '	TCP Fast Open: 		\033[40;31;1m Disable \033[0m'
	case $proxy_mod in
	G)
	echo -e '	Proxy Mod: 		\033[40;32;1m GFWList \033[0m'
	;;
	C)
	echo -e '	Proxy Mod: 		\033[40;32;1m Other Than China \033[0m'
	;;
	A)
	echo -e '	Proxy Mod: 		\033[40;32;1m All Public IP address \033[0m'
	;;
	esac

	if [ $ss_server == 1 -a $ss_local == 1 ]
	then
		echo -e '	Other Service: 		\033[40;33;1m ss-server + ss-local \033[0m'
	else if [ $ss_server == 1 -a $ss_local == 0 ]
		then
			echo -e '	Other Service: 		\033[40;33;1m ss-server \033[0m'
		else if [ $ss_server == 0 -a $ss_local == 1 ]
			then 
				echo -e '	Other Service: 		\033[40;33;1m ss-local \033[0m'
			else echo -e '	Other Service: 		\033[40;31;1m Disabled \033[0m'
			fi
		fi
	fi
	echo ''
	[ $(ps|grep ${PRG_REDIR}|grep -v grep|wc -l) -ge 1 ] && echo -e "	SSR-Redir		\033[40;32;1m Running \033[0m 		Port: \033[40;34;1m $local_port \033[0m	PID: \033[40;34;1m $(pidof ${PRG_REDIR##*/}) \033[0m" || echo -e '	SSR-Redir		\033[40;31;1m Stopped \033[0m '

	case $dns_server in
	T)
	[ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ] && echo -e "	SSR-Tunnel		\033[40;32;1m Running \033[0m 		Port: \033[40;34;1m $tunnel_port \033[0m	PID: \033[40;34;1m $(pidof ${PRG_TUNNEL##*/}) \033[0m" || echo -e '	SSR-Tunnel		\033[40;31;1m Stopped \033[0m '
	;;
	O)
	echo -e "	DNS-Server		\033[40;32;1m $other_dns \033[0m"
	[ $with_tunnel -a $with_tunnel  == 1 ] && {
		[ $(ps|grep ${PRG_TUNNEL}|grep -v grep|wc -l) -ge 1 ] && echo -e "	SSR-Tunnel		\033[40;32;1m Running \033[0m 		Port: \033[40;34;1m $tunnel_port \033[0m	PID: \033[40;34;1m $(pidof ${PRG_TUNNEL##*/}) \033[0m" || echo -e '	SSR-Tunnel		\033[40;31;1m Stopped \033[0m '
	}
	;;
	N)
	echo -e '	DNS-Server		\033[40;32;1m System Default \033[0m Besure your system DNS is clean.'
	;;
	esac

	[ $(ps|grep ${PRG_SERVER}|grep -v grep|wc -l) -ge 1 ] && echo -e "	SSR-Server		\033[40;32;1m Running \033[0m 		Port: \033[40;34;1m $ss_srv_port \033[0m	PID: \033[40;34;1m $(pidof ${PRG_SERVER##*/}) \033[0m" || echo -e '	SSR-Server		\033[40;31;1m Stopped \033[0m ' 
	[ $(ps|grep ${PRG_LOCAL}|grep -v grep|wc -l) -ge 1 ] && echo -e "	SSR-Local		\033[40;32;1m Running \033[0m 		Port: \033[40;34;1m $ss_local_port \033[0m	PID: \033[40;34;1m $(pidof ${PRG_LOCAL##*/}) \033[0m" || echo -e '	SSR-Local		\033[40;31;1m Stopped \033[0m ' 
	[ $(ps|grep ${PRG_DNSMASQ}|grep -v grep|wc -l) -ge 1 ] && echo -e "	DNSMasq			\033[40;32;1m Running \033[0m 		Port: \033[40;34;1m 53 \033[0m	PID: \033[40;34;1m $(pidof ${PRG_DNSMASQ##*/}) \033[0m" || echo -e '	DNSMasq			\033[40;31;1m Stopped \033[0m ' 
	echo ''
}

update_list() {
	mkdir -p $TMP_DIR

	echo 'GFWList Updating...'
	cp $GFWLIST $LIST_DIR/GFWList.backup

	wget --no-check-certificate -q -P $TMP_DIR $GFWLIST_URL
	[ -e $TMP_DIR/domains.txt ] && cp $TMP_DIR/domains.txt $GFWLIST && echo '	GFWList Updated. '|| echo '	Download GFWList Fail. '
	rm -f $TMP_DIR/domains.txt
	echo ''

	echo 'ChinaList Updating...'
	cp $CHINALIST $LIST_DIR/ChinaList.backup
	curl --progress-bar $CHINALIST_URL \
		| grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > $TMP_DIR/ChinaList.txt 
	[ -e $TMP_DIR/ChinaList.txt ] && cp $TMP_DIR/ChinaList.txt $CHINALIST && echo '	ChinaList Updated. ' || echo '	Download ChinaList Fail. '
	rm -f $TMP_DIR/ChinaList.txt

	echo 'ChinaDomainList Updating...'
	cp $CHINADOMAINLIST $LIST_DIR/ChinaDomainList.backup
	
	wget --no-check-certificate -q -P $TMP_DIR $CHINACDNLIST_URL -O ChinaCDNList.txt
	wget --no-check-certificate -q -P $TMP_DIR $CHINADOMAINLIST_URL -O ChinaDomainList.txt
	
	cat $TMP_DIR/ChinaCDNList.txt $TMP_DIR/ChinaDomainList.txt > $TMP_DIR/ChinaDomainList-tmp.txt
	
	[ -e $TMP_DIR/ChinaDomainList.txt ] && cp $TMP_DIR/ChinaDomainList-tmp.txt $CHINADOMAINLIST && echo '	ChinaDomainList Updated. ' || echo '	Download ChinaDomainList Fail. '
	rm -f $TMP_DIR/ChinaDomainList.txt
}

update_ipsetrules () {
	echo ''
	config_load shadowsocks-rss
	config_foreach ssr_header

	case $PROXY_MOD in
	G)
#	GFW List
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
	awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"gfwlist"'\n",$0)}' $GFWLIST > $DNSMASQ_IPSET
	awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"gfwlist"'\n",$0)}' $USER_LIST >> $DNSMASQ_IPSET
	;;
	C)
#	ALL the IP address not China
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
	awk '!/^$/&&!/^#/{printf("add ChinaList %s''\n",$0)}' $CHINALIST > $TMP_DIR/ChinaList.ipset
	;;
	A)
#	All Public IP address
	awk '!/^$/&&!/^#/{printf("add BypassList %s''\n",$0)}' $BYPASSLIST > $TMP_DIR/BypassList.ipset
	;;
	esac
	echo -e ' 	DNS Rules		\033[40;32;1m Updated \033[0m '
	echo ''
}

help() {

	echo -e 'Available Commands:'
	echo -e '	\033[40;33;1m status \033[0m	Checking Program status.'
	echo -e "	\033[40;33;1m udate_list \033[0m	Update ChinaList And GFWList. Buckup Is in The Floder $LIST_DIR"
	echo -e '	\033[40;33;1m help	 \033[0m	This help. '

}

case $1 in
	help) help;shift 1;;
	h) help;shift 1;;
	-h) help;shift 1;;
esac
