From 06be957f86d037ed710a8b426aca493590c451de Mon Sep 17 00:00:00 2001
From: Felix Fietkau <nbd@nbd.name>
Date: Mon, 29 Apr 2024 18:58:41 +0200
Subject: [PATCH] mt76: update to Git HEAD (2023-12-08)
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit

890ae4d717f1 wifi: mt76: mt76x02: fix MT76x0 external LNA gain handling
fcc2f3d82bc9 wifi: mt76: fix lock dependency problem for wed_lock
77cc14596202 wifi: mt76: mt792x: move mt7921_skb_add_usb_sdio_hdr in mt792x module
bc85355885d1 wifi: mt76: mt792x: move some common usb code in mt792x module
c27f01c4c834 wifi: mt76: mt7996: get tx_retries and tx_failed from txfree
30aba4c18307 wifi: mt76: mt7996: Add mcu commands for getting sta tx statistic
119bebff244b wifi: mt76: mt7996: enable PPDU-TxS to host
a4005e0e83e7 wifi: mt76: mt7996: remove periodic MPDU TXS request
d6cc20bf5913 wifi: mt76: reduce spin_lock_bh held up in mt76_dma_rx_cleanup
5d94251d641c wifi: mt76: mt7921: move connac nic capability handling to mt7921
266341b5019d wifi: mt76: mt7921: enable set txpower for UNII-4
581449ac5274 wifi: mt76: mt7921: add 6GHz power type support for clc
9bfd669e9477 wifi: mt76: mt7921: get regulatory information from the clc event
4a0f839da0f1 wifi: mt76: mt7921: update the channel usage when the regd domain changed
f4df423d3d56 wifi: mt76: add ability to explicitly forbid LED registration with DT
54d369e79972 wifi: mt76: mt7921: support 5.9/6GHz channel config in acpi
b39b6cba220f wifi: mt76: mt7996: fix uninitialized variable in parsing txfree
77194e652885 wifi: mt76: fix typo in mt76_get_of_eeprom_from_nvmem function
c37738fc9097 wifi: mt76: limit support of precal loading for mt7915 to MTD only
d6e8aa634a19 wifi: mt76: make mt76_get_of_eeprom static again
d1c671a90eba wifi: mt76: permit to use alternative cell name to eeprom NVMEM load
5539001fe4e3 wifi: mt76: permit to load precal from NVMEM cell for mt7915
48d413380685 wifi: mt76: Remove unnecessary (void*) conversions
ea2814289147 wifi: mt76: mmio: move mt76_mmio_wed_{init,release}_rx_buf in common code
9fb0277d7ee8 wifi: mt76: move mt76_mmio_wed_offload_{enable,disable} in common code
4b47145ecf44 wifi: mt76: move mt76_net_setup_tc in common code
d798d5d6f770 wifi: mt76: introduce mt76_queue_is_wed_tx_free utility routine
48b0cedbf83f wifi: mt76: introduce wed pointer in mt76_queue
c550204e347d wifi: mt76: increase MT_QFLAG_WED_TYPE size
2e7f30f22cfd wifi: mt76: mt7996: add wed tx support
ec8765a02fc8 wifi: mt76: dma: introduce __mt76_dma_queue_reset utility routine
a469aaac9784 wifi: mt76: mt7996: use u16 for val field in mt7996_mcu_set_rro signature
abca260a15c4 wifi: mt76: mt7996: add wed rx support
be2e74c0c495 wifi: mt76: move wed reset common code in mt76 module
7f17e164fbb4 wifi: mt76: mt7996: add wed reset support
0f89bf58efda wifi: mt76: mt7996: add wed rro delete session garbage collector
a58b75f863ca wifi: mt76: mt7915: fallback to non-wed mode if platform_get_resource fails in mt7915_mmio_wed_init()
36d2ddd94eeb wifi: mt76: mt7996: add support for variants with auxiliary RX path
cec7720c9341 wifi: mt76: mt7996: add TX statistics for EHT mode in debugfs
9852093062e8 wifi: mt76: connac: add thermal protection support for mt7996
955540a4df74 wifi: mt76: mt7996: add thermal sensor device support
af41374a3b8e wifi: mt76: connac: add beacon duplicate TX mode support for mt7996
3c98d7b7fa23 wifi: mt76: mt7996: fix the size of struct bss_rate_tlv
ee2169c00539 wifi: mt76: mt7996: adjust WFDMA settings to improve performance
0aead5de68a7 wifi: mt76: connac: set fixed_bw bit in TX descriptor for fixed rate frames
ab5580ff5a4f wifi: mt76: mt7996: handle IEEE80211_RC_SMPS_CHANGED
eed234afed7e wifi: mt76: mt7996: align the format of fixed rate command
d9a855285b95 wifi: mt76: mt7996: fix rate usage of inband discovery frames
47799aefe263 wifi: mt76: change txpower init to per-phy
264e1ecfe1b4 wifi: mt76: mt7996: add txpower setting support
c7b243b127eb wifi: mt76: use chainmask for power delta calculation
05f433900a02 wifi: mt76: mt7996: switch to mcu command for TX GI report
ae963198e605 wifi: mt76: mt7996: fix alignment of sta info event
d0d2e03591d6 wifi: mt76: mt7996: rework ampdu params setting
e87f4efc7638 wifi: mt76: connac: add beacon protection support for mt7996
0dfcc53a8e5d wifi: mt76: connac: fix EHT phy mode check
30c54a53bf8b wifi: mt76: mt7915: fix EEPROM offset of TSSI flag on MT7981
17297c97b737 wifi: mt76: mt7915: also MT7981 is 3T3R but nss2 on 5 GHz band
eeb48c081034 wifi: mt76: mt7996: fix mt7996_mcu_all_sta_info_event struct packing
b74ad922659c wifi: mt76: mt7996: introduce mt7996_band_valid()
51cb541c1e53 wifi: mt76: connac: add firmware support for mt7992
c0eda4d96ec8 wifi: mt76: mt7996: add DMA support for mt7992
f12471968a53 wifi: mt76: mt7996: rework register offsets for mt7992
8d11dae73eb8 wifi: mt76: mt7996: support mt7992 eeprom loading
6c2b2c37abd7 wifi: mt76: mt7996: adjust interface num and wtbl size for mt7992
df1d3b3c67e5 wifi: mt76: connac: add new definition of tx descriptor
f997e759cea5 wifi: mt76: mt7996: add PCI IDs for mt7992
94e3632e4e93 wifi: mt76: mt7925: remove iftype from mt7925_init_eht_caps signature
9c7b98c03173 net: ethernet: mtk_wed: rename mtk_rxbm_desc in mtk_wed_bm_desc
4423b4eb69fb wifi: mt76: mt7996: fix endianness in mt7996_mcu_wed_rro_event
b97d899a7907 wifi: mt76: mt7921: fix kernel panic by accessing invalid 6GHz channel info
9ef06028d4fe wifi: mt76: mt7921s: fix workqueue problem causes STA association fail
95c14207d2a9 wifi: mt76: mt7996: set DMA mask to 36 bits for boards with more than 4GB of RAM
dbea5151412b wifi: mt76: mt7921: reduce the size of MCU firmware download Rx queue
a84a355d2e0a wifi: mt76: mt7921: fix country count limitation for CLC
c498f27ad075 wifi: mt76: mt7921: fix CLC command timeout when suspend/resume
3098d968abe4 wifi: mt76: mt7921: fix wrong 6Ghz power type
7730fc91dd15 wifi: mt76: fix shift overflow warnings on 32 bit systems
f559adf1849c wifi: mt76: fix crash with WED rx support enabled

Signed-off-by: Felix Fietkau <nbd@nbd.name>
(cherry picked from commit 8f782ed07dc23b64bb24f63ce31d939ee6afb5ad)
[rmilecki: add patches/fixes for regressions from this commit]
Signed-off-by: Rafał Miłecki <rafal@milecki.pl>
---
 package/kernel/mt76/Makefile                  |  8 +--
 ..._wed-rename-mtk_rxbm_desc-in-mtk_wed.patch | 24 --------
 ...-fix-shift-overflow-warning-on-32-bi.patch | 34 +++++++++++
 ...-fix-6GHz-disabled-by-the-missing-de.patch | 31 ++++++++++
 ...wifi-mt76-mt7996-fix-fortify-warning.patch | 26 ++++++++
 ...i-mt76-mt7996-fix-fw-loading-timeout.patch | 38 ++++++++++++
 ...-check-txs-format-before-getting-skb.patch | 60 +++++++++++++++++++
 ...-fix-incorrect-type-conversion-for-C.patch | 38 ++++++++++++
 ...e-issue-of-missing-txpwr-settings-fr.patch | 28 +++++++++
 ...7996-fix-size-of-txpower-MCU-command.patch | 56 +++++++++++++++++
 ...-fix-uninitialized-variable-in-mt799.patch | 27 +++++++++
 ...-fix-potential-memory-leakage-when-r.patch | 39 ++++++++++++
 12 files changed, 381 insertions(+), 28 deletions(-)
 delete mode 100644 package/kernel/mt76/patches/0001-net-ethernet-mtk_wed-rename-mtk_rxbm_desc-in-mtk_wed.patch
 create mode 100644 package/kernel/mt76/patches/0001-wifi-mt76-mt7996-fix-shift-overflow-warning-on-32-bi.patch
 create mode 100644 package/kernel/mt76/patches/0002-wifi-mt76-mt7921-fix-6GHz-disabled-by-the-missing-de.patch
 create mode 100644 package/kernel/mt76/patches/0003-wifi-mt76-mt7996-fix-fortify-warning.patch
 create mode 100644 package/kernel/mt76/patches/0004-wifi-mt76-mt7996-fix-fw-loading-timeout.patch
 create mode 100644 package/kernel/mt76/patches/0005-wifi-mt76-mt7996-check-txs-format-before-getting-skb.patch
 create mode 100644 package/kernel/mt76/patches/0006-wifi-mt76-mt7921-fix-incorrect-type-conversion-for-C.patch
 create mode 100644 package/kernel/mt76/patches/0007-wifi-mt76-fix-the-issue-of-missing-txpwr-settings-fr.patch
 create mode 100644 package/kernel/mt76/patches/0008-wifi-mt76-mt7996-fix-size-of-txpower-MCU-command.patch
 create mode 100644 package/kernel/mt76/patches/0009-wifi-mt76-mt7996-fix-uninitialized-variable-in-mt799.patch
 create mode 100644 package/kernel/mt76/patches/0010-wifi-mt76-mt7996-fix-potential-memory-leakage-when-r.patch

diff --git a/package/kernel/mt76/Makefile b/package/kernel/mt76/Makefile
index dd75390ee76dd0..762f474ce90754 100644
--- a/package/kernel/mt76/Makefile
+++ b/package/kernel/mt76/Makefile
@@ -8,9 +8,9 @@ PKG_LICENSE_FILES:=
 
 PKG_SOURCE_URL:=https://github.com/openwrt/mt76
 PKG_SOURCE_PROTO:=git
-PKG_SOURCE_DATE:=2023-09-18
-PKG_SOURCE_VERSION:=2afc7285f75dca5a0583fd917285bf33f1429cc6
-PKG_MIRROR_HASH:=2c9556b298246277ac2d65415e4449f98e6d5fdb99e0d0a92262f162df772bbc
+PKG_SOURCE_DATE:=2023-12-08
+PKG_SOURCE_VERSION:=f559adf1849c8af91f5a5eb670f4ed2c24988898
+PKG_MIRROR_HASH:=74dde4478442d5f0edbae918636b40767b0e49181b732d4184feeccd8a8cc328
 
 PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
 PKG_USE_NINJA:=0
@@ -318,7 +318,7 @@ endef
 define KernelPackage/mt7996e
   $(KernelPackage/mt76-default)
   TITLE:=MediaTek MT7996E wireless driver
-  DEPENDS+=@PCI_SUPPORT +kmod-mt76-connac
+  DEPENDS+=@PCI_SUPPORT +kmod-mt76-connac +kmod-hwmon-core
   FILES:= $(PKG_BUILD_DIR)/mt7996/mt7996e.ko
   AUTOLOAD:=$(call AutoProbe,mt7996e)
 endef
diff --git a/package/kernel/mt76/patches/0001-net-ethernet-mtk_wed-rename-mtk_rxbm_desc-in-mtk_wed.patch b/package/kernel/mt76/patches/0001-net-ethernet-mtk_wed-rename-mtk_rxbm_desc-in-mtk_wed.patch
deleted file mode 100644
index 15241c8195dc43..00000000000000
--- a/package/kernel/mt76/patches/0001-net-ethernet-mtk_wed-rename-mtk_rxbm_desc-in-mtk_wed.patch
+++ /dev/null
@@ -1,24 +0,0 @@
-From 9c7b98c03173a1a201d74203a81b344a0cd637ac Mon Sep 17 00:00:00 2001
-From: Lorenzo Bianconi <lorenzo@kernel.org>
-Date: Mon, 18 Sep 2023 12:29:07 +0200
-Subject: [PATCH] net: ethernet: mtk_wed: rename mtk_rxbm_desc in
- mtk_wed_bm_desc
-
-Rename mtk_rxbm_desc structure in mtk_wed_bm_desc since it will be used
-even on tx side by MT7988 SoC.
-
-Signed-off-by: Lorenzo Bianconi <lorenzo@kernel.org>
-Signed-off-by: Paolo Abeni <pabeni@redhat.com>
----
-
---- a/mt7915/mmio.c
-+++ b/mt7915/mmio.c
-@@ -591,7 +591,7 @@ static void mt7915_mmio_wed_release_rx_b
- 
- static u32 mt7915_mmio_wed_init_rx_buf(struct mtk_wed_device *wed, int size)
- {
--	struct mtk_rxbm_desc *desc = wed->rx_buf_ring.desc;
-+	struct mtk_wed_bm_desc *desc = wed->rx_buf_ring.desc;
- 	struct mt76_txwi_cache *t = NULL;
- 	struct mt7915_dev *dev;
- 	struct mt76_queue *q;
diff --git a/package/kernel/mt76/patches/0001-wifi-mt76-mt7996-fix-shift-overflow-warning-on-32-bi.patch b/package/kernel/mt76/patches/0001-wifi-mt76-mt7996-fix-shift-overflow-warning-on-32-bi.patch
new file mode 100644
index 00000000000000..5acc9e88a585bc
--- /dev/null
+++ b/package/kernel/mt76/patches/0001-wifi-mt76-mt7996-fix-shift-overflow-warning-on-32-bi.patch
@@ -0,0 +1,34 @@
+From f63f87cd5b45c3779293e6062c6b26bdf57e851d Mon Sep 17 00:00:00 2001
+From: Christian Marangi <ansuelsmth@gmail.com>
+Date: Sat, 9 Dec 2023 22:44:57 +0100
+Subject: [PATCH] wifi: mt76: mt7996: fix shift overflow warning on 32 bit
+ systems
+
+Fix additional shift overflow warning on 32 bit systems for mt7996 mac.c
+source.
+
+Fixes: 95c14207d2a9 ("wifi: mt76: mt7996: set DMA mask to 36 bits for boards with more than 4GB of RAM")
+Signed-off-by: Christian Marangi <ansuelsmth@gmail.com>
+---
+ mt7996/mac.c | 10 +++++++---
+ 1 file changed, 7 insertions(+), 3 deletions(-)
+
+--- a/mt7996/mac.c
++++ b/mt7996/mac.c
+@@ -942,9 +942,13 @@ int mt7996_tx_prepare_skb(struct mt76_de
+ 
+ 	txp = (struct mt76_connac_txp_common *)(txwi + MT_TXD_SIZE);
+ 	for (i = 0; i < nbuf; i++) {
+-		u16 len = FIELD_PREP(MT_TXP_BUF_LEN, tx_info->buf[i + 1].len) |
+-			  FIELD_PREP(MT_TXP_DMA_ADDR_H,
+-				     tx_info->buf[i + 1].addr >> 32);
++		u16 len;
++
++		len = FIELD_PREP(MT_TXP_BUF_LEN, tx_info->buf[i + 1].len);
++#ifdef CONFIG_ARCH_DMA_ADDR_T_64BIT
++		len |= FIELD_PREP(MT_TXP_DMA_ADDR_H,
++				  tx_info->buf[i + 1].addr >> 32);
++#endif
+ 
+ 		txp->fw.buf[i] = cpu_to_le32(tx_info->buf[i + 1].addr);
+ 		txp->fw.len[i] = cpu_to_le16(len);
diff --git a/package/kernel/mt76/patches/0002-wifi-mt76-mt7921-fix-6GHz-disabled-by-the-missing-de.patch b/package/kernel/mt76/patches/0002-wifi-mt76-mt7921-fix-6GHz-disabled-by-the-missing-de.patch
new file mode 100644
index 00000000000000..3fff9caa3cd15d
--- /dev/null
+++ b/package/kernel/mt76/patches/0002-wifi-mt76-mt7921-fix-6GHz-disabled-by-the-missing-de.patch
@@ -0,0 +1,31 @@
+From bebd9cffc2aeb2cecb40aadbb8c6eab3bdf7971b Mon Sep 17 00:00:00 2001
+From: Ming Yen Hsieh <mingyen.hsieh@mediatek.com>
+Date: Mon, 30 Oct 2023 15:17:34 +0800
+Subject: [PATCH] wifi: mt76: mt7921: fix 6GHz disabled by the missing default
+ CLC config
+
+No matter CLC is enabled or disabled, the driver should initialize
+the default value 0xff for channel configuration of CLC. Otherwise,
+the zero value would disable channels.
+
+Reported-and-tested-by: Ben Greear <greearb@candelatech.com>
+Closes: https://lore.kernel.org/all/2fb78387-d226-3193-8ca7-90040561b9ad@candelatech.com/
+Fixes: 09382d8f8641 ("wifi: mt76: mt7921: update the channel usage when the regd domain changed")
+Signed-off-by: Ming Yen Hsieh <mingyen.hsieh@mediatek.com>
+Signed-off-by: Deren Wu <deren.wu@mediatek.com>
+Signed-off-by: Kalle Valo <kvalo@kernel.org>
+Link: https://lore.kernel.org/r/5a976ddf1f636b5cb809373501d3cfdc6d8de3e4.1698648737.git.deren.wu@mediatek.com
+---
+ mt7921/mcu.c | 1 +
+ 1 file changed, 1 insertion(+)
+
+--- a/mt7921/mcu.c
++++ b/mt7921/mcu.c
+@@ -375,6 +375,7 @@ static int mt7921_load_clc(struct mt792x
+ 	int ret, i, len, offset = 0;
+ 	u8 *clc_base = NULL, hw_encap = 0;
+ 
++	dev->phy.clc_chan_conf = 0xff;
+ 	if (mt7921_disable_clc ||
+ 	    mt76_is_usb(&dev->mt76))
+ 		return 0;
diff --git a/package/kernel/mt76/patches/0003-wifi-mt76-mt7996-fix-fortify-warning.patch b/package/kernel/mt76/patches/0003-wifi-mt76-mt7996-fix-fortify-warning.patch
new file mode 100644
index 00000000000000..f3cf9c10fa6826
--- /dev/null
+++ b/package/kernel/mt76/patches/0003-wifi-mt76-mt7996-fix-fortify-warning.patch
@@ -0,0 +1,26 @@
+From 786a339bac36d8e53eb8b540e79221d20011ab2a Mon Sep 17 00:00:00 2001
+From: Felix Fietkau <nbd@nbd.name>
+Date: Sat, 3 Feb 2024 14:21:58 +0100
+Subject: [PATCH] wifi: mt76: mt7996: fix fortify warning
+
+Copy cck and ofdm separately in order to avoid __read_overflow2_field
+warning.
+
+Fixes: f75e4779d215 ("wifi: mt76: mt7996: add txpower setting support")
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7996/mcu.c | 3 ++-
+ 1 file changed, 2 insertions(+), 1 deletion(-)
+
+--- a/mt7996/mcu.c
++++ b/mt7996/mcu.c
+@@ -4477,7 +4477,8 @@ int mt7996_mcu_set_txpower_sku(struct mt
+ 
+ 	skb_put_data(skb, &req, sizeof(req));
+ 	/* cck and ofdm */
+-	skb_put_data(skb, &la.cck, sizeof(la.cck) + sizeof(la.ofdm));
++	skb_put_data(skb, &la.cck, sizeof(la.cck));
++	skb_put_data(skb, &la.ofdm, sizeof(la.ofdm));
+ 	/* ht20 */
+ 	skb_put_data(skb, &la.mcs[0], 8);
+ 	/* ht40 */
diff --git a/package/kernel/mt76/patches/0004-wifi-mt76-mt7996-fix-fw-loading-timeout.patch b/package/kernel/mt76/patches/0004-wifi-mt76-mt7996-fix-fw-loading-timeout.patch
new file mode 100644
index 00000000000000..9c2247b0c2f032
--- /dev/null
+++ b/package/kernel/mt76/patches/0004-wifi-mt76-mt7996-fix-fw-loading-timeout.patch
@@ -0,0 +1,38 @@
+From bc37a7ebc267e400fc4e9886b7197b4b866763d1 Mon Sep 17 00:00:00 2001
+From: Lorenzo Bianconi <lorenzo@kernel.org>
+Date: Thu, 21 Dec 2023 10:41:18 +0100
+Subject: [PATCH] wifi: mt76: mt7996: fix fw loading timeout
+
+Fix the following firmware loading error due to a wrong dma register
+configuration if wed is disabled.
+
+[    8.245881] mt7996e_hif 0001:01:00.0: assign IRQ: got 128
+[    8.251308] mt7996e_hif 0001:01:00.0: enabling device (0000 -> 0002)
+[    8.257674] mt7996e_hif 0001:01:00.0: enabling bus mastering
+[    8.263488] mt7996e 0000:01:00.0: assign IRQ: got 126
+[    8.268537] mt7996e 0000:01:00.0: enabling device (0000 -> 0002)
+[    8.274551] mt7996e 0000:01:00.0: enabling bus mastering
+[   28.648773] mt7996e 0000:01:00.0: Message 00000010 (seq 1) timeout
+[   28.654959] mt7996e 0000:01:00.0: Failed to get patch semaphore
+[   29.661033] mt7996e: probe of 0000:01:00.0 failed with error -11
+
+Suggested-by: Sujuan Chen" <sujuan.chen@mediatek.com>
+Fixes: 4920a3a1285f ("wifi: mt76: mt7996: set DMA mask to 36 bits for boards with more than 4GB of RAM")
+Signed-off-by: Lorenzo Bianconi <lorenzo@kernel.org>
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7996/dma.c | 3 ++-
+ 1 file changed, 2 insertions(+), 1 deletion(-)
+
+--- a/mt7996/dma.c
++++ b/mt7996/dma.c
+@@ -237,7 +237,8 @@ void mt7996_dma_start(struct mt7996_dev
+ 				 MT_WFDMA0_GLO_CFG_TX_DMA_EN |
+ 				 MT_WFDMA0_GLO_CFG_RX_DMA_EN |
+ 				 MT_WFDMA0_GLO_CFG_OMIT_TX_INFO |
+-				 MT_WFDMA0_GLO_CFG_OMIT_RX_INFO_PFET2);
++				 MT_WFDMA0_GLO_CFG_OMIT_RX_INFO_PFET2 |
++				 MT_WFDMA0_GLO_CFG_EXT_EN);
+ 
+ 		if (dev->hif2)
+ 			mt76_set(dev, MT_WFDMA0_GLO_CFG + hif1_ofs,
diff --git a/package/kernel/mt76/patches/0005-wifi-mt76-mt7996-check-txs-format-before-getting-skb.patch b/package/kernel/mt76/patches/0005-wifi-mt76-mt7996-check-txs-format-before-getting-skb.patch
new file mode 100644
index 00000000000000..f72c76ec666719
--- /dev/null
+++ b/package/kernel/mt76/patches/0005-wifi-mt76-mt7996-check-txs-format-before-getting-skb.patch
@@ -0,0 +1,60 @@
+From 025d5734caba6fa1fd96b57c19c61e42e601815b Mon Sep 17 00:00:00 2001
+From: Peter Chiu <chui-hao.chiu@mediatek.com>
+Date: Fri, 26 Jan 2024 17:09:12 +0800
+Subject: [PATCH] wifi: mt76: mt7996: check txs format before getting skb by
+ pid
+
+The PPDU TXS does not include the error bit so it cannot use to report
+status to mac80211. This patch fixes issue that STA wrongly detects if AP
+is still alive.
+
+Fixes: 2569ea5326e2 ("wifi: mt76: mt7996: enable PPDU-TxS to host")
+Signed-off-by: Peter Chiu <chui-hao.chiu@mediatek.com>
+Signed-off-by: Shayne Chen <shayne.chen@mediatek.com>
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7996/mac.c | 23 +++++++++++++----------
+ 1 file changed, 13 insertions(+), 10 deletions(-)
+
+--- a/mt7996/mac.c
++++ b/mt7996/mac.c
+@@ -1188,25 +1188,28 @@ mt7996_mac_add_txs_skb(struct mt7996_dev
+ 	struct ieee80211_tx_info *info;
+ 	struct sk_buff_head list;
+ 	struct rate_info rate = {};
+-	struct sk_buff *skb;
++	struct sk_buff *skb = NULL;
+ 	bool cck = false;
+ 	u32 txrate, txs, mode, stbc;
+ 
+ 	txs = le32_to_cpu(txs_data[0]);
+ 
+ 	mt76_tx_status_lock(mdev, &list);
+-	skb = mt76_tx_status_skb_get(mdev, wcid, pid, &list);
+ 
+-	if (skb) {
+-		info = IEEE80211_SKB_CB(skb);
+-		if (!(txs & MT_TXS0_ACK_ERROR_MASK))
+-			info->flags |= IEEE80211_TX_STAT_ACK;
+-
+-		info->status.ampdu_len = 1;
+-		info->status.ampdu_ack_len =
+-			!!(info->flags & IEEE80211_TX_STAT_ACK);
++	/* only report MPDU TXS */
++	if (le32_get_bits(txs_data[0], MT_TXS0_TXS_FORMAT) == 0) {
++		skb = mt76_tx_status_skb_get(mdev, wcid, pid, &list);
++		if (skb) {
++			info = IEEE80211_SKB_CB(skb);
++			if (!(txs & MT_TXS0_ACK_ERROR_MASK))
++				info->flags |= IEEE80211_TX_STAT_ACK;
++
++			info->status.ampdu_len = 1;
++			info->status.ampdu_ack_len =
++				!!(info->flags & IEEE80211_TX_STAT_ACK);
+ 
+-		info->status.rates[0].idx = -1;
++			info->status.rates[0].idx = -1;
++		}
+ 	}
+ 
+ 	if (mtk_wed_device_active(&dev->mt76.mmio.wed) && wcid->sta) {
diff --git a/package/kernel/mt76/patches/0006-wifi-mt76-mt7921-fix-incorrect-type-conversion-for-C.patch b/package/kernel/mt76/patches/0006-wifi-mt76-mt7921-fix-incorrect-type-conversion-for-C.patch
new file mode 100644
index 00000000000000..a85dfb7f72625a
--- /dev/null
+++ b/package/kernel/mt76/patches/0006-wifi-mt76-mt7921-fix-incorrect-type-conversion-for-C.patch
@@ -0,0 +1,38 @@
+From d75eac9f5531e484fbbabf2652922976e15a7a7a Mon Sep 17 00:00:00 2001
+From: Ming Yen Hsieh <mingyen.hsieh@mediatek.com>
+Date: Tue, 16 Jan 2024 10:48:54 +0800
+Subject: [PATCH] wifi: mt76: mt7921: fix incorrect type conversion for CLC
+ command
+
+clc->len is defined as 32 bits in length, so it must also be
+operated on with 32 bits, not 16 bits.
+
+Fixes: fa6ad88e023d ("wifi: mt76: mt7921: fix country count limitation for CLC")
+Signed-off-by: Ming Yen Hsieh <mingyen.hsieh@mediatek.com>
+Reported-by: kernel test robot <lkp@intel.com>
+Closes: https://lore.kernel.org/oe-kbuild-all/202312112104.Zkc3QUHr-lkp@intel.com/
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7921/mcu.c | 4 ++--
+ 1 file changed, 2 insertions(+), 2 deletions(-)
+
+--- a/mt7921/mcu.c
++++ b/mt7921/mcu.c
+@@ -1272,7 +1272,7 @@ int __mt7921_mcu_set_clc(struct mt792x_d
+ 		.mtcl_conf = mt792x_acpi_get_mtcl_conf(&dev->phy, alpha2),
+ 	};
+ 	int ret, valid_cnt = 0;
+-	u16 buf_len = 0;
++	u32 buf_len = 0;
+ 	u8 *pos;
+ 
+ 	if (!clc)
+@@ -1283,7 +1283,7 @@ int __mt7921_mcu_set_clc(struct mt792x_d
+ 	if (mt76_find_power_limits_node(&dev->mt76))
+ 		req.cap |= CLC_CAP_DTS_EN;
+ 
+-	buf_len = le16_to_cpu(clc->len) - sizeof(*clc);
++	buf_len = le32_to_cpu(clc->len) - sizeof(*clc);
+ 	pos = clc->data;
+ 	while (buf_len > 16) {
+ 		struct mt7921_clc_rule *rule = (struct mt7921_clc_rule *)pos;
diff --git a/package/kernel/mt76/patches/0007-wifi-mt76-fix-the-issue-of-missing-txpwr-settings-fr.patch b/package/kernel/mt76/patches/0007-wifi-mt76-fix-the-issue-of-missing-txpwr-settings-fr.patch
new file mode 100644
index 00000000000000..380bdfac38d292
--- /dev/null
+++ b/package/kernel/mt76/patches/0007-wifi-mt76-fix-the-issue-of-missing-txpwr-settings-fr.patch
@@ -0,0 +1,28 @@
+From 841bf82e99581f648325bee570de98892cad894f Mon Sep 17 00:00:00 2001
+From: Ming Yen Hsieh <mingyen.hsieh@mediatek.com>
+Date: Wed, 7 Feb 2024 11:31:23 +0800
+Subject: [PATCH] wifi: mt76: fix the issue of missing txpwr settings from
+ ch153 to ch177
+
+Because the number of channels to be configured is calculated using the %,
+and it results in 0 when there's an exact division, this leads to some
+channels not having their tx power configured.
+
+Fixes: 7801da338856 ("wifi: mt76: mt7921: enable set txpower for UNII-4")
+Signed-off-by: Ming Yen Hsieh <mingyen.hsieh@mediatek.com>
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt76_connac_mcu.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+--- a/mt76_connac_mcu.c
++++ b/mt76_connac_mcu.c
+@@ -2101,7 +2101,7 @@ mt76_connac_mcu_rate_txpower_band(struct
+ 		int j, msg_len, num_ch;
+ 		struct sk_buff *skb;
+ 
+-		num_ch = i == batch_size - 1 ? n_chan % batch_len : batch_len;
++		num_ch = i == batch_size - 1 ? n_chan - i * batch_len : batch_len;
+ 		msg_len = sizeof(tx_power_tlv) + num_ch * sizeof(sku_tlbv);
+ 		skb = mt76_mcu_msg_alloc(dev, NULL, msg_len);
+ 		if (!skb) {
diff --git a/package/kernel/mt76/patches/0008-wifi-mt76-mt7996-fix-size-of-txpower-MCU-command.patch b/package/kernel/mt76/patches/0008-wifi-mt76-mt7996-fix-size-of-txpower-MCU-command.patch
new file mode 100644
index 00000000000000..f1d3af80b8621f
--- /dev/null
+++ b/package/kernel/mt76/patches/0008-wifi-mt76-mt7996-fix-size-of-txpower-MCU-command.patch
@@ -0,0 +1,56 @@
+From b108dda7e201994f10c885362b07ff3b6e1e843d Mon Sep 17 00:00:00 2001
+From: Chad Monroe <chad@monroe.io>
+Date: Tue, 5 Mar 2024 17:55:35 +0000
+Subject: [PATCH] wifi: mt76: mt7996: fix size of txpower MCU command
+
+Fixes issues with scanning and low power output at some rates.
+
+Fixes: f75e4779d215 ("wifi: mt76: mt7996: add txpower setting support")
+Signed-off-by: Chad Monroe <chad@monroe.io>
+Signed-off-by: Ryder Lee <ryder.lee@mediatek.com>
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7996/mcu.c    | 7 +++++--
+ mt7996/mt7996.h | 1 +
+ 2 files changed, 6 insertions(+), 2 deletions(-)
+
+--- a/mt7996/mcu.c
++++ b/mt7996/mcu.c
+@@ -4456,7 +4456,7 @@ int mt7996_mcu_set_txpower_sku(struct mt
+ 		u8 band_idx;
+ 	} __packed req = {
+ 		.tag = cpu_to_le16(UNI_TXPOWER_POWER_LIMIT_TABLE_CTRL),
+-		.len = cpu_to_le16(sizeof(req) + MT7996_SKU_RATE_NUM - 4),
++		.len = cpu_to_le16(sizeof(req) + MT7996_SKU_PATH_NUM - 4),
+ 		.power_ctrl_id = UNI_TXPOWER_POWER_LIMIT_TABLE_CTRL,
+ 		.power_limit_type = TX_POWER_LIMIT_TABLE_RATE,
+ 		.band_idx = phy->mt76->band_idx,
+@@ -4471,7 +4471,7 @@ int mt7996_mcu_set_txpower_sku(struct mt
+ 	mphy->txpower_cur = tx_power;
+ 
+ 	skb = mt76_mcu_msg_alloc(&dev->mt76, NULL,
+-				 sizeof(req) + MT7996_SKU_RATE_NUM);
++				 sizeof(req) + MT7996_SKU_PATH_NUM);
+ 	if (!skb)
+ 		return -ENOMEM;
+ 
+@@ -4495,6 +4495,9 @@ int mt7996_mcu_set_txpower_sku(struct mt
+ 	/* eht */
+ 	skb_put_data(skb, &la.eht[0], sizeof(la.eht));
+ 
++	/* padding */
++	skb_put_zero(skb, MT7996_SKU_PATH_NUM - MT7996_SKU_RATE_NUM);
++
+ 	return mt76_mcu_skb_send_msg(&dev->mt76, skb,
+ 				     MCU_WM_UNI_CMD(TXPOWER), true);
+ }
+--- a/mt7996/mt7996.h
++++ b/mt7996/mt7996.h
+@@ -50,6 +50,7 @@
+ #define MT7996_CFEND_RATE_11B		0x03	/* 11B LP, 11M */
+ 
+ #define MT7996_SKU_RATE_NUM		417
++#define MT7996_SKU_PATH_NUM		494
+ 
+ #define MT7996_MAX_TWT_AGRT		16
+ #define MT7996_MAX_STA_TWT_AGRT		8
diff --git a/package/kernel/mt76/patches/0009-wifi-mt76-mt7996-fix-uninitialized-variable-in-mt799.patch b/package/kernel/mt76/patches/0009-wifi-mt76-mt7996-fix-uninitialized-variable-in-mt799.patch
new file mode 100644
index 00000000000000..b0b7a78e3c1e06
--- /dev/null
+++ b/package/kernel/mt76/patches/0009-wifi-mt76-mt7996-fix-uninitialized-variable-in-mt799.patch
@@ -0,0 +1,27 @@
+From b96ab5e62010887a8abee43dbcccf6f4b3fcb269 Mon Sep 17 00:00:00 2001
+From: Lorenzo Bianconi <lorenzo@kernel.org>
+Date: Tue, 19 Mar 2024 13:05:36 +0100
+Subject: [PATCH] wifi: mt76: mt7996: fix uninitialized variable in
+ mt7996_irq_tasklet()
+
+Set intr1 to 0 in mt7996_irq_tasklet() in order to avoid possible
+uninitialized variable usage if wed is not active for hif2.
+
+Fixes: 83eafc9251d6 ("wifi: mt76: mt7996: add wed tx support")
+Signed-off-by: Lorenzo Bianconi <lorenzo@kernel.org>
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7996/mmio.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+--- a/mt7996/mmio.c
++++ b/mt7996/mmio.c
+@@ -499,7 +499,7 @@ static void mt7996_irq_tasklet(struct ta
+ 	struct mt7996_dev *dev = from_tasklet(dev, t, mt76.irq_tasklet);
+ 	struct mtk_wed_device *wed = &dev->mt76.mmio.wed;
+ 	struct mtk_wed_device *wed_hif2 = &dev->mt76.mmio.wed_hif2;
+-	u32 i, intr, mask, intr1;
++	u32 i, intr, mask, intr1 = 0;
+ 
+ 	if (dev->hif2 && mtk_wed_device_active(wed_hif2)) {
+ 		mtk_wed_device_irq_set_mask(wed_hif2, 0);
diff --git a/package/kernel/mt76/patches/0010-wifi-mt76-mt7996-fix-potential-memory-leakage-when-r.patch b/package/kernel/mt76/patches/0010-wifi-mt76-mt7996-fix-potential-memory-leakage-when-r.patch
new file mode 100644
index 00000000000000..a0d62dc5af96a9
--- /dev/null
+++ b/package/kernel/mt76/patches/0010-wifi-mt76-mt7996-fix-potential-memory-leakage-when-r.patch
@@ -0,0 +1,39 @@
+From 424e9df466cea3bb39a1e92bf95f3efe65472c27 Mon Sep 17 00:00:00 2001
+From: Howard Hsu <howard-yh.hsu@mediatek.com>
+Date: Wed, 20 Mar 2024 19:09:14 +0800
+Subject: [PATCH] wifi: mt76: mt7996: fix potential memory leakage when reading
+ chip temperature
+
+Without this commit, reading chip temperature will cause memory leakage.
+
+Fixes: 6879b2e94172 ("wifi: mt76: mt7996: add thermal sensor device support")
+Reported-by: Ryder Lee <ryder.lee@mediatek.com>
+Signed-off-by: Howard Hsu <howard-yh.hsu@mediatek.com>
+Signed-off-by: Shayne Chen <shayne.chen@mediatek.com>
+Signed-off-by: Felix Fietkau <nbd@nbd.name>
+---
+ mt7996/mcu.c | 5 ++++-
+ 1 file changed, 4 insertions(+), 1 deletion(-)
+
+--- a/mt7996/mcu.c
++++ b/mt7996/mcu.c
+@@ -3721,6 +3721,7 @@ int mt7996_mcu_get_temperature(struct mt
+ 	} __packed * res;
+ 	struct sk_buff *skb;
+ 	int ret;
++	u32 temp;
+ 
+ 	ret = mt76_mcu_send_and_get_msg(&phy->dev->mt76, MCU_WM_UNI_CMD(THERMAL),
+ 					&req, sizeof(req), true, &skb);
+@@ -3728,8 +3729,10 @@ int mt7996_mcu_get_temperature(struct mt
+ 		return ret;
+ 
+ 	res = (void *)skb->data;
++	temp = le32_to_cpu(res->temperature);
++	dev_kfree_skb(skb);
+ 
+-	return le32_to_cpu(res->temperature);
++	return temp;
+ }
+ 
+ int mt7996_mcu_set_thermal_throttling(struct mt7996_phy *phy, u8 state)
