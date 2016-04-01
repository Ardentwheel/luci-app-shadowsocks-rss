-- Copyright 2015
-- Matthew
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.shadowsocks-rss", package.seeall)

function index()

	local page

	page = entry({"admin", "services", "shadowsocks-rss"}, cbi("shadowsocks-rss"), _("Shadowsocks-RSS"))
	page.dependent = true
end
