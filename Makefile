# Copyright 2015 
# Matthew

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-shadowsocks-rss
PKG_VERSION:= 1.0
PKG_RELEASE:= 1.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-shadowsocks-rss
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI for shadowsocks-rss
	PKGARCH:=all
endef

define Package/luci-app-shadowsocks-rss/description
	LuCI for shadowsocks-rss. 
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-shadowsocks-rss/conffiles
/etc/config/shadowsocks-rss
endef

define Package/luci-app-shadowsocks-rss/preinst
endef

define Package/luci-app-shadowsocks-rss/postinst
#!/bin/sh
	/etc/init.d/shadowsocks-rss.sh enable
	[ -e /etc/init.d/shadowsocksr ] && /etc/init.d/shadowsocksr disable
	[ -e /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks disable
	/etc/init.d/shadowsocks-rss.sh help
exit 0
endef

define Package/luci-app-shadowsocks-rss/prerm
#!/bin/sh
	/etc/init.d/shadowsocks-rss.sh stop
	[ -e /etc/init.d/shadowsocksr ] && /etc/init.d/shadowsocksr enable
	[ -e /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks enable
exit 0
endef

define Package/luci-app-shadowsocks-rss/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/shadowsocks-rss $(1)/etc/config/shadowsocks-rss
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/shadowsocks-rss.sh $(1)/etc/init.d/shadowsocks-rss.sh
	
	$(INSTALL_DIR) $(1)/etc/shadowsocks-rss/list
	$(INSTALL_DATA) ./files/etc/shadowsocks-rss/list/BypassList $(1)/etc/shadowsocks-rss/list/BypassList
	$(INSTALL_DATA) ./files/etc/shadowsocks-rss/list/ChinaList $(1)/etc/shadowsocks-rss/list/ChinaList
	$(INSTALL_DATA) ./files/etc/shadowsocks-rss/list/GFWList $(1)/etc/shadowsocks-rss/list/GFWList
	$(INSTALL_DATA) ./files/etc/shadowsocks-rss/list/UserList $(1)/etc/shadowsocks-rss/list/UserList
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/controller/shadowsocks-rss.lua $(1)/usr/lib/lua/luci/controller/shadowsocks-rss.lua
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./files/usr/model/shadowsocks-rss.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocks-rss.lua
endef


$(eval $(call BuildPackage,luci-app-shadowsocks-rss))
