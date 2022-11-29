diff --git a/feeds/packages/net/openvpn/files/openvpn.options b/feeds/packages/net/openvpn/files/openvpn.options
index 5a7c756..ae99e82 100644
--- a/feeds/packages/net/openvpn/files/openvpn.options
+++ b/feeds/packages/net/openvpn/files/openvpn.options
@@ -23,6 +23,7 @@ connect_retry
 connect_retry_max
 connect_timeout
 crl_verify
+data_ciphers
 data_ciphers_fallback
 dev
 dev_node
@@ -70,6 +71,7 @@ mode
 mssfix
 mtu_disc
 mute
+ncp_ciphers
 nice
 ping
 ping_exit
@@ -198,8 +200,6 @@ vlan_tagging
 '
 
 OPENVPN_LIST='
-data_ciphers
-ncp_ciphers
 tls_cipher
 tls_ciphersuites
 tls_groups
-- 
2.38.1.windows.1

