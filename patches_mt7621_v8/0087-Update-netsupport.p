diff --git a/package/kernel/linux/modules/netsupport.mk b/package/kernel/linux/modules/netsupport.mk
index 4fcb9ed..efb55d1 100644
--- a/package/kernel/linux/modules/netsupport.mk
+++ b/package/kernel/linux/modules/netsupport.mk
@@ -229,6 +229,7 @@ define KernelPackage/ipsec4
 	CONFIG_INET_ESP \
 	CONFIG_INET_IPCOMP \
 	CONFIG_INET_XFRM_TUNNEL \
+	CONFIG_XFRM_OFFLOAD \
 	CONFIG_INET_ESP_OFFLOAD=n
   FILES:=$(foreach mod,$(IPSEC4-m),$(LINUX_DIR)/net/$(mod).ko)
   AUTOLOAD:=$(call AutoLoad,32,$(notdir $(IPSEC4-m)))
-- 
2.38.1.windows.1

