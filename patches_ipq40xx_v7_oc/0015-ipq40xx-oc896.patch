From 9bb33781e982efd59edd0cf06ce4e24fd4e38d59 Mon Sep 17 00:00:00 2001
From: gw826943555 <gw826943555@qq.com>
Date: Fri, 18 Dec 2020 22:59:41 +0800
Subject: [PATCH] ipq40xx: improve cpu operating points and oc to 896Mz

---
 .../999-ipq40xx-unlock-cpu-frequency.patch    | 62 +++++++++++++++++++
 1 file changed, 62 insertions(+)
 create mode 100644 target/linux/ipq40xx/patches-5.15/991-ipq40xx-unlock-cpu-frequency.patch

diff --git a/target/linux/ipq40xx/patches-5.15/991-ipq40xx-unlock-cpu-frequency.patch b/target/linux/ipq40xx/patches-5.15/991-ipq40xx-unlock-cpu-frequency.patch
new file mode 100644
index 00000000000..c8390c133c8
--- /dev/null
+++ b/target/linux/ipq40xx/patches-5.15/991-ipq40xx-unlock-cpu-frequency.patch
@@ -0,0 +1,62 @@
+From: William <gw826943555@qq.com>
+Subject: [PATCH] ipq40xx: improve CPU clock
+Date: Tue, 15 Dec 2020 15:26:35 +0800
+
+This patch will match the clock-latency-ns values in the device tree 
+for those found inside the OEM device tree and kernel source code and 
+unlock 896Mhz CPU operating points.
+
+Signed-off-by: William <gw826943555@qq.com>
+---
+
+--- a/arch/arm/boot/dts/qcom-ipq4019.dtsi
++++ b/arch/arm/boot/dts/qcom-ipq4019.dtsi
+@@ -114,20 +114,32 @@
+ 
+ 		opp-48000000 {
+ 			opp-hz = /bits/ 64 <48000000>;
+-			clock-latency-ns = <256000>;
++			clock-latency-ns = <100000>;
+ 		};
+ 		opp-200000000 {
+ 			opp-hz = /bits/ 64 <200000000>;
+-			clock-latency-ns = <256000>;
++			clock-latency-ns = <100000>;
+ 		};
+ 		opp-500000000 {
+ 			opp-hz = /bits/ 64 <500000000>;
+-			clock-latency-ns = <256000>;
++			clock-latency-ns = <100000>;
+ 		};
+ 		opp-716000000 {
+ 			opp-hz = /bits/ 64 <716000000>;
+-			clock-latency-ns = <256000>;
++			clock-latency-ns = <100000>;
+  		};
++		opp-768000000 {
++			opp-hz = /bits/ 64 <768000000>;
++			clock-latency-ns = <100000>;
++		};
++		opp-823000000 {
++			opp-hz = /bits/ 64 <823000000>;
++			clock-latency-ns = <100000>;
++		};
++		opp-896000000 {
++			opp-hz = /bits/ 64 <896000000>;
++			clock-latency-ns = <100000>;
++		};
+ 	};
+ 
+ 	memory {
+--- a/drivers/clk/qcom/gcc-ipq4019.c
++++ b/drivers/clk/qcom/gcc-ipq4019.c
+@@ -579,6 +579,9 @@ static const struct freq_tbl ftbl_gcc_ap
+ 	F(632000000, P_DDRPLLAPSS, 1, 0, 0),
+ 	F(672000000, P_DDRPLLAPSS, 1, 0, 0),
+ 	F(716000000, P_DDRPLLAPSS, 1, 0, 0),
++	F(768000000, P_DDRPLLAPSS, 1, 0, 0),
++	F(823000000, P_DDRPLLAPSS, 1, 0, 0),
++	F(896000000, P_DDRPLLAPSS, 1, 0, 0),
+ 	{ }
+ };
+ 
