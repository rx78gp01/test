From 46d673033b7f6974d0bf5696ff8365fd412cd646 Mon Sep 17 00:00:00 2001
From: Aviana Cruz <gwencroft@proton.me>
Date: Mon, 20 Jun 2022 21:55:45 +0800
Subject: [PATCH] ramips: add support for mtk eip93 crypto engine

Mediatek EIP93 Crypto engine is a crypto accelerator which
is available in the Mediatek MT7621 SoC.

Signed-off-by: Aviana Cruz <gwencroft@proton.me>
Co-authored-by: Richard van Schagen <vschagen@icloud.com>
Co-authored-by: Chukun Pan <amadeus@jmu.edu.cn>
---
 package/kernel/linux/modules/crypto.mk        |   29 +
 target/linux/ramips/dts/mt7621.dtsi           |    8 +
 target/linux/ramips/mt7621/target.mk          |    2 +-
 .../860-ramips-add-eip93-driver.patch         | 3276 +++++++++++++++++
 4 files changed, 3314 insertions(+), 1 deletion(-)
 create mode 100644 target/linux/ramips/patches-5.15/860-ramips-add-eip93-driver.patch

diff --git a/package/kernel/linux/modules/crypto.mk b/package/kernel/linux/modules/crypto.mk
index 248b4d68f9e14..501be4b0a02c8 100644
--- a/package/kernel/linux/modules/crypto.mk
+++ b/package/kernel/linux/modules/crypto.mk
@@ -463,6 +463,37 @@ endef
 
 $(eval $(call KernelPackage,crypto-hw-talitos))
 
+define KernelPackage/crypto-hw-eip93
+  TITLE:=MTK EIP93 crypto module
+  DEPENDS:=@TARGET_ramips_mt7621 \
+	+kmod-crypto-authenc \
+	+kmod-crypto-des \
+	+kmod-crypto-md5 \
+	+kmod-crypto-sha1 \
+	+kmod-crypto-sha256
+  KCONFIG:= \
+	CONFIG_CRYPTO_HW=y \
+	CONFIG_CRYPTO_DEV_EIP93 \
+	CONFIG_CRYPTO_DEV_EIP93_AES=y \
+	CONFIG_CRYPTO_DEV_EIP93_DES=y \
+	CONFIG_CRYPTO_DEV_EIP93_AEAD=y \
+	CONFIG_CRYPTO_DEV_EIP93_GENERIC_SW_MAX_LEN=256 \
+	CONFIG_CRYPTO_DEV_EIP93_AES_128_SW_MAX_LEN=512 \
+	CONFIG_CRYPTO_DEV_EIP93_PRNG \
+	CONFIG_CRYPTO_DEV_EIP93_IPSEC
+  FILES:=$(LINUX_DIR)/drivers/crypto/mtk-eip93/crypto-hw-eip93.ko
+  AUTOLOAD:=$(call AutoLoad,09,crypto-hw-eip93)
+  $(call AddDepends/crypto)
+endef
+
+define KernelPackage/crypto-hw-eip93/description
+Kernel module to enable EIP-93 Crypto engine as found
+in the Mediatek MT7621 SoC.
+It enables DES/3DES/AES ECB/CBC/CTR and
+IPSEC offload with authenc(hmac(sha1/sha256), aes/cbc/rfc3686)
+endef
+
+$(eval $(call KernelPackage,crypto-hw-eip93))
 
 define KernelPackage/crypto-kpp
   TITLE:=Key-agreement Protocol Primitives
diff --git a/target/linux/ramips/dts/mt7621.dtsi b/target/linux/ramips/dts/mt7621.dtsi
index f1f77282b2478..4d82aa327b5f8 100644
--- a/target/linux/ramips/dts/mt7621.dtsi
+++ b/target/linux/ramips/dts/mt7621.dtsi
@@ -423,6 +423,14 @@
 		clock-names = "nfi_clk";
 	};
 
+	crypto: crypto@1e004000 {
+		compatible = "mediatek,mtk-eip93";
+		reg = <0x1e004000 0x1000>;
+
+		interrupt-parent = <&gic>;
+		interrupts = <GIC_SHARED 19 IRQ_TYPE_LEVEL_HIGH>;
+	};
+
 	ethernet: ethernet@1e100000 {
 		compatible = "mediatek,mt7621-eth";
 		reg = <0x1e100000 0x10000>;
diff --git a/target/linux/ramips/mt7621/target.mk b/target/linux/ramips/mt7621/target.mk
index 153ff08421d69..2b9a1312af0ab 100644
--- a/target/linux/ramips/mt7621/target.mk
+++ b/target/linux/ramips/mt7621/target.mk
@@ -10,7 +10,7 @@ KERNELNAME:=vmlinux vmlinuz
 # make Kernel/CopyImage use $LINUX_DIR/vmlinuz
 IMAGES_DIR:=../../..
 
-DEFAULT_PACKAGES += wpad-openssl uboot-envtools
+DEFAULT_PACKAGES += wpad-openssl uboot-envtools kmod-crypto-hw-eip93 kmod-crypto-sha1
 
 define Target/Description
 	Build firmware images for Ralink MT7621 based boards.
diff --git a/target/linux/ramips/patches-5.15/860-ramips-add-eip93-driver.patch b/target/linux/ramips/patches-5.15/860-ramips-add-eip93-driver.patch
new file mode 100644
index 0000000..df8fd14
--- /dev/null
+++ b/target/linux/ramips/patches-5.15/860-ramips-add-eip93-driver.patch
@@ -0,0 +1,5610 @@
+diff --git a/drivers/crypto/mtk-eip93/Kconfig b/drivers/crypto/mtk-eip93/Kconfig
+new file mode 100644
+index 0000000..b8f7e86
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/Kconfig
+@@ -0,0 +1,101 @@
++# SPDX-License-Identifier: GPL-2.0
++config CRYPTO_DEV_EIP93_SKCIPHER
++	tristate
++
++config CRYPTO_DEV_EIP93_AES
++	tristate
++
++config CRYPTO_DEV_EIP93_DES
++	tristate
++
++config CRYPTO_DEV_EIP93_HMAC
++	tristate
++
++config CRYPTO_DEV_EIP93
++	tristate "Support for EIP93 crypto HW accelerators"
++	depends on SOC_MT7621
++	help
++	  EIP93 have various crypto HW accelerators. Select this if
++	  you want to use the EIP93 modules for any of the crypto algorithms.
++
++if CRYPTO_DEV_EIP93
++
++config CRYPTO_DEV_EIP93_SKCIPHER_AES
++	bool "Register AES algorithm implementations with the Crypto API"
++	default y
++	select CRYPTO_DEV_EIP93_SKCIPHER
++	select CYRPTO_DEV_EIP93_AES
++	select CRYPTO_LIB_AES
++	select CRYPTO_SKCIPHER
++	help
++	  Selecting this will offload AES - ECB, CBC and CTR crypto
++	  to the EIP-93 crypto engine.
++
++config CRYPTO_DEV_EIP93_SKCIPHER_DES
++	bool "Register legacy DES / 3DES algorithm with the Crypto API"
++	default y
++	select CRYPTO_DEV_EIP93_SKCIPHER
++	select CRYPTO_DEV_EIP93_DES
++	select CRYPTO_LIB_DES
++	select CRYPTO_SKCIPHER
++	help
++	  Selecting this will offload DES and 3DES ECB and CBC
++	  crypto to the EIP-93 crypto engine.
++
++config CRYPTO_DEV_EIP93_AEAD
++  	bool "Register AEAD algorithm with the Crypto API"
++  	default y
++	select CRYPTO_DEV_EIP93_HMAC
++	select CRYPTO_DEV_EIP93_AES
++	select CRYPTO_AEAD
++	select CRYPTO_AUTHENC
++	select CRYPTO_MD5
++	select CRYPTO_SHA1
++	select CRYPTO_SHA256
++	help
++  	  Selecting this will offload AEAD authenc(hmac(x), cipher(y))
++	  crypto to the EIP-93 crypto engine. When legacy DES is selected,
++		these will also be used for AEAD.
++
++config CRYPTO_DEV_EIP93_GENERIC_SW_MAX_LEN
++	int "Max skcipher software fallback length"
++	default 256
++	help
++	  Max length of crypt request which
++	  will fallback to software crypt of skcipher *except* AES-128.
++
++config CRYPTO_DEV_EIP93_AES_128_SW_MAX_LEN
++	int "Max AES-128 skcipher software fallback length"
++	default 512
++	help
++	  Max length of crypt request which
++	  will fallback to software crypt of AES-128 skcipher.
++
++config CRYPTO_DEV_EIP93_HASH
++	bool "Register HASH algorithm implementatons with the Crypto API"
++	default n
++	select CRYPTO_MD5
++	select CRYPTO_SHA1
++	select CRYPTO_SHA256
++	help
++	  Selecting this will offload SHA1, SHA224 and SHA256 hash algorithm
++	  and HMAC(SHA1), HMAC(SHA224) and HMAC(SHA256) to the EIP-93 crypto
++	  engine.
++
++config CRYPTO_DEV_EIP93_PRNG
++	bool "Register PRNG device with the Crypto API"
++	default n
++	help
++	  Selecting this will add the ANSI X9.31 Pseudo Random Number Generator
++	  to the EIP-93 crypto engine.
++
++config CRYPTO_DEV_EIP93_IPSEC
++	bool "Register IPSec ESP hardware offloading"
++	default n
++	select CRYPTO_DEV_EIP93_PRNG
++	select CRYPTO_DEV_EIP93_HMAC
++	help
++	  Selecting this will add ESP HW offloading for IPSec
++	  to the EIP-93 crypto engine. Requires IPSec offload
++	  to be selected with the Mediatek Ethernet Driver
++endif
+diff --git a/drivers/crypto/mtk-eip93/Makefile b/drivers/crypto/mtk-eip93/Makefile
+new file mode 100644
+index 0000000..a915bf3
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/Makefile
+@@ -0,0 +1,9 @@
++obj-$(CONFIG_CRYPTO_DEV_EIP93) += crypto-hw-eip93.o
++
++crypto-hw-eip93-y += eip93-main.o eip93-common.o
++
++crypto-hw-eip93-$(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER) += eip93-cipher.o
++crypto-hw-eip93-$(CONFIG_CRYPTO_DEV_EIP93_AEAD) += eip93-aead.o
++crypto-hw-eip93-$(CONFIG_CRYPTO_DEV_EIP93_PRNG) += eip93-prng.o
++
++crypto-hw-eip93-$(CONFIG_CRYPTO_DEV_EIP93_IPSEC) += eip93-ipsec.o
+diff --git a/drivers/crypto/mtk-eip93/eip93-aead.c b/drivers/crypto/mtk-eip93/eip93-aead.c
+new file mode 100644
+index 0000000..3288ba9
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-aead.c
+@@ -0,0 +1,758 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <crypto/aead.h>
++#include <crypto/aes.h>
++#include <crypto/authenc.h>
++#include <crypto/ctr.h>
++#include <crypto/hmac.h>
++#include <crypto/internal/aead.h>
++#include <crypto/md5.h>
++#include <crypto/null.h>
++#include <crypto/sha1.h>
++#include <crypto/sha2.h>
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++#include <crypto/internal/des.h>
++#endif
++
++#include <linux/crypto.h>
++#include <linux/dma-mapping.h>
++
++#include "eip93-aead.h"
++#include "eip93-cipher.h"
++#include "eip93-common.h"
++#include "eip93-regs.h"
++
++void mtk_aead_handle_result(struct aead_request *req, int err)
++{
++	struct mtk_cipher_reqctx *rctx = aead_request_ctx(req);
++
++	mtk_unmap_dma(rctx, req->src, req->dst);
++	mtk_handle_result(rctx, req->iv);
++
++	if (err == 1)
++		err = -EBADMSG;
++	/* let software handle anti-replay errors */
++	if (err == 4)
++		err = 0;
++
++	aead_request_complete(req, err);
++}
++
++static int mtk_aead_send_req(struct aead_request *req)
++{
++	struct mtk_cipher_reqctx *rctx = aead_request_ctx(req);
++	int err;
++
++	err = check_valid_request(rctx);
++	if (err) {
++		aead_request_complete(req, err);
++		return err;
++	}
++
++	rctx->async = (uintptr_t)req;
++	return mtk_send_req(rctx, req->iv);
++}
++
++/* Crypto aead API functions */
++static int mtk_aead_cra_init(struct crypto_tfm *tfm)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++	struct mtk_alg_template *tmpl = container_of(tfm->__crt_alg,
++				struct mtk_alg_template, alg.aead.base);
++	u32 flags = tmpl->flags;
++	char *alg_base;
++
++	//memset(ctx, 0, sizeof(*ctx));
++
++	crypto_aead_set_reqsize(__crypto_aead_cast(tfm),
++			sizeof(struct mtk_cipher_reqctx));
++
++	ctx->mtk = tmpl->mtk;
++	ctx->in_first = true;
++	ctx->out_first = true;
++
++	ctx->sa_in = kzalloc(sizeof(struct saRecord_s), GFP_KERNEL);
++	if (!ctx->sa_in)
++		return -ENOMEM;
++
++	ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	ctx->sa_out = kzalloc(sizeof(struct saRecord_s), GFP_KERNEL);
++	if (!ctx->sa_out)
++		return -ENOMEM;
++
++	ctx->sa_base_out = dma_map_single(ctx->mtk->dev, ctx->sa_out,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	/* software workaround for now */
++	if (IS_HASH_MD5(flags))
++		alg_base = "md5";
++	if (IS_HASH_SHA1(flags))
++		alg_base = "sha1";
++	if (IS_HASH_SHA224(flags))
++		alg_base = "sha224";
++	if (IS_HASH_SHA256(flags))
++		alg_base = "sha256";
++
++	ctx->shash = crypto_alloc_shash(alg_base, 0, CRYPTO_ALG_NEED_FALLBACK);
++
++	if (IS_ERR(ctx->shash)) {
++		dev_err(ctx->mtk->dev, "base driver %s could not be loaded.\n",
++				alg_base);
++		return PTR_ERR(ctx->shash);
++	}
++
++	return 0;
++}
++
++static void mtk_aead_cra_exit(struct crypto_tfm *tfm)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++
++	if (ctx->shash)
++		crypto_free_shash(ctx->shash);
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_out,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	kfree(ctx->sa_in);
++	kfree(ctx->sa_out);
++}
++
++static int mtk_aead_setkey(struct crypto_aead *ctfm, const u8 *key,
++			unsigned int len)
++{
++	struct crypto_tfm *tfm = crypto_aead_tfm(ctfm);
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++	struct mtk_alg_template *tmpl = container_of(tfm->__crt_alg,
++				struct mtk_alg_template, alg.skcipher.base);
++	u32 flags = tmpl->flags;
++	u32 nonce = 0;
++	struct crypto_authenc_keys keys;
++	struct crypto_aes_ctx aes;
++	struct saRecord_s *saRecord = ctx->sa_out;
++	int sa_size = sizeof(struct saRecord_s);
++	int err = -EINVAL;
++
++
++	if (crypto_authenc_extractkeys(&keys, key, len))
++		return err;
++
++	if (IS_RFC3686(flags)) {
++		if (keys.enckeylen < CTR_RFC3686_NONCE_SIZE)
++			return err;
++
++		keys.enckeylen -= CTR_RFC3686_NONCE_SIZE;
++		memcpy(&nonce, keys.enckey + keys.enckeylen,
++						CTR_RFC3686_NONCE_SIZE);
++	}
++
++	switch ((flags & MTK_ALG_MASK)) {
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++	case MTK_ALG_DES:
++		err = verify_aead_des_key(ctfm, keys.enckey, keys.enckeylen);
++		break;
++	case MTK_ALG_3DES:
++		if (keys.enckeylen != DES3_EDE_KEY_SIZE)
++			return -EINVAL;
++
++		err = verify_aead_des3_key(ctfm, keys.enckey, keys.enckeylen);
++		break;
++#endif
++	case MTK_ALG_AES:
++		err = aes_expandkey(&aes, keys.enckey, keys.enckeylen);
++	}
++	if (err)
++		return err;
++
++	ctx->blksize = crypto_aead_blocksize(ctfm);
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in, sa_size,
++								DMA_TO_DEVICE);
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_out, sa_size,
++								DMA_TO_DEVICE);
++	/* Encryption key */
++	mtk_set_saRecord(saRecord, keys.enckeylen, flags);
++	saRecord->saCmd0.bits.opCode = 1;
++	saRecord->saCmd0.bits.digestLength = ctx->authsize >> 2;
++
++	memcpy(saRecord->saKey, keys.enckey, keys.enckeylen);
++	ctx->saNonce = nonce;
++	saRecord->saNonce = nonce;
++
++	/* authentication key */
++	err = mtk_authenc_setkey(ctx->shash, saRecord, keys.authkey,
++							keys.authkeylen);
++
++	saRecord->saCmd0.bits.direction = 0;
++	memcpy(ctx->sa_in, saRecord, sa_size);
++	ctx->sa_in->saCmd0.bits.direction = 1;
++	ctx->sa_in->saCmd1.bits.copyDigest = 0;
++
++	ctx->sa_base_out = dma_map_single(ctx->mtk->dev, ctx->sa_out, sa_size,
++								DMA_TO_DEVICE);
++	ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in, sa_size,
++								DMA_TO_DEVICE);
++	ctx->in_first = true;
++	ctx->out_first = true;
++
++	return err;
++}
++
++static int mtk_aead_setauthsize(struct crypto_aead *ctfm,
++				unsigned int authsize)
++{
++	struct crypto_tfm *tfm = crypto_aead_tfm(ctfm);
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_out,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	ctx->authsize = authsize;
++	ctx->sa_in->saCmd0.bits.digestLength = ctx->authsize >> 2;
++	ctx->sa_out->saCmd0.bits.digestLength = ctx->authsize >> 2;
++
++	ctx->sa_base_out = dma_map_single(ctx->mtk->dev, ctx->sa_out,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	return 0;
++}
++
++static void mtk_aead_setassoc(struct mtk_crypto_ctx *ctx,
++			struct aead_request *req, bool in)
++{
++	struct saRecord_s *saRecord;
++
++	if (in) {
++		dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++		saRecord = ctx->sa_in;
++		saRecord->saCmd1.bits.hashCryptOffset = req->assoclen >> 2;
++
++		ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	} else {
++		dma_unmap_single(ctx->mtk->dev, ctx->sa_base_out,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++		saRecord = ctx->sa_out;
++		saRecord->saCmd1.bits.hashCryptOffset = req->assoclen >> 2;
++
++		ctx->sa_base_out = dma_map_single(ctx->mtk->dev, ctx->sa_out,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	}
++}
++
++static int mtk_aead_crypt(struct aead_request *req)
++{
++	struct mtk_cipher_reqctx *rctx = aead_request_ctx(req);
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
++	struct crypto_aead *aead = crypto_aead_reqtfm(req);
++
++	rctx->textsize = req->cryptlen;
++	rctx->blksize = ctx->blksize;
++	rctx->assoclen = req->assoclen;
++	rctx->authsize = ctx->authsize;
++	rctx->sg_src = req->src;
++	rctx->sg_dst = req->dst;
++	rctx->ivsize = crypto_aead_ivsize(aead);
++	rctx->flags |= MTK_DESC_AEAD;
++	rctx->mtk = ctx->mtk;
++	rctx->saNonce = ctx->saNonce;
++
++	if IS_DECRYPT(rctx->flags)
++		rctx->textsize -= rctx->authsize;
++
++	return mtk_aead_send_req(req);
++}
++
++static int mtk_aead_encrypt(struct aead_request *req)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
++	struct mtk_cipher_reqctx *rctx = aead_request_ctx(req);
++	struct mtk_alg_template *tmpl = container_of(req->base.tfm->__crt_alg,
++				struct mtk_alg_template, alg.aead.base);
++
++	rctx->flags = tmpl->flags;
++	rctx->flags |= MTK_ENCRYPT;
++	if (ctx->out_first) {
++		mtk_aead_setassoc(ctx, req, false);
++		ctx->out_first = false;
++	}
++
++	rctx->saRecord_base = ctx->sa_base_out;
++
++	return mtk_aead_crypt(req);
++}
++
++static int mtk_aead_decrypt(struct aead_request *req)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
++	struct mtk_cipher_reqctx *rctx = aead_request_ctx(req);
++	struct mtk_alg_template *tmpl = container_of(req->base.tfm->__crt_alg,
++				struct mtk_alg_template, alg.aead.base);
++
++	rctx->flags = tmpl->flags;
++	rctx->flags |= MTK_DECRYPT;
++	if (ctx->in_first) {
++		mtk_aead_setassoc(ctx, req, true);
++		ctx->in_first = false;
++	}
++
++	rctx->saRecord_base = ctx->sa_base_in;
++
++	return mtk_aead_crypt(req);
++}
++
++/* Available authenc algorithms in this module */
++
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AES)
++struct mtk_alg_template mtk_alg_authenc_hmac_md5_cbc_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_MD5 | MTK_MODE_CBC | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= AES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = MD5_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(md5),cbc(aes))",
++			.cra_driver_name =
++				"authenc(hmac(md5-eip93), cbc(aes-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = AES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha1_cbc_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA1 | MTK_MODE_CBC | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= AES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA1_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha1),cbc(aes))",
++			.cra_driver_name =
++				"authenc(hmac(sha1-eip93),cbc(aes-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = AES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha224_cbc_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA224 | MTK_MODE_CBC | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= AES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA224_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha224),cbc(aes))",
++			.cra_driver_name =
++				"authenc(hmac(sha224-eip93),cbc(aes-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = AES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha256_cbc_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA256 | MTK_MODE_CBC | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= AES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA256_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha256),cbc(aes))",
++			.cra_driver_name =
++				"authenc(hmac(sha256-eip93),cbc(aes-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = AES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_md5_rfc3686_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_MD5 |
++			MTK_MODE_CTR | MTK_MODE_RFC3686 | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= CTR_RFC3686_IV_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = MD5_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(md5),rfc3686(ctr(aes)))",
++			.cra_driver_name =
++			"authenc(hmac(md5-eip93),rfc3686(ctr(aes-eip93)))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = 1,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha1_rfc3686_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA1 |
++			MTK_MODE_CTR | MTK_MODE_RFC3686 | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= CTR_RFC3686_IV_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA1_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha1),rfc3686(ctr(aes)))",
++			.cra_driver_name =
++			"authenc(hmac(sha1-eip93),rfc3686(ctr(aes-eip93)))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = 1,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha224_rfc3686_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA224 |
++			MTK_MODE_CTR | MTK_MODE_RFC3686 | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= CTR_RFC3686_IV_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA224_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha224),rfc3686(ctr(aes)))",
++			.cra_driver_name =
++			"authenc(hmac(sha224-eip93),rfc3686(ctr(aes-eip93)))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = 1,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha256_rfc3686_aes = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA256 |
++			MTK_MODE_CTR | MTK_MODE_RFC3686 | MTK_ALG_AES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= CTR_RFC3686_IV_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA256_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha256),rfc3686(ctr(aes)))",
++			.cra_driver_name =
++			"authenc(hmac(sha256-eip93),rfc3686(ctr(aes-eip93)))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = 1,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++struct mtk_alg_template mtk_alg_authenc_hmac_md5_cbc_des = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_MD5 | MTK_MODE_CBC | MTK_ALG_DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = MD5_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(md5),cbc(des))",
++			.cra_driver_name =
++				"authenc(hmac(md5-eip93),cbc(des-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha1_cbc_des = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA1 | MTK_MODE_CBC | MTK_ALG_DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA1_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha1),cbc(des))",
++			.cra_driver_name =
++				"authenc(hmac(sha1-eip93),cbc(des-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha224_cbc_des = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA224 | MTK_MODE_CBC | MTK_ALG_DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA224_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha224),cbc(des))",
++			.cra_driver_name =
++				"authenc(hmac(sha224-eip93),cbc(des-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha256_cbc_des = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA256 | MTK_MODE_CBC | MTK_ALG_DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA256_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha256),cbc(des))",
++			.cra_driver_name =
++				"authenc(hmac(sha256-eip93),cbc(des-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_md5_cbc_des3_ede = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_MD5 | MTK_MODE_CBC | MTK_ALG_3DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES3_EDE_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = MD5_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(md5),cbc(des3_ede))",
++			.cra_driver_name =
++				"authenc(hmac(md5-eip93),cbc(des3_ede-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES3_EDE_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0x0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha1_cbc_des3_ede = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA1 | MTK_MODE_CBC | MTK_ALG_3DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES3_EDE_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA1_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha1),cbc(des3_ede))",
++			.cra_driver_name =
++				"authenc(hmac(sha1-eip93),cbc(des3_ede-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES3_EDE_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0x0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha224_cbc_des3_ede = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA224 | MTK_MODE_CBC | MTK_ALG_3DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES3_EDE_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA224_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha224),cbc(des3_ede))",
++			.cra_driver_name =
++			"authenc(hmac(sha224-eip93),cbc(des3_ede-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES3_EDE_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0x0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_authenc_hmac_sha256_cbc_des3_ede = {
++	.type = MTK_ALG_TYPE_AEAD,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA256 | MTK_MODE_CBC | MTK_ALG_3DES,
++	.alg.aead = {
++		.setkey = mtk_aead_setkey,
++		.encrypt = mtk_aead_encrypt,
++		.decrypt = mtk_aead_decrypt,
++		.ivsize	= DES3_EDE_BLOCK_SIZE,
++		.setauthsize = mtk_aead_setauthsize,
++		.maxauthsize = SHA256_DIGEST_SIZE,
++		.base = {
++			.cra_name = "authenc(hmac(sha256),cbc(des3_ede))",
++			.cra_driver_name =
++			"authenc(hmac(sha256-eip93),cbc(des3_ede-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES3_EDE_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0x0,
++			.cra_init = mtk_aead_cra_init,
++			.cra_exit = mtk_aead_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++#endif
+diff --git a/drivers/crypto/mtk-eip93/eip93-aead.h b/drivers/crypto/mtk-eip93/eip93-aead.h
+new file mode 100644
+index 0000000..86e459a
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-aead.h
+@@ -0,0 +1,31 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#ifndef _EIP93_AEAD_H_
++#define _EIP93_AEAD_H_
++
++extern struct mtk_alg_template mtk_alg_authenc_hmac_md5_cbc_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha1_cbc_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha224_cbc_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha256_cbc_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_md5_rfc3686_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha1_rfc3686_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha224_rfc3686_aes;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha256_rfc3686_aes;
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++extern struct mtk_alg_template mtk_alg_authenc_hmac_md5_cbc_des;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha1_cbc_des;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha224_cbc_des;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha256_cbc_des;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_md5_cbc_des3_ede;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha1_cbc_des3_ede;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha224_cbc_des3_ede;
++extern struct mtk_alg_template mtk_alg_authenc_hmac_sha256_cbc_des3_ede;
++#endif
++
++void mtk_aead_handle_result(struct aead_request *req, int err);
++
++#endif /* _EIP93_AEAD_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-aes.h b/drivers/crypto/mtk-eip93/eip93-aes.h
+new file mode 100644
+index 0000000..4c0b926
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-aes.h
+@@ -0,0 +1,15 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#ifndef _EIP93_AES_H_
++#define _EIP93_AES_H_
++
++extern struct mtk_alg_template mtk_alg_ecb_aes;
++extern struct mtk_alg_template mtk_alg_cbc_aes;
++extern struct mtk_alg_template mtk_alg_ctr_aes;
++extern struct mtk_alg_template mtk_alg_rfc3686_aes;
++
++#endif /* _EIP93_AES_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-cipher.c b/drivers/crypto/mtk-eip93/eip93-cipher.c
+new file mode 100644
+index 0000000..59abfb5
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-cipher.c
+@@ -0,0 +1,484 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AES)
++#include <crypto/aes.h>
++#include <crypto/ctr.h>
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++#include <crypto/internal/des.h>
++#endif
++#include <linux/dma-mapping.h>
++
++#include "eip93-cipher.h"
++#include "eip93-common.h"
++#include "eip93-regs.h"
++
++void mtk_skcipher_handle_result(struct skcipher_request *req, int err)
++{
++	struct mtk_cipher_reqctx *rctx = skcipher_request_ctx(req);
++
++	mtk_unmap_dma(rctx, req->src, req->dst);
++	mtk_handle_result(rctx, req->iv);
++
++	skcipher_request_complete(req, err);
++}
++
++static inline bool mtk_skcipher_is_fallback(const struct crypto_tfm *tfm,
++					    u32 flags)
++{
++	return (tfm->__crt_alg->cra_flags & CRYPTO_ALG_NEED_FALLBACK) &&
++	       !IS_RFC3686(flags);
++}
++
++static int mtk_skcipher_send_req(struct skcipher_request *req)
++{
++	struct mtk_cipher_reqctx *rctx = skcipher_request_ctx(req);
++	int err;
++
++	err = check_valid_request(rctx);
++
++	if (err) {
++		skcipher_request_complete(req, err);
++		return err;
++	}
++
++	rctx->async = (uintptr_t)req;
++	return mtk_send_req(rctx, req->iv);
++}
++
++/* Crypto skcipher API functions */
++static int mtk_skcipher_cra_init(struct crypto_tfm *tfm)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++	struct mtk_alg_template *tmpl = container_of(tfm->__crt_alg,
++				struct mtk_alg_template, alg.skcipher.base);
++
++	bool fallback = mtk_skcipher_is_fallback(tfm, tmpl->flags);
++
++	if (fallback) {
++		ctx->fallback = crypto_alloc_skcipher(
++			crypto_tfm_alg_name(tfm), 0, CRYPTO_ALG_NEED_FALLBACK);
++		if (IS_ERR(ctx->fallback))
++			return PTR_ERR(ctx->fallback);
++	}
++
++	crypto_skcipher_set_reqsize(
++		__crypto_skcipher_cast(tfm),
++		sizeof(struct mtk_cipher_reqctx) +
++			(fallback ? crypto_skcipher_reqsize(ctx->fallback) :
++					  0));
++
++	//memset(ctx, 0, sizeof(*ctx));
++	ctx->mtk = tmpl->mtk;
++
++	ctx->sa_in = kzalloc(sizeof(struct saRecord_s), GFP_KERNEL);
++	if (!ctx->sa_in)
++		return -ENOMEM;
++
++	ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	ctx->sa_out = kzalloc(sizeof(struct saRecord_s), GFP_KERNEL);
++	if (!ctx->sa_out)
++		return -ENOMEM;
++
++	ctx->sa_base_out = dma_map_single(ctx->mtk->dev, ctx->sa_out,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	return 0;
++}
++
++static void mtk_skcipher_cra_exit(struct crypto_tfm *tfm)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_out,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++	kfree(ctx->sa_in);
++	kfree(ctx->sa_out);
++
++	crypto_free_skcipher(ctx->fallback);
++}
++
++static int mtk_skcipher_setkey(struct crypto_skcipher *ctfm, const u8 *key,
++				 unsigned int len)
++{
++	struct crypto_tfm *tfm = crypto_skcipher_tfm(ctfm);
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(tfm);
++	struct mtk_alg_template *tmpl = container_of(tfm->__crt_alg,
++				struct mtk_alg_template, alg.skcipher.base);
++	struct saRecord_s *saRecord = ctx->sa_out;
++	u32 flags = tmpl->flags;
++	u32 nonce = 0;
++	unsigned int keylen = len;
++	int sa_size = sizeof(struct saRecord_s);
++	int err = -EINVAL;
++
++	if (!key || !keylen)
++		return err;
++
++	ctx->keylen = keylen;
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++	if (flags & MTK_ALG_DES) {
++		ctx->blksize = DES_BLOCK_SIZE;
++		err = verify_skcipher_des_key(ctfm, key);
++	}
++	if (flags & MTK_ALG_3DES) {
++		ctx->blksize = DES3_EDE_BLOCK_SIZE;
++		err = verify_skcipher_des3_key(ctfm, key);
++	}
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AES)
++	if (IS_RFC3686(flags)) {
++		if (len < CTR_RFC3686_NONCE_SIZE)
++			return -EINVAL;
++
++		keylen = len - CTR_RFC3686_NONCE_SIZE;
++		memcpy(&nonce, key + keylen, CTR_RFC3686_NONCE_SIZE);
++	}
++
++	if (flags & MTK_ALG_AES) {
++		struct crypto_aes_ctx aes;
++		bool fallback = mtk_skcipher_is_fallback(tfm, flags);
++
++		if (fallback && !IS_RFC3686(flags)) {
++			err = crypto_skcipher_setkey(ctx->fallback, key,
++						     keylen);
++			if (err)
++				return err;
++		}
++
++		ctx->blksize = AES_BLOCK_SIZE;
++		err = aes_expandkey(&aes, key, keylen);
++	}
++#endif
++	if (err)
++		return err;
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in, sa_size,
++								DMA_TO_DEVICE);
++
++	dma_unmap_single(ctx->mtk->dev, ctx->sa_base_out, sa_size,
++								DMA_TO_DEVICE);
++
++	mtk_set_saRecord(saRecord, keylen, flags);
++
++	memcpy(saRecord->saKey, key, keylen);
++	ctx->saNonce = nonce;
++	saRecord->saNonce = nonce;
++	saRecord->saCmd0.bits.direction = 0;
++
++	memcpy(ctx->sa_in, saRecord, sa_size);
++	ctx->sa_in->saCmd0.bits.direction = 1;
++
++	ctx->sa_base_out = dma_map_single(ctx->mtk->dev, ctx->sa_out, sa_size,
++								DMA_TO_DEVICE);
++
++	ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in, sa_size,
++								DMA_TO_DEVICE);
++	return 0;
++}
++
++static int mtk_skcipher_crypt(struct skcipher_request *req, bool encrypt)
++{
++	struct mtk_cipher_reqctx *rctx = skcipher_request_ctx(req);
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
++	struct crypto_skcipher *skcipher = crypto_skcipher_reqtfm(req);
++	bool fallback = mtk_skcipher_is_fallback(req->base.tfm, rctx->flags);
++
++	if (!req->cryptlen)
++		return 0;
++
++	/*
++	 * ECB and CBC algorithms require message lengths to be
++	 * multiples of block size.
++	 */
++	if (IS_ECB(rctx->flags) || IS_CBC(rctx->flags))
++		if (!IS_ALIGNED(req->cryptlen,
++				crypto_skcipher_blocksize(skcipher)))
++			return -EINVAL;
++
++	if (fallback &&
++	    req->cryptlen <= (AES_KEYSIZE_128 ?
++				      CONFIG_CRYPTO_DEV_EIP93_AES_128_SW_MAX_LEN :
++				      CONFIG_CRYPTO_DEV_EIP93_GENERIC_SW_MAX_LEN)) {
++		skcipher_request_set_tfm(&rctx->fallback_req, ctx->fallback);
++		skcipher_request_set_callback(&rctx->fallback_req,
++					      req->base.flags,
++					      req->base.complete,
++					      req->base.data);
++		skcipher_request_set_crypt(&rctx->fallback_req, req->src,
++					   req->dst, req->cryptlen, req->iv);
++		return encrypt ? crypto_skcipher_encrypt(&rctx->fallback_req) :
++				 crypto_skcipher_decrypt(&rctx->fallback_req);
++	}
++
++	rctx->assoclen = 0;
++	rctx->textsize = req->cryptlen;
++	rctx->authsize = 0;
++	rctx->sg_src = req->src;
++	rctx->sg_dst = req->dst;
++	rctx->ivsize = crypto_skcipher_ivsize(skcipher);
++	rctx->flags |= MTK_DESC_SKCIPHER;
++	if (!IS_ECB(rctx->flags))
++		rctx->flags |= MTK_DESC_DMA_IV;
++
++	return mtk_skcipher_send_req(req);
++}
++
++static int mtk_skcipher_encrypt(struct skcipher_request *req)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
++	struct mtk_cipher_reqctx *rctx = skcipher_request_ctx(req);
++	struct mtk_alg_template *tmpl = container_of(req->base.tfm->__crt_alg,
++				struct mtk_alg_template, alg.skcipher.base);
++
++	rctx->flags = tmpl->flags;
++	rctx->flags |= MTK_ENCRYPT;
++	rctx->saRecord_base = ctx->sa_base_out;
++	rctx->blksize = ctx->blksize;
++	rctx->mtk = ctx->mtk;
++	rctx->saNonce = ctx->saNonce;
++
++	return mtk_skcipher_crypt(req, true);
++}
++
++static int mtk_skcipher_decrypt(struct skcipher_request *req)
++{
++	struct mtk_crypto_ctx *ctx = crypto_tfm_ctx(req->base.tfm);
++	struct mtk_cipher_reqctx *rctx = skcipher_request_ctx(req);
++	struct mtk_alg_template *tmpl = container_of(req->base.tfm->__crt_alg,
++				struct mtk_alg_template, alg.skcipher.base);
++
++	rctx->flags = tmpl->flags;
++	rctx->flags |= MTK_DECRYPT;
++	rctx->saRecord_base = ctx->sa_base_in;
++	rctx->blksize = ctx->blksize;
++	rctx->mtk = ctx->mtk;
++	rctx->saNonce = ctx->saNonce;
++
++	return mtk_skcipher_crypt(req, false);
++}
++
++/* Available algorithms in this module */
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AES)
++struct mtk_alg_template mtk_alg_ecb_aes = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_ECB | MTK_ALG_AES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = AES_MIN_KEY_SIZE,
++		.max_keysize = AES_MAX_KEY_SIZE,
++		.ivsize	= 0,
++		.base = {
++			.cra_name = "ecb(aes)",
++			.cra_driver_name = "ecb(aes-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_NEED_FALLBACK |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = AES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0xf,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_cbc_aes = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_CBC | MTK_ALG_AES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = AES_MIN_KEY_SIZE,
++		.max_keysize = AES_MAX_KEY_SIZE,
++		.ivsize	= AES_BLOCK_SIZE,
++		.base = {
++			.cra_name = "cbc(aes)",
++			.cra_driver_name = "cbc(aes-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_NEED_FALLBACK |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = AES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0xf,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_ctr_aes = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_CTR | MTK_ALG_AES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = AES_MIN_KEY_SIZE,
++		.max_keysize = AES_MAX_KEY_SIZE,
++		.ivsize	= AES_BLOCK_SIZE,
++		.base = {
++			.cra_name = "ctr(aes)",
++			.cra_driver_name = "ctr(aes-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++				     CRYPTO_ALG_NEED_FALLBACK |
++				     CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = 1,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0xf,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_rfc3686_aes = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_CTR | MTK_MODE_RFC3686 | MTK_ALG_AES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = AES_MIN_KEY_SIZE + CTR_RFC3686_NONCE_SIZE,
++		.max_keysize = AES_MAX_KEY_SIZE + CTR_RFC3686_NONCE_SIZE,
++		.ivsize	= CTR_RFC3686_IV_SIZE,
++		.base = {
++			.cra_name = "rfc3686(ctr(aes))",
++			.cra_driver_name = "rfc3686(ctr(aes-eip93))",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_NEED_FALLBACK |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = 1,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0xf,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++struct mtk_alg_template mtk_alg_ecb_des = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_ECB | MTK_ALG_DES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = DES_KEY_SIZE,
++		.max_keysize = DES_KEY_SIZE,
++		.ivsize	= 0,
++		.base = {
++			.cra_name = "ecb(des)",
++			.cra_driver_name = "ebc(des-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_cbc_des = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_CBC | MTK_ALG_DES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = DES_KEY_SIZE,
++		.max_keysize = DES_KEY_SIZE,
++		.ivsize	= DES_BLOCK_SIZE,
++		.base = {
++			.cra_name = "cbc(des)",
++			.cra_driver_name = "cbc(des-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_ecb_des3_ede = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_ECB | MTK_ALG_3DES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = DES3_EDE_KEY_SIZE,
++		.max_keysize = DES3_EDE_KEY_SIZE,
++		.ivsize	= 0,
++		.base = {
++			.cra_name = "ecb(des3_ede)",
++			.cra_driver_name = "ecb(des3_ede-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES3_EDE_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_cbc_des3_ede = {
++	.type = MTK_ALG_TYPE_SKCIPHER,
++	.flags = MTK_MODE_CBC | MTK_ALG_3DES,
++	.alg.skcipher = {
++		.setkey = mtk_skcipher_setkey,
++		.encrypt = mtk_skcipher_encrypt,
++		.decrypt = mtk_skcipher_decrypt,
++		.min_keysize = DES3_EDE_KEY_SIZE,
++		.max_keysize = DES3_EDE_KEY_SIZE,
++		.ivsize	= DES3_EDE_BLOCK_SIZE,
++		.base = {
++			.cra_name = "cbc(des3_ede)",
++			.cra_driver_name = "cbc(des3_ede-eip93)",
++			.cra_priority = MTK_CRA_PRIORITY,
++			.cra_flags = CRYPTO_ALG_ASYNC |
++					CRYPTO_ALG_KERN_DRIVER_ONLY,
++			.cra_blocksize = DES3_EDE_BLOCK_SIZE,
++			.cra_ctxsize = sizeof(struct mtk_crypto_ctx),
++			.cra_alignmask = 0,
++			.cra_init = mtk_skcipher_cra_init,
++			.cra_exit = mtk_skcipher_cra_exit,
++			.cra_module = THIS_MODULE,
++		},
++	},
++};
++#endif
+diff --git a/drivers/crypto/mtk-eip93/eip93-cipher.h b/drivers/crypto/mtk-eip93/eip93-cipher.h
+new file mode 100644
+index 0000000..b47e72d
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-cipher.h
+@@ -0,0 +1,56 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#ifndef _EIP93_CIPHER_H_
++#define _EIP93_CIPHER_H_
++
++#include "eip93-main.h"
++
++struct mtk_crypto_ctx {
++	struct mtk_device		*mtk;
++	struct saRecord_s		*sa_in;
++	dma_addr_t			sa_base_in;
++	struct saRecord_s		*sa_out;
++	dma_addr_t			sa_base_out;
++	uint32_t			saNonce;
++	int				blksize;
++	/* AEAD specific */
++	unsigned int			authsize;
++	bool				in_first;
++	bool				out_first;
++	struct crypto_shash		*shash;
++	unsigned int keylen;
++	struct crypto_skcipher *fallback;
++};
++
++struct mtk_cipher_reqctx {
++	struct mtk_device		*mtk;
++	uintptr_t			async;
++	unsigned long			flags;
++	unsigned int			blksize;
++	unsigned int			ivsize;
++	unsigned int			textsize;
++	unsigned int			assoclen;
++	unsigned int			authsize;
++	dma_addr_t			saRecord_base;
++	uint32_t			saNonce;
++	struct saState_s		*saState;
++	dma_addr_t			saState_base;
++	uint32_t			saState_idx;
++	struct eip93_descriptor_s	*cdesc;
++	struct scatterlist		*sg_src;
++	struct scatterlist		*sg_dst;
++	int				src_nents;
++	int				dst_nents;
++	struct saState_s		*saState_ctr;
++	dma_addr_t			saState_base_ctr;
++	uint32_t			saState_ctr_idx;
++	struct skcipher_request fallback_req; // keep at the end
++};
++
++void mtk_skcipher_handle_result(struct skcipher_request *req, int err);
++
++#endif /* _EIP93_CIPHER_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-common.c b/drivers/crypto/mtk-eip93/eip93-common.c
+new file mode 100644
+index 0000000..4dcfafc
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-common.c
+@@ -0,0 +1,752 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <crypto/aes.h>
++#include <crypto/ctr.h>
++#include <crypto/hmac.h>
++#include <crypto/sha1.h>
++#include <crypto/sha2.h>
++#include <linux/delay.h>
++#include <linux/dma-mapping.h>
++#include <linux/scatterlist.h>
++
++#include "eip93-cipher.h"
++#include "eip93-common.h"
++#include "eip93-main.h"
++#include "eip93-regs.h"
++
++int mtk_ring_free(struct mtk_desc_ring *ring)
++{
++	if ((ring->read <= ring->write))
++		return (MTK_RING_SIZE -
++			((ring->write - ring->read) / ring->offset));
++	else
++		return (ring->read - ring->write) / ring->offset;
++}
++
++static void *mtk_ring_next_wptr(struct mtk_desc_ring *ring)
++{
++	void *ptr = ring->write;
++
++	if ((ring->write == ring->read - ring->offset) ||
++		(ring->read == ring->base && ring->write == ring->base_end))
++		return ERR_PTR(-ENOMEM);
++
++	if (ring->write == ring->base_end)
++		ring->write = ring->base;
++	else
++		ring->write += ring->offset;
++
++	return ptr;
++}
++
++static void *mtk_ring_next_rptr(struct mtk_desc_ring *ring)
++{
++	void *ptr = ring->read;
++
++	if (ring->write == ring->read)
++		return ERR_PTR(-ENOENT);
++
++	if (ring->read == ring->base_end)
++		ring->read = ring->base;
++	else
++		ring->read += ring->offset;
++
++	return ptr;
++}
++
++int mtk_put_descriptor(struct mtk_device *mtk, struct eip93_descriptor_s *desc)
++{
++	u32 *ptr;
++	const u32 *cdesc = (u32)desc;
++	unsigned long irqflags;
++
++	spin_lock_irqsave(&mtk->ring->write_lock, irqflags);
++
++	ptr = mtk_ring_next_wptr(&mtk->ring->rdr);
++
++	if (IS_ERR(ptr)) {
++		spin_unlock_irqrestore(&mtk->ring->write_lock, irqflags);
++		return -ENOENT;
++	}
++
++	ptr[0] = 0;
++	ptr[7] = 0;
++
++	ptr = mtk_ring_next_wptr(&mtk->ring->cdr);
++
++	if (IS_ERR(ptr)) {
++		spin_unlock_irqrestore(&mtk->ring->write_lock, irqflags);
++		return -ENOENT;
++	}
++
++	ptr[0] = cdesc[0];
++	ptr[1] = cdesc[1];
++	ptr[2] = cdesc[2];
++	ptr[3] = cdesc[3];
++	ptr[4] = cdesc[4];
++	ptr[5] = cdesc[5];
++	ptr[6] = cdesc[6];
++	ptr[7] = cdesc[7];
++
++	spin_unlock_irqrestore(&mtk->ring->write_lock, irqflags);
++
++	return 0;
++}
++
++void *mtk_get_descriptor(struct mtk_device *mtk)
++{
++	u32 *ptr;
++	unsigned long irqflags;
++
++	spin_lock_irqsave(&mtk->ring->read_lock, irqflags);
++
++	ptr = mtk_ring_next_rptr(&mtk->ring->cdr);
++
++	if (IS_ERR(ptr)) {
++		spin_unlock_irqrestore(&mtk->ring->read_lock, irqflags);
++		return ERR_PTR(-ENOENT);
++	}
++
++	ptr[0] = 0;
++	ptr[7] = 0;
++
++	ptr = mtk_ring_next_rptr(&mtk->ring->rdr);
++	if (IS_ERR(ptr)) {
++		spin_unlock_irqrestore(&mtk->ring->read_lock, irqflags);
++		return ERR_PTR(-ENOENT);
++	}
++
++	spin_unlock_irqrestore(&mtk->ring->read_lock, irqflags);
++
++	return ptr;
++}
++
++int mtk_get_free_saState(struct mtk_device *mtk)
++{
++	struct mtk_state_pool *saState_pool;
++	int i;
++
++	for (i = 0; i < MTK_RING_SIZE; i++) {
++		saState_pool = &mtk->ring->saState_pool[i];
++		if (saState_pool->in_use == false) {
++			saState_pool->in_use = true;
++			return i;
++		}
++	}
++
++	return -ENOENT;
++}
++
++static void mtk_free_sg_copy(const int len, struct scatterlist **sg)
++{
++	if (!*sg || !len)
++		return;
++
++	free_pages((unsigned long)sg_virt(*sg), get_order(len));
++	kfree(*sg);
++	*sg = NULL;
++}
++
++static int mtk_make_sg_copy(struct scatterlist *src,
++			struct scatterlist **dst,
++			const uint32_t len, const bool copy)
++{
++	void *pages;
++
++	*dst = kmalloc(sizeof(**dst), GFP_KERNEL);
++	if (!*dst)
++		return -ENOMEM;
++
++
++	pages = (void *)__get_free_pages(GFP_KERNEL | GFP_DMA,
++					get_order(len));
++
++	if (!pages) {
++		kfree(*dst);
++		*dst = NULL;
++		return -ENOMEM;
++	}
++
++	sg_init_table(*dst, 1);
++	sg_set_buf(*dst, pages, len);
++
++	/* copy only as requested */
++	if (copy)
++		sg_copy_to_buffer(src, sg_nents(src), pages, len);
++
++	return 0;
++}
++
++static bool mtk_is_sg_aligned(struct scatterlist *sg, u32 len,
++						const int blksize)
++{
++	int nents;
++
++	for (nents = 0; sg; sg = sg_next(sg), ++nents) {
++		if (!IS_ALIGNED(sg->offset, 4))
++			return false;
++
++		if (len <= sg->length) {
++			if (!IS_ALIGNED(len, blksize))
++				return false;
++
++			return true;
++		}
++
++		if (!IS_ALIGNED(sg->length, blksize))
++			return false;
++
++		len -= sg->length;
++	}
++	return false;
++}
++
++int check_valid_request(struct mtk_cipher_reqctx *rctx)
++{
++	struct scatterlist *src = rctx->sg_src;
++	struct scatterlist *dst = rctx->sg_dst;
++	uint32_t src_nents, dst_nents;
++	u32 textsize = rctx->textsize;
++	u32 authsize = rctx->authsize;
++	u32 blksize = rctx->blksize;
++	u32 totlen_src = rctx->assoclen + rctx->textsize;
++	u32 totlen_dst = rctx->assoclen + rctx->textsize;
++	u32 copy_len;
++	bool src_align, dst_align;
++	int err = -EINVAL;
++
++	if (!IS_CTR(rctx->flags)) {
++		if (!IS_ALIGNED(textsize, blksize))
++			return err;
++	}
++
++	if (authsize) {
++		if (IS_ENCRYPT(rctx->flags))
++			totlen_dst += authsize;
++		else
++			totlen_src += authsize;
++	}
++
++	src_nents = sg_nents_for_len(src, totlen_src);
++	dst_nents = sg_nents_for_len(dst, totlen_dst);
++
++	if (src == dst) {
++		src_nents = max(src_nents, dst_nents);
++		dst_nents = src_nents;
++		if (unlikely((totlen_src || totlen_dst) && (src_nents <= 0)))
++			return err;
++
++	} else {
++		if (unlikely(totlen_src && (src_nents <= 0)))
++			return err;
++
++		if (unlikely(totlen_dst && (dst_nents <= 0)))
++			return err;
++	}
++
++	if (authsize) {
++		if (dst_nents == 1 && src_nents == 1) {
++			src_align = mtk_is_sg_aligned(src, totlen_src, blksize);
++			if (src ==  dst)
++				dst_align = src_align;
++			else
++				dst_align = mtk_is_sg_aligned(dst,
++						totlen_dst, blksize);
++		} else {
++			src_align = false;
++			dst_align = false;
++		}
++	} else {
++		src_align = mtk_is_sg_aligned(src, totlen_src, blksize);
++		if (src == dst)
++			dst_align = src_align;
++		else
++			dst_align = mtk_is_sg_aligned(dst, totlen_dst, blksize);
++	}
++
++	copy_len = max(totlen_src, totlen_dst);
++	if (!src_align) {
++		err = mtk_make_sg_copy(src, &rctx->sg_src, copy_len, true);
++		if (err)
++			return err;
++	}
++
++	if (!dst_align) {
++		err = mtk_make_sg_copy(dst, &rctx->sg_dst, copy_len, false);
++		if (err)
++			return err;
++	}
++
++	rctx->src_nents = sg_nents_for_len(rctx->sg_src, totlen_src);
++	rctx->dst_nents = sg_nents_for_len(rctx->sg_dst, totlen_dst);
++
++	return 0;
++}
++/*
++ * Set saRecord function:
++ * Even saRecord is set to "0", keep " = 0" for readability.
++ */
++void mtk_set_saRecord(struct saRecord_s *saRecord, const unsigned int keylen,
++				const u32 flags)
++{
++	saRecord->saCmd0.bits.ivSource = 2;
++	if (IS_ECB(flags))
++		saRecord->saCmd0.bits.saveIv = 0;
++	else
++		saRecord->saCmd0.bits.saveIv = 1;
++
++	saRecord->saCmd0.bits.opGroup = 0;
++	saRecord->saCmd0.bits.opCode = 0;
++
++	switch ((flags & MTK_ALG_MASK)) {
++	case MTK_ALG_AES:
++		saRecord->saCmd0.bits.cipher = 3;
++		saRecord->saCmd1.bits.aesKeyLen = keylen >> 3;
++		break;
++	case MTK_ALG_3DES:
++		saRecord->saCmd0.bits.cipher = 1;
++		break;
++	case MTK_ALG_DES:
++		saRecord->saCmd0.bits.cipher = 0;
++		break;
++	default:
++		saRecord->saCmd0.bits.cipher = 15;
++	}
++
++	switch ((flags & MTK_HASH_MASK)) {
++	case MTK_HASH_SHA256:
++		saRecord->saCmd0.bits.hash = 3;
++		break;
++	case MTK_HASH_SHA224:
++		saRecord->saCmd0.bits.hash = 2;
++		break;
++	case MTK_HASH_SHA1:
++		saRecord->saCmd0.bits.hash = 1;
++		break;
++	case MTK_HASH_MD5:
++		saRecord->saCmd0.bits.hash = 0;
++		break;
++	default:
++		saRecord->saCmd0.bits.hash = 15;
++	}
++
++	saRecord->saCmd0.bits.hdrProc = 0;
++	saRecord->saCmd0.bits.padType = 3;
++	saRecord->saCmd0.bits.extPad = 0;
++	saRecord->saCmd0.bits.scPad = 0;
++
++	switch ((flags & MTK_MODE_MASK)) {
++	case MTK_MODE_CBC:
++		saRecord->saCmd1.bits.cipherMode = 1;
++		break;
++	case MTK_MODE_CTR:
++		saRecord->saCmd1.bits.cipherMode = 2;
++		break;
++	case MTK_MODE_ECB:
++		saRecord->saCmd1.bits.cipherMode = 0;
++		break;
++	}
++
++	saRecord->saCmd1.bits.byteOffset = 0;
++	saRecord->saCmd1.bits.hashCryptOffset = 0;
++	saRecord->saCmd0.bits.digestLength = 0;
++	saRecord->saCmd1.bits.copyPayload = 0;
++
++	if (IS_HMAC(flags)) {
++		saRecord->saCmd1.bits.hmac = 1;
++		saRecord->saCmd1.bits.copyDigest = 1;
++		saRecord->saCmd1.bits.copyHeader = 1;
++	} else {
++		saRecord->saCmd1.bits.hmac = 0;
++		saRecord->saCmd1.bits.copyDigest = 0;
++		saRecord->saCmd1.bits.copyHeader = 0;
++	}
++
++	saRecord->saCmd1.bits.seqNumCheck = 0;
++	saRecord->saSpi = 0x0;
++	saRecord->saSeqNumMask[0] = 0xFFFFFFFF;
++	saRecord->saSeqNumMask[1] = 0x0;
++}
++
++/*
++ * Poor mans Scatter/gather function:
++ * Create a Descriptor for every segment to avoid copying buffers.
++ * For performance better to wait for hardware to perform multiple DMA
++ *
++ */
++static int mtk_scatter_combine(struct mtk_cipher_reqctx *rctx,
++			u32 datalen, u32 split)
++{
++	struct eip93_descriptor_s *cdesc = rctx->cdesc;
++	struct scatterlist *sgsrc = rctx->sg_src;
++	struct scatterlist *sgdst = rctx->sg_dst;
++	unsigned int remainin = sg_dma_len(sgsrc);
++	unsigned int remainout = sg_dma_len(sgdst);
++	dma_addr_t saddr = sg_dma_address(sgsrc);
++	dma_addr_t daddr = sg_dma_address(sgdst);
++	dma_addr_t stateAddr;
++	u32 len, n;
++	bool nextin = false;
++	bool nextout = false;
++	int offsetin = 0, offsetout = 0;
++	int err;
++
++	if (split < datalen) {
++		stateAddr = rctx->saState_base_ctr;
++		n = split;
++	} else {
++		stateAddr = rctx->saState_base;
++		n = datalen;
++	}
++
++	do {
++		if (nextin) {
++			sgsrc = sg_next(sgsrc);
++			remainin = sg_dma_len(sgsrc);
++			if (remainin == 0)
++				continue;
++
++			saddr = sg_dma_address(sgsrc);
++			offsetin = 0;
++			nextin = false;
++		}
++
++		if (nextout) {
++			sgdst = sg_next(sgdst);
++			remainout = sg_dma_len(sgdst);
++			if (remainout == 0)
++				continue;
++
++			daddr = sg_dma_address(sgdst);
++			offsetout = 0;
++			nextout = false;
++		}
++		cdesc->srcAddr = saddr + offsetin;
++		cdesc->dstAddr = daddr + offsetout;
++		cdesc->stateAddr = stateAddr;
++
++		if (remainin == remainout) {
++			len = remainin;
++			if (len > n) {
++				len = n;
++				remainin -= n;
++				remainout -= n;
++				offsetin += n;
++				offsetout += n;
++			} else {
++				nextin = true;
++				nextout = true;
++			}
++		} else if (remainin < remainout) {
++			len = remainin;
++			if (len > n) {
++				len = n;
++				remainin -= n;
++				remainout -= n;
++				offsetin += n;
++				offsetout += n;
++			} else {
++				offsetout += len;
++				remainout -= len;
++				nextin = true;
++			}
++		} else {
++			len = remainout;
++			if (len > n) {
++				len = n;
++				remainin -= n;
++				remainout -= n;
++				offsetin += n;
++				offsetout += n;
++			} else {
++				offsetin += len;
++				remainin -= len;
++				nextout = true;
++			}
++		}
++		n -= len;
++
++		cdesc->peLength.bits.peReady = 0;
++		cdesc->peLength.bits.byPass = 0;
++		cdesc->peLength.bits.length = len;
++		cdesc->peLength.bits.hostReady = 1;
++
++		if (n == 0) {
++			n = datalen - split;
++			split = datalen;
++			stateAddr = rctx->saState_base;
++		}
++
++		if (n == 0)
++			cdesc->userId |= MTK_DESC_LAST;
++
++		/* Loop - Delay - No need to rollback
++		 * Maybe refine by slowing down at MTK_RING_BUSY
++		 */
++again:
++		err = mtk_put_descriptor(rctx->mtk, cdesc);
++		if (err) {
++			udelay(500);
++			goto again;
++		}
++		/* Writing new descriptor count starts DMA action */
++		writel(1, rctx->mtk->base + EIP93_REG_PE_CD_COUNT);
++	} while (n);
++
++	return -EINPROGRESS;
++}
++
++int mtk_send_req(struct mtk_cipher_reqctx *rctx, const u8 *reqiv)
++{
++	struct mtk_device *mtk = rctx->mtk;
++	struct scatterlist *src = rctx->sg_src;
++	struct scatterlist *dst = rctx->sg_dst;
++	struct saState_s *saState;
++	struct mtk_state_pool *saState_pool;
++	struct eip93_descriptor_s cdesc;
++	u32 flags = rctx->flags;
++	int idx;
++	u32 datalen = rctx->assoclen + rctx->textsize;
++	u32 split = datalen;
++	u32 start, end, ctr, blocks;
++	u32 iv[AES_BLOCK_SIZE / sizeof(u32)];
++
++	rctx->saState_ctr = NULL;
++	rctx->saState = NULL;
++
++	if (IS_ECB(flags)) {
++		rctx->saState_base = 0;
++		goto skip_iv;
++	}
++
++	memcpy(iv, reqiv, rctx->ivsize);
++
++	if (!IS_ALIGNED((u32)reqiv, rctx->ivsize) || IS_RFC3686(flags)) {
++		rctx->flags &= ~MTK_DESC_DMA_IV;
++		flags = rctx->flags;
++	}
++
++	if (IS_DMA_IV(flags)) {
++		rctx->saState = (void *)reqiv;
++	} else  {
++		idx = mtk_get_free_saState(mtk);
++		if (idx < 0)
++			return -ENOMEM;
++
++		saState_pool = &mtk->ring->saState_pool[idx];
++		rctx->saState_idx = idx;
++		rctx->saState = saState_pool->base;
++		rctx->saState_base = saState_pool->base_dma;
++		memcpy(rctx->saState->stateIv, iv, rctx->ivsize);
++	}
++
++	saState = rctx->saState;
++
++	if (IS_RFC3686(flags)) {
++		saState->stateIv[0] = rctx->saNonce;
++		saState->stateIv[1] = iv[0];
++		saState->stateIv[2] = iv[1];
++		saState->stateIv[3] = htonl(1);
++	} else if (!IS_HMAC(flags) && IS_CTR(flags)) {
++		/* Compute data length. */
++		blocks = DIV_ROUND_UP(rctx->textsize, AES_BLOCK_SIZE);
++		ctr = ntohl(iv[3]);
++		/* Check 32bit counter overflow. */
++		start = ctr;
++		end = start + blocks - 1;
++		if (end < start) {
++			split = AES_BLOCK_SIZE * -start;
++			/*
++			 * Increment the counter manually to cope with
++			 * the hardware counter overflow.
++			 */
++			iv[3] = 0xffffffff;
++			crypto_inc((u8 *)iv, AES_BLOCK_SIZE);
++			idx = mtk_get_free_saState(mtk);
++			if (idx < 0)
++				goto free_state;
++			saState_pool = &mtk->ring->saState_pool[idx];
++			rctx->saState_ctr_idx = idx;
++			rctx->saState_ctr = saState_pool->base;
++			rctx->saState_base_ctr = saState_pool->base_dma;
++
++			memcpy(rctx->saState_ctr->stateIv, reqiv, rctx->ivsize);
++			memcpy(saState->stateIv, iv, rctx->ivsize);
++		}
++	}
++
++	if (IS_DMA_IV(flags)) {
++		rctx->saState_base = dma_map_single(mtk->dev, (void *)reqiv,
++						rctx->ivsize, DMA_TO_DEVICE);
++		if (dma_mapping_error(mtk->dev, rctx->saState_base))
++			goto free_state;
++	}
++skip_iv:
++	cdesc.peCrtlStat.bits.hostReady = 1;
++	cdesc.peCrtlStat.bits.prngMode = 0;
++	cdesc.peCrtlStat.bits.hashFinal = 0;
++	cdesc.peCrtlStat.bits.padCrtlStat = 0;
++	cdesc.peCrtlStat.bits.peReady = 0;
++	cdesc.saAddr = rctx->saRecord_base;
++	cdesc.arc4Addr = (uintptr_t)rctx->async;
++	cdesc.userId = flags;
++	rctx->cdesc = &cdesc;
++
++	/* map DMA_BIDIRECTIONAL to invalidate cache on destination
++	 * implies __dma_cache_wback_inv
++	 */
++	dma_map_sg(mtk->dev, dst, rctx->dst_nents, DMA_BIDIRECTIONAL);
++	if (src != dst)
++		dma_map_sg(mtk->dev, src, rctx->src_nents, DMA_TO_DEVICE);
++
++	return mtk_scatter_combine(rctx, datalen, split);
++
++free_state:
++	if (rctx->saState) {
++		saState_pool = &mtk->ring->saState_pool[rctx->saState_idx];
++		saState_pool->in_use = false;
++	}
++
++	if (rctx->saState_ctr) {
++		saState_pool = &mtk->ring->saState_pool[rctx->saState_ctr_idx];
++		saState_pool->in_use = false;
++	}
++
++	return -ENOMEM;
++}
++
++void mtk_unmap_dma(struct mtk_cipher_reqctx *rctx, struct scatterlist *reqsrc,
++		struct scatterlist *reqdst)
++{
++	struct mtk_device *mtk = rctx->mtk;
++	u32 len = rctx->assoclen + rctx->textsize;
++	u32 authsize = rctx->authsize;
++	u32 flags = rctx->flags;
++	u32 *otag;
++	int i;
++
++	if (rctx->sg_src == rctx->sg_dst) {
++		dma_unmap_sg(mtk->dev, rctx->sg_dst, rctx->dst_nents,
++							DMA_BIDIRECTIONAL);
++		goto process_tag;
++	}
++
++	dma_unmap_sg(mtk->dev, rctx->sg_src, rctx->src_nents,
++							DMA_TO_DEVICE);
++
++	if (rctx->sg_src != reqsrc)
++		mtk_free_sg_copy(len +  rctx->authsize, &rctx->sg_src);
++
++	dma_unmap_sg(mtk->dev, rctx->sg_dst, rctx->dst_nents,
++							DMA_BIDIRECTIONAL);
++
++	/* SHA tags need conversion from net-to-host */
++process_tag:
++	if (IS_DECRYPT(flags))
++		authsize = 0;
++
++	if (authsize) {
++		if (!IS_HASH_MD5(flags)) {
++			otag = sg_virt(rctx->sg_dst) + len;
++			for (i = 0; i < (authsize / 4); i++)
++				otag[i] = ntohl(otag[i]);
++		}
++	}
++
++	if (rctx->sg_dst != reqdst) {
++		sg_copy_from_buffer(reqdst, sg_nents(reqdst),
++				sg_virt(rctx->sg_dst), len + authsize);
++		mtk_free_sg_copy(len + rctx->authsize, &rctx->sg_dst);
++	}
++}
++
++void mtk_handle_result(struct mtk_cipher_reqctx *rctx, u8 *reqiv)
++{
++	struct mtk_device *mtk = rctx->mtk;
++	struct mtk_state_pool *saState_pool;
++
++	if (IS_DMA_IV(rctx->flags))
++		dma_unmap_single(mtk->dev, rctx->saState_base, rctx->ivsize,
++						DMA_TO_DEVICE);
++
++	if (!IS_ECB(rctx->flags))
++		memcpy(reqiv, rctx->saState->stateIv, rctx->ivsize);
++
++	if ((rctx->saState) && !(IS_DMA_IV(rctx->flags))) {
++		saState_pool = &mtk->ring->saState_pool[rctx->saState_idx];
++		saState_pool->in_use = false;
++	}
++
++	if (rctx->saState_ctr) {
++		saState_pool = &mtk->ring->saState_pool[rctx->saState_ctr_idx];
++		saState_pool->in_use = false;
++	}
++}
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HMAC)
++/* basically this is set hmac - key */
++int mtk_authenc_setkey(struct crypto_shash *cshash, struct saRecord_s *sa,
++			const u8 *authkey, unsigned int authkeylen)
++{
++	int bs = crypto_shash_blocksize(cshash);
++	int ds = crypto_shash_digestsize(cshash);
++	int ss = crypto_shash_statesize(cshash);
++	u8 *ipad, *opad;
++	unsigned int i, err;
++
++	SHASH_DESC_ON_STACK(shash, cshash);
++
++	shash->tfm = cshash;
++
++	/* auth key
++	 *
++	 * EIP93 can only authenticate with hash of the key
++	 * do software shash until EIP93 hash function complete.
++	 */
++	ipad = kcalloc(2, SHA256_BLOCK_SIZE + ss, GFP_KERNEL);
++	if (!ipad)
++		return -ENOMEM;
++
++	opad = ipad + SHA256_BLOCK_SIZE + ss;
++
++	if (authkeylen > bs) {
++		err = crypto_shash_digest(shash, authkey,
++					authkeylen, ipad);
++		if (err)
++			return err;
++
++		authkeylen = ds;
++	} else
++		memcpy(ipad, authkey, authkeylen);
++
++	memset(ipad + authkeylen, 0, bs - authkeylen);
++	memcpy(opad, ipad, bs);
++
++	for (i = 0; i < bs; i++) {
++		ipad[i] ^= HMAC_IPAD_VALUE;
++		opad[i] ^= HMAC_OPAD_VALUE;
++	}
++
++	err = crypto_shash_init(shash) ?:
++		crypto_shash_update(shash, ipad, bs) ?:
++		crypto_shash_export(shash, ipad) ?:
++		crypto_shash_init(shash) ?:
++		crypto_shash_update(shash, opad, bs) ?:
++		crypto_shash_export(shash, opad);
++
++	if (err)
++		return err;
++
++	/* add auth key */
++	memcpy(&sa->saIDigest, ipad, SHA256_DIGEST_SIZE);
++	memcpy(&sa->saODigest, opad, SHA256_DIGEST_SIZE);
++
++	kfree(ipad);
++	return 0;
++}
++#endif
+diff --git a/drivers/crypto/mtk-eip93/eip93-common.h b/drivers/crypto/mtk-eip93/eip93-common.h
+new file mode 100644
+index 0000000..d8f571a
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-common.h
+@@ -0,0 +1,40 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#ifndef _EIP93_COMMON_H_
++#define _EIP93_COMMON_H_
++
++#include "eip93-main.h"
++#include "eip93-cipher.h"
++
++int mtk_ring_free(struct mtk_desc_ring *ring);
++
++int mtk_put_descriptor(struct mtk_device *mtk,
++					struct eip93_descriptor_s *desc);
++
++void *mtk_get_descriptor(struct mtk_device *mtk);
++
++int mtk_get_free_saState(struct mtk_device *mtk);
++
++void mtk_set_saRecord(struct saRecord_s *saRecord, const unsigned int keylen,
++			const u32 flags);
++
++int mtk_send_req(struct mtk_cipher_reqctx *rctx, const u8 *reqiv);
++
++void mtk_handle_result(struct mtk_cipher_reqctx *rctx, u8 *reqiv);
++
++int check_valid_request(struct mtk_cipher_reqctx *rctx);
++
++void mtk_unmap_dma(struct mtk_cipher_reqctx *rctx, struct scatterlist *reqsrc,
++			struct scatterlist *reqdst);
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HMAC)
++int mtk_authenc_setkey(struct crypto_shash *cshash, struct saRecord_s *sa,
++			const u8 *authkey, unsigned int authkeylen);
++#endif
++
++#endif /* _EIP93_COMMON_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-des.h b/drivers/crypto/mtk-eip93/eip93-des.h
+new file mode 100644
+index 0000000..08ed10c
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-des.h
+@@ -0,0 +1,15 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#ifndef _EIP93_DES_H_
++#define _EIP93_DES_H_
++
++extern struct mtk_alg_template mtk_alg_ecb_des;
++extern struct mtk_alg_template mtk_alg_cbc_des;
++extern struct mtk_alg_template mtk_alg_ecb_des3_ede;
++extern struct mtk_alg_template mtk_alg_cbc_des3_ede;
++
++#endif /* _EIP93_DES_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-hash.c b/drivers/crypto/mtk-eip93/eip93-hash.c
+new file mode 100644
+index 0000000..f6d85bc
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-hash.c
+@@ -0,0 +1,659 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2021
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <linux/device.h>
++#include <linux/dmapool.h>
++#include <linux/interrupt.h>
++#include <crypto/internal/hash.h>
++
++#include "eip93-main.h"
++#include "eip93-regs.h"
++#include "eip93-common.h"
++#include "eip93-hash.h"
++
++int mtk_ahash_handle_result(struct mtk_device *mtk,
++				  struct crypto_async_request *async,
++				  int err)
++{
++	struct ahash_request *areq = ahash_request_cast(async);
++	struct crypto_ahash *ahash = crypto_ahash_reqtfm(areq);
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	int cache_len;
++
++
++	if (rctx->nents) {
++		dma_unmap_sg(mtk->dev, areq->src, rctx->nents, DMA_TO_DEVICE);
++		rctx->nents = 0;
++	}
++
++	if (rctx->result_dma) {
++		dma_unmap_sg(mtk->dev, areq->src, rctx->nents, DMA_FROM_DEVICE);
++		rctx->result_dma = 0;
++	}
++
++
++	// done by hardware
++//	if (sreq->finish) {
++//		memcpy(areq->result, rctx-sreq->state,
++//				crypto_ahash_digestsize(ahash));
++//	}
++
++	cache_len = rctx->len - rctx->processed;
++	if (cache_len)
++		memcpy(rctx->cache, rctx->cache_next, cache_len);
++
++	if (complete)
++		async->complete(async, err);
++
++	return 0;
++}
++
++int mtk_ahash_send_req(struct mtk_device *mtk,
++			struct crypto_async_request *async)
++{
++	struct ahash_request *areq = ahash_request_cast(async);
++	struct crypto_ahash *ahash = crypto_ahash_reqtfm(areq);
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	struct mtk_ahash_ctx *ctx = crypto_ahash_ctx(crypto_ahash_reqtfm(areq));
++	struct eip93_descriptor *cdesc, *first_cdesc = NULL;
++	struct scatterlist *sg;
++	bool last = (rctx->flags & MTK_DESC_LAST);
++	bool finish = (rctx->flags & MTK_DESC_FINISH);
++	int i, queued, len, cache_len, extra, n_cdesc = 0, ret = 0;
++
++	queued = len = rctx->len - rctx->processed;
++	if (queued <= SHA256_BLOCK_SIZE)
++		cache_len = queued;
++	else
++		cache_len = queued - areq->nbytes;
++
++	if (!finish && !last) {
++		/* If this is not the last request and the queued data does not
++		 * fit into full cache blocks, cache it for the next send call.
++		 */
++		extra = queued & (SHA256_BLOCK_SIZE - 1);
++
++		/* If this is not the last request and the queued data
++		 * is a multiple of a block, cache the last one for now.
++		 */
++		if (!extra)
++			extra = SHA256_BLOCK_SIZE;
++
++		sg_pcopy_to_buffer(areq->src, sg_nents(areq->src),
++				   req->cache_next, extra,
++				   areq->nbytes - extra);
++		queued -= extra;
++		len -= extra;
++
++		if (!queued) {
++			return 0;
++		}
++	}
++
++	/* Add a command descriptor for the cached data, if any */
++	if (cache_len) {
++		rctx->cache_dma = dma_map_single(mtk->dev, rctx->cache,
++						cache_len, DMA_TO_DEVICE);
++		if (dma_mapping_error(mtk->dev, rctx->cache_dma))
++			return -EINVAL;
++
++		rctx->cache_sz = cache_len;
++		first_cdesc = safexcel_add_cdesc(priv, ring, 1,
++						 (cache_len == len),
++						 req->cache_dma, cache_len, len,
++						 ctx->base.ctxr_dma);
++		if (IS_ERR(first_cdesc)) {
++			ret = PTR_ERR(first_cdesc);
++			goto unmap_cache;
++		}
++		n_cdesc++;
++
++		queued -= cache_len;
++		if (!queued)
++			goto send_command;
++	}
++
++		/* Skip descriptor generation for zero-length requests */
++		if (!areq->nbytes)
++			goto send_command;
++
++	/* Now handle the current ahash request buffer(s) */
++	req->nents = dma_map_sg(mtk->dev, areq->src,
++				sg_nents_for_len(areq->src, areq->nbytes),
++				DMA_TO_DEVICE);
++	if (!req->nents) {
++		ret = -ENOMEM;
++		goto cdesc_rollback;
++	}
++
++	for_each_sg(areq->src, sg, req->nents, i) {
++		int sglen = sg_dma_len(sg);
++
++		/* Do not overflow the request */
++		if (queued - sglen < 0)
++			sglen = queued;
++
++		cdesc = mtk_add_cdesc(mtk, sg_dma_address(sg), Result.base,
++						saRecord.base, saState.base, sglen, 0);
++		if (IS_ERR(cdesc)) {
++			ret = PTR_ERR(cdesc);
++			goto cdesc_rollback;
++		}
++		rdesc = mtk_add_rdesc(mtk);
++
++		n_cdesc++;
++
++		if (n_cdesc == 1)
++			first_cdesc = cdesc;
++
++		queued -= sglen;
++		if (!queued)
++			break;
++	}
++
++send_command:
++	req->processed += len;
++	request->req = &areq->base;
++
++	return 0;
++
++unmap_result:
++
++unmap_sg:
++
++cdesc_rollback:
++	for (i = 0; i < n_cdesc; i++)
++		mtk_ring_rollback_wptr(priv, &priv->ring[ring].cdr);
++unmap_cache:
++	if (req->bcache_dma) {
++		dma_unmap_single(priv->dev, ctx->base.cache_dma,
++				 ctx->base.cache_sz, DMA_TO_DEVICE);
++		req->cache_sz = 0;
++	}
++
++	return ret;
++}
++
++static int mtk_ahash_enqueue(struct ahash_request *areq)
++{
++	struct mtk_ahash_ctx *ctx = crypto_ahash_ctx(crypto_ahash_reqtfm(areq));
++	struct mtk_ahash_reqctx *req = ahash_request_ctx(areq);
++	struct mtk_device *mtk = ctx->mtk;
++	int ret;
++
++	spin_lock(&mtk->ring->queue_lock);
++	ret = crypto_enqueue_request(&mtk->ring->queue, base);
++	spin_unlock(&mtk->ring->queue_lock);
++
++	queue_work(mtk->ring->dequeue, &mtk->ring->dequeue_data.work);
++
++	return ret;
++}
++
++static int mtk_ahash_cache(struct ahash_request *areq)
++{
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	struct crypto_ahash *ahash = crypto_ahash_reqtfm(areq);
++	int queued, cache_len;
++
++	cache_len = rctx->len - areq->nbytes - rctx->processed;
++	queued = rctx->len - rctx->processed;
++
++	/*
++	 * In case there isn't enough bytes to proceed (less than a
++	 * block size), cache the data until we have enough.
++	 */
++	if (cache_len + areq->nbytes <= crypto_ahash_blocksize(ahash)) {
++		sg_pcopy_to_buffer(areq->src, sg_nents(areq->src),
++				   req->cache + cache_len,
++				   areq->nbytes, 0);
++		return areq->nbytes;
++	}
++
++	/* We could'nt cache all the data */
++	return -E2BIG;
++}
++
++static int mtk_ahash_update(struct ahash_request *areq)
++{
++	struct mtk_ahash_ctx *ctx = crypto_ahash_ctx(crypto_ahash_reqtfm(areq));
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	struct crypto_ahash *ahash = crypto_ahash_reqtfm(areq);
++	struct saRecord_s *saRecord = ctx->sa_in;
++	bool last = (rctx->flags & MTK_DESC_LAST);
++	bool finish = (rctx->flags & MTK_DESC_FINISH);
++	int ret;
++
++	/* If the request is 0 length, do nothing */
++	if (!areq->nbytes)
++		return 0;
++
++	/* Add request to the cache if it fits */
++	ret = mtk_ahash_cache(areq);
++
++	/* Update total request length */
++	rctx->len += areq->nbytes;
++
++	/* If not all data could fit into the cache, go process the excess.
++	 * Also go process immediately for an HMAC IV precompute, which
++	 * will never be finished at all, but needs to be processed anyway.
++	 */
++	if ((ret && !finish) || last)
++		return mtk_ahash_enqueue(areq);
++
++	return 0;
++}
++
++static int mtk_ahash_final(struct ahash_request *areq)
++{
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	struct mtk_ahash_ctx *ctx = crypto_ahash_ctx(crypto_ahash_reqtfm(areq));
++
++	rctx->flags |= (MTK_DESC_LAST | MTK_DESC_FINISH);
++
++	/* If we have an overall 0 length request */
++	if (!(rctx->len + areq->nbytes)) {
++		if (IS_HASH_SHA1(req->flags))
++			memcpy(areq->result, sha1_zero_message_hash,
++				SHA1_DIGEST_SIZE);
++		else if (IS_HASH_SHA224(req->flags))
++			memcpy(areq->result, sha224_zero_message_hash,
++				SHA224_DIGEST_SIZE);
++		else if (IS_HASH_SHA256(req->flags))
++			memcpy(areq->result, sha256_zero_message_hash,
++				SHA256_DIGEST_SIZE);
++		else if (IS_HASH_MD5(req->flags))
++       			memcpy(areq->result, md5_zero_message_hash,
++				MD5_DIGEST_SIZE);
++		return 0;
++	}
++
++	return mtk_ahash_enqueue(areq);
++}
++
++static int mtk_ahash_finup(struct ahash_request *areq)
++{
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++
++	rctx->flags |= (MTK_DESC_LAST | MTK_DESC_FINISH);
++
++	mtk_ahash_update(areq);
++
++	return mtk_ahash_final(areq);
++}
++
++static int mtk_ahash_export(struct ahash_request *areq, void *out)
++{
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	struct mtk_ahash_export_state *export = out;
++	struct saRecord_s *saRecord = rctx->saRecord;
++
++	export->len = rctx->len;
++	export->processed = rctx->processed;
++	export->flags = rctx->flags;
++	export->stateByteCnt[0] = saRecord->stateByteCnt[0];
++	export->stateByteCnt[1] = saRecord->stateByteCnt[1];
++	memcpy(export->saIDigest, saRecord->saIDigest, SHA256_DIGEST_SIZE);
++	memcpy(export->cache, req->cache, SHA256_BLOCK_SIZE);
++
++	return 0;
++}
++
++static int mtk_ahash_import(struct ahash_request *areq, const void *in)
++{
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	const struct mtk_ahash_export_state *export = in;
++	struct saRecord_s *saRecord = rctx->saRecord;
++	int ret;
++
++	ret = crypto_ahash_init(areq);
++	if (ret)
++		return ret;
++
++	rctx->len = export->len;
++	rctx->processed = export->processed;
++	rctx->flags = export->flags;
++	saRecord->stateByteCnt[0] = export->stateByteCnt[0];
++	saRecord->stateByteCnt[1] = export->stateByteCnt[1];
++	memcpy(saRecord->saIDigest, export->saIDigest, SHA256_DIGEST_SIZE);
++	memcpy(req->cache, export->cache, SHA256_BLOCK_SIZE);
++
++	return 0;
++}
++
++static int mtk_hmac_setkey(struct crypto_ahash *ctfm, const u8 *key,
++			  u32 keylen)
++{
++	struct crypto_tfm *tfm = crypto_ahash_tfm(ctfm);
++	struct mtk_ahash_ctx *ctx = crypto_ahash_ctx(ctfm);
++	struct saRecord_s *saRecord = ctx->sa_in;
++	int err;
++
++	/* authentication key */
++	err = mtk_authenc_setkey(ctx->shash, saRecord, key, keylen);
++
++	saRecord->saCmd0.bits.direction = 1;
++	saRecord->saCmd1.bits.copyHeader = 0;
++	saRecord->saCmd1.bits.copyDigest = 0;
++
++	return err;
++}
++
++static int mtk_ahash_cra_init(struct crypto_tfm *tfm)
++{
++	struct mtk_ahash_ctx *ctx = crypto_tfm_ctx(tfm);
++	struct mtk_alg_template *tmpl = container_of(tfm->__crt_alg,
++				struct mtk_alg_template, alg.ahash.halg.base);
++	struct mtk_device *mtk = tmpl->mtk;
++	u32 flags = tmpl->flags;
++	char *alg_base;
++
++	crypto_ahash_set_reqsize(__crypto_ahash_cast(tfm),
++				 sizeof(struct mtk_ahash_reqctx));
++
++	ctx->mtk = tmpl->mtk;
++
++	ctx->sa_in = kzalloc(sizeof(struct saRecord_s), GFP_KERNEL);
++	if (!ctx->sa_in)
++		return -ENOMEM;
++
++	ctx->sa_base_in = NULL;
++
++	/* for HMAC need software fallback */
++	if (IS_HASH_MD5(flags)) {
++		alg_base = "md5";
++		ctx->init_state = { SHA1_H3, SHA1_H2, SHA1_H1, SHA1_H0 };
++	}
++	if (IS_HASH_SHA1(flags)) {
++		alg_base = "sha1";
++		ctx->init_state = { SHA1_H4, SHA1_H3, SHA1_H2, SHA1_H1,
++				SHA1_H0 };
++	}
++	if (IS_HASH_SHA224(flags)) {
++		alg_base = "sha224";
++		ctx->init_state = { SHA224_H7, SHA224_H6, SHA224_H5, SHA224_H4,
++				SHA224_H3, SHA224_H2, SHA224_H1, SHA224_H0 };
++	}
++	if (IS_HASH_SHA256(flags)) {
++		alg_base = "sha256";
++		ctx->init_state = { SHA256_H7, SHA256_H6, SHA256_H5, SHA256_H4,
++				SHA256_H3, SHA256_H2, SHA256_H1, SHA256_H0 };
++	}
++
++	if (IS_HMAC(flags)) {
++		ctx->shash = crypto_alloc_shash(alg_base, 0,
++			CRYPTO_ALG_NEED_FALLBACK);
++
++		if (IS_ERR(ctx->shash)) {
++			dev_err(ctx->mtk->dev, "base driver %s not loaded.\n",
++				alg_base);
++				return PTR_ERR(ctx->shash);
++		}
++	}
++
++	return 0;
++}
++
++static int mtk_ahash_init(struct ahash_request *areq)
++{
++	struct mtk_ahash_ctx *ctx = crypto_ahash_ctx(crypto_ahash_reqtfm(areq));
++	struct mtk_ahash_reqctx *rctx = ahash_request_ctx(areq);
++	struct mtk_alg_template *tmpl = container_of(tfm->__crt_alg,
++				struct mtk_alg_template, alg.ahash.halg.base);
++	struct crypto_ahash *ahash = crypto_ahash_reqtfm(areq);
++	struct saRecord_s *saRecord = ctx->sa_in;
++	struct saState_s *saState;
++	struct mtk_state_pool *saState_pool;
++	u32 flags = tmpl->flags;
++	int idx;
++
++	if (ctx->sa_base_in)
++		dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	mtk_set_saRecord(saRecord, 0, flags);
++	saRecord->saCmd0.bits.saveHash = 1;
++	saRecord->saCmd1.bits.copyDigest = 0;
++	saRecord->saCmd1.bits.copyHeader = 0;
++	saRecord->saCmd0.bits.hashSource = 2;
++	saRecord->saCmd0.bits.digestLength = crypto_ahash_digestsize(ahash) / 4;
++
++	ctx->sa_base_in = dma_map_single(ctx->mtk->dev, ctx->sa_in,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	rctx->saRecord = saRecord;
++	rctx->saRecord_base = ctx->sa_base_in;
++
++	if (!rctx->saState_base) {
++		idx = mtk_get_free_saState(mtk);
++		if (idx < 0)
++			return -ENOMEM;
++
++		saState_pool = &mtk->ring->saState_pool[idx];
++		rctx->saState_idx = idx;
++		rctx->saState = saState_pool->base;
++		rctx->saState_base = saState_pool->base_dma;
++	}
++	saState = rctx->saState;
++	saState->stateByteCnt = 0x40;
++
++	if (IS_HMAC(flags))
++		memcpy(saState->saIDigest,saRecord->saIDigest,
++							SHA256_DIGEST_SIZE);
++	} else {
++		saState->saIDigest = ctx->init_state;
++	}
++
++	return 0;
++}
++
++static int mtk_ahash_digest(struct ahash_request *areq)
++{
++	int ret = mtk_ahash_init(areq);
++
++	if (ret)
++		return ret;
++
++	return mtk_ahash_finup(areq);
++}
++
++static void mtk_ahash_cra_exit(struct crypto_tfm *tfm)
++{
++	struct mtk_ahash_ctx *ctx = crypto_tfm_ctx(tfm);
++
++	if (ctx->sa_base_in)
++		dma_unmap_single(ctx->mtk->dev, ctx->sa_base_in,
++			sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	if (ctx->shash)
++		crypto_free_shash(ctx->shash);
++
++	kfree(ctx->sa_in);
++}
++
++struct mtk_alg_template mtk_alg_sha1 = {
++	.type = MTK_ALG_TYPE_AHASH,
++	.flags = MTK_HASH_SHA1,
++	.alg.ahash = {
++		.init = mtk_ahash_init,
++		.update = mtk_ahash_update,
++		.final = mtk_ahash_final,
++		.finup = mtk_ahash_finup,
++		.digest = mtk_ahash_digest,
++		.export = mtk_ahash_export,
++		.import = mtk_ahash_import,
++		.halg = {
++			.digestsize = SHA1_DIGEST_SIZE,
++			.statesize = sizeof(struct mtk_ahash_export_state),
++			.base = {
++				.cra_name = "sha1",
++				.cra_driver_name = "sha1-eip93",
++				.cra_priority = 300,
++				.cra_flags = CRYPTO_ALG_ASYNC |
++						CRYPTO_ALG_KERN_DRIVER_ONLY,
++				.cra_blocksize = SHA1_BLOCK_SIZE,
++				.cra_ctxsize = sizeof(struct mtk_ahash_ctx),
++				.cra_init = mtk_ahash_cra_init,
++				.cra_exit = mtk_ahash_cra_exit,
++				.cra_module = THIS_MODULE,
++			},
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_sha224 = {
++	.type = MTK_ALG_TYPE_AHASH,
++	.flags = MTK_HASH_SHA224,
++	.alg.ahash = {
++		.init = mtk_ahash_init,
++		.update = mtk_ahash_update,
++		.final = mtk_ahash_final,
++		.finup = mtk_ahash_finup,
++		.digest= mtk_ahash_digest,
++		.export = mtk_ahash_export,
++		.import = mtk_ahash_import,
++		.halg = {
++			.digestsize = SHA224_DIGEST_SIZE,
++			.statesize = sizeof(struct mtk_ahash_export_state),
++			.base = {
++				.cra_name = "sha224",
++				.cra_driver_name = "sha224-eip93",
++				.cra_priority = 300,
++				.cra_flags = CRYPTO_ALG_ASYNC |
++						CRYPTO_ALG_KERN_DRIVER_ONLY,
++				.cra_blocksize = SHA224_BLOCK_SIZE,
++				.cra_ctxsize = sizeof(struct mtk_ahash_ctx),
++				.cra_init = mtk_ahash_cra_init,
++				.cra_exit = mtk_ahash_cra_exit,
++				.cra_module = THIS_MODULE,
++			},
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_sha256 = {
++	.type = MTK_ALG_TYPE_AHASH,
++	.flags = MTK_HASH_SHA256,
++	.alg.ahash = {
++		.init = mtk_ahash_init,
++		.update = mtk_ahash_update,
++		.final = mtk_ahash_final,
++		.finup = mtk_ahash_finup,
++		.digest= mtk_ahash_digest,
++		.export = mtk_ahash_export,
++		.import = mtk_ahash_import,
++		.halg = {
++			.digestsize = SHA256_DIGEST_SIZE,
++			.statesize = sizeof(struct mtk_ahash_export_state),
++			.base = {
++				.cra_name = "sha256",
++				.cra_driver_name = "sha256-eip93",
++				.cra_priority = 300,
++				.cra_flags = CRYPTO_ALG_ASYNC |
++						CRYPTO_ALG_KERN_DRIVER_ONLY,
++				.cra_blocksize = SHA256_BLOCK_SIZE,
++				.cra_ctxsize = sizeof(struct mtk_ahash_ctx),
++				.cra_init = mtk_ahash_cra_init,
++				.cra_exit = mtk_ahash_cra_exit,
++				.cra_module = THIS_MODULE,
++			},
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_hmac_sha1 = {
++	.type = MTK_ALG_TYPE_AHASH,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA1,
++	.alg.ahash = {
++		.init = mtk_ahash_init,
++		.update = mtk_ahash_update,
++		.final = mtk_ahash_final,
++		.finup = mtk_ahash_finup,
++		.digest= mtk_ahash_digest,
++		.setkey = mtk_hmac_setkey,
++		.export = mtk_ahash_export,
++		.import = mtk_ahash_import,
++		.halg = {
++			.digestsize = SHA1_DIGEST_SIZE,
++			.statesize = sizeof(struct mtk_ahash_export_state),
++			.base = {
++				.cra_name = "hmac(sha1)",
++				.cra_driver_name = "hmac(sha1-eip93)",
++				.cra_priority = 300,
++				.cra_flags = CRYPTO_ALG_ASYNC |
++						CRYPTO_ALG_KERN_DRIVER_ONLY,
++				.cra_blocksize = SHA1_BLOCK_SIZE,
++				.cra_ctxsize = sizeof(struct mtk_ahash_ctx),
++				.cra_init = mtk_ahash_cra_init,
++				.cra_exit = mtk_ahash_cra_exit,
++				.cra_module = THIS_MODULE,
++			},
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_hmac_sha224 = {
++	.type = MTK_ALG_TYPE_AHASH,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA224,
++	.alg.ahash = {
++		.init = mtk_ahash_init,
++		.update = mtk_ahash_update,
++		.final = mtk_ahash_final,
++		.finup = mtk_ahash_finup,
++		.digest= mtk_ahash_digest,
++		.setkey = mtk_hmac_setkey,
++		.export = mtk_ahash_export,
++		.import = mtk_ahash_import,
++		.halg = {
++			.digestsize = SHA224_DIGEST_SIZE,
++			.statesize = sizeof(struct mtk_ahash_export_state),
++			.base = {
++				.cra_name = "hmac(sha224)",
++				.cra_driver_name = "hmac(sha224-eip93)",
++				.cra_priority = 300,
++				.cra_flags = CRYPTO_ALG_ASYNC |
++						CRYPTO_ALG_KERN_DRIVER_ONLY,
++				.cra_blocksize = SHA224_BLOCK_SIZE,
++				.cra_ctxsize = sizeof(struct mtk_ahash_ctx),
++				.cra_init = mtk_ahash_cra_init,
++				.cra_exit = mtk_ahash_cra_exit,
++				.cra_module = THIS_MODULE,
++			},
++		},
++	},
++};
++
++struct mtk_alg_template mtk_alg_hmac_sha256 = {
++	.type = MTK_ALG_TYPE_AHASH,
++	.flags = MTK_HASH_HMAC | MTK_HASH_SHA256,
++	.alg.ahash = {
++		.init = mtk_ahash_init,
++		.update = mtk_ahash_update,
++		.final = mtk_ahash_final,
++		.finup = mtk_ahash_finup,
++		.digest= mtk_ahash_digest,
++		.setkey = mtk_hmac_setkey,
++		.export = mtk_ahash_export,
++		.import = mtk_ahash_import,
++		.halg = {
++			.digestsize = SHA1_DIGEST_SIZE,
++			.statesize = sizeof(struct mtk_ahash_export_state),
++			.base = {
++				.cra_name = "hmac(sha256)",
++				.cra_driver_name = "hmac(sha256-eip93)",
++				.cra_priority = 300,
++				.cra_flags = CRYPTO_ALG_ASYNC |
++						CRYPTO_ALG_KERN_DRIVER_ONLY,
++				.cra_blocksize = SHA1_BLOCK_SIZE,
++				.cra_ctxsize = sizeof(struct mtk_ahash_ctx),
++				.cra_init = mtk_ahash_cra_init,
++				.cra_exit = mtk_ahash_cra_exit,
++				.cra_module = THIS_MODULE,
++			},
++		},
++	},
++};
+diff --git a/drivers/crypto/mtk-eip93/eip93-hash.h b/drivers/crypto/mtk-eip93/eip93-hash.h
+new file mode 100644
+index 0000000..e543005
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-hash.h
+@@ -0,0 +1,68 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2021
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#ifndef _SHA_H_
++#define _SHA_H_
++
++#include <crypto/sha.h>
++
++#include "eip93-main.h"
++
++extern struct mtk_alg_template mtk_alg_sha1;
++extern struct mtk_alg_template mtk_alg_sha224;
++extern struct mtk_alg_template mtk_alg_sha256;
++extern struct mtk_alg_template mtk_alg_hmac_sha1;
++extern struct mtk_alg_template mtk_alg_hmac_sha224;
++extern struct mtk_alg_template mtk_alg_hmac_sha256;
++
++struct mtk_ahash_ctx {
++	struct mtk_device	*mtk;
++	struct saRecord_s	*sa_in;
++	dma_addr_t		sa_base_in;
++	u32			init_state[SHA256_DIGEST_SIZE / sizeof(u32)];
++	struct crypto_shash	*shash;
++};
++
++struct mtk_ahash_reqctx {
++	struct mtk_device	*mtk;
++	struct saState_s	*saState;
++	dma_addr_t		saState_base;
++	u32			saState_idx;
++	struct saRecord_s	*saRecord;
++	dma_addr_t		saRecord_base;
++	u32			flags;
++
++	int		nents;
++	dma_addr_t	result_dma;
++
++	u64		len;
++	u64		processed;
++
++	u8		cache[SHA256_BLOCK_SIZE] __aligned(sizeof(u32));
++	dma_addr_t	cache_dma;
++	unsigned int	cache_sz;
++
++	u8		cache_next[SHA256_BLOCK_SIZE] __aligned(sizeof(u32));
++};
++
++struct mtk_ahash_export_state {
++	u64		len;
++	u64		processed;
++	u32		flags;
++
++	u32		saIDigest[8];
++	u32		stateByteCnt[2];
++	u8		cache[SHA256_BLOCK_SIZE];
++};
++
++int mtk_ahash_handle_result(struct mtk_device *mtk,
++				  struct crypto_async_request *async,
++				  int err);
++
++int mtk_ahash_send_req(struct mtk_device *mtk,
++				struct crypto_async_request *async);
++#endif /* _SHA_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-ipsec.c b/drivers/crypto/mtk-eip93/eip93-ipsec.c
+new file mode 100644
+index 0000000..4bf746c
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-ipsec.c
+@@ -0,0 +1,965 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2021 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <crypto/aead.h>
++#include <crypto/authenc.h>
++#include <crypto/ctr.h>
++#include <linux/netdevice.h>
++#include <linux/skbuff.h>
++#include <net/esp.h>
++#include <net/ip.h>
++#include <net/protocol.h>
++#include <net/udp.h>
++#include <net/xfrm.h>
++
++#include "eip93-common.h"
++#include "eip93-main.h"
++#include "eip93-ipsec.h"
++#include "eip93-regs.h"
++
++static int mtk_xfrm_add_state(struct xfrm_state *x);
++static void mtk_xfrm_del_state(struct xfrm_state *x);
++static void mtk_xfrm_free_state(struct xfrm_state *x);
++static bool mtk_ipsec_offload_ok(struct sk_buff *skb, struct xfrm_state *x);
++static void mtk_advance_esn_state(struct xfrm_state *x);
++
++static const struct xfrmdev_ops mtk_xfrmdev_ops = {
++	.xdo_dev_state_add      = mtk_xfrm_add_state,
++	.xdo_dev_state_delete   = mtk_xfrm_del_state,
++	.xdo_dev_state_free     = mtk_xfrm_free_state,
++	.xdo_dev_offload_ok     = mtk_ipsec_offload_ok,
++	.xdo_dev_state_advance_esn = mtk_advance_esn_state,
++};
++
++int mtk_add_xfrmops(struct net_device *netdev)
++{
++	if (netdev->features & NETIF_F_HW_ESP)
++		return NOTIFY_DONE;
++/*
++	if (netdev->dev.type == NULL)
++		return NOTIFY_DONE;
++
++	if (strcmp(netdev->dev.type->name, "dsa"))  {
++		if (strcmp(netdev->dev.type->name, "bridge"))
++			return NOTIFY_DONE;
++	}
++*/
++
++	/* enable ESP HW offload */
++	netdev->xfrmdev_ops = &mtk_xfrmdev_ops;
++	netdev->features |= NETIF_F_HW_ESP;
++	netdev->hw_enc_features |= NETIF_F_HW_ESP;
++	/* enable ESP GSO */
++	netdev->features |= NETIF_F_GSO_ESP;
++	netdev->hw_features |= NETIF_F_GSO_ESP;
++	netdev->hw_enc_features |= NETIF_F_GSO_ESP;
++
++	netdev_change_features(netdev);
++	netdev_info(netdev, "ESP HW offload added.\n");
++	return NOTIFY_DONE;
++}
++
++int mtk_del_xfrmops(struct net_device *netdev)
++{
++	if (netdev->features & NETIF_F_HW_ESP) {
++		netdev->xfrmdev_ops = NULL;
++		netdev->hw_enc_features &= ~NETIF_F_HW_ESP;
++		netdev->hw_enc_features &= ~NETIF_F_GSO_ESP;
++		netdev->hw_features &= ~NETIF_F_GSO_ESP;
++		netdev->features &= ~NETIF_F_HW_ESP;
++		netdev->features &= ~NETIF_F_GSO_ESP;
++		netdev_change_features(netdev);
++		netdev_info(netdev, "ESP HW offload removed.\n");
++	}
++
++	return NOTIFY_DONE;
++}
++
++/*
++ * mtk_validate_state
++ * return 0 in case doesn't validate or "flags" which
++ * can never be "0"
++ */
++u32 mtk_validate_state(struct xfrm_state *x)
++{
++ 	struct net_device *netdev = x->xso.dev;
++ 	u32 flags = 0;
++
++	if (x->id.proto != IPPROTO_ESP) {
++ 		netdev_info(netdev, "Only ESP XFRM state may be offloaded\n");
++ 		return 0;
++ 	}
++	/* TODO: add ipv6 support */
++	if (x->props.family != AF_INET) {
++//		&& x->props.family != AF_INET6) {
++		netdev_info(netdev, "Only IPv4 xfrm states may be offloaded\n");
++		return 0;
++	}
++	if (x->aead) {
++		netdev_info(netdev, "Cannot offload xfrm states with aead\n");
++		return 0;
++	}
++ 	if (x->props.aalgo == SADB_AALG_NONE) {
++ 		netdev_info(netdev, "Cannot offload without authentication\n");
++ 		return 0;
++ 	}
++ 	if (x->props.calgo != SADB_X_CALG_NONE) {
++ 		netdev_info(netdev, "Cannot offload compressed xfrm states\n");
++ 		return 0;
++ 	}
++ 	/* TODO: support ESN in software */
++ 	if (x->props.flags & XFRM_STATE_ESN) {
++ 		netdev_info(netdev, "Cannot offload ESN xfrm states\n");
++ 		return 0;
++ 	}
++ 	if (x->props.mode != XFRM_MODE_TUNNEL
++			&& x->props.mode != XFRM_MODE_TRANSPORT) {
++ 		netdev_info(netdev, "only offload Tunnel & Transport Mode\n");
++ 		return 0;
++ 	}
++	/*
++	 * It seems the XFRM device doesn't support encap or tfcpad
++	 * TODO: support ESPINUDP for NAT-T on xmit
++	 * (recv works via esp_input_done2)
++	 *
++ 	if (x->encap) {
++ 		netdev_info(netdev, "Encapsulated xfrm can not be offloaded\n");
++ 		return 0;
++ 	}
++	*/
++ 	if (x->tfcpad) {
++ 		netdev_info(netdev, "No tfc padding supported\n");
++ 		return 0;
++ 	}
++
++     	switch (x->props.ealgo) {
++ 	case SADB_EALG_DESCBC:
++ 		flags |= MTK_ALG_DES | MTK_MODE_CBC;
++ 		break;
++ 	case SADB_EALG_3DESCBC:
++ 		flags |= MTK_ALG_3DES | MTK_MODE_CBC;
++ 		break;
++ 	case SADB_X_EALG_AESCBC:
++ 		flags |= MTK_ALG_AES | MTK_MODE_CBC;
++ 		break;
++ 	case SADB_X_EALG_AESCTR: // CTR is ONLY in RFC3686 for ESP
++ 		flags |= MTK_ALG_AES | MTK_MODE_CTR | MTK_MODE_RFC3686;
++ 	case SADB_EALG_NULL:
++ 		break;
++ 	default:
++ 		netdev_info(netdev, "Cannot offload encryption: %s\n",
++							x->ealg->alg_name);
++ 		return 0;
++ 	}
++
++ 	switch (x->props.aalgo) {
++ 	case SADB_AALG_SHA1HMAC:
++ 		flags |= MTK_HASH_HMAC | MTK_HASH_SHA1;
++ 		break;
++ 	case SADB_X_AALG_SHA2_256HMAC:
++ 		flags |= MTK_HASH_HMAC | MTK_HASH_SHA256;
++ 		break;
++ 	case SADB_AALG_MD5HMAC:
++ 		flags |= MTK_HASH_HMAC | MTK_HASH_MD5;
++ 		break;
++ 	default:
++ 		netdev_info(netdev, "Cannot offload authentication: %s\n",
++							x->aalg->alg_name);
++ 		return 0;
++	}
++ /*
++ 	if (x->aead->alg_icv_len != 128) {
++ 		netdev_info(netdev, "Cannot offload xfrm states with AEAD ICV length other than 128bit\n");
++ 		return -EINVAL;
++ 	}
++ */
++
++ /*
++ 	TODO check key_len
++ 	// split for RFC3686 with nonce vs others !!
++ 	if ((x->aead->alg_key_len != 128 + 32) &&
++ 	    (x->aead->alg_key_len != 256 + 32)) {
++ 		netdev_info(netdev, "Cannot offload xfrm states with AEAD key length other than 128/256 bit\n");
++ 		return -EINVAL;
++ 	}
++ */
++	return flags;
++}
++
++static int mtk_create_sa(struct mtk_device *mtk, struct ipsec_sa_entry *ipsec,
++			struct xfrm_state *x, u32 flags)
++{
++	struct saRecord_s *saRecord;
++	char *alg_base;
++	const u8 *enckey = x->ealg->alg_key;
++	unsigned int enckeylen = (x->ealg->alg_key_len >>3);
++	const u8 *authkey = x->aalg->alg_key;
++	unsigned int authkeylen = (x->aalg->alg_key_len >>3);
++	unsigned int trunc_len = (x->aalg->alg_trunc_len >>3);
++	u32 nonce = 0;
++	int err;
++
++	if (IS_HASH_MD5(flags))
++		alg_base = "md5";
++	if (IS_HASH_SHA1(flags))
++		alg_base = "sha1";
++	if (IS_HASH_SHA256(flags))
++		alg_base = "sha256";
++
++	ipsec->shash = crypto_alloc_shash(alg_base, 0, CRYPTO_ALG_NEED_FALLBACK);
++
++	if (IS_ERR(ipsec->shash)) {
++	 	dev_err(mtk->dev, "base driver %s could not be loaded.\n",
++			 alg_base);
++	return PTR_ERR(ipsec->shash);
++	}
++
++	ipsec->sa = kzalloc(sizeof(struct saRecord_s), GFP_KERNEL);
++	if (!ipsec->sa)
++		return -ENOMEM;
++
++	ipsec->sa_base = dma_map_single(mtk->dev, ipsec->sa,
++				sizeof(struct saRecord_s), DMA_TO_DEVICE);
++
++	saRecord = ipsec->sa;
++
++	if (IS_RFC3686(flags)) {
++		if (enckeylen < CTR_RFC3686_NONCE_SIZE)
++			dev_err(mtk->dev, "rfc 3686 bad key\n");
++
++		enckeylen -= CTR_RFC3686_NONCE_SIZE;
++		memcpy(&nonce, enckey + enckeylen,
++						CTR_RFC3686_NONCE_SIZE);
++	}
++
++	/* Encryption key */
++	mtk_set_saRecord(saRecord, enckeylen, flags);
++
++	memcpy(saRecord->saKey, enckey, enckeylen);
++	saRecord->saNonce = nonce;
++
++	/* authentication key */
++	err = mtk_authenc_setkey(ipsec->shash,  saRecord, authkey, authkeylen);
++	if (err)
++		dev_err(mtk->dev, "Set Key failed: %d\n", err);
++
++	saRecord->saCmd0.bits.opGroup = 1;
++	saRecord->saCmd0.bits.opCode = 0;
++	saRecord->saCmd1.bits.byteOffset = 0;
++	saRecord->saCmd1.bits.hashCryptOffset = 0;
++	saRecord->saCmd0.bits.digestLength = (trunc_len >> 2);
++	saRecord->saCmd1.bits.hmac = 1;
++	saRecord->saCmd0.bits.padType = 0; // IPSec padding
++	saRecord->saCmd0.bits.extPad = 0;
++	saRecord->saCmd0.bits.scPad = 1; // Allow Stream Cipher padding
++	saRecord->saCmd1.bits.copyPad = 0;
++	saRecord->saCmd0.bits.hdrProc = 1;
++	saRecord->saCmd1.bits.seqNumCheck = 1;
++	saRecord->saSpi = ntohl(x->id.spi);
++	saRecord->saSeqNum[0] = 0;
++	saRecord->saSeqNum[1] = 0;
++	saRecord->saSeqNumMask[0] = 0xFFFFFFFF;
++	saRecord->saSeqNumMask[1] = x->replay.bitmap;
++
++	if (x->xso.flags & XFRM_OFFLOAD_INBOUND) {
++		saRecord->saCmd0.bits.direction = 1;
++		saRecord->saCmd1.bits.copyHeader = 1;
++		saRecord->saCmd1.bits.copyDigest = 0;
++		saRecord->saCmd0.bits.ivSource = 1;
++		flags |= MTK_DECRYPT;
++	} else {
++		saRecord->saCmd0.bits.direction = 0;
++		saRecord->saCmd1.bits.copyHeader = 0;
++		saRecord->saCmd1.bits.copyDigest = 1;
++		saRecord->saCmd0.bits.ivSource = 3;
++		flags |= MTK_ENCRYPT;
++	}
++
++	ipsec->cdesc.peCrtlStat.bits.hostReady = 1;
++	ipsec->cdesc.peCrtlStat.bits.prngMode = 0;
++	ipsec->cdesc.peCrtlStat.bits.hashFinal = 1;
++	ipsec->cdesc.peCrtlStat.bits.padCrtlStat = 2; // Pad align 4 as esp4.c
++	ipsec->cdesc.peCrtlStat.bits.peReady = 0;
++	ipsec->cdesc.saAddr = ipsec->sa_base;
++	ipsec->cdesc.stateAddr = 0;
++	ipsec->cdesc.arc4Addr = 0;
++	ipsec->cdesc.userId = flags |
++			MTK_DESC_IPSEC | MTK_DESC_LAST | MTK_DESC_FINISH;
++
++	return 0;
++}
++
++/*
++* mtk_xfrm_add_state
++*/
++static int mtk_xfrm_add_state(struct xfrm_state *x)
++{
++	struct crypto_rng *rng;
++	struct rng_alg *alg;
++	struct mtk_alg_template *tmpl;
++	struct mtk_device *mtk;
++	struct ipsec_sa_entry *ipsec;
++	struct crypto_aead *aead;
++	u32 flags = 0;
++	int err;
++
++	rng = crypto_alloc_rng("eip93-prng", 0, 0);
++	if (IS_ERR(rng))
++		return -EOPNOTSUPP;
++
++	alg = crypto_rng_alg(rng);
++	tmpl = container_of(alg, struct mtk_alg_template, alg.rng);
++	mtk = tmpl->mtk;
++	crypto_free_rng(rng);
++
++	flags = mtk_validate_state(x);
++
++	if (!flags) {
++		dev_info(mtk->dev, "did not validate\n");
++		return -EOPNOTSUPP;
++	}
++
++	ipsec = kmalloc(sizeof(struct ipsec_sa_entry), GFP_KERNEL);
++
++	/*
++	 * TODO: add key checks
++	 */
++
++	err = mtk_create_sa(mtk, ipsec, x, flags);
++	if (err) {
++		dev_err(mtk->dev, "error creating sa\n");
++		return err;
++	}
++
++	aead = x->data;
++	/* authsize = const for the SA */
++	ipsec->authsize = crypto_aead_authsize(aead);
++	/* blksize is const for the SA */
++	ipsec->blksize = ALIGN(crypto_aead_blocksize(aead), 4);
++	/*  ivsize = const for the (SA) cipher */
++	ipsec->ivsize = crypto_aead_ivsize(aead);
++
++	ipsec->mtk = mtk;
++
++	x->xso.offload_handle = (unsigned long)ipsec;
++	try_module_get(THIS_MODULE);
++
++	return 0;
++}
++
++static void mtk_xfrm_del_state(struct xfrm_state *x)
++{
++	// do nothing.
++
++	return;
++}
++
++static void mtk_xfrm_free_state(struct xfrm_state *x)
++{
++	struct mtk_device *mtk;
++	struct ipsec_sa_entry *ipsec;
++
++	ipsec = (struct ipsec_sa_entry *)x->xso.offload_handle;
++	mtk = ipsec->mtk;
++
++	dma_unmap_single(mtk->dev, ipsec->sa_base, sizeof(struct saRecord_s),
++								DMA_TO_DEVICE);
++	kfree(ipsec->sa);
++	kfree(ipsec);
++
++	module_put(THIS_MODULE);
++
++	return;
++}
++
++static void mtk_advance_esn_state(struct xfrm_state *x)
++{
++	return;
++}
++
++/**
++ * mtk_ipsec_offload_ok - can this packet use the xfrm hw offload
++ * @skb: current data packet
++ * @xs: pointer to transformer state struct
++ **/
++static bool mtk_ipsec_offload_ok(struct sk_buff *skb, struct xfrm_state *x)
++{
++	if (x->props.family == AF_INET) {
++		/* Offload with IPv4 options is not supported yet */
++		if (ip_hdr(skb)->ihl > 5)
++			return false;
++	} else {
++		/* Offload with IPv6 extension headers is not support yet */
++		if (ipv6_ext_hdr(ipv6_hdr(skb)->nexthdr))
++			return false;
++	}
++
++	return true;
++}
++
++void mtk_ipsec_rx_done(unsigned long data)
++{
++	struct mtk_device *mtk = (struct mtk_device *)data;
++	struct mtk_ipsec_cb *mtk_ipsec_cb;
++	struct sk_buff *skb;
++	dma_addr_t dstAddr;
++	u8 nexthdr;
++	int err, len;
++	struct xfrm_state *x;
++	struct xfrm_offload *xo;
++	const struct iphdr *iph;
++	int hlen;
++	int ihl;
++
++	while ((skb = skb_dequeue(&mtk->ring->rx_queue))) {
++		mtk_ipsec_cb = (struct mtk_ipsec_cb *)MTK_IPSEC_CB(skb)->cb;
++		nexthdr = mtk_ipsec_cb->nexthdr;
++		err = mtk_ipsec_cb->err;
++		len = mtk_ipsec_cb->len;
++		dstAddr = mtk_ipsec_cb->dstAddr;
++		MTK_IPSEC_CB(skb)->cb = mtk_ipsec_cb->org_cb;
++		kfree(mtk_ipsec_cb);
++
++		x = xfrm_input_state(skb);
++
++		xo = xfrm_offload(skb);
++		xo->flags |= XFRM_ESP_NO_TRAILER;
++		xo->flags |= CRYPTO_DONE;
++		xo->status = CRYPTO_SUCCESS;
++		if (err ==  1)
++			xo->status = CRYPTO_TUNNEL_ESP_AUTH_FAILED;
++
++		dma_unmap_single(mtk->dev, dstAddr, skb->len, DMA_BIDIRECTIONAL);
++		xo->proto = nexthdr;
++
++		pskb_trim(skb, len);
++		// for inbound continue XFRM (<-1 is GRO; make -3 for encap)
++		xfrm_input(skb, IPPROTO_ESP, x->id.spi, -2);
++		/* Remove header as test
++		hlen = sizeof(struct ip_esp_hdr) + crypto_aead_ivsize(x->data);
++		iph = ip_hdr(skb);
++		ihl = iph->ihl * 4;
++
++		skb_pull_rcsum(skb, hlen);
++		if (x->props.mode == XFRM_MODE_TUNNEL)
++			skb_reset_transport_header(skb);
++		else
++			skb_set_transport_header(skb, -ihl);
++
++		/* "-1" resume, and resume with nextheader */
++//		xfrm_input(skb, nexthdr, x->id.spi, -1);
++	}
++}
++
++void mtk_ipsec_tx_done(unsigned long data)
++{
++	struct mtk_device *mtk = (struct mtk_device *)data;
++	struct mtk_ipsec_cb *mtk_ipsec_cb;
++	struct sk_buff *skb;
++	dma_addr_t dAddr;
++	int err, len;
++	struct xfrm_offload *xo;
++
++	while ((skb = skb_dequeue(&mtk->ring->tx_queue))) {
++		mtk_ipsec_cb = (struct mtk_ipsec_cb *)MTK_IPSEC_CB(skb)->cb;
++		err = mtk_ipsec_cb->err;
++		len = mtk_ipsec_cb->len;
++		dAddr = mtk_ipsec_cb->dstAddr;
++		MTK_IPSEC_CB(skb)->cb = mtk_ipsec_cb->org_cb;
++		kfree(mtk_ipsec_cb);
++
++		xo = xfrm_offload(skb);
++		xo->flags |= CRYPTO_DONE;
++		xo->status = CRYPTO_SUCCESS;
++
++		dma_unmap_single(mtk->dev, dAddr, len + 20, DMA_BIDIRECTIONAL);
++
++		skb_put(skb, len - (skb->len - 20));
++		ip_hdr(skb)->tot_len = htons(skb->len);
++		ip_send_check(ip_hdr(skb));
++
++		skb_push(skb, skb->data - skb_mac_header(skb));
++		secpath_reset(skb);
++		xfrm_dev_resume(skb);
++	}
++}
++
++int mtk_ipsec_offload(struct xfrm_state *x, struct sk_buff *skb,
++			struct esp_info *esp)
++{
++	struct ipsec_sa_entry *ipsec =
++				(struct ipsec_sa_entry *)x->xso.offload_handle;
++	struct mtk_device *mtk = ipsec->mtk;
++	struct eip93_descriptor_s desc = ipsec->cdesc;
++	struct eip93_descriptor_s cdesc;
++	struct mtk_ipsec_cb *mtk_ipsec_cb;
++	dma_addr_t saddr;
++	int err;
++
++	mtk_ipsec_cb = kmalloc(sizeof(struct mtk_ipsec_cb), GFP_KERNEL);
++	mtk_ipsec_cb->org_cb = MTK_IPSEC_CB(skb)->cb;
++	MTK_IPSEC_CB(skb)->cb = (u32)mtk_ipsec_cb;
++
++	if (x->xso.flags & XFRM_OFFLOAD_INBOUND) {
++		if (unlikely(mtk_ring_free(&mtk->ring->cdr) <= MTK_RING_BUSY)) {
++			dev_info(mtk->dev, "RCV packet drop\n");
++			xfrm_input(skb, -ENOSPC, x->id.spi, -1);
++			return -ENOSPC;
++		}
++		saddr = dma_map_single(mtk->dev, (void *)skb->data, skb->len,
++							DMA_BIDIRECTIONAL);
++
++		cdesc.peCrtlStat.word = desc.peCrtlStat.word;
++		cdesc.srcAddr = saddr;
++		cdesc.dstAddr = saddr;
++		cdesc.peLength.bits.length = skb->len;
++	} else {
++		if (unlikely(mtk_ring_free(&mtk->ring->cdr) <= MTK_RING_BUSY)) {
++			dev_info(mtk->dev, "XMIT packet drop\n");
++			return -ENOSPC;
++		}
++
++		saddr = dma_map_single(mtk->dev, (void *)skb->data,
++			skb->len + esp->tailen, DMA_BIDIRECTIONAL);
++
++		cdesc.peCrtlStat.bits.hostReady = 1;
++		cdesc.peCrtlStat.bits.prngMode = 0;
++		cdesc.peCrtlStat.bits.padValue = esp->proto;
++		cdesc.peCrtlStat.bits.padCrtlStat = 2; // Pad align 4 as esp4.c
++		cdesc.peCrtlStat.bits.hashFinal = 1;
++		cdesc.peCrtlStat.bits.peReady = 0;
++
++		esp->esph = ip_esp_hdr(skb);
++		cdesc.srcAddr = (u32)esp->esph
++				+ sizeof(struct ip_esp_hdr) + ipsec->ivsize;
++		cdesc.dstAddr = (u32)esp->esph;
++
++		cdesc.peLength.bits.length = skb->len - sizeof(struct iphdr) -
++			sizeof(struct ip_esp_hdr) - ipsec->ivsize;
++	}
++
++	cdesc.saAddr = desc.saAddr;
++	cdesc.stateAddr = desc.stateAddr;
++	cdesc.arc4Addr = (uintptr_t)skb;
++	cdesc.userId = desc.userId;
++	cdesc.peLength.bits.peReady = 0;
++	cdesc.peLength.bits.byPass = 0;
++	cdesc.peLength.bits.hostReady = 1;
++again:
++	err = mtk_put_descriptor(mtk, &cdesc);
++	/* Should not happen 32 descriptors margin */
++	if (err) {
++		udelay(100);
++		goto again;
++	}
++
++	writel(1, mtk->base + EIP93_REG_PE_CD_COUNT);
++
++	return -EINPROGRESS;
++}
++
++static struct sk_buff *mtk_esp4_gro_receive(struct list_head *head,
++					struct sk_buff *skb)
++{
++	int offset = skb_gro_offset(skb);
++	struct xfrm_offload *xo;
++	struct xfrm_state *x;
++	__be32 seq;
++	__be32 spi;
++	int err;
++
++	if (!pskb_pull(skb, offset))
++		return NULL;
++
++	if ((err = xfrm_parse_spi(skb, IPPROTO_ESP, &spi, &seq)) != 0)
++		goto out;
++
++	xo = xfrm_offload(skb);
++	if (!xo || !(xo->flags & CRYPTO_DONE)) {
++		struct sec_path *sp = secpath_set(skb);
++
++		if (!sp)
++			goto out;
++
++		if (sp->len == XFRM_MAX_DEPTH)
++			goto out_reset;
++
++		x = xfrm_state_lookup(dev_net(skb->dev), skb->mark,
++				      (xfrm_address_t *)&ip_hdr(skb)->daddr,
++				      spi, IPPROTO_ESP, AF_INET);
++		if (!x)
++			goto out_reset;
++
++		skb->mark = xfrm_smark_get(skb->mark, x);
++
++		sp->xvec[sp->len++] = x;
++		sp->olen++;
++
++		xo = xfrm_offload(skb);
++		if (!xo)
++			goto out_reset;
++	}
++
++	xo->flags |= XFRM_GRO;
++
++	XFRM_TUNNEL_SKB_CB(skb)->tunnel.ip4 = NULL;
++	XFRM_SPI_SKB_CB(skb)->family = AF_INET;
++	XFRM_SPI_SKB_CB(skb)->daddroff = offsetof(struct iphdr, daddr);
++	XFRM_SPI_SKB_CB(skb)->seq = seq;
++
++	/* We don't need to handle errors from xfrm_input, it does all
++	 * the error handling and frees the resources on error. */
++	if (xo && x->xso.offload_handle) {
++		skb->ip_summed = CHECKSUM_NONE;
++		err = mtk_ipsec_offload(x, skb, NULL);
++	} else {
++		xfrm_input(skb, IPPROTO_ESP, spi, -2);
++	}
++
++	return ERR_PTR(-EINPROGRESS);
++out_reset:
++	secpath_reset(skb);
++out:
++	skb_push(skb, offset);
++	NAPI_GRO_CB(skb)->same_flow = 0;
++	NAPI_GRO_CB(skb)->flush = 1;
++
++	return NULL;
++}
++
++static void mtk_esp4_gso_encap(struct xfrm_state *x, struct sk_buff *skb)
++{
++	struct ip_esp_hdr *esph;
++	struct iphdr *iph = ip_hdr(skb);
++	struct xfrm_offload *xo = xfrm_offload(skb);
++	u8 proto = iph->protocol;
++
++	skb_push(skb, -skb_network_offset(skb));
++
++	esph = ip_esp_hdr(skb);
++	*skb_mac_header(skb) = IPPROTO_ESP;
++
++	esph->spi = x->id.spi;
++	esph->seq_no = htonl(XFRM_SKB_CB(skb)->seq.output.low);
++
++	xo->proto = proto;
++}
++
++static struct sk_buff *xfrm4_tunnel_gso_segment(struct xfrm_state *x,
++						struct sk_buff *skb,
++						netdev_features_t features)
++{
++	__skb_push(skb, skb->mac_len);
++	return skb_mac_gso_segment(skb, features);
++}
++
++static struct sk_buff *xfrm4_transport_gso_segment(struct xfrm_state *x,
++						   struct sk_buff *skb,
++						   netdev_features_t features)
++{
++	const struct net_offload *ops;
++	struct sk_buff *segs = ERR_PTR(-EINVAL);
++	struct xfrm_offload *xo = xfrm_offload(skb);
++
++	skb->transport_header += x->props.header_len;
++	ops = rcu_dereference(inet_offloads[xo->proto]);
++	if (likely(ops && ops->callbacks.gso_segment))
++		segs = ops->callbacks.gso_segment(skb, features);
++
++	return segs;
++}
++
++static struct sk_buff *xfrm4_beet_gso_segment(struct xfrm_state *x,
++					      struct sk_buff *skb,
++					      netdev_features_t features)
++{
++	struct xfrm_offload *xo = xfrm_offload(skb);
++	struct sk_buff *segs = ERR_PTR(-EINVAL);
++	const struct net_offload *ops;
++	u8 proto = xo->proto;
++
++	skb->transport_header += x->props.header_len;
++
++	if (x->sel.family != AF_INET6) {
++		if (proto == IPPROTO_BEETPH) {
++			struct ip_beet_phdr *ph =
++				(struct ip_beet_phdr *)skb->data;
++
++			skb->transport_header += ph->hdrlen * 8;
++			proto = ph->nexthdr;
++		} else {
++			skb->transport_header -= IPV4_BEET_PHMAXLEN;
++		}
++	} else {
++		__be16 frag;
++
++		skb->transport_header +=
++			ipv6_skip_exthdr(skb, 0, &proto, &frag);
++		if (proto == IPPROTO_TCP)
++			skb_shinfo(skb)->gso_type |= SKB_GSO_TCPV4;
++	}
++
++	__skb_pull(skb, skb_transport_offset(skb));
++	ops = rcu_dereference(inet_offloads[proto]);
++	if (likely(ops && ops->callbacks.gso_segment))
++		segs = ops->callbacks.gso_segment(skb, features);
++
++	return segs;
++}
++
++static struct sk_buff *xfrm4_outer_mode_gso_segment(struct xfrm_state *x,
++						    struct sk_buff *skb,
++						    netdev_features_t features)
++{
++	switch (x->outer_mode.encap) {
++	case XFRM_MODE_TUNNEL:
++		return xfrm4_tunnel_gso_segment(x, skb, features);
++	case XFRM_MODE_TRANSPORT:
++		return xfrm4_transport_gso_segment(x, skb, features);
++	case XFRM_MODE_BEET:
++		return xfrm4_beet_gso_segment(x, skb, features);
++	}
++
++	return ERR_PTR(-EOPNOTSUPP);
++}
++
++static struct sk_buff *mtk_esp4_gso_segment(struct sk_buff *skb,
++				        netdev_features_t features)
++{
++	struct xfrm_state *x;
++	struct ip_esp_hdr *esph;
++	struct crypto_aead *aead;
++	netdev_features_t esp_features = features;
++	struct xfrm_offload *xo = xfrm_offload(skb);
++	struct sec_path *sp;
++
++	if (!xo)
++		return ERR_PTR(-EINVAL);
++
++	if (!(skb_shinfo(skb)->gso_type & SKB_GSO_ESP))
++		return ERR_PTR(-EINVAL);
++
++	sp = skb_sec_path(skb);
++	x = sp->xvec[sp->len - 1];
++	aead = x->data;
++	esph = ip_esp_hdr(skb);
++
++	if (esph->spi != x->id.spi)
++		return ERR_PTR(-EINVAL);
++
++	if (!pskb_may_pull(skb, sizeof(*esph) + crypto_aead_ivsize(aead)))
++		return ERR_PTR(-EINVAL);
++
++	__skb_pull(skb, sizeof(*esph) + crypto_aead_ivsize(aead));
++
++	skb->encap_hdr_csum = 1;
++
++	if ((!(skb->dev->gso_partial_features & NETIF_F_HW_ESP) &&
++	     !(features & NETIF_F_HW_ESP)) || x->xso.dev != skb->dev)
++		esp_features = features & ~(NETIF_F_SG | NETIF_F_CSUM_MASK |
++					    NETIF_F_SCTP_CRC);
++	else if (!(features & NETIF_F_HW_ESP_TX_CSUM) &&
++		 !(skb->dev->gso_partial_features & NETIF_F_HW_ESP_TX_CSUM))
++		esp_features = features & ~(NETIF_F_CSUM_MASK |
++					    NETIF_F_SCTP_CRC);
++
++	xo->flags |= XFRM_GSO_SEGMENT;
++
++	return xfrm4_outer_mode_gso_segment(x, skb, esp_features);
++}
++
++static int mtk_esp_input_tail(struct xfrm_state *x, struct sk_buff *skb)
++{
++	struct crypto_aead *aead = x->data;
++	struct xfrm_offload *xo = xfrm_offload(skb);
++	const struct iphdr *iph;
++	int hlen;
++	int ihl;
++
++	if (xo && x->xso.offload_handle) {
++		hlen = sizeof(struct ip_esp_hdr) + crypto_aead_ivsize(x->data);
++		iph = ip_hdr(skb);
++		ihl = iph->ihl * 4;
++
++		skb_pull_rcsum(skb, hlen);
++		if (x->props.mode == XFRM_MODE_TUNNEL)
++			skb_reset_transport_header(skb);
++		else
++			skb_set_transport_header(skb, -ihl);
++
++		return xo->proto;
++	}
++
++	if (!pskb_may_pull(skb, sizeof(struct ip_esp_hdr) +
++						crypto_aead_ivsize(aead)))
++		return -EINVAL;
++
++	if (!(xo->flags & CRYPTO_DONE))
++		skb->ip_summed = CHECKSUM_NONE;
++
++	return esp_input_done2(skb, 0);
++}
++
++static int mtk_esp_xmit(struct xfrm_state *x, struct sk_buff *skb,
++			netdev_features_t features)
++{
++	int err;
++	int alen;
++	int blksize;
++	struct xfrm_offload *xo = xfrm_offload(skb);
++	struct ip_esp_hdr *esph;
++	struct esp_info esp;
++	struct crypto_aead *aead;
++	bool hw_offload = true;
++	__u32 seq;
++	int org_len;
++	struct ipsec_sa_entry *ipsec =
++				(struct ipsec_sa_entry *)x->xso.offload_handle;
++
++	if (!xo)
++		return -EINVAL;
++
++	if ((!(features & NETIF_F_HW_ESP) &&
++	     !(skb->dev->gso_partial_features & NETIF_F_HW_ESP)) ||
++	    x->xso.dev != skb->dev) {
++		xo->flags |= CRYPTO_FALLBACK;
++		hw_offload = false;
++	}
++
++	esp.inplace = true;
++	esp.proto = xo->proto;
++	esp.tfclen = 0;
++	esp.esph = ip_esp_hdr(skb);
++
++	if (hw_offload) {
++		esp.clen = ALIGN(skb->len + 2, ipsec->blksize);
++		esp.plen = esp.clen - skb->len;
++		esp.tailen = esp.plen + ipsec->authsize;
++	} else {
++		aead = x->data;
++		alen = crypto_aead_authsize(aead);
++		blksize = ALIGN(crypto_aead_blocksize(aead), 4);
++
++		esp.clen = ALIGN(skb->len + 2 + esp.tfclen, blksize);
++		esp.plen = esp.clen - skb->len - esp.tfclen;
++		esp.tailen = esp.tfclen + esp.plen + alen;
++	}
++
++	if  ((!hw_offload) || (esp.tailen > skb_tailroom(skb))) {
++		org_len = skb->len;
++		esp.nfrags = esp_output_head(x, skb, &esp);
++		if (esp.nfrags < 0)
++			return esp.nfrags;
++
++		err = skb_linearize(skb);
++		if (err)
++			return err;
++
++		if (hw_offload)
++			skb_put(skb, org_len - skb->len);
++	}
++
++	seq = xo->seq.low;
++
++	esph = esp.esph;
++	esph->spi = x->id.spi;
++
++	skb_push(skb, -skb_network_offset(skb));
++
++	if (xo->flags & XFRM_GSO_SEGMENT) {
++		esph->seq_no = htonl(seq);
++
++		if (!skb_is_gso(skb))
++			xo->seq.low++;
++		else
++			xo->seq.low += skb_shinfo(skb)->gso_segs;
++	}
++
++	esp.seqno = cpu_to_be64(seq + ((u64)xo->seq.hi << 32));
++
++	ip_hdr(skb)->tot_len = htons(skb->len);
++	ip_send_check(ip_hdr(skb));
++
++	if (hw_offload) {
++		if (!skb_ext_add(skb, SKB_EXT_SEC_PATH))
++			return -ENOMEM;
++
++		xo->flags |= XFRM_XMIT;
++		err = mtk_ipsec_offload(x, skb, &esp);
++
++		return err;
++	}
++
++	err = esp_output_tail(x, skb, &esp);
++	if (err)
++		return err;
++
++	secpath_reset(skb);
++
++	return 0;
++}
++
++static int ipsec_dev_event(struct notifier_block *this, unsigned long event, void *ptr)
++{
++	struct net_device *dev = netdev_notifier_info_to_dev(ptr);
++
++	switch (event) {
++	case NETDEV_REGISTER:
++		return mtk_add_xfrmops(dev);
++
++	case NETDEV_FEAT_CHANGE:
++		return mtk_add_xfrmops(dev);
++
++	case NETDEV_DOWN:
++	case NETDEV_UNREGISTER:
++		return mtk_del_xfrmops(dev);
++	}
++	return NOTIFY_DONE;
++}
++
++static struct notifier_block ipsec_dev_notifier = {
++	.notifier_call	= ipsec_dev_event,
++};
++
++static const struct net_offload mtk_esp4_offload = {
++	.callbacks = {
++		.gro_receive = mtk_esp4_gro_receive,
++		.gso_segment = mtk_esp4_gso_segment,
++	},
++};
++
++static struct xfrm_type_offload mtk_esp_offload = {
++	.owner		= THIS_MODULE,
++	.proto	     	= IPPROTO_ESP,
++	.input_tail	= mtk_esp_input_tail,
++	.xmit		= mtk_esp_xmit,
++	.encap		= mtk_esp4_gso_encap,
++};
++
++int mtk_offload_register(void)
++{
++	xfrm_register_type_offload(&mtk_esp_offload, AF_INET);
++
++	inet_add_offload(&mtk_esp4_offload, IPPROTO_ESP);
++
++	return register_netdevice_notifier(&ipsec_dev_notifier);
++}
++
++void mtk_offload_deregister(void)
++{
++	xfrm_unregister_type_offload(&mtk_esp_offload, AF_INET);
++
++	inet_del_offload(&mtk_esp4_offload, IPPROTO_ESP);
++}
++/*
++module_init(mtk_offload_register);
++module_exit(mtk_offload_deregister);
++MODULE_AUTHOR("Richard van Schagen <vschagen@icloud.com>");
++MODULE_ALIAS("platform:" KBUILD_MODNAME);
++MODULE_DESCRIPTION("Mediatek EIP-93 ESP Offload");
++MODULE_LICENSE("GPL v2");
++*/
+diff --git a/drivers/crypto/mtk-eip93/eip93-ipsec.h b/drivers/crypto/mtk-eip93/eip93-ipsec.h
+new file mode 100644
+index 0000000..9fc8f7a
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-ipsec.h
+@@ -0,0 +1,49 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2021 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <linux/skbuff.h>
++#include <net/esp.h>
++#include <net/xfrm.h>
++
++#include "eip93-main.h"
++#include "eip93-regs.h"
++
++#define MTK_IPSEC_CB(__skb) ((struct mtk_ipsec_results *)&((__skb)->cb[0]))
++
++struct ipsec_sa_entry {
++	struct mtk_device		*mtk;
++	struct saRecord_s		*sa;
++	dma_addr_t			sa_base;
++	struct crypto_shash		*shash;
++	int				blksize;
++	int				authsize;
++	int				ivsize;
++	struct eip93_descriptor_s	cdesc;
++};
++
++struct mtk_ipsec_results {
++	u32		cb;
++};
++
++struct mtk_ipsec_cb {
++	u32		org_cb;
++	dma_addr_t	dstAddr;
++	int 		err;
++	int		len;
++	u8		nexthdr;
++};
++
++int mtk_offload_register(void);
++
++void mtk_offload_deregister(void);
++
++int mtk_ipsec_offload(struct xfrm_state *x, struct sk_buff *skb,
++			struct esp_info *esp);
++
++void mtk_ipsec_rx_done(unsigned long data);
++
++void mtk_ipsec_tx_done(unsigned long data);
+diff --git a/drivers/crypto/mtk-eip93/eip93-main.c b/drivers/crypto/mtk-eip93/eip93-main.c
+new file mode 100644
+index 0000000..bded2c3
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-main.c
+@@ -0,0 +1,549 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <linux/atomic.h>
++#include <linux/clk.h>
++#include <linux/delay.h>
++#include <linux/dma-mapping.h>
++#include <linux/interrupt.h>
++#include <linux/module.h>
++#include <linux/of_device.h>
++#include <linux/platform_device.h>
++#include <linux/spinlock.h>
++
++#include "eip93-main.h"
++#include "eip93-regs.h"
++#include "eip93-common.h"
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER)
++#include "eip93-cipher.h"
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER_AES)
++#include "eip93-aes.h"
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER_DES)
++#include "eip93-des.h"
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AEAD)
++#include "eip93-aead.h"
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_PRNG)
++#include "eip93-prng.h"
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HASH)
++#include "eip93-hash.h"
++#include <crypto/sha2.h>
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC)
++#include "eip93-ipsec.h"
++#endif
++
++static struct mtk_alg_template *mtk_algs[] = {
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER_DES)
++	&mtk_alg_ecb_des,
++	&mtk_alg_cbc_des,
++	&mtk_alg_ecb_des3_ede,
++	&mtk_alg_cbc_des3_ede,
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER_AES)
++	&mtk_alg_ecb_aes,
++	&mtk_alg_cbc_aes,
++	&mtk_alg_ctr_aes,
++	&mtk_alg_rfc3686_aes,
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AEAD)
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES)
++	&mtk_alg_authenc_hmac_md5_cbc_des,
++	&mtk_alg_authenc_hmac_sha1_cbc_des,
++	&mtk_alg_authenc_hmac_sha224_cbc_des,
++	&mtk_alg_authenc_hmac_sha256_cbc_des,
++	&mtk_alg_authenc_hmac_md5_cbc_des3_ede,
++	&mtk_alg_authenc_hmac_sha1_cbc_des3_ede,
++	&mtk_alg_authenc_hmac_sha224_cbc_des3_ede,
++	&mtk_alg_authenc_hmac_sha256_cbc_des3_ede,
++#endif
++	&mtk_alg_authenc_hmac_md5_cbc_aes,
++	&mtk_alg_authenc_hmac_sha1_cbc_aes,
++	&mtk_alg_authenc_hmac_sha224_cbc_aes,
++	&mtk_alg_authenc_hmac_sha256_cbc_aes,
++	&mtk_alg_authenc_hmac_md5_rfc3686_aes,
++	&mtk_alg_authenc_hmac_sha1_rfc3686_aes,
++	&mtk_alg_authenc_hmac_sha224_rfc3686_aes,
++	&mtk_alg_authenc_hmac_sha256_rfc3686_aes,
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_PRNG)
++	&mtk_alg_prng,
++//	&mtk_alg_cprng,
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HASH)
++//	&mtk_alg_sha1,
++//	&mtk_alg_sha224,
++//	&mtk_alg_sha256,
++//	&mtk_alg_hmac_sha1,
++//	&mtk_alg_hmac_sha224,
++//	&mtk_alg_hmac_sha256,
++#endif
++};
++
++static void mtk_unregister_algs(unsigned int i)
++{
++	unsigned int j;
++
++	for (j = 0; j < i; j++) {
++		switch (mtk_algs[j]->type) {
++		case MTK_ALG_TYPE_SKCIPHER:
++			crypto_unregister_skcipher(&mtk_algs[j]->alg.skcipher);
++			break;
++		case MTK_ALG_TYPE_AEAD:
++			crypto_unregister_aead(&mtk_algs[j]->alg.aead);
++			break;
++		case MTK_ALG_TYPE_AHASH:
++			crypto_unregister_ahash(&mtk_algs[j]->alg.ahash);
++			break;
++		case MTK_ALG_TYPE_PRNG:
++			crypto_unregister_rng(&mtk_algs[j]->alg.rng);
++		}
++	}
++}
++
++static int mtk_register_algs(struct mtk_device *mtk)
++{
++	unsigned int i;
++	int err = 0;
++
++	for (i = 0; i < ARRAY_SIZE(mtk_algs); i++) {
++		mtk_algs[i]->mtk = mtk;
++
++		switch (mtk_algs[i]->type) {
++		case MTK_ALG_TYPE_SKCIPHER:
++			err = crypto_register_skcipher(&mtk_algs[i]->alg.skcipher);
++			break;
++		case MTK_ALG_TYPE_AEAD:
++			err = crypto_register_aead(&mtk_algs[i]->alg.aead);
++			break;
++		case MTK_ALG_TYPE_AHASH:
++			err = crypto_register_ahash(&mtk_algs[i]->alg.ahash);
++			break;
++		case MTK_ALG_TYPE_PRNG:
++			err = crypto_register_rng(&mtk_algs[i]->alg.rng);
++		}
++		if (err)
++			goto fail;
++	}
++
++	return 0;
++
++fail:
++	mtk_unregister_algs(i);
++
++	return err;
++}
++
++static void mtk_handle_result_descriptor(struct mtk_device *mtk)
++{
++	struct eip93_descriptor_s *rdesc;
++	bool last_entry;
++	u32 flags;
++	int handled, ready, err;
++	union peCrtlStat_w done1;
++	union peLength_w done2;
++
++get_more:
++	ready = readl(mtk->base + EIP93_REG_PE_RD_COUNT) & GENMASK(10, 0);
++
++	if (!ready) {
++		__raw_writel(EIP93_INT_PE_RDRTHRESH_REQ,
++					mtk->base + EIP93_REG_INT_CLR);
++		__raw_writel(EIP93_INT_PE_RDRTHRESH_REQ,
++					mtk->base + EIP93_REG_MASK_ENABLE);
++		return;
++	}
++
++	handled = 0;
++	last_entry = false;
++
++	while (ready) {
++		rdesc = mtk_get_descriptor(mtk);
++		if (IS_ERR(rdesc)) {
++			dev_err(mtk->dev, "Ndesc: %d nreq: %d\n",
++				handled, ready);
++			err = -EIO;
++			break;
++		}
++		/* make sure DMA is finished writing */
++		do {
++			done1.word = READ_ONCE(rdesc->peCrtlStat.word);
++			done2.word = READ_ONCE(rdesc->peLength.word);
++		} while ((!done1.bits.peReady) || (!done2.bits.peReady));
++
++//		writel(1, mtk->base + EIP93_REG_PE_RD_COUNT);
++		handled++;
++		ready--;
++		flags = rdesc->userId;
++
++		if (flags & MTK_DESC_LAST) {
++			err = rdesc->peCrtlStat.bits.errStatus;
++			last_entry = true;
++			break;
++		}
++	}
++
++	if (handled)
++		writel(handled, mtk->base + EIP93_REG_PE_RD_COUNT);
++
++	if (!last_entry)
++		goto get_more;
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_SKCIPHER)
++	if (flags & MTK_DESC_SKCIPHER)
++		mtk_skcipher_handle_result(
++			(struct skcipher_request *)rdesc->arc4Addr, err);
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AEAD)
++	if (flags & MTK_DESC_AEAD)
++		mtk_aead_handle_result(
++			(struct aead_request *)rdesc->arc4Addr, err);
++#endif
++//#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HASH)
++//	if (flags & MTK_DESC_AHASH)
++//		mtk_ahash_handle_result(async, err);
++//#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_PRNG)
++	if (flags & MTK_DESC_PRNG)
++		mtk_prng_done(mtk, err);
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC)
++	if (flags & MTK_DESC_IPSEC) {
++		struct mtk_ipsec_cb *mtk_ipsec_cb;
++		struct sk_buff *skb;
++
++		skb = (struct sk_buff *)rdesc->arc4Addr;
++		mtk_ipsec_cb = (struct mtk_ipsec_cb *)MTK_IPSEC_CB(skb)->cb;
++		mtk_ipsec_cb->dstAddr = (u32)rdesc->dstAddr;
++		mtk_ipsec_cb->len = rdesc->peLength.bits.length;
++		mtk_ipsec_cb->err = err;
++		mtk_ipsec_cb->nexthdr = rdesc->peCrtlStat.bits.padValue;
++		if (IS_DECRYPT(flags)) {
++			__skb_queue_tail(&mtk->ring->rx_queue, skb);
++			tasklet_hi_schedule(&mtk->ring->rx_task);
++		} else {
++			__skb_queue_tail(&mtk->ring->tx_queue, skb);
++			tasklet_hi_schedule(&mtk->ring->tx_task);
++		}
++	}
++#endif
++	goto get_more;
++}
++
++static void mtk_done_task(unsigned long data)
++{
++	struct mtk_device *mtk = (struct mtk_device *)data;
++
++	mtk_handle_result_descriptor(mtk);
++}
++
++static irqreturn_t mtk_irq_handler(int irq, void *dev_id)
++{
++	struct mtk_device *mtk = (struct mtk_device *)dev_id;
++	u32 irq_status;
++
++	irq_status = readl(mtk->base + EIP93_REG_INT_MASK_STAT);
++
++	if (irq_status & EIP93_INT_PE_RDRTHRESH_REQ) {
++		__raw_writel(EIP93_INT_PE_RDRTHRESH_REQ,
++					mtk->base + EIP93_REG_MASK_DISABLE);
++		tasklet_schedule(&mtk->ring->done_task);
++		return IRQ_HANDLED;
++	}
++
++	__raw_writel(irq_status, mtk->base + EIP93_REG_INT_CLR);
++	if (irq_status)
++		__raw_writel(irq_status, mtk->base + EIP93_REG_MASK_DISABLE);
++
++	return IRQ_NONE;
++}
++
++static void mtk_initialize(struct mtk_device *mtk)
++{
++	union peConfig_w peConfig;
++	union peEndianCfg_w peEndianCfg;
++	union peIntCfg_w peIntCfg;
++	union peClockCfg_w peClockCfg;
++	union peBufThresh_w peBufThresh;
++	union peRingThresh_w peRingThresh;
++
++	/* Reset Engine and setup Mode */
++	peConfig.word = 0;
++	peConfig.bits.resetPE = 1;
++	peConfig.bits.resetRing = 1;
++	peConfig.bits.peMode = 3;
++	peConfig.bits.enCDRupdate = 1;
++
++	writel(peConfig.word, mtk->base + EIP93_REG_PE_CONFIG);
++
++	udelay(10);
++
++	peConfig.bits.resetPE = 0;
++	peConfig.bits.resetRing = 0;
++
++	writel(peConfig.word, mtk->base + EIP93_REG_PE_CONFIG);
++
++	/* Initialize the BYTE_ORDER_CFG register */
++	peEndianCfg.word = 0;
++	writel(peEndianCfg.word, mtk->base + EIP93_REG_PE_ENDIAN_CONFIG);
++
++	/* Initialize the INT_CFG register */
++	peIntCfg.word = 0;
++	writel(peIntCfg.word, mtk->base + EIP93_REG_INT_CFG);
++
++	/* Config Clocks */
++	peClockCfg.word = 0;
++	peClockCfg.bits.enPEclk = 1;
++#if (IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_DES) || \
++				IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC))
++	peClockCfg.bits.enDESclk = 1;
++#endif
++#if (IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_AES) || \
++				IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC))
++	peClockCfg.bits.enAESclk = 1;
++#endif
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HMAC)
++	peClockCfg.bits.enHASHclk = 1;
++#endif
++	writel(peClockCfg.word, mtk->base + EIP93_REG_PE_CLOCK_CTRL);
++
++	/* Config DMA thresholds */
++	peBufThresh.word = 0;
++	peBufThresh.bits.inputBuffer  = 128;
++	peBufThresh.bits.outputBuffer = 128;
++
++	writel(peBufThresh.word, mtk->base + EIP93_REG_PE_BUF_THRESH);
++
++	/* Clear/ack all interrupts before disable all */
++	__raw_writel(0xFFFFFFFF, mtk->base + EIP93_REG_INT_CLR);
++	__raw_writel(0xFFFFFFFF, mtk->base + EIP93_REG_MASK_DISABLE);
++
++	/* Config Ring Threshold */
++	peRingThresh.word = 0;
++	peRingThresh.bits.CDRThresh = MTK_RING_SIZE - MTK_RING_BUSY;
++	peRingThresh.bits.RDRThresh = 0;
++	peRingThresh.bits.RDTimeout = 5;
++	peRingThresh.bits.enTimeout = 1;
++
++	writel(peRingThresh.word, mtk->base + EIP93_REG_PE_RING_THRESH);
++}
++
++static void mtk_desc_free(struct mtk_device *mtk)
++{
++	writel(0, mtk->base + EIP93_REG_PE_RING_CONFIG);
++	writel(0, mtk->base + EIP93_REG_PE_CDR_BASE);
++	writel(0, mtk->base + EIP93_REG_PE_RDR_BASE);
++}
++
++static int mtk_set_ring(struct mtk_device *mtk, struct mtk_desc_ring *ring,
++			int Offset)
++{
++	ring->offset = Offset;
++	ring->base = dmam_alloc_coherent(mtk->dev, Offset * MTK_RING_SIZE,
++					&ring->base_dma, GFP_KERNEL);
++	if (!ring->base)
++		return -ENOMEM;
++
++	ring->write = ring->base;
++	ring->base_end = ring->base + Offset * (MTK_RING_SIZE - 1);
++	ring->read  = ring->base;
++
++	return 0;
++}
++
++static int mtk_desc_init(struct mtk_device *mtk)
++{
++	struct mtk_state_pool *saState_pool;
++	struct mtk_desc_ring *cdr = &mtk->ring->cdr;
++	struct mtk_desc_ring *rdr = &mtk->ring->rdr;
++	union peRingCfg_w peRingCfg;
++	int RingOffset, err, i;
++
++	RingOffset = sizeof(struct eip93_descriptor_s);
++
++	err = mtk_set_ring(mtk, cdr, RingOffset);
++	if (err)
++		return err;
++
++	err = mtk_set_ring(mtk, rdr, RingOffset);
++	if (err)
++		return err;
++
++	writel((u32)cdr->base_dma, mtk->base + EIP93_REG_PE_CDR_BASE);
++	writel((u32)rdr->base_dma, mtk->base + EIP93_REG_PE_RDR_BASE);
++
++	peRingCfg.word = 0;
++	peRingCfg.bits.ringSize = MTK_RING_SIZE - 1;
++	peRingCfg.bits.ringOffset =  RingOffset / 4;
++
++	writel(peRingCfg.word, mtk->base + EIP93_REG_PE_RING_CONFIG);
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_HASH)
++	err = mtk_set_ring(mtk, hash_buf, RingOffset);
++	if (err)
++		return err;
++#endif
++	/* Create State record DMA pool */
++	RingOffset = sizeof(struct saState_s);
++	mtk->ring->saState = dmam_alloc_coherent(mtk->dev,
++					RingOffset * MTK_RING_SIZE,
++					&mtk->ring->saState_dma, GFP_KERNEL);
++	if (!mtk->ring->saState)
++		return -ENOMEM;
++
++	mtk->ring->saState_pool = devm_kcalloc(mtk->dev, 1,
++				sizeof(struct mtk_state_pool) * MTK_RING_SIZE,
++				GFP_KERNEL);
++
++	for (i = 0; i < MTK_RING_SIZE; i++) {
++		saState_pool = &mtk->ring->saState_pool[i];
++		saState_pool->base = mtk->ring->saState + (i * RingOffset);
++		saState_pool->base_dma = mtk->ring->saState_dma + (i * RingOffset);
++		saState_pool->in_use = false;
++	}
++
++	return 0;
++}
++
++static void mtk_cleanup(struct mtk_device *mtk)
++{
++	tasklet_kill(&mtk->ring->done_task);
++
++	/* Clear/ack all interrupts before disable all */
++	__raw_writel(0xFFFFFFFF, mtk->base + EIP93_REG_INT_CLR);
++	__raw_writel(0xFFFFFFFF, mtk->base + EIP93_REG_MASK_DISABLE);
++
++	writel(0, mtk->base + EIP93_REG_PE_CLOCK_CTRL);
++
++	mtk_desc_free(mtk);
++}
++
++static int mtk_crypto_probe(struct platform_device *pdev)
++{
++	struct device *dev = &pdev->dev;
++	struct mtk_device *mtk;
++	struct resource *res;
++	int err;
++
++	mtk = devm_kzalloc(dev, sizeof(*mtk), GFP_KERNEL);
++	if (!mtk)
++		return -ENOMEM;
++
++	mtk->dev = dev;
++	platform_set_drvdata(pdev, mtk);
++
++	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
++	mtk->base = devm_ioremap_resource(&pdev->dev, res);
++
++	if (IS_ERR(mtk->base))
++		return PTR_ERR(mtk->base);
++
++	mtk->irq = platform_get_irq(pdev, 0);
++
++	if (mtk->irq < 0)
++		return mtk->irq;
++
++	err = devm_request_threaded_irq(mtk->dev, mtk->irq, mtk_irq_handler,
++					NULL, IRQF_ONESHOT,
++					dev_name(mtk->dev), mtk);
++
++	mtk->ring = devm_kcalloc(mtk->dev, 1, sizeof(*mtk->ring), GFP_KERNEL);
++
++	if (!mtk->ring)
++		return -ENOMEM;
++
++	err = mtk_desc_init(mtk);
++	if (err)
++		return err;
++
++	tasklet_init(&mtk->ring->done_task, mtk_done_task, (unsigned long)mtk);
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC)
++	__skb_queue_head_init(&mtk->ring->rx_queue);
++	__skb_queue_head_init(&mtk->ring->tx_queue);
++
++	tasklet_init(&mtk->ring->rx_task, mtk_ipsec_rx_done,
++							(unsigned long)mtk);
++	tasklet_init(&mtk->ring->tx_task, mtk_ipsec_tx_done,
++							(unsigned long)mtk);
++#endif
++
++	spin_lock_init(&mtk->ring->read_lock);
++	spin_lock_init(&mtk->ring->write_lock);
++
++	mtk_initialize(mtk);
++
++	/* Init. finished, enable RDR interupt */
++	__raw_writel(EIP93_INT_PE_RDRTHRESH_REQ,
++					mtk->base + EIP93_REG_MASK_ENABLE);
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_PRNG)
++	mtk->prng = devm_kcalloc(mtk->dev, 1, sizeof(*mtk->prng), GFP_KERNEL);
++
++	if (!mtk->prng)
++		return -ENOMEM;
++
++	err = mtk_prng_init(mtk, true);
++#endif
++
++	err = mtk_register_algs(mtk);
++	if (err) {
++		mtk_cleanup(mtk);
++		return err;
++	}
++
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC)
++	err = mtk_offload_register();
++#endif
++
++	dev_info(mtk->dev, "EIP93 Crypto Engine Initialized.");
++
++	return 0;
++}
++
++static int mtk_crypto_remove(struct platform_device *pdev)
++{
++	struct mtk_device *mtk = platform_get_drvdata(pdev);
++
++	mtk_unregister_algs(ARRAY_SIZE(mtk_algs));
++#if IS_ENABLED(CONFIG_CRYPTO_DEV_EIP93_IPSEC)
++	mtk_offload_deregister();
++	tasklet_kill(&mtk->ring->rx_task);
++	tasklet_kill(&mtk->ring->tx_task);
++#endif
++	mtk_cleanup(mtk);
++	dev_info(mtk->dev, "EIP93 removed.\n");
++
++	return 0;
++}
++
++#if defined(CONFIG_OF)
++static const struct of_device_id mtk_crypto_of_match[] = {
++	{ .compatible = "mediatek,mtk-eip93", },
++	{}
++};
++MODULE_DEVICE_TABLE(of, mtk_crypto_of_match);
++#endif
++
++static struct platform_driver mtk_crypto_driver = {
++	.probe = mtk_crypto_probe,
++	.remove = mtk_crypto_remove,
++	.driver = {
++		.name = "mtk-eip93",
++		.of_match_table = of_match_ptr(mtk_crypto_of_match),
++	},
++};
++module_platform_driver(mtk_crypto_driver);
++
++MODULE_AUTHOR("Richard van Schagen <vschagen@cs.com>");
++MODULE_ALIAS("platform:" KBUILD_MODNAME);
++MODULE_DESCRIPTION("Mediatek EIP-93 crypto engine driver");
++MODULE_LICENSE("GPL v2");
+diff --git a/drivers/crypto/mtk-eip93/eip93-main.h b/drivers/crypto/mtk-eip93/eip93-main.h
+new file mode 100644
+index 0000000..18d0151
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-main.h
+@@ -0,0 +1,168 @@
++/* SPDX-License-Identifier: GPL-2.0
++ *
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#ifndef _EIP93_MAIN_H_
++#define _EIP93_MAIN_H_
++
++#include <crypto/internal/aead.h>
++#include <crypto/internal/hash.h>
++#include <crypto/internal/rng.h>
++#include <crypto/internal/skcipher.h>
++#include <linux/device.h>
++#include <linux/skbuff.h>
++
++#define MTK_RING_SIZE			1024
++#define MTK_RING_BUSY			32
++#define MTK_CRA_PRIORITY		1500
++
++/* cipher algorithms */
++#define MTK_ALG_DES			BIT(0)
++#define MTK_ALG_3DES			BIT(1)
++#define MTK_ALG_AES			BIT(2)
++#define MTK_ALG_MASK			GENMASK(2, 0)
++/* hash and hmac algorithms */
++#define MTK_HASH_MD5			BIT(3)
++#define MTK_HASH_SHA1			BIT(4)
++#define MTK_HASH_SHA224			BIT(5)
++#define MTK_HASH_SHA256			BIT(6)
++#define MTK_HASH_HMAC			BIT(7)
++#define MTK_HASH_MASK			GENMASK(6, 3)
++/* cipher modes */
++#define MTK_MODE_CBC			BIT(8)
++#define MTK_MODE_ECB			BIT(9)
++#define MTK_MODE_CTR			BIT(10)
++#define MTK_MODE_RFC3686		BIT(11)
++#define MTK_MODE_MASK			GENMASK(10, 8)
++
++/* cipher encryption/decryption operations */
++#define MTK_ENCRYPT			BIT(12)
++#define MTK_DECRYPT			BIT(13)
++
++#define MTK_BUSY			BIT(14)
++
++/* descriptor flags */
++#define MTK_DESC_ASYNC			BIT(31)
++#define MTK_DESC_SKCIPHER		BIT(30)
++#define MTK_DESC_AEAD			BIT(29)
++#define MTK_DESC_AHASH			BIT(28)
++#define MTK_DESC_PRNG			BIT(27)
++#define MTK_DESC_FAKE_HMAC		BIT(26)
++#define MTK_DESC_LAST			BIT(25)
++#define MTK_DESC_FINISH			BIT(24)
++#define MTK_DESC_IPSEC			BIT(23)
++#define MTK_DESC_DMA_IV			BIT(22)
++
++#define IS_DES(flags)			(flags & MTK_ALG_DES)
++#define IS_3DES(flags)			(flags & MTK_ALG_3DES)
++#define IS_AES(flags)			(flags & MTK_ALG_AES)
++
++#define IS_HASH_MD5(flags)		(flags & MTK_HASH_MD5)
++#define IS_HASH_SHA1(flags)		(flags & MTK_HASH_SHA1)
++#define IS_HASH_SHA224(flags)		(flags & MTK_HASH_SHA224)
++#define IS_HASH_SHA256(flags)		(flags & MTK_HASH_SHA256)
++#define IS_HMAC(flags)			(flags & MTK_HASH_HMAC)
++
++#define IS_CBC(mode)			(mode & MTK_MODE_CBC)
++#define IS_ECB(mode)			(mode & MTK_MODE_ECB)
++#define IS_CTR(mode)			(mode & MTK_MODE_CTR)
++#define IS_RFC3686(mode)		(mode & MTK_MODE_RFC3686)
++
++#define IS_BUSY(flags)			(flags & MTK_BUSY)
++#define IS_DMA_IV(flags)		(flags & MTK_DESC_DMA_IV)
++
++#define IS_ENCRYPT(dir)			(dir & MTK_ENCRYPT)
++#define IS_DECRYPT(dir)			(dir & MTK_DECRYPT)
++
++#define IS_CIPHER(flags)		(flags & (MTK_ALG_DES || \
++						MTK_ALG_3DES ||  \
++						MTK_ALG_AES))
++
++#define IS_HASH(flags)			(flags & (MTK_HASH_MD5 ||  \
++						MTK_HASH_SHA1 ||   \
++						MTK_HASH_SHA224 || \
++						MTK_HASH_SHA256))
++
++/**
++ * struct mtk_device - crypto engine device structure
++ */
++struct mtk_device {
++	void __iomem		*base;
++	struct device		*dev;
++	struct clk		*clk;
++	int			irq;
++	struct mtk_ring		*ring;
++	struct mtk_state_pool	*saState_pool;
++	struct mtk_prng_device	*prng;
++};
++
++struct mtk_prng_device {
++	struct saRecord_s	*PRNGSaRecord;
++	dma_addr_t		PRNGSaRecord_dma;
++	void			*PRNGBuffer[2];
++	dma_addr_t		PRNGBuffer_dma[2];
++	uint32_t		cur_buf;
++	struct completion	Filled;
++	atomic_t		State;
++};
++
++struct mtk_desc_ring {
++	void			*base;
++	void			*base_end;
++	dma_addr_t		base_dma;
++	/* write and read pointers */
++	void			*read;
++	void			*write;
++	/* descriptor element offset */
++	u32			offset;
++};
++
++struct mtk_state_pool {
++	void			*base;
++	dma_addr_t		base_dma;
++	bool			in_use;
++};
++
++struct mtk_ring {
++	struct tasklet_struct		done_task;
++	/* command/result rings */
++	struct mtk_desc_ring		cdr;
++	struct mtk_desc_ring		rdr;
++	spinlock_t			write_lock;
++	spinlock_t			read_lock;
++	/* saState */
++	struct mtk_state_pool		*saState_pool;
++	void				*saState;
++	dma_addr_t			saState_dma;
++	/* Hash buffers */
++	struct mtk_desc_ring		hash_buf;
++	/* IPSec */
++	struct tasklet_struct		rx_task;
++	struct tasklet_struct		tx_task;
++	/* queue */
++	struct sk_buff_head		rx_queue;
++	struct sk_buff_head		tx_queue;
++};
++
++enum mtk_alg_type {
++	MTK_ALG_TYPE_AEAD,
++	MTK_ALG_TYPE_AHASH,
++	MTK_ALG_TYPE_SKCIPHER,
++	MTK_ALG_TYPE_PRNG,
++};
++
++struct mtk_alg_template {
++	struct mtk_device	*mtk;
++	enum mtk_alg_type	type;
++	u32			flags;
++	union {
++		struct aead_alg		aead;
++		struct ahash_alg	ahash;
++		struct skcipher_alg	skcipher;
++		struct rng_alg		rng;
++	} alg;
++};
++
++#endif /* _EIP93_MAIN_H_ */
+diff --git a/drivers/crypto/mtk-eip93/eip93-prng.c b/drivers/crypto/mtk-eip93/eip93-prng.c
+new file mode 100644
+index 0000000..aa1e884
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-prng.c
+@@ -0,0 +1,358 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2021
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++
++#include <linux/dma-mapping.h>
++
++#include "eip93-common.h"
++#include "eip93-main.h"
++#include "eip93-regs.h"
++#include "eip93-prng.h"
++
++static int mtk_prng_push_job(struct mtk_device *mtk, bool reset)
++{
++	struct mtk_prng_device *prng = mtk->prng;
++	struct eip93_descriptor_s cdesc;
++	int cur = prng->cur_buf;
++	int len, mode, err;
++
++	if (reset) {
++		len = 0;
++		mode = 1;
++	} else {
++		len = 4080;
++		mode = 2;
++	}
++
++	init_completion(&prng->Filled);
++	atomic_set(&prng->State, BUF_EMPTY);
++
++	memset(&cdesc, 0, sizeof(struct eip93_descriptor_s));
++	cdesc.peCrtlStat.bits.hostReady = 1;
++	cdesc.peCrtlStat.bits.prngMode = mode;
++	cdesc.peCrtlStat.bits.hashFinal = 0;
++	cdesc.peCrtlStat.bits.padCrtlStat = 0;
++	cdesc.peCrtlStat.bits.peReady = 0;
++	cdesc.srcAddr = 0;
++	cdesc.dstAddr = prng->PRNGBuffer_dma[cur];
++	cdesc.saAddr = prng->PRNGSaRecord_dma;
++	cdesc.stateAddr = 0;
++	cdesc.arc4Addr = 0;
++	cdesc.userId = MTK_DESC_PRNG | MTK_DESC_LAST | MTK_DESC_FINISH;
++	cdesc.peLength.bits.byPass = 0;
++	cdesc.peLength.bits.length = 4080;
++	cdesc.peLength.bits.hostReady = 1;
++
++	err = mtk_put_descriptor(mtk, &cdesc);
++	/* TODO error handling */
++	if (err)
++		dev_err(mtk->dev, "PRNG: No Descriptor space");
++
++	writel(1, mtk->base + EIP93_REG_PE_CD_COUNT);
++
++	wait_for_completion(&prng->Filled);
++
++//	if (atomic_read(&prng->State) == PRNG_NEED_RESET)
++//		return false;
++
++	return true;
++}
++
++/*----------------------------------------------------------------------------
++ * mtk_prng_init
++ *
++ * This function initializes the PE PRNG for the ARM mode.
++ *
++ * Return Value
++ *      true: PRNG is initialized
++ *     false: PRNG initialization failed
++ */
++bool mtk_prng_init(struct mtk_device *mtk, bool fLongSA)
++{
++	struct mtk_prng_device *prng = mtk->prng;
++	int i, ret;
++	struct saRecord_s *saRecord;
++	const uint32_t PRNGKey[]  = {0xe0fc631d, 0xcbb9fb9a,
++					0x869285cb, 0xcbb9fb9a};
++	const uint32_t PRNGSeed[]  = {0x758bac03, 0xf20ab39e,
++					0xa569f104, 0x95dfaea6};
++	const uint32_t PRNGDateTime[] = {0, 0, 0, 0};
++
++	if (!mtk)
++		return -ENODEV;
++
++	prng->cur_buf = 0;
++	/* TODO: check to kzalloc and create free after remove */
++	prng->PRNGBuffer[0] = devm_kzalloc(mtk->dev, 4080, GFP_KERNEL);
++	prng->PRNGBuffer_dma[0] = (u32)dma_map_single(mtk->dev,
++				(void *)prng->PRNGBuffer[0],
++				4080, DMA_FROM_DEVICE);
++
++	prng->PRNGBuffer[1] = devm_kzalloc(mtk->dev, 4080, GFP_KERNEL);
++	prng->PRNGBuffer_dma[1] = (u32)dma_map_single(mtk->dev,
++				(void *)prng->PRNGBuffer[1],
++				4080, DMA_FROM_DEVICE);
++
++	prng->PRNGSaRecord = dmam_alloc_coherent(mtk->dev,
++				sizeof(struct saRecord_s),
++				&prng->PRNGSaRecord_dma, GFP_KERNEL);
++
++	if (!prng->PRNGSaRecord) {
++		dev_err(mtk->dev, "PRNG dma_alloc for saRecord failed\n");
++		return -ENOMEM;
++	}
++
++	saRecord = &prng->PRNGSaRecord[0];
++
++	saRecord->saCmd0.word = 0x00001307;
++	saRecord->saCmd1.word = 0x02000000;
++
++	for (i = 0; i < 4; i++) {
++		saRecord->saKey[i] = PRNGKey[i];
++		saRecord->saIDigest[i] = PRNGSeed[i];
++		saRecord->saODigest[i] = PRNGDateTime[i];
++	}
++
++	return mtk_prng_push_job(mtk, true);
++}
++
++void mtk_prng_done(struct mtk_device *mtk, u32 err)
++{
++	struct mtk_prng_device *prng = mtk->prng;
++	int cur = prng->cur_buf;
++
++	if (err) {
++		dev_err(mtk->dev, "PRNG error: %d\n", err);
++		atomic_set(&prng->State, PRNG_NEED_RESET);
++	}
++
++	/* Buffer refilled, invalidate cache */
++	dma_unmap_single(mtk->dev, prng->PRNGBuffer_dma[cur],
++							4080, DMA_FROM_DEVICE);
++
++	complete(&prng->Filled);
++}
++
++static int get_prng_bytes(char *buf, size_t nbytes, struct mtk_prng_ctx *ctx,
++				int do_cont_test)
++{
++	int err;
++
++	spin_lock(&ctx->prng_lock);
++
++	err = -EINVAL;
++	if (ctx->flags & PRNG_NEED_RESET)
++		goto done;
++
++done:
++	spin_unlock(&ctx->prng_lock);
++	return err;
++}
++
++static int mtk_prng_generate(struct crypto_rng *tfm, const u8 *src,
++			   unsigned int slen, u8 *dst, unsigned int dlen)
++{
++	struct mtk_prng_ctx *prng = crypto_rng_ctx(tfm);
++
++	return get_prng_bytes(dst, dlen, prng, 1);
++}
++
++static int mtk_prng_seed(struct crypto_rng *tfm, const u8 *seed,
++		       unsigned int slen)
++{
++	struct rng_alg *alg = crypto_rng_alg(tfm);
++	struct mtk_alg_template *tmpl = container_of(alg,
++				struct mtk_alg_template, alg.rng);
++	struct mtk_device *mtk = tmpl->mtk;
++
++	return 0;
++}
++
++static bool mtk_prng_fill_buffer(struct mtk_device *mtk)
++{
++	struct mtk_prng_device *prng = mtk->prng;
++	int cur = prng->cur_buf;
++	int ret;
++
++	if (!mtk)
++		return -ENODEV;
++
++	/* add logic for 2 buffers and swap */
++	prng->PRNGBuffer_dma[cur] = (u32)dma_map_single(mtk->dev,
++					(void *)prng->PRNGBuffer[cur],
++					4080, DMA_FROM_DEVICE);
++
++	ret = mtk_prng_push_job(mtk, false);
++
++	return ret;
++}
++
++static int reset_prng_context(struct mtk_prng_ctx *ctx,
++				const unsigned char *key,
++				const unsigned char *V,
++				const unsigned char *DT)
++{
++	spin_lock_bh(&ctx->prng_lock);
++	ctx->flags |= PRNG_NEED_RESET;
++
++	if (key)
++		memcpy(ctx->PRNGKey, key, DEFAULT_PRNG_KSZ);
++	else
++		memcpy(ctx->PRNGKey, DEFAULT_PRNG_KEY, DEFAULT_PRNG_KSZ);
++
++
++	if (V)
++		memcpy(ctx->PRNGSeed, V, DEFAULT_BLK_SZ);
++	else
++		memcpy(ctx->PRNGSeed, DEFAULT_V_SEED, DEFAULT_BLK_SZ);
++
++	if (DT)
++		memcpy(ctx->PRNGDateTime, DT, DEFAULT_BLK_SZ);
++	else
++		memset(ctx->PRNGDateTime, 0, DEFAULT_BLK_SZ);
++
++	memset(ctx->rand_data, 0, DEFAULT_BLK_SZ);
++	memset(ctx->last_rand_data, 0, DEFAULT_BLK_SZ);
++
++	ctx->rand_data_valid = DEFAULT_BLK_SZ;
++
++	ctx->flags &= ~PRNG_NEED_RESET;
++	spin_unlock_bh(&ctx->prng_lock);
++
++	return 0;
++}
++
++/*
++ *  This is the cprng_registered reset method the seed value is
++ *  interpreted as the tuple { V KEY DT}
++ *  V and KEY are required during reset, and DT is optional, detected
++ *  as being present by testing the length of the seed
++ */
++static int cprng_reset(struct crypto_rng *tfm,
++		       const u8 *seed, unsigned int slen)
++{
++	struct mtk_prng_ctx *prng = crypto_rng_ctx(tfm);
++	const u8 *key = seed + DEFAULT_BLK_SZ;
++	const u8 *dt = NULL;
++
++	if (slen < DEFAULT_PRNG_KSZ + DEFAULT_BLK_SZ)
++		return -EINVAL;
++
++	if (slen >= (2 * DEFAULT_BLK_SZ + DEFAULT_PRNG_KSZ))
++		dt = key + DEFAULT_PRNG_KSZ;
++
++	reset_prng_context(prng, key, seed, dt);
++
++	if (prng->flags & PRNG_NEED_RESET)
++		return -EINVAL;
++	return 0;
++}
++
++
++static void free_prng_context(struct mtk_prng_ctx *ctx)
++{
++	crypto_free_cipher(ctx->tfm);
++}
++
++static int cprng_init(struct crypto_tfm *tfm)
++{
++	struct mtk_prng_ctx *ctx = crypto_tfm_ctx(tfm);
++
++	spin_lock_init(&ctx->prng_lock);
++
++	if (reset_prng_context(ctx, NULL, NULL, NULL) < 0)
++		return -EINVAL;
++
++	/*
++	 * after allocation, we should always force the user to reset
++	 * so they don't inadvertently use the insecure default values
++	 * without specifying them intentially
++	 */
++	ctx->flags |= PRNG_NEED_RESET;
++	return 0;
++}
++
++static void cprng_exit(struct crypto_tfm *tfm)
++{
++	free_prng_context(crypto_tfm_ctx(tfm));
++}
++
++struct mtk_alg_template mtk_alg_prng = {
++	.type = MTK_ALG_TYPE_PRNG,
++	.flags = 0,
++	.alg.rng = {
++		.generate = mtk_prng_generate,
++		.seed = mtk_prng_seed,
++		.seedsize = 0,
++		.base = {
++			.cra_name = "stdrng",
++			.cra_driver_name = "eip93-prng",
++			.cra_priority = 200,
++			.cra_ctxsize = sizeof(struct mtk_prng_ctx),
++			.cra_module = THIS_MODULE,
++			.cra_init = cprng_init,
++			.cra_exit = cprng_exit,
++		},
++	},
++};
++
++//#if IS_ENABLED(CONFIG_CRYPTO_FIPS
++static int fips_cprng_get_random(struct crypto_rng *tfm,
++				 const u8 *src, unsigned int slen,
++				 u8 *rdata, unsigned int dlen)
++{
++	struct mtk_prng_ctx *prng = crypto_rng_ctx(tfm);
++
++	return get_prng_bytes(rdata, dlen, prng, 1);
++}
++
++static int fips_cprng_reset(struct crypto_rng *tfm,
++			    const u8 *seed, unsigned int slen)
++{
++	struct mtk_prng_ctx *prng = crypto_rng_ctx(tfm);
++	u8 rdata[DEFAULT_BLK_SZ];
++	const u8 *key = seed + DEFAULT_BLK_SZ;
++	int rc;
++
++	if (slen < DEFAULT_PRNG_KSZ + DEFAULT_BLK_SZ)
++		return -EINVAL;
++
++	/* fips strictly requires seed != key */
++	if (!memcmp(seed, key, DEFAULT_PRNG_KSZ))
++		return -EINVAL;
++
++	rc = cprng_reset(tfm, seed, slen);
++
++	if (!rc)
++		goto out;
++
++	/* this primes our continuity test */
++	rc = get_prng_bytes(rdata, DEFAULT_BLK_SZ, prng, 0);
++	prng->rand_data_valid = DEFAULT_BLK_SZ;
++
++out:
++	return rc;
++}
++
++struct mtk_alg_template mtk_alg_cprng = {
++	.type = MTK_ALG_TYPE_PRNG,
++	.flags = 0,
++	.alg.rng = {
++		.generate = fips_cprng_get_random,
++		.seed = fips_cprng_reset,
++		.seedsize = DEFAULT_PRNG_KSZ + 2 * DEFAULT_BLK_SZ,
++		.base = {
++			.cra_name = "fips(ansi_cprng)",
++			.cra_driver_name = "eip93-fips_ansi_cprng",
++			.cra_priority = 300,
++			.cra_ctxsize = sizeof(struct mtk_prng_ctx),
++			.cra_module = THIS_MODULE,
++			.cra_init = cprng_init,
++			.cra_exit = cprng_exit,
++		},
++	},
++};
++//#endif
+diff --git a/drivers/crypto/mtk-eip93/eip93-prng.h b/drivers/crypto/mtk-eip93/eip93-prng.h
+new file mode 100644
+index 0000000..064bed1
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-prng.h
+@@ -0,0 +1,34 @@
++// SPDX-License-Identifier: GPL-2.0
++/*
++ * Copyright (C) 2019 - 2021
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#define DEFAULT_PRNG_KEY "0123456789abcdef"
++#define DEFAULT_PRNG_KSZ 16
++#define DEFAULT_BLK_SZ 16
++#define DEFAULT_V_SEED "zaybxcwdveuftgsh"
++
++#define BUF_NOT_EMPTY 0
++#define BUF_EMPTY 1
++#define BUF_PENDING 2
++#define PRNG_NEED_RESET 3
++
++extern struct mtk_alg_template mtk_alg_prng;
++extern struct mtk_alg_template mtk_alg_cprng;
++
++bool mtk_prng_init(struct mtk_device *mtk, bool fLongSA);
++
++void mtk_prng_done(struct mtk_device *mtk, u32 err);
++
++struct mtk_prng_ctx {
++	spinlock_t		prng_lock;
++	unsigned char		rand_data[DEFAULT_BLK_SZ];
++	unsigned char		last_rand_data[DEFAULT_BLK_SZ];
++	uint32_t		PRNGKey[4];
++	uint32_t		PRNGSeed[4];
++	uint32_t		PRNGDateTime[4];
++	struct crypto_cipher	*tfm;
++	uint32_t		rand_data_valid;
++	uint32_t		flags;
++};
+diff --git a/drivers/crypto/mtk-eip93/eip93-regs.h b/drivers/crypto/mtk-eip93/eip93-regs.h
+new file mode 100644
+index 0000000..4ee07fb
+--- /dev/null
++++ b/drivers/crypto/mtk-eip93/eip93-regs.h
+@@ -0,0 +1,382 @@
++/* SPDX-License-Identifier: GPL-2.0 */
++/*
++ * Copyright (C) 2019 - 2022
++ *
++ * Richard van Schagen <vschagen@icloud.com>
++ */
++#ifndef REG_EIP93_H
++#define REG_EIP93_H
++
++#define EIP93_REG_WIDTH			4
++/*-----------------------------------------------------------------------------
++ * Register Map
++ */
++#define DESP_BASE			0x0000000
++#define EIP93_REG_PE_CTRL_STAT		((DESP_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_SOURCE_ADDR	((DESP_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_DEST_ADDR		((DESP_BASE)+(0x02 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_SA_ADDR		((DESP_BASE)+(0x03 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_ADDR		((DESP_BASE)+(0x04 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_USER_ID		((DESP_BASE)+(0x06 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_LENGTH		((DESP_BASE)+(0x07 * EIP93_REG_WIDTH))
++
++//PACKET ENGINE RING configuration registers
++#define PE_RNG_BASE			0x0000080
++
++#define EIP93_REG_PE_CDR_BASE		((PE_RNG_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_RDR_BASE		((PE_RNG_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_RING_CONFIG	((PE_RNG_BASE)+(0x02 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_RING_THRESH	((PE_RNG_BASE)+(0x03 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_CD_COUNT		((PE_RNG_BASE)+(0x04 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_RD_COUNT		((PE_RNG_BASE)+(0x05 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_RING_RW_PNTR	((PE_RNG_BASE)+(0x06 * EIP93_REG_WIDTH))
++
++//PACKET ENGINE  configuration registers
++#define PE_CFG_BASE			0x0000100
++#define EIP93_REG_PE_CONFIG		((PE_CFG_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_STATUS		((PE_CFG_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_BUF_THRESH		((PE_CFG_BASE)+(0x03 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_INBUF_COUNT	((PE_CFG_BASE)+(0x04 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_OUTBUF_COUNT	((PE_CFG_BASE)+(0x05 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_BUF_RW_PNTR	((PE_CFG_BASE)+(0x06 * EIP93_REG_WIDTH))
++
++//PACKET ENGINE endian config
++#define EN_CFG_BASE			0x00001CC
++#define EIP93_REG_PE_ENDIAN_CONFIG	((EN_CFG_BASE)+(0x00 * EIP93_REG_WIDTH))
++
++//EIP93 CLOCK control registers
++#define CLOCK_BASE			0x01E8
++#define EIP93_REG_PE_CLOCK_CTRL		((CLOCK_BASE)+(0x00 * EIP93_REG_WIDTH))
++
++//EIP93 Device Option and Revision Register
++#define REV_BASE			0x01F4
++#define EIP93_REG_PE_OPTION_1		((REV_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_OPTION_0		((REV_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_PE_REVISION		((REV_BASE)+(0x02 * EIP93_REG_WIDTH))
++
++//EIP93 Interrupt Control Register
++#define INT_BASE			0x0200
++#define EIP93_REG_INT_UNMASK_STAT	((INT_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_INT_MASK_STAT		((INT_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_INT_CLR		((INT_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_INT_MASK		((INT_BASE)+(0x02 * EIP93_REG_WIDTH))
++#define EIP93_REG_INT_CFG		((INT_BASE)+(0x03 * EIP93_REG_WIDTH))
++#define EIP93_REG_MASK_ENABLE		((INT_BASE)+(0X04 * EIP93_REG_WIDTH))
++#define EIP93_REG_MASK_DISABLE		((INT_BASE)+(0X05 * EIP93_REG_WIDTH))
++
++//EIP93 SA Record register
++#define SA_BASE				0x0400
++#define EIP93_REG_SA_CMD_0		((SA_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_SA_CMD_1		((SA_BASE)+(0x01 * EIP93_REG_WIDTH))
++
++//#define EIP93_REG_SA_READY		((SA_BASE)+(31 * EIP93_REG_WIDTH))
++
++//State save register
++#define STATE_BASE			0x0500
++#define EIP93_REG_STATE_IV_0		((STATE_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_STATE_IV_1		((STATE_BASE)+(0x01 * EIP93_REG_WIDTH))
++
++#define EIP93_PE_ARC4STATE_BASEADDR_REG	0x0700
++
++//RAM buffer start address
++#define EIP93_INPUT_BUFFER		0x0800
++#define EIP93_OUTPUT_BUFFER		0x0800
++
++//EIP93 PRNG Configuration Register
++#define PRNG_BASE			0x0300
++#define EIP93_REG_PRNG_STAT		((PRNG_BASE)+(0x00 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_CTRL		((PRNG_BASE)+(0x01 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_SEED_0		((PRNG_BASE)+(0x02 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_SEED_1		((PRNG_BASE)+(0x03 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_SEED_2		((PRNG_BASE)+(0x04 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_SEED_3		((PRNG_BASE)+(0x05 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_KEY_0		((PRNG_BASE)+(0x06 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_KEY_1		((PRNG_BASE)+(0x07 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_KEY_2		((PRNG_BASE)+(0x08 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_KEY_3		((PRNG_BASE)+(0x09 * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_RES_0		((PRNG_BASE)+(0x0A * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_RES_1		((PRNG_BASE)+(0x0B * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_RES_2		((PRNG_BASE)+(0x0C * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_RES_3		((PRNG_BASE)+(0x0D * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_LFSR_0		((PRNG_BASE)+(0x0E * EIP93_REG_WIDTH))
++#define EIP93_REG_PRNG_LFSR_1		((PRNG_BASE)+(0x0F * EIP93_REG_WIDTH))
++
++/*-----------------------------------------------------------------------------
++ * Constants & masks
++ */
++
++#define EIP93_SUPPORTED_INTERRUPTS_MASK	0xffff7f00
++#define EIP93_PRNG_DT_TEXT_LOWERHALF	0xDEAD
++#define EIP93_PRNG_DT_TEXT_UPPERHALF	0xC0DE
++#define EIP93_10BITS_MASK		0X3FF
++#define EIP93_12BITS_MASK		0XFFF
++#define EIP93_4BITS_MASK		0X04
++#define EIP93_20BITS_MASK		0xFFFFF
++
++#define EIP93_MIN_DESC_DONE_COUNT	0
++#define EIP93_MAX_DESC_DONE_COUNT	15
++
++#define EIP93_MIN_DESC_PENDING_COUNT	0
++#define EIP93_MAX_DESC_PENDING_COUNT	1023
++
++#define EIP93_MIN_TIMEOUT_COUNT		0
++#define EIP93_MAX_TIMEOUT_COUNT		15
++
++#define EIP93_MIN_PE_INPUT_THRESHOLD	1
++#define EIP93_MAX_PE_INPUT_THRESHOLD	511
++
++#define EIP93_MIN_PE_OUTPUT_THRESHOLD	1
++#define EIP93_MAX_PE_OUTPUT_THRESHOLD	432
++
++#define EIP93_MIN_PE_RING_SIZE		1
++#define EIP93_MAX_PE_RING_SIZE		1023
++
++#define EIP93_MIN_PE_DESCRIPTOR_SIZE	7
++#define EIP93_MAX_PE_DESCRIPTOR_SIZE	15
++
++//3DES keys,seed,known data and its result
++#define EIP93_KEY_0			0x133b3454
++#define EIP93_KEY_1			0x5e5b890b
++#define EIP93_KEY_2			0x5eb30757
++#define EIP93_KEY_3			0x93ab15f7
++#define EIP93_SEED_0			0x62c4bf5e
++#define EIP93_SEED_1			0x972667c8
++#define EIP93_SEED_2			0x6345bf67
++#define EIP93_SEED_3			0xcb3482bf
++#define EIP93_LFSR_0			0xDEADC0DE
++#define EIP93_LFSR_1			0xBEEFF00D
++
++/*-----------------------------------------------------------------------------
++ * EIP93 device initialization specifics
++ */
++
++/*----------------------------------------------------------------------------
++ * Byte Order Reversal Mechanisms Supported in EIP93
++ * EIP93_BO_REVERSE_HALF_WORD : reverse the byte order within a half-word
++ * EIP93_BO_REVERSE_WORD :  reverse the byte order within a word
++ * EIP93_BO_REVERSE_DUAL_WORD : reverse the byte order within a dual-word
++ * EIP93_BO_REVERSE_QUAD_WORD : reverse the byte order within a quad-word
++ */
++enum EIP93_Byte_Order_Value_t {
++	EIP93_BO_REVERSE_HALF_WORD = 1,
++	EIP93_BO_REVERSE_WORD = 2,
++	EIP93_BO_REVERSE_DUAL_WORD = 4,
++	EIP93_BO_REVERSE_QUAD_WORD = 8,
++};
++
++/*----------------------------------------------------------------------------
++ * Byte Order Reversal Mechanisms Supported in EIP93 for Target Data
++ * EIP93_BO_REVERSE_HALF_WORD : reverse the byte order within a half-word
++ * EIP93_BO_REVERSE_WORD :  reverse the byte order within a word
++ */
++enum EIP93_Byte_Order_Value_TD_t {
++	EIP93_BO_REVERSE_HALF_WORD_TD = 1,
++	EIP93_BO_REVERSE_WORD_TD = 2,
++};
++
++// BYTE_ORDER_CFG register values
++#define EIP93_BYTE_ORDER_PD		EIP93_BO_REVERSE_WORD
++#define EIP93_BYTE_ORDER_SA		EIP93_BO_REVERSE_WORD
++#define EIP93_BYTE_ORDER_DATA		EIP93_BO_REVERSE_WORD
++#define EIP93_BYTE_ORDER_TD		EIP93_BO_REVERSE_WORD_TD
++
++// INT_CFG register values
++#define EIP93_INT_HOST_OUTPUT_TYPE	0
++#define EIP93_INT_PULSE_CLEAR		0
++
++/*
++ * Interrupts of EIP93
++ */
++
++enum EIP93_InterruptSource_t {
++	EIP93_INT_PE_CDRTHRESH_REQ =	BIT(0),
++	EIP93_INT_PE_RDRTHRESH_REQ =	BIT(1),
++	EIP93_INT_PE_OPERATION_DONE =	BIT(9),
++	EIP93_INT_PE_INBUFTHRESH_REQ =	BIT(10),
++	EIP93_INT_PE_OUTBURTHRSH_REQ =	BIT(11),
++	EIP93_INT_PE_PRNG_IRQ =		BIT(12),
++	EIP93_INT_PE_ERR_REG =		BIT(13),
++	EIP93_INT_PE_RD_DONE_IRQ =	BIT(16),
++};
++
++union peConfig_w {
++	u32 word;
++	struct {
++		u32 resetPE		:1;
++		u32 resetRing		:1;
++		u32 reserved		:6;
++		u32 peMode		:2;
++		u32 enCDRupdate		:1;
++		u32 reserved2		:5;
++		u32 swapCDRD		:1;
++		u32 swapSA		:1;
++		u32 swapData		:1;
++		u32 reserved3		:13;
++	} bits;
++} __packed;
++
++union peEndianCfg_w {
++	u32 word;
++	struct {
++		u32 masterByteSwap	:8;
++		u32 reserved		:8;
++		u32 targetByteSwap	:8;
++		u32 reserved2		:8;
++	} bits;
++} __packed;
++
++union peIntCfg_w {
++	u32 word;
++	struct {
++		u32 PulseClear		:1;
++		u32 IntType		:1;
++		u32 reserved		:30;
++	} bits;
++} __packed;
++
++union peClockCfg_w {
++	u32 word;
++	struct {
++		u32 enPEclk		:1;
++		u32 enDESclk		:1;
++		u32 enAESclk		:1;
++		u32 reserved		:1;
++		u32 enHASHclk		:1;
++		u32 reserved2		:27;
++	} bits;
++} __packed;
++
++union peBufThresh_w {
++	u32 word;
++	struct {
++		u32 inputBuffer		:8;
++		u32 reserved		:8;
++		u32 outputBuffer	:8;
++		u32 reserved2		:8;
++	} bits;
++} __packed;
++
++union peRingThresh_w {
++	u32 word;
++	struct {
++		u32 CDRThresh		:10;
++		u32 reserved		:6;
++		u32 RDRThresh		:10;
++		u32 RDTimeout		:4;
++		u32 reserved2		:1;
++		u32 enTimeout		:1;
++	} bits;
++} __packed;
++
++union peRingCfg_w {
++	u32 word;
++	struct {
++		u32 ringSize		:10;
++		u32 reserved		:6;
++		u32 ringOffset		:8;
++		u32 reserved2		:8;
++	} bits;
++} __packed;
++
++union saCmd0 {
++	u32	word;
++	struct {
++		u32 opCode		:3;
++		u32 direction		:1;
++		u32 opGroup		:2;
++		u32 padType		:2;
++		u32 cipher		:4;
++		u32 hash		:4;
++		u32 reserved2		:1;
++		u32 scPad		:1;
++		u32 extPad		:1;
++		u32 hdrProc		:1;
++		u32 digestLength	:4;
++		u32 ivSource		:2;
++		u32 hashSource		:2;
++		u32 saveIv		:1;
++		u32 saveHash		:1;
++		u32 reserved1		:2;
++	} bits;
++} __packed;
++
++union saCmd1 {
++	u32	word;
++	struct {
++		u32 copyDigest		:1;
++		u32 copyHeader		:1;
++		u32 copyPayload		:1;
++		u32 copyPad		:1;
++		u32 reserved4		:4;
++		u32 cipherMode		:2;
++		u32 reserved3		:1;
++		u32 sslMac		:1;
++		u32 hmac		:1;
++		u32 byteOffset		:1;
++		u32 reserved2		:2;
++		u32 hashCryptOffset	:8;
++		u32 aesKeyLen		:3;
++		u32 reserved1		:1;
++		u32 aesDecKey		:1;
++		u32 seqNumCheck		:1;
++		u32 reserved0		:2;
++	} bits;
++} __packed;
++
++struct saRecord_s {
++	union saCmd0	saCmd0;
++	union saCmd1	saCmd1;
++	u32		saKey[8];
++	u32		saIDigest[8];
++	u32		saODigest[8];
++	u32		saSpi;
++	u32		saSeqNum[2];
++	u32		saSeqNumMask[2];
++	u32		saNonce;
++} __packed;
++
++struct saState_s {
++	u32	stateIv[4];
++	u32	stateByteCnt[2];
++	u32	stateIDigest[8];
++} __packed;
++
++union peCrtlStat_w {
++	u32 word;
++	struct {
++		u32 hostReady		:1;
++		u32 peReady		:1;
++		u32 reserved		:1;
++		u32 initArc4		:1;
++		u32 hashFinal		:1;
++		u32 haltMode		:1;
++		u32 prngMode		:2;
++		u32 padValue		:8;
++		u32 errStatus		:8;
++		u32 padCrtlStat		:8;
++	} bits;
++} __packed;
++
++union  peLength_w {
++	u32 word;
++	struct {
++		u32 length		:20;
++		u32 reserved		:2;
++		u32 hostReady		:1;
++		u32 peReady		:1;
++		u32 byPass		:8;
++	} bits;
++} __packed;
++
++struct eip93_descriptor_s {
++	union peCrtlStat_w	peCrtlStat;
++	u32			srcAddr;
++	u32			dstAddr;
++	u32			saAddr;
++	u32			stateAddr;
++	u32			arc4Addr;
++	u32			userId;
++	union peLength_w	peLength;
++} __packed;
++
++#endif
+-- 
+2.38.1.windows.1
+
-- 
