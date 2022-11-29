From 57dd58a14c9ac153eff04871b05fc571766be32d Mon Sep 17 00:00:00 2001
From: Martin Schiller <ms@dev.tdt.de>
Date: Wed, 28 Jun 2023 09:08:52 +0200
Subject: [PATCH] ovpn-dco: Update to v0.2.20230426

OpenVPN 2.6.2+ changes the way OpenVPN control packets are handled on
Linux when DCO is active, fixing the lockups observed with 2.6.0/2.6.1
under high client connect/disconnect activity. This is an INCOMPATIBLE
change and therefore an ovpn-dco kernel module older than v0.2.20230323
(commit ID 726fdfe0fa21) will not work anymore and must be upgraded.
The kernel module was renamed to "ovpn-dco-v2.ko" in order to highlight
this change and ensure that users and userspace software could easily
understand which version is loaded. Attempting to use the old ovpn-dco
with 2.6.2+ will lead to disabling DCO at runtime.

Signed-off-by: Martin Schiller <ms@dev.tdt.de>
---
 kernel/ovpn-dco/Makefile | 23 +++++++++++------------
 1 file changed, 11 insertions(+), 12 deletions(-)

diff --git a/feeds/packages/kernel/ovpn-dco/Makefile b/feeds/packages/kernel/ovpn-dco/Makefile
index e278a0eb3e1ab..53ab890ae444b 100644
--- a/feeds/packages/kernel/ovpn-dco/Makefile
+++ b/feeds/packages/kernel/ovpn-dco/Makefile
@@ -9,13 +9,12 @@ include $(TOPDIR)/rules.mk
 include $(INCLUDE_DIR)/kernel.mk
 
 PKG_NAME:=ovpn-dco
-PKG_SOURCE_DATE:=2022-10-23
-PKG_RELEASE:=3
+PKG_VERSION:=0.2.20240320
+PKG_RELEASE:=1
 
-PKG_SOURCE_PROTO:=git
-PKG_SOURCE_URL=https://github.com/OpenVPN/ovpn-dco.git
-PKG_SOURCE_VERSION:=d1d53564e17d807aed2b945ea3d4ec35bdd9f09b
-PKG_MIRROR_HASH:=d3152623383676d314cb6e4861cadeebfe75b0cf9b2607c86cce1f3953d906ed
+PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
+PKG_SOURCE_URL=https://codeload.github.com/OpenVPN/ovpn-dco/tar.gz/v$(PKG_VERSION)?
+PKG_HASH:=83a02dc3e6e40b0ef128cd32ce7f47da7fccd759af68657f44925d64a88db37b
 
 PKG_MAINTAINER:=Jianhui Zhao <zhaojh329@gmail.com>
 PKG_LICENSE:=GPL-2.0-only
@@ -23,15 +22,16 @@ PKG_LICENSE:=GPL-2.0-only
 
 include $(INCLUDE_DIR)/package.mk
 
-define KernelPackage/ovpn-dco
+define KernelPackage/ovpn-dco-v2
   SUBMENU:=Network Support
   TITLE:=OpenVPN data channel offload
-  DEPENDS:=+kmod-crypto-aead +kmod-udptunnel4 +kmod-udptunnel6
-  FILES:=$(PKG_BUILD_DIR)/drivers/net/ovpn-dco/ovpn-dco.ko
-  AUTOLOAD:=$(call AutoLoad,30,ovpn-dco)
+  DEPENDS:=+kmod-crypto-aead +kmod-udptunnel4 +IPV6:kmod-udptunnel6 \
+     +kmod-crypto-chacha20poly1305 +kmod-crypto-lib-chacha20 +kmod-crypto-lib-poly1305
+  FILES:=$(PKG_BUILD_DIR)/drivers/net/ovpn-dco/ovpn-dco-v2.ko
+  AUTOLOAD:=$(call AutoLoad,30,ovpn-dco-v2)
 endef
 
-define KernelPackage/ovpn-dco/description
+define KernelPackage/ovpn-dco-v2/description
   This module enhances the performance of the OpenVPN userspace software
   by offloading the data channel processing to kernelspace.
 endef
@@ -38,10 +38,11 @@ NOSTDINC_FLAGS += \
 NOSTDINC_FLAGS += \
 	$(KERNEL_NOSTDINC_FLAGS) \
 	-I$(PKG_BUILD_DIR)/include \
+	-I$(PKG_BUILD_DIR)/compat-include \
 	-include $(PKG_BUILD_DIR)/linux-compat.h
 
 EXTRA_KCONFIG:= \
-	CONFIG_OVPN_DCO=m
+	CONFIG_OVPN_DCO_V2=m
 
 PKG_EXTMOD_SUBDIRS = drivers/net/ovpn-dco
 
@@ -58,4 +57,4 @@ define Build/Compile
 		modules
 endef
 
-$(eval $(call KernelPackage,ovpn-dco))
+$(eval $(call KernelPackage,ovpn-dco-v2))