diff --git a/feeds/packages/net/openvpn/Makefile b/feeds/packages/net/openvpn/Makefile
index 20a468a..a1112fd 100644
--- a/feeds/packages/net/openvpn/Makefile
+++ b/feeds/packages/net/openvpn/Makefile
@@ -85,7 +85,7 @@ define Build/Configure
 		$(if $(CONFIG_OPENVPN_$(BUILD_VARIANT)_ENABLE_DEF_AUTH),--enable,--disable)-def-auth \
 		$(if $(CONFIG_OPENVPN_$(BUILD_VARIANT)_ENABLE_PF),--enable,--disable)-pf \
 		$(if $(CONFIG_OPENVPN_$(BUILD_VARIANT)_ENABLE_PORT_SHARE),--enable,--disable)-port-share \
-		$(if $(CONFIG_OPENVPN_OPENSSL),--with-crypto-library=openssl --with-openssl-engine=no) \
+		$(if $(CONFIG_OPENVPN_OPENSSL),--with-crypto-library=openssl --with-openssl-engine=yes) \
 		$(if $(CONFIG_OPENVPN_MBEDTLS),--with-crypto-library=mbedtls) \
 		$(if $(CONFIG_OPENVPN_WOLFSSL),--with-crypto-library=wolfssl) \
 	)
-- 
2.38.1.windows.1

