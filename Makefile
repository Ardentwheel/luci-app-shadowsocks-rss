# Copyright 2015 
# Matthew

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-shadowsocks-rss
PKG_VERSION:= 1.0
PKG_RELEASE:= 1.0

#PO2LMO:=./bin/po2lmo
include $(INCLUDE_DIR)/package.mk

define Package/luci-app-shadowsocks-rss
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI for shadowsocks-rss
	PKGARCH:=all
	DEPENDS:=+ipset +iptables-mod-nat-extra 
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
<<<<<<< HEAD
	[ -e /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks disable
	/etc/init.d/shadowsocks-rss.sh help
=======
	[ -e /etc/init.d/shadowsocksr-server ] && /etc/init.d/shadowsocksr-server disable
>>>>>>> origin/master
exit 0
endef

define Package/luci-app-shadowsocks-rss/prerm
#!/bin/sh
	/etc/init.d/shadowsocks-rss.sh stop
	[ -e /etc/init.d/shadowsocksr ] && /etc/init.d/shadowsocksr enable
<<<<<<< HEAD
	[ -e /etc/init.d/shadowsocks ] && /etc/init.d/shadowsocks enable
=======
	[ -e /etc/init.d/shadowsocksr-server ] && /etc/init.d/shadowsocksr-server enable
>>>>>>> origin/master
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
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
#	$(INSTALL_DATA) ./files/usr/i18n/shadowsocks-rss.lmo $(1)/usr/lib/lua/luci/i18n/shadowsocks-rss.lmo
#	$(PO2LMO) ./po/zh-cn/shadowsocks-rss.po $(1)/usr/lib/lua/luci/i18n/shadowsocks-rss.lmo
endef


$(eval $(call BuildPackage,luci-app-shadowsocks-rss))
