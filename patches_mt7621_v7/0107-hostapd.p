From 52a5f4491c642fcb524494800ce64c5040901b86 Mon Sep 17 00:00:00 2001
From: Felix Fietkau <nbd@nbd.name>
Date: Wed, 1 May 2024 18:57:00 +0200
Subject: [PATCH] hostapd: fix a null pointer dereference in wpa_supplicant on
 teardown

Signed-off-by: Felix Fietkau <nbd@nbd.name>
---
 ...ull-pointer-check-in-hostapd_free_ha.patch | 20 +++++++++++++++++++
 1 file changed, 20 insertions(+)
 create mode 100644 package/network/services/hostapd/patches/052-AP-add-missing-null-pointer-check-in-hostapd_free_ha.patch

diff --git a/package/network/services/hostapd/patches/052-AP-add-missing-null-pointer-check-in-hostapd_free_ha.patch b/package/network/services/hostapd/patches/052-AP-add-missing-null-pointer-check-in-hostapd_free_ha.patch
new file mode 100644
index 0000000000000..85d5127f600d2
--- /dev/null
+++ b/package/network/services/hostapd/patches/052-AP-add-missing-null-pointer-check-in-hostapd_free_ha.patch
@@ -0,0 +1,20 @@
+From: Felix Fietkau <nbd@nbd.name>
+Date: Wed, 1 May 2024 18:55:24 +0200
+Subject: [PATCH] AP: add missing null pointer check in hostapd_free_hapd_data
+
+When called from wpa_supplicant, iface->interfaces can be NULL
+
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+
+--- a/src/ap/hostapd.c
++++ b/src/ap/hostapd.c
+@@ -502,7 +502,7 @@ void hostapd_free_hapd_data(struct hosta
+ 		struct hapd_interfaces *ifaces = hapd->iface->interfaces;
+ 		size_t i;
+ 
+-		for (i = 0; i < ifaces->count; i++) {
++		for (i = 0; ifaces && i < ifaces->count; i++) {
+ 			struct hostapd_iface *iface = ifaces->iface[i];
+ 			size_t j;
+ 
