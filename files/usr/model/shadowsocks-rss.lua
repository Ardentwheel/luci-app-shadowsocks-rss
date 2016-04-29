-- Copyright 2015
-- Matthew
-- Licensed to the public under the Apache License 2.0.

local fs = require "nixio.fs"

local state_msg = ""
local ss_redir_on = (luci.sys.call("pidof ssr-redir > /dev/null") == 0)
if ss_redir_on then	
	state_msg = "<b><font color=\"green\">" .. translate("Running") .. "</font></b>"
else
	state_msg = "<b><font color=\"red\">" .. translate("Not running") .. "</font></b>"
end

local method_list = {
	"table",
	"rc4",
	"rc4-md5",
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"bf-cfb",
	"camellia-128-cfb",
	"camellia-192-cfb",
	"camellia-256-cfb",
	"cast5-cfb",
	"des-cfb",
	"idea-cfb",
	"rc2-cfb",
	"seed-cfb",
	"salsa20",
	"chacha20",
	"chacha20-ietf",
}

local protocol_list = {
	"origin",
	"verify_simple",
	"verify_deflate",
	"auth_simple",
	"auth_sha1",
	"auth_sha1_v2"
}

local obfs_list = {
	"plain",
	"http_simple",
	"tls_simple",
	"random_hesd",
	"tls1.0_session_auth",
	"tls1.2_ticket_auth",
}

m = Map("shadowsocks-rss", translate("Shadowsocks-RSS"),
	translate("A fast secure tunnel proxy that help you get through firewalls on your router") .. " - " .. state_msg)

basic = m:section(TypedSection, "basic", "")
basic.anonymous = true

basic:tab("general", translate("General Settings"))
basic:tab("dns_page", translate("DNS"))
basic:tab("advanced", translate("Advanced Settings"))
basic:tab("ipset", translate("ipset Settings"))

---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


-- General Settings
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    

switch = basic:taboption("general", Flag, "enabled", translate("Enable"), translate("<a href=\"https://github.com/breakwa11/shadowsocks-rss/wiki\" target=\"_black\">Documents</a>"))
switch.rmempty = false

fast_open = basic:taboption("general", Flag, "fast_open", translate("TCP Fast Open"),
	translate("IPv4 support needs Liunx version newer than 3.7. IPv6 TFO support needs Liunx version newer than 3.16."))
fast_open.rmempty = false

proxy_mod = basic:taboption("general", ListValue, "proxy_mod", translate("Proxy Mod"))
proxy_mod:value("G", "GFW List")
proxy_mod:value("C", "Other Than China")
proxy_mod:value("A", "All Public IP address")
proxy_mod.default = "G"
proxy_mod.rmempty = false

server = basic:taboption("general", Value, "server", translate("Server Address"))
server.default = "8.8.8.8"
server.datatype = "ipaddr"
server.rmempty = false

server_port = basic:taboption("general", Value, "server_port", translate("Server Port"))
server_port.default = "443"
server_port.datatype = "port"
server_port.rmempty = false

local_port = basic:taboption("general", Value, "local_port", translate("Local Port"))
local_port.default = "1080"
local_port.datatype = "port"
local_port.rmempty = false

password = basic:taboption("general", Value, "password", translate("Password"))
password.default = "password"
password.password = true
password.rmempty = false

one_auth = basic:taboption("general", Flag, "one_auth", translate("Onetime Authentication"),
	translate(""))
one_auth.rmempty = false

method = basic:taboption("general", ListValue, "method", translate("Encryption Method"))
for _, value in ipairs(method_list) do method:value(value) end
method.default = "table"
method.rmempty = false

protocol = basic:taboption("general", ListValue, "protocol", translate("Protocol"))
for _, value in ipairs(protocol_list) do protocol:value(value) end
protocol.rmempty = false

protocol_param = basic:taboption("general", Value, "protocol_param", translate("Protocol Param"))
protocol_param:value("", "Disable")

obfs = basic:taboption("general", ListValue, "obfs", translate("Obfs"))
for _, value in ipairs(obfs_list) do obfs:value(value) end
obfs.default = "plain"
obfs.rmempty = false

obfs_param = basic:taboption("general", Value, "obfs_param", translate("Obfs Param"))
obfs_param:value("", "Disable")
obfs_param:value("cloudfront.net")
obfs_param:value("cloudfront.net,cloudfront.com")
obfs_param:value("youku.com,cloudfront.net,sohu.com,bilibili.com")
obfs_param.default = ""
obfs_param:depends("obfs", "http_simple")
obfs_param:depends("obfs", "tls1.2_ticket_auth")

timeout = basic:taboption("general", Value, "timeout", translate("timeout"))
timeout:value("30")
timeout:value("60")
timeout:value("120")
timeout:value("200")
timeout:value("300")
timeout:value("600")
timeout.default = "120"
timeout.rmempty = false


---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


-- DNS
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    

dns_server = basic:taboption("dns_page", ListValue, "dns_server", translate("DNS Server"), translate("System Default：Besure your system DNS is clean. "))
dns_server:value("T", "Shadowsocks Tunnel")
dns_server:value("O", "Other DNS Server")
dns_server:value("N", "System Default")
dns_server.default = "T"
dns_server.rmempty = false

with_tunnel = basic:taboption("dns_page", Flag, "with_tunnel", translate("Shadowsocks Tunnel"), translate(""))
with_tunnel.default = "0"
with_tunnel:depends("dns_server", "O")

tunnel_port = basic:taboption("dns_page", Value, "tunnel_port", translate("Tunnel Port"))
tunnel_port.default = "5353"
tunnel_port.datatype = "port"
tunnel_port:depends("dns_server", "T")
tunnel_port:depends("with_tunnel", "1")

dns_server_addr = basic:taboption("dns_page", Value, "dns_server_addr", translate("DNS Address"), translate("Tunnel Listening DNS Address (IP:port)"))
dns_server_addr:value("8.8.8.8:53")
dns_server_addr:value("8.8.4.4:53")
dns_server_addr:value("208.67.220.220:443")
dns_server_addr:value("208.67.222.222:5353")
dns_server_addr.default = "8.8.8.8:53"
dns_server_addr:depends("dns_server", "T")
dns_server_addr:depends("with_tunnel", "1")

other_dns_overall = basic:taboption("dns_page", Flag, "other_dns_overall", translate("Overall Upstream DNS"), translate("All request will handed over to the DNS set below. "))
other_dns_overall.default = "0"
other_dns_overall:depends("dns_server", "O")

other_dns = basic:taboption("dns_page", Value, "other_dns", translate("Other DNS Server"), translate("Default:Only the domain mach GFWList will be handed over to the DNS set above. IP#port"))
other_dns:value("127.0.0.1#1053")
other_dns.default = "127.0.0.1#1053"
other_dns:depends("dns_server", "O")

dns_server_addr = basic:taboption("dns_page", Value, "dns_server_addr", translate("DNS Address"), translate("Tunnel Listening DNS Address (IP:port)"))
dns_server_addr:value("8.8.8.8:53")
dns_server_addr:value("8.8.4.4:53")
dns_server_addr:value("208.67.220.220:443")
dns_server_addr:value("208.67.222.222:5353")
dns_server_addr.default = "8.8.8.8:53"
dns_server_addr:depends("dns_server", "T")

dns_cache = basic:taboption("dns_page", Value, "dns_cache", translate("DNS Cache Max Quantity"))
dns_cache:value("150")
dns_cache:value("300")
dns_cache:value("900")
dns_cache.default = "300"
dns_cache.rmempty = false

dns_cache_ttl = basic:taboption("dns_page", Value, "dns_cache_ttl", translate("DNS Cache Timeout"))
dns_cache_ttl:value("300")
dns_cache_ttl:value("900")
dns_cache_ttl:value("1800")
dns_cache_ttl.default = "900"
dns_cache_ttl.rmempty = false




---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


-- Advanced Settings
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    

random_port = basic:taboption("advanced", Flag, "random_port", translate("Enable Random Port"),
	translate("Need Server Support"))
random_port.rmempty = false

random_port_A = basic:taboption("advanced", Value, "random_port_A", translate("Local Mod Port"))
random_port_A.datatype = "port"
random_port_A:depends("random_port", "1")

random_port_O = basic:taboption("advanced", Value, "random_port_O", translate("Local Mod Port"))
random_port_O.datatype = "port"
random_port_O:depends("random_port", "1")

ss_local = basic:taboption("advanced", Flag, "ss_local", translate("Enable Local Mod"))
ss_local.rmempty = false

ss_local_listen = basic:taboption("advanced", Value, "ss_local_listen", translate("Server Listening Address"))
ss_local_listen:value("0.0.0.0")
ss_local_listen:value("127.0.0.1")
ss_local_listen.default = "0.0.0.0"
ss_local_listen.datatype = "ipaddr"
ss_local_listen:depends("ss_server", "1")

ss_local_port = basic:taboption("advanced", Value, "ss_local_port", translate("Local Mod Port"))
ss_local_port.default = "1085"
ss_local_port.datatype = "port"
ss_local_port:depends("ss_local", "1")

ss_server = basic:taboption("advanced", Flag, "ss_server", translate("Enable Server Mod"))
ss_server.rmempty = false

ss_srv_fastopen = basic:taboption("advanced", Flag, "ss_srv_fastopen", translate("TCP Fast Open"),
	translate("IPv4 support needs Liunx version newer than 3.7. IPv6 TFO support needs Liunx version newer than 3.16."))
ss_srv_fastopen:depends("ss_server", "1")

ss_srv_listen = basic:taboption("advanced", Value, "ss_srv_listen", translate("Server Listening Address"))
ss_srv_listen:value("0.0.0.0")
ss_srv_listen:value("127.0.0.1")
ss_srv_listen.default = "0.0.0.0"
ss_srv_listen.datatype = "ipaddr"
ss_srv_listen:depends("ss_server", "1")

ss_srv_port = basic:taboption("advanced", Value, "ss_srv_port", translate("Server Mod Port"))
ss_srv_port.default = "1090"
ss_srv_port.datatype = "port"
ss_srv_port:depends("ss_server", "1")

ss_srv_pwd = basic:taboption("advanced", Value, "ss_srv_pwd", translate("Password"))
ss_srv_pwd.default = "password"
ss_srv_pwd:depends("ss_server", "1")
ss_srv_pwd.password = true

srv_one_auth = basic:taboption("advanced", Flag, "srv_one_auth", translate("Onetime Authentication"),
	translate(""))

ss_srv_method = basic:taboption("advanced", ListValue, "ss_srv_method", translate("Encryption Method"))
for _, value in ipairs(method_list) do ss_srv_method:value(value) end
ss_srv_method:depends("ss_server", "1")

ss_srv_prot = basic:taboption("advanced", ListValue, "ss_srv_prot", translate("Protocol"))
ss_srv_prot:value("origin")
ss_srv_prot:value("verify_simple")
ss_srv_prot:value("verify_deflate")
ss_srv_prot:value("verify_sha1")
ss_srv_prot:value("verify_sha1_compatible")
ss_srv_prot:value("auth_simple")
ss_srv_prot:value("auth_sha1")
ss_srv_prot:value("auth_sha1_compatible")
ss_srv_prot:value("auth_sha1_v2")
ss_srv_prot:value("auth_sha1_v2_compatible")
ss_srv_prot.default = "origin"
ss_srv_prot:depends("ss_server", "1")

ss_srv_prot_param = basic:taboption("advanced", Value, "ss_srv_prot_param", translate("Protocol Param"))
ss_srv_prot_param:value("", "Disable")
ss_srv_prot_param:depends("ss_server", "1")
 
ss_srv_obfs = basic:taboption("advanced", ListValue, "ss_srv_obfs", translate("Obfs"))
ss_srv_obfs:value("plain")
ss_srv_obfs:value("http_simple")
ss_srv_obfs:value("http_simple_compatible")
ss_srv_obfs:value("tls_simple")
ss_srv_obfs:value("tls_simple_compatible")
ss_srv_obfs:value("random_hesd")
ss_srv_obfs:value("random_hesd_compatible")
ss_srv_obfs:value("tls1.0_session_auth")
ss_srv_obfs:value("tls1.0_session_auth_compatible")
ss_srv_obfs:value("tls1.2_ticket_auth")
ss_srv_obfs:value("tls1.2_ticket_auth_compatible")
ss_srv_obfs. = "plain"
ss_srv_obfs:depends("ss_server", "1")

ss_srv_obfs_param = basic:taboption("advanced", Value, "ss_srv_obfs_param", translate("Obfs Param"))
ss_srv_obfs_param:value("", "Disable")
ss_srv_obfs_param:depends("ss_srv_obfs", "http_simple")
ss_srv_obfs_param:depends("ss_srv_obfs", "http_simple_compatible")
ss_srv_obfs_param:depends("ss_srv_obfs", "tls1.2_ticket_auth")
ss_srv_obfs_param:depends("ss_srv_obfs", "tls1.2_ticket_auth_compatible")

ss_srv_timeout = basic:taboption("advanced", Value, "ss_srv_timeout", translate("Timeout"))
ss_srv_timeout:value("30")
ss_srv_timeout:value("60")
ss_srv_timeout:value("120")
ss_srv_timeout:value("200")
ss_srv_timeout:value("300")
ss_srv_timeout:value("600")
ss_srv_timeout.default = "120"
ss_srv_timeout:depends("ss_server", "1")


---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


--Ipset Settings
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


button_update_list = basic: taboption ("ipset", Button, "_button_update_list", "GFWList update") 
button_update_list.inputtitle = translate ( "Update GFWList Rules")
button_update_list.inputstyle = "apply" 
function button_update_list.write (self, section, value)
	luci.sys.call ( "/etc/init.d/shadowsocks-rss.sh update_list")
end 

--[[
userlist = basic: taboption ("ipset", Button, "_button_update_dnsrules", "Ipset Rules update", translate ( "Click, If you change the User List Below. ")) 
userlist.inputtitle = translate ( "Update Ipset Rules ")
userlist.inputstyle = "apply" 
]]--

userlist = basic:taboption("ipset", Value, "_tmpl",
	translate("User's List"), 
	translate(""))
userlist.template = "cbi/tvalue"
userlist.rows = 25

function userlist.cfgvalue(self, section)
	return nixio.fs.readfile("/etc/shadowsocks-rss/list/UserList")
end

function userlist.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("//etc/shadowsocks-rss/list/UserList", value)
end
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/shadowsocks-rss.sh restart")
end



return m
