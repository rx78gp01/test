From 3129664c702a482c4a5766c880e5759a3eaa3dfc Mon Sep 17 00:00:00 2001
From: Paul Donald <newtwen+github@gmail.com>
Date: Wed, 17 Apr 2024 02:49:49 +0200
Subject: [PATCH] luci-app-openvpn: change Value to DynamicList for ciphers

Signed-off-by: Paul Donald <newtwen+github@gmail.com>
(cherry picked from commit f6301561e709433b8602264fa00495c4aeb70ad3)
---
 .../luasrc/model/cbi/openvpn-advanced.lua        | 16 ++++++++++++----
 1 file changed, 12 insertions(+), 4 deletions(-)

diff --git a/feeds/luci/applications/luci-app-openvpn/luasrc/model/cbi/openvpn-advanced.lua b/feeds/luci/applications/luci-app-openvpn/luasrc/model/cbi/openvpn-advanced.lua
index a7eefdf5fe5c..656aeedf9aaf 100644
--- a/feeds/luci/applications/luci-app-openvpn/luasrc/model/cbi/openvpn-advanced.lua
+++ b/feeds/luci/applications/luci-app-openvpn/luasrc/model/cbi/openvpn-advanced.lua
@@ -801,13 +801,21 @@ local knownParams = {
 			"ncp_disable",
 			0,
 			translate("This completely disables cipher negotiation") },
-		{ Value,
+		{ DynamicList,
 			"ncp_ciphers",
-			"AES-256-GCM:AES-128-GCM",
+			{
+				"AES-256-GCM",
+				"AES-128-GCM"
+			},
 			translate("Restrict the allowed ciphers to be negotiated") },
-		{ Value,
+		{ DynamicList,
 			"data_ciphers",
-			"CHACHA20-POLY1305:AES-256-GCM:AES-128-GCM:AES-256-CBC",  
+			{
+				"CHACHA20-POLY1305",
+				"AES-256-GCM",
+				"AES-128-GCM",
+				"AES-256-CBC"
+			},
 			translate("Restrict the allowed ciphers to be negotiated") },
 	} }
 }
