--- /dev/null	2017-05-31 19:11:25.769633897 +0800
+++ ./target/linux/ramips/patches-5.4/999-disable-gro-gso-default.patch	2017-05-31 20:44:54.210769624 +0800
@@ -0,0 +1,11 @@
+--- a/net/core/dev.c
++++ b/net/core/dev.c
+@@ -10285,7 +10285,7 @@ int register_netdevice(struct net_device
+ 	 * software offloads (GSO and GRO).
+ 	 */
+ 	dev->hw_features |= NETIF_F_SOFT_FEATURES;
+-	dev->features |= NETIF_F_SOFT_FEATURES;
++	//dev->features |= NETIF_F_SOFT_FEATURES;
+ 
+ 	if (dev->netdev_ops->ndo_udp_tunnel_add) {
+ 		dev->features |= NETIF_F_RX_UDP_TUNNEL_PORT;
