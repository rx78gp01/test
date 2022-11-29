From 4b93f8db98517b1ef13136f7db7f21e421ac5daa Mon Sep 17 00:00:00 2001
From: Felix Fietkau <nbd@nbd.name>
Date: Tue, 23 Apr 2024 12:08:45 +0200
Subject: [PATCH] kernel: backport flow offload pppoe fix

Signed-off-by: Felix Fietkau <nbd@nbd.name>
---
diff --git a/target/linux/generic/backport-5.15/741-v6.9-01-netfilter-flowtable-validate-pppoe-header.patch b/target/linux/generic/backport-5.15/741-v6.9-01-netfilter-flowtable-validate-pppoe-header.patch
new file mode 100644
index 0000000000..02407da8a8
--- /dev/null
+++ b/target/linux/generic/backport-5.15/741-v6.9-01-netfilter-flowtable-validate-pppoe-header.patch
@@ -0,0 +1,85 @@
+From: Pablo Neira Ayuso <pablo@netfilter.org>
+Date: Thu, 11 Apr 2024 13:28:59 +0200
+Subject: [PATCH] netfilter: flowtable: validate pppoe header
+
+Ensure there is sufficient room to access the protocol field of the
+PPPoe header. Validate it once before the flowtable lookup, then use a
+helper function to access protocol field.
+
+Reported-by: syzbot+b6f07e1c07ef40199081@syzkaller.appspotmail.com
+Fixes: 72efd585f714 ("netfilter: flowtable: add pppoe support")
+Signed-off-by: Pablo Neira Ayuso <pablo@netfilter.org>
+---
+
+--- a/include/net/netfilter/nf_flow_table.h
++++ b/include/net/netfilter/nf_flow_table.h
+@@ -318,7 +318,7 @@ int nf_flow_rule_route_ipv6(struct net *
+ int nf_flow_table_offload_init(void);
+ void nf_flow_table_offload_exit(void);
+ 
+-static inline __be16 nf_flow_pppoe_proto(const struct sk_buff *skb)
++static inline __be16 __nf_flow_pppoe_proto(const struct sk_buff *skb)
+ {
+ 	__be16 proto;
+ 
+@@ -334,4 +334,14 @@ static inline __be16 nf_flow_pppoe_proto
+ 	return 0;
+ }
+ 
++static inline bool nf_flow_pppoe_proto(struct sk_buff *skb, __be16 *inner_proto)
++{
++	if (!pskb_may_pull(skb, PPPOE_SES_HLEN))
++		return false;
++
++	*inner_proto = __nf_flow_pppoe_proto(skb);
++
++	return true;
++}
++
+ #endif /* _NF_FLOW_TABLE_H */
+--- a/net/netfilter/nf_flow_table_inet.c
++++ b/net/netfilter/nf_flow_table_inet.c
+@@ -21,7 +21,8 @@ nf_flow_offload_inet_hook(void *priv, st
+ 		proto = veth->h_vlan_encapsulated_proto;
+ 		break;
+ 	case htons(ETH_P_PPP_SES):
+-		proto = nf_flow_pppoe_proto(skb);
++		if (!nf_flow_pppoe_proto(skb, &proto))
++			return NF_ACCEPT;
+ 		break;
+ 	default:
+ 		proto = skb->protocol;
+--- a/net/netfilter/nf_flow_table_ip.c
++++ b/net/netfilter/nf_flow_table_ip.c
+@@ -246,10 +246,11 @@ static unsigned int nf_flow_xmit_xfrm(st
+ 	return NF_STOLEN;
+ }
+ 
+-static bool nf_flow_skb_encap_protocol(const struct sk_buff *skb, __be16 proto,
++static bool nf_flow_skb_encap_protocol(struct sk_buff *skb, __be16 proto,
+ 				       u32 *offset)
+ {
+ 	struct vlan_ethhdr *veth;
++	__be16 inner_proto;
+ 
+ 	switch (skb->protocol) {
+ 	case htons(ETH_P_8021Q):
+@@ -260,7 +261,8 @@ static bool nf_flow_skb_encap_protocol(c
+ 		}
+ 		break;
+ 	case htons(ETH_P_PPP_SES):
+-		if (nf_flow_pppoe_proto(skb) == proto) {
++		if (nf_flow_pppoe_proto(skb, &inner_proto) &&
++		    inner_proto == proto) {
+ 			*offset += PPPOE_SES_HLEN;
+ 			return true;
+ 		}
+@@ -289,7 +291,7 @@ static void nf_flow_encap_pop(struct sk_
+ 			skb_reset_network_header(skb);
+ 			break;
+ 		case htons(ETH_P_PPP_SES):
+-			skb->protocol = nf_flow_pppoe_proto(skb);
++			skb->protocol = __nf_flow_pppoe_proto(skb);
+ 			skb_pull(skb, PPPOE_SES_HLEN);
+ 			skb_reset_network_header(skb);
+ 			break;
diff --git a/target/linux/generic/backport-5.15/741-v6.9-02-netfilter-flowtable-incorrect-pppoe-tuple.patch b/target/linux/generic/backport-5.15/741-v6.9-02-netfilter-flowtable-incorrect-pppoe-tuple.patch
new file mode 100644
index 0000000000..3b822b169d
--- /dev/null
+++ b/target/linux/generic/backport-5.15/741-v6.9-02-netfilter-flowtable-incorrect-pppoe-tuple.patch
@@ -0,0 +1,24 @@
+From: Pablo Neira Ayuso <pablo@netfilter.org>
+Date: Thu, 11 Apr 2024 13:29:00 +0200
+Subject: [PATCH] netfilter: flowtable: incorrect pppoe tuple
+
+pppoe traffic reaching ingress path does not match the flowtable entry
+because the pppoe header is expected to be at the network header offset.
+This bug causes a mismatch in the flow table lookup, so pppoe packets
+enter the classical forwarding path.
+
+Fixes: 72efd585f714 ("netfilter: flowtable: add pppoe support")
+Signed-off-by: Pablo Neira Ayuso <pablo@netfilter.org>
+---
+
+--- a/net/netfilter/nf_flow_table_ip.c
++++ b/net/netfilter/nf_flow_table_ip.c
+@@ -156,7 +156,7 @@ static void nf_flow_tuple_encap(struct s
+ 		tuple->encap[i].proto = skb->protocol;
+ 		break;
+ 	case htons(ETH_P_PPP_SES):
+-		phdr = (struct pppoe_hdr *)skb_mac_header(skb);
++		phdr = (struct pppoe_hdr *)skb_network_header(skb);
+ 		tuple->encap[i].id = ntohs(phdr->sid);
+ 		tuple->encap[i].proto = skb->protocol;
+ 		break;
diff --git a/target/linux/generic/hack-5.15/650-netfilter-add-xt_FLOWOFFLOAD-target.patch b/target/linux/generic/hack-5.15/650-netfilter-add-xt_FLOWOFFLOAD-target.patch
index ec887539d5..49f339bddc 100644
--- a/target/linux/generic/hack-5.15/650-netfilter-add-xt_FLOWOFFLOAD-target.patch
+++ b/target/linux/generic/hack-5.15/650-netfilter-add-xt_FLOWOFFLOAD-target.patch
@@ -98,7 +98,7 @@ Signed-off-by: Felix Fietkau <nbd@nbd.name>
  obj-$(CONFIG_NETFILTER_XT_TARGET_LED) += xt_LED.o
 --- /dev/null
 +++ b/net/netfilter/xt_FLOWOFFLOAD.c
-@@ -0,0 +1,701 @@
+@@ -0,0 +1,702 @@
 +/*
 + * Copyright (C) 2018-2021 Felix Fietkau <nbd@nbd.name>
 + *
@@ -163,7 +163,8 @@ Signed-off-by: Felix Fietkau <nbd@nbd.name>
 +		proto = veth->h_vlan_encapsulated_proto;
 +		break;
 +	case htons(ETH_P_PPP_SES):
-+		proto = nf_flow_pppoe_proto(skb);
++		if (!nf_flow_pppoe_proto(skb, &proto))
++			return NF_ACCEPT;
 +		break;
 +	default:
 +		proto = skb->protocol;
-- 
2.30.2

