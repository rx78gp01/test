diff --git a/package/network/utils/nftables/patches/001-cache.patch b/package/network/utils/nftables/patches/001-cache.patch
new file mode 100644
index 0000000..9f93767
--- /dev/null
+++ b/package/network/utils/nftables/patches/001-cache.patch
@@ -0,0 +1,55 @@
+diff --git a/src/cache.c b/src/cache.c
+index b7f46c001d6eb..97f50ccaf6ba1 100644
+--- a/src/cache.c
++++ b/src/cache.c
+@@ -203,11 +203,17 @@ static unsigned int evaluate_cache_list(struct nft_ctx *nft, struct cmd *cmd,
+ {
+ 	switch (cmd->obj) {
+ 	case CMD_OBJ_TABLE:
+-		if (filter && cmd->handle.table.name) {
++		if (filter)
+ 			filter->list.family = cmd->handle.family;
++		if (!cmd->handle.table.name) {
++			flags |= NFT_CACHE_TABLE;
++			break;
++		} else if (filter) {
+ 			filter->list.table = cmd->handle.table.name;
+ 		}
+ 		flags |= NFT_CACHE_FULL;
++		if (nft_output_terse(&nft->output))
++			flags |= NFT_CACHE_TERSE;
+ 		break;
+ 	case CMD_OBJ_CHAIN:
+ 		if (filter && cmd->handle.chain.name) {
+@@ -234,8 +234,6 @@ static unsigned int evaluate_cache_list(struct nft_ctx *nft, struct cmd *cmd,
+ 		}
+ 		if (filter->list.table && filter->list.set)
+ 			flags |= NFT_CACHE_TABLE | NFT_CACHE_SET | NFT_CACHE_SETELEM;
+-		else if (nft_output_terse(&nft->output))
+-			flags |= NFT_CACHE_FULL | NFT_CACHE_TERSE;
+ 		else
+ 			flags |= NFT_CACHE_FULL;
+ 		break;
+@@ -261,17 +259,15 @@ static unsigned int evaluate_cache_list(struct nft_ctx *nft, struct cmd *cmd,
+ 		flags |= NFT_CACHE_TABLE | NFT_CACHE_FLOWTABLE;
+ 		break;
+ 	case CMD_OBJ_RULESET:
+-		if (nft_output_terse(&nft->output))
+-			flags |= NFT_CACHE_FULL | NFT_CACHE_TERSE;
+-		else
+-			flags |= NFT_CACHE_FULL;
+-		break;
+ 	default:
+ 		flags |= NFT_CACHE_FULL;
+ 		break;
+ 	}
+ 	flags |= NFT_CACHE_REFRESH;
+ 
++	if (nft_output_terse(&nft->output))
++		flags |= NFT_CACHE_TERSE;
++
+ 	return flags;
+ }
+ 
+-- 
+2.43.0
\ No newline at end of file
-- 
2.43.0

