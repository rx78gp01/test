diff --git a/target/linux/ramips/patches-5.15/999-mtk_eth_soc.patch b/target/linux/ramips/patches-5.15/999-mtk_eth_soc.patch
new file mode 100644
index 0000000..696413b
--- /dev/null
+++ b/target/linux/ramips/patches-5.15/999-mtk_eth_soc.patch
@@ -0,0 +1,44 @@
+diff --git a/drivers/net/ethernet/mediatek/mtk_eth_soc.c b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+index ea3ff92..6b55c3d 100644
+--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.c
++++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.c
+@@ -1553,7 +1553,7 @@
+ 			if (ret != XDP_PASS)
+ 				goto skip_rx;
+ 
+-			skb = build_skb(data, PAGE_SIZE);
++			skb = napi_build_skb(data, PAGE_SIZE);
+ 			if (unlikely(!skb)) {
+ 				page_pool_put_full_page(ring->page_pool,
+ 							page, true);
+@@ -1653,7 +1653,7 @@
+ 			dma_unmap_single(eth->dma_dev, ((u64)trxd.rxd1 | addr64),
+ 					 ring->buf_size, DMA_FROM_DEVICE);
+ 
+-			skb = build_skb(data, ring->frag_size);
++			skb = napi_build_skb(data, ring->frag_size);
+ 			if (unlikely(!skb)) {
+ 				netdev->stats.rx_dropped++;
+ 				skb_free_frag(data);
+@@ -2738,7 +2738,7 @@
+ 			if (ring->frag_size <= PAGE_SIZE)
+ 				data = netdev_alloc_frag(ring->frag_size);
+ 			else
+-				data = mtk_max_lro_buf_alloc(GFP_KERNEL);
++				data = mtk_max_lro_buf_alloc(GFP_ATOMIC);
+ 
+ 			if (!data)
+ 				return -ENOMEM;
+@@ -3212,7 +3212,10 @@
+ 			mtk_rx_clean(eth, &eth->rx_ring[i], false)
+ 	}
+ 
+-	kfree(eth->scratch_head);
++	if (eth->scratch_head) {
++		kfree(eth->scratch_head);
++		eth->scratch_head = NULL;
++	}
+ }
+ 
+ static bool mtk_hw_reset_check(struct mtk_eth *eth)
+ 
\ No newline at end of file
-- 
2.38.1.windows.1

