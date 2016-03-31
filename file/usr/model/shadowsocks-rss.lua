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
proxy_mod:value("C", "ALL the IP address not China")
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

one_AUT = basic:taboption("general", Flag, "one_AUT", translate("Onetime Authentication"),
	translate(""))
one_AUT.rmempty = false

method = basic:taboption("general", ListValue, "method", translate("Encryption Method"))
method:value("table")
method:value("aes-128-cfb")
method:value("aes-192-cfb")
method:value("aes-256-cfb")
method:value("bf-cfb")
method:value("camellia-128-cfb")
method:value("camellia-192-cfb")
method:value("camellia-256-cfb")
method:value("cast5-cfb")
method:value("chacha20")
method:value("chacha20-ietf")
method:value("des-cfb")
method:value("idea-cfb")
method:value("rc2-cfb")
method:value("rc4")
method:value("rc4-md5")
method:value("seed-cfb")
method:value("salsa20")
method.default = "table"
method.rmempty = false

protocol = basic:taboption("general", ListValue, "protocol", translate("Protocol"))
protocol:value("origin")
protocol:value("verify_simple")
protocol:value("verify_deflate")
protocol:value("auth_simple")
protocol:value("auth_sha1")
protocol:value("auth_sha1_v2")
protocol.default = "origin"
protocol.rmempty = false

protocol_param = basic:taboption("general", Value, "protocol_param", translate("protocol_param"))


obfs = basic:taboption("general", ListValue, "obfs", translate("Obfs"))
obfs:value("plain")
obfs:value("http_simple")
obfs:value("tls_simple")
obfs:value("random_hesd")
obfs:value("tls1.0_session_auth")
obfs.default = "plain"
obfs.rmempty = false

obfs_param = basic:taboption("general", Value, "obfs_param", translate("obfs_param"))
obfs_param:value("youku.com,sohu.com,bilibili.com")
obfs_param.default = "youku.com,sohu.com,bilibili.com"
obfs_param:depends("obfs", "http_simple")

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
dns_server:value("O", "Other DNS Server")
dns_server:value("T", "Shadowsocks Tunnel")
dns_server:value("N", "System Default")
dns_server.default = "T"
dns_server.rmempty = false

tunnel_port = basic:taboption("dns_page", Value, "tunnel_port", translate("Shadowsocks Tunnel Port"))
tunnel_port.default = "5353"
tunnel_port.datatype = "port"
tunnel_port:depends("dns_server", "T")

dns_server_addr = basic:taboption("dns_page", Value, "dns_server_addr", translate("DNS Address"), translate("Tunnel Listening DNS Address (IP:port)"))
dns_server_addr:value("8.8.8.8:53")
dns_server_addr:value("8.8.4.4:53")
dns_server_addr:value("208.67.220.220:443")
dns_server_addr:value("208.67.222.222:5353")
dns_server_addr.default = "8.8.8.8:53"
dns_server_addr:depends("dns_server", "T")

other_dns_overall = basic:taboption("dns_page", Flag, "other_dns_overall", translate("Overall Upstream DNS"), translate("All request will handed over to the DNS set below. "))
other_dns_overall.default = "0"
other_dns_overall:depends("dns_server", "O")

other_dns = basic:taboption("dns_page", Value, "other_dns", translate("Other DNS Server"), translate("Default:Only the domain mach GFWList will be handed over to the DNS set above. IP#port"))
other_dns:value("127.0.0.1#1053")
other_dns.default = "127.0.0.1#1053"
other_dns:depends("dns_server", "O")


---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


-- Advanced Settings
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    

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

ss_srv_port = basic:taboption("advanced", Value, "ss_srv_port", translate("Shadowsocks Server Mod Port"))
ss_srv_port.default = "1085"
ss_srv_port.datatype = "port"
ss_srv_port:depends("ss_server", "1")

ss_srv_pwd = basic:taboption("advanced", Value, "ss_srv_pwd", translate("Password"))
ss_srv_pwd.default = "password"
ss_srv_pwd:depends("ss_server", "1")
ss_srv_pwd.password = true

ss_srv_method = basic:taboption("advanced", ListValue, "ss_srv_method", translate("Encryption Method"))
ss_srv_method:value("table")
ss_srv_method:value("aes-128-cfb")
ss_srv_method:value("aes-192-cfb")
ss_srv_method:value("aes-256-cfb")
ss_srv_method:value("bf-cfb")
ss_srv_method:value("camellia-128-cfb")
ss_srv_method:value("camellia-192-cfb")
ss_srv_method:value("camellia-256-cfb")
ss_srv_method:value("cast5-cfb")
ss_srv_method:value("chacha20")
ss_srv_method:value("chacha20-ietf")
ss_srv_method:value("des-cfb")
ss_srv_method:value("idea-cfb")
ss_srv_method:value("rc2-cfb")
ss_srv_method:value("rc4")
ss_srv_method:value("rc4-md5")
ss_srv_method:value("seed-cfb")
ss_srv_method:value("salsa20")
ss_srv_method.default = "table"
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
ss_srv_prot_param:depends("ss_server", "1")
 
ss_srv_obfs = basic:taboption("advanced", ListValue, "ss_srv_obfs", translate("obfs"))
ss_srv_obfs:value("plain")
ss_srv_obfs:value("http_simple")
ss_srv_obfs:value("http_simple_compatible")
ss_srv_obfs:value("tls_simple")
ss_srv_obfs:value("tls_simple_compatible")
ss_srv_obfs:value("random_hesd")
ss_srv_obfs:value("random_hesd_compatible")
ss_srv_obfs:value("tls1.0_session_auth")
ss_srv_obfs:value("tls1.0_session_auth_compatible")
ss_srv_obfs.default = "plain"
ss_srv_obfs:depends("ss_server", "1")

ss_srv_obfs_param = basic:taboption("advanced", Value, "ss_srv_obfs_param", translate("obfs_param"))
ss_srv_obfs_param:depends("ss_srv_obfs", "http_simple")

ss_srv_timeout = basic:taboption("advanced", Value, "ss_srv_timeout", translate("Timeout"))
ss_srv_timeout:value("30")
ss_srv_timeout:value("60")
ss_srv_timeout:value("120")
ss_srv_timeout:value("200")
ss_srv_timeout:value("300")
ss_srv_timeout:value("600")
ss_srv_timeout.default = "120"
ss_srv_timeout:depends("ss_server", "1")


ss_local = basic:taboption("advanced", Flag, "ss_local", translate("Enable Local Mod"))
ss_local.rmempty = false

ss_local_port = basic:taboption("advanced", Value, "ss_local_port", translate("Shadowsocks Server Mod Port"))
ss_local_port.default = "1090"
ss_local_port.datatype = "port"
ss_local_port:depends("ss_local", "1")

---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


-- ipset Settings
---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    

button_update = basic: taboption ("ipset", Button, "_button_update", "GFWList update") 
button_update.inputtitle = translate ( "Update GFWList Rules") 
button_update.inputstyle = "apply" 
function button_update.write (self, section) 
luci.sys.call ( "") 
end 

gfwlist = basic:taboption("ipset", Value, "_tmpl",
	translate("GFWList"), 
	translate(""))
gfwlist.template = "cbi/tvalue"
gfwlist.rows = 25

function gfwlist.cfgvalue(self, section)
	return nixio.fs.readfile("/etc/shadowsocks-rss/list/UserList")
end

function gfwlist.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("//etc/shadowsocks-rss/list/UserList", value)
end

---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    ---------    


local apply = luci.http.formvalue("cbi.apply")
if apply then
	io.popen("/etc/init.d/shadowsocks-rss.sh restart")
end



return m
