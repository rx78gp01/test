From c3b9f00aaae37db603f6107d93245e0d8aa8a2d0 Mon Sep 17 00:00:00 2001
From: Robert Meijer <robert.s.meijer@gmail.com>
Date: Fri, 9 Oct 2020 19:58:46 +0200
Subject: [PATCH] ath79: increase max tx ring buffer for ag71xx

This allows the user to specify a larger tx ring buffer size via ethtool.
Having symmetrical ring buffer sizes increases throughput on high bandwidth
(1 gbps tested) network connections.

The default value is not changed so the same behaviour is saved.

Signed-off-by: Robert Meijer <robert.s.meijer@gmail.com>
[ improve title, commit description and wrap to 80 columns ]
Signed-off-by: Christian Marangi <ansuelsmth@gmail.com>
[ increase default value to 256]
---
 .../ath79/files/drivers/net/ethernet/atheros/ag71xx/ag71xx.h    | 4 +-
 1 file changed, 2 insertion(+), 2 deletion(-)

diff --git a/target/linux/ath79/files/drivers/net/ethernet/atheros/ag71xx/ag71xx.h b/target/linux/ath79/files/drivers/net/ethernet/atheros/ag71xx/ag71xx.h
index 1955cd288f3c5..0773f1a5af0e5 100644
--- a/target/linux/ath79/files/drivers/net/ethernet/atheros/ag71xx/ag71xx.h
+++ b/target/linux/ath79/files/drivers/net/ethernet/atheros/ag71xx/ag71xx.h
@@ -62,7 +62,7 @@
 #define AG71XX_TX_RING_SPLIT		512
 #define AG71XX_TX_RING_DS_PER_PKT	DIV_ROUND_UP(AG71XX_TX_MTU_LEN, \
 						     AG71XX_TX_RING_SPLIT)
-#define AG71XX_TX_RING_SIZE_DEFAULT	128
+#define AG71XX_TX_RING_SIZE_DEFAULT	256
 #define AG71XX_RX_RING_SIZE_DEFAULT	256
 
 #define AG71XX_TX_RING_SIZE_MAX		256
