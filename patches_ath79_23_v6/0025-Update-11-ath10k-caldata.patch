diff --git a/target/linux/ath79/generic/base-files/etc/hotplug.d/firmware/11-ath10k-caldata b/target/linux/ath79/generic/base-files/etc/hotplug.d/firmware/11-ath10k-caldata
index f0a3755..a83aa9f 100644
--- a/target/linux/ath79/generic/base-files/etc/hotplug.d/firmware/11-ath10k-caldata
+++ b/target/linux/ath79/generic/base-files/etc/hotplug.d/firmware/11-ath10k-caldata
@@ -198,8 +198,8 @@ case "$FIRMWARE" in
 	dlink,dir-842-c1|\
 	dlink,dir-842-c2|\
 	dlink,dir-842-c3)
-		caldata_extract "art" 0x5000 0x2f20
-		caldata_valid "202f" || caldata_extract "reserved" 0x15000 0x2f20
+		caldata_extract "reserved" 0x15000 0x2f20
+		caldata_valid "202f" || caldata_extract "art" 0x5000 0x2f20
 		ath10k_patch_mac $(mtd_get_mac_ascii devdata wlan5mac)
 		ln -sf /lib/firmware/ath10k/pre-cal-pci-0000\:00\:00.0.bin \
 			/lib/firmware/ath10k/QCA9888/hw2.0/board.bin
