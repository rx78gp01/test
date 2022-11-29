From 5c4c9ae05953884a75e1c2b0afb14759b9e6d6f8 Mon Sep 17 00:00:00 2001
From: Felix Fietkau <nbd@nbd.name>
Date: Mon, 29 Apr 2024 18:58:40 +0200
Subject: [PATCH] mt76: update to the latest version
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit

b5d13611d35e mt76: mt7915: fix monitor mode issues
bbbac7deee3d wifi: mt76: rename mt76_packet_id_init/flush to mt76_wcid_init/cleanup
f1e1e67d97d1 wifi: mt76: fix race condition related to checking tx queue fill status
b3f739a64e6b wifi: mt76: mt7996: add eht rx rate support
ca4917062f17 wifi: mt76: mt76x0: remove dead code in mt76x0_phy_get_target_power
325a0c493199 wifi: mt76: mt7996: fill txd by host driver
cd371fcc98d4 mt76: mt7996: sync with upstream
d71f8d1b172b wifi: mt76: use atomic iface iteration for pre-TBTT work
8d5ea32d4895 wifi: mt76: remove unused error path in mt76_connac_tx_complete_skb
01860c02c505 wifi: mt76: add DMA mapping error check in mt76_alloc_txwi()
62ddb6d46a97 wifi: mt76: connac: introduce helper for mt7925 chipset
0837f37e998b wifi: mt76: mt792x: support mt7925 chip init
899ff378082b wifi: mt76: connac: export functions for mt7925
c3858b5bf347 wifi: mt76: connac: add eht support for phy mode config
5df6b26a9fc5 wifi: mt76: connac: add eht support for tx power
a8081345c636 wifi: mt76: connac: add data field in struct tlv
9b38aebecf78 wifi: mt76: connac: add more unified command IDs
84984e6dc87d wifi: mt76: connac: add more unified event IDs
6fe92398c9ce wifi: mt76: mt7996: set correct wcid in txp
2cfe2fb0bb80 wifi: mt76: mt7996: fix beamform mcu cmd configuration
e512241bb5bb wifi: mt76: mt7996: fix beamformee ss subfield in EHT PHY cap
719a98f832c7 wifi: mt76: mt7996: fix wmm queue mapping
9723562f2a5b wifi: mt76: mt7996: fix rx rate report for CBW320-2
1bb5a6a54943 wifi: mt76: mt7996: fix TWT command format
751b054891f6 wifi: mt76: mt7996: only set vif teardown cmds at remove interface
fea1e10c7741 wifi: mt76: mt7996: support more options for mt7996_set_bitrate_mask()
d497ee8aa2f5 wifi: mt76: mt7996: support per-band LED control
8ccc84111141 wifi: mt76: Use PTR_ERR_OR_ZERO() to simplify code
161f70217edf wifi: mt76: mt7921e: Support MT7992 IP in Xiaomi Redmibook 15 Pro (2023)
7d25bfc3f0cc wifi: mt76: fix clang-specific fortify warnings
5971aa968401 wifi: mt76: connac: add MBSSID support for mt7996
5a47dd323be1 wifi: mt76: update beacon size limitation
d5b4b81dcc9e wifi: mt76: check sta rx control frame to multibss capability
af0e1f6dafb5 wifi: mt76: fix potential memory leak of beacon commands
65d91a833b01 wifi: mt76: get rid of false alamrs of tx emission issues
29411e52059f wifi: mt76: fix per-band IEEE80211_CONF_MONITOR flag comparison
4da62774038a wifi: mt76: check vif type before reporting cca and csa
4a85678fe089 wifi: mt76: mt7915: update mpdu density capability
791a45cffadf wifi: mt76: mt7915: fix beamforming availability check
08e1e6cb7d41 wifi: mt76: Drop unnecessary error check for debugfs_create_dir()
d1881b1b2bf6 wifi: mt76: move struct ieee80211_chanctx_conf up to struct mt76_vif
66d5694e1898 wifi: mt76: mt7921: fix the wrong rate pickup for the chanctx driver
9fc37b0ac546 wifi: mt76: mt7921: fix the wrong rate selected in fw for the chanctx driver
2afc7285f75d wifi: mt76: mt7925: add Mediatek Wi-Fi7 driver for mt7925 chips

Signed-off-by: Felix Fietkau <nbd@nbd.name>
(cherry picked from commit ef8e2f66f563d0d1864be37075dacf3f13defdc7)
Signed-off-by: Rafał Miłecki <rafal@milecki.pl>
---
 package/kernel/mt76/Makefile | 56 +++++++++++++++++++++++++++++++++---
 1 file changed, 52 insertions(+), 4 deletions(-)

diff --git a/package/kernel/mt76/Makefile b/package/kernel/mt76/Makefile
index 500735303f98a..dd75390ee76dd 100644
--- a/package/kernel/mt76/Makefile
+++ b/package/kernel/mt76/Makefile
@@ -1,16 +1,16 @@
 include $(TOPDIR)/rules.mk
 
 PKG_NAME:=mt76
-PKG_RELEASE=2
+PKG_RELEASE=1
 
 PKG_LICENSE:=GPLv2
 PKG_LICENSE_FILES:=
 
 PKG_SOURCE_URL:=https://github.com/openwrt/mt76
 PKG_SOURCE_PROTO:=git
-PKG_SOURCE_DATE:=2023-09-11
-PKG_SOURCE_VERSION:=f1e1e67d97d1e9a8bb01b59ab20c45ebc985a958
-PKG_MIRROR_HASH:=41fde79de5bec3aaafdb64658475a1fa99bc483b8122e6aad9b2aa8aa8edfce6
+PKG_SOURCE_DATE:=2023-09-18
+PKG_SOURCE_VERSION:=2afc7285f75dca5a0583fd917285bf33f1429cc6
+PKG_MIRROR_HASH:=2c9556b298246277ac2d65415e4449f98e6d5fdb99e0d0a92262f162df772bbc
 
 PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
 PKG_USE_NINJA:=0
@@ -315,6 +315,38 @@ define KernelPackage/mt7921e
   AUTOLOAD:=$(call AutoProbe,mt7921e)
 endef
 
+define KernelPackage/mt7996e
+  $(KernelPackage/mt76-default)
+  TITLE:=MediaTek MT7996E wireless driver
+  DEPENDS+=@PCI_SUPPORT +kmod-mt76-connac
+  FILES:= $(PKG_BUILD_DIR)/mt7996/mt7996e.ko
+  AUTOLOAD:=$(call AutoProbe,mt7996e)
+endef
+
+define KernelPackage/mt7925-common
+  $(KernelPackage/mt76-default)
+  TITLE:=MediaTek MT7925 wireless driver common code
+  HIDDEN:=1
+  DEPENDS+=+kmod-mt792x-common +@DRIVER_11AX_SUPPORT +kmod-hwmon-core
+  FILES:= $(PKG_BUILD_DIR)/mt7925/mt7925-common.ko
+endef
+
+define KernelPackage/mt7925u
+  $(KernelPackage/mt76-default)
+  TITLE:=MediaTek MT7925U wireless driver
+  DEPENDS+=+kmod-mt792x-usb +kmod-mt7925-common
+  FILES:= $(PKG_BUILD_DIR)/mt7925/mt7925u.ko
+  AUTOLOAD:=$(call AutoProbe,mt7921u)
+endef
+
+define KernelPackage/mt7925e
+  $(KernelPackage/mt76-default)
+  TITLE:=MediaTek MT7925e wireless driver
+  DEPENDS+=@PCI_SUPPORT +kmod-mt7925-common
+  FILES:= $(PKG_BUILD_DIR)/mt7925/mt7925e.ko
+  AUTOLOAD:=$(call AutoProbe,mt7921e)
+endef
+
 define Package/mt76-test
   SECTION:=devel
   CATEGORY:=Development
@@ -423,6 +455,18 @@ endif
 ifdef CONFIG_PACKAGE_kmod-mt7921e
   PKG_MAKE_FLAGS += CONFIG_MT7921E=m
 endif
+ifdef CONFIG_PACKAGE_kmod-mt7996e
+  PKG_MAKE_FLAGS += CONFIG_MT7996E=m
+endif
+ifdef CONFIG_PACKAGE_kmod-mt7925-common
+  PKG_MAKE_FLAGS += CONFIG_MT7925_COMMON=m
+endif
+ifdef CONFIG_PACKAGE_kmod-mt7925u
+  PKG_MAKE_FLAGS += CONFIG_MT7925U=m
+endif
+ifdef CONFIG_PACKAGE_kmod-mt7925e
+  PKG_MAKE_FLAGS += CONFIG_MT7925E=m
+endif
 
 define Build/Compile
 	+$(KERNEL_MAKE) $(PKG_JOBS) \
@@ -603,8 +647,12 @@ $(eval $(call KernelPackage,mt7922-firmware))
 $(eval $(call KernelPackage,mt792x-common))
 $(eval $(call KernelPackage,mt792x-usb))
 $(eval $(call KernelPackage,mt7921-common))
+$(eval $(call KernelPackage,mt7925-common))
 $(eval $(call KernelPackage,mt7921u))
 $(eval $(call KernelPackage,mt7921s))
 $(eval $(call KernelPackage,mt7921e))
+$(eval $(call KernelPackage,mt7925u))
+$(eval $(call KernelPackage,mt7925e))
+$(eval $(call KernelPackage,mt7996e))
 $(eval $(call KernelPackage,mt76))
 $(eval $(call BuildPackage,mt76-test))
