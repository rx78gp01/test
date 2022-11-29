diff --git a/package/libs/openssl/patches/0001-Prepare-for-3.0.14.patch b/package/libs/openssl/patches/0001-Prepare-for-3.0.14.patch
new file mode 100644
index 0000000..1590645
--- /dev/null
+++ b/package/libs/openssl/patches/0001-Prepare-for-3.0.14.patch
@@ -0,0 +1,61 @@
+From a1572c9a10bd07aee5daeb19ac97b01a21831d2d Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Tue, 30 Jan 2024 13:28:22 +0000
+Subject: [PATCH 01/76] Prepare for 3.0.14
+
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Release: yes
+---
+ CHANGES.md  | 4 ++++
+ NEWS.md     | 4 ++++
+ VERSION.dat | 6 +++---
+ 3 files changed, 11 insertions(+), 3 deletions(-)
+
+diff --git a/CHANGES.md b/CHANGES.md
+index bd876eb89d..91dd358db8 100644
+--- a/CHANGES.md
++++ b/CHANGES.md
+@@ -28,6 +28,10 @@ breaking changes, and mappings for the large list of deprecated functions.
+ 
+ [Migration guide]: https://github.com/openssl/openssl/tree/master/doc/man7/migration_guide.pod
+ 
++### Changes between 3.0.13 and 3.0.14 [xx XXX xxxx]
++
++ * none yet
++
+ ### Changes between 3.0.12 and 3.0.13 [30 Jan 2024]
+ 
+  * A file in PKCS12 format can contain certificates and keys and may come from
+diff --git a/NEWS.md b/NEWS.md
+index d9a48b157e..11fc8b10b0 100644
+--- a/NEWS.md
++++ b/NEWS.md
+@@ -18,6 +18,10 @@ OpenSSL Releases
+ OpenSSL 3.0
+ -----------
+ 
++### Major changes between OpenSSL 3.0.13 and OpenSSL 3.0.14 [under development]
++
++  * none
++
+ ### Major changes between OpenSSL 3.0.12 and OpenSSL 3.0.13 [30 Jan 2024]
+ 
+   * Fixed PKCS12 Decoding crashes
+diff --git a/VERSION.dat b/VERSION.dat
+index 3ee1a6f829..3080991a11 100644
+--- a/VERSION.dat
++++ b/VERSION.dat
+@@ -1,7 +1,7 @@
+ MAJOR=3
+ MINOR=0
+-PATCH=13
+-PRE_RELEASE_TAG=
++PATCH=14
++PRE_RELEASE_TAG=dev
+ BUILD_METADATA=
+-RELEASE_DATE="30 Jan 2024"
++RELEASE_DATE=""
+ SHLIB_VERSION=3
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0002-fix-missing-null-check-in-kdf_test_ctrl.patch b/package/libs/openssl/patches/0002-fix-missing-null-check-in-kdf_test_ctrl.patch
new file mode 100644
index 0000000..deaba04
--- /dev/null
+++ b/package/libs/openssl/patches/0002-fix-missing-null-check-in-kdf_test_ctrl.patch
@@ -0,0 +1,66 @@
+From 4ee81ec4e0c2842d9ec1549a83516000b4685a4d Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Fri, 26 Jan 2024 11:33:18 -0500
+Subject: [PATCH 02/76] fix missing null check in kdf_test_ctrl
+
+Coverity issue 1453632 noted a missing null check in kdf_test_ctrl
+recently.  If a malformed value is passed in from the test file that
+does not contain a ':' character, the p variable will be NULL, leading
+to a NULL derefence prepare_from_text
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23398)
+
+(cherry picked from commit 6ca1d3ee81b61bc973e4e1079ec68ac73331c159)
+---
+ test/evp_test.c | 15 +++++++++------
+ 1 file changed, 9 insertions(+), 6 deletions(-)
+
+diff --git a/test/evp_test.c b/test/evp_test.c
+index 782841a692..2701040dab 100644
+--- a/test/evp_test.c
++++ b/test/evp_test.c
+@@ -2773,30 +2773,33 @@ static int kdf_test_ctrl(EVP_TEST *t, EVP_KDF_CTX *kctx,
+     if (!TEST_ptr(name = OPENSSL_strdup(value)))
+         return 0;
+     p = strchr(name, ':');
+-    if (p != NULL)
++    if (p == NULL)
++        p = "";
++    else
+         *p++ = '\0';
+ 
+     rv = OSSL_PARAM_allocate_from_text(kdata->p, defs, name, p,
+-                                       p != NULL ? strlen(p) : 0, NULL);
++                                       strlen(p), NULL);
+     *++kdata->p = OSSL_PARAM_construct_end();
+     if (!rv) {
+         t->err = "KDF_PARAM_ERROR";
+         OPENSSL_free(name);
+         return 0;
+     }
+-    if (p != NULL && strcmp(name, "digest") == 0) {
++    if (strcmp(name, "digest") == 0) {
+         if (is_digest_disabled(p)) {
+             TEST_info("skipping, '%s' is disabled", p);
+             t->skip = 1;
+         }
+     }
+-    if (p != NULL
+-        && (strcmp(name, "cipher") == 0
+-            || strcmp(name, "cekalg") == 0)
++
++    if ((strcmp(name, "cipher") == 0
++        || strcmp(name, "cekalg") == 0)
+         && is_cipher_disabled(p)) {
+         TEST_info("skipping, '%s' is disabled", p);
+         t->skip = 1;
+     }
++
+     OPENSSL_free(name);
+     return 1;
+ }
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0003-Fix-a-possible-memleak-in-bind_afalg.patch b/package/libs/openssl/patches/0003-Fix-a-possible-memleak-in-bind_afalg.patch
new file mode 100644
index 0000000..7f199b7
--- /dev/null
+++ b/package/libs/openssl/patches/0003-Fix-a-possible-memleak-in-bind_afalg.patch
@@ -0,0 +1,46 @@
+From 25681cb8dcc3086c681917926fe8199df14bf83e Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Sun, 28 Jan 2024 23:50:16 +0100
+Subject: [PATCH 03/76] Fix a possible memleak in bind_afalg
+
+bind_afalg calls afalg_aes_cbc which allocates
+cipher_handle->_hidden global object(s)
+but if one of them fails due to out of memory,
+the function bind_afalg relies on the engine destroy
+method to be called.  But that does not happen
+because the dynamic engine object is not destroyed
+in the usual way in dynamic_load in this case:
+
+If the bind_engine function fails, there will be no
+further calls into the shared object.
+See ./crypto/engine/eng_dyn.c near the comment:
+/* Copy the original ENGINE structure back */
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23409)
+
+(cherry picked from commit 729a1496cc4cda669dea6501c991113c78f04560)
+---
+ engines/e_afalg.c | 4 +++-
+ 1 file changed, 3 insertions(+), 1 deletion(-)
+
+diff --git a/engines/e_afalg.c b/engines/e_afalg.c
+index 2c08cbb28d..ccef155ea2 100644
+--- a/engines/e_afalg.c
++++ b/engines/e_afalg.c
+@@ -811,8 +811,10 @@ static int bind_helper(ENGINE *e, const char *id)
+     if (!afalg_chk_platform())
+         return 0;
+ 
+-    if (!bind_afalg(e))
++    if (!bind_afalg(e)) {
++        afalg_destroy(e);
+         return 0;
++    }
+     return 1;
+ }
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0004-Fix-error-reporting-in-EVP_PKEY_-sign-verify-verify_.patch b/package/libs/openssl/patches/0004-Fix-error-reporting-in-EVP_PKEY_-sign-verify-verify_.patch
new file mode 100644
index 0000000..1277f7e
--- /dev/null
+++ b/package/libs/openssl/patches/0004-Fix-error-reporting-in-EVP_PKEY_-sign-verify-verify_.patch
@@ -0,0 +1,117 @@
+From 5781c0a181c97530e57708fa67bb5faa44368246 Mon Sep 17 00:00:00 2001
+From: Richard Levitte <levitte@openssl.org>
+Date: Mon, 29 Jan 2024 08:51:52 +0100
+Subject: [PATCH 04/76] Fix error reporting in
+ EVP_PKEY_{sign,verify,verify_recover}
+
+For some reason, those functions (and the _init functions too) would
+raise EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE when the passed
+ctx is NULL, and then not check if the provider supplied the function
+that would support these libcrypto functions.
+
+This corrects the situation, and has all those libcrypto functions
+raise ERR_R_PASS_NULL_PARAMETER if ctx is NULL, and then check for the
+corresponding provider supplied, and only when that one is missing,
+raise EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE.
+
+Because 0 doesn't mean error for EVP_PKEY_verify(), -1 is returned when
+ERR_R_PASSED_NULL_PARAMETER is raised.  This is done consistently for all
+affected functions.
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23411)
+
+(cherry picked from commit 5a25177d1b07ef6e754fec1747b57ee90ab1e028)
+---
+ crypto/evp/signature.c | 31 +++++++++++++++++++++++--------
+ 1 file changed, 23 insertions(+), 8 deletions(-)
+
+diff --git a/crypto/evp/signature.c b/crypto/evp/signature.c
+index fb269b3bfd..5689505566 100644
+--- a/crypto/evp/signature.c
++++ b/crypto/evp/signature.c
+@@ -403,8 +403,8 @@ static int evp_pkey_signature_init(EVP_PKEY_CTX *ctx, int operation,
+     int iter;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     evp_pkey_ctx_free_old_ops(ctx);
+@@ -634,8 +634,8 @@ int EVP_PKEY_sign(EVP_PKEY_CTX *ctx,
+     int ret;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     if (ctx->operation != EVP_PKEY_OP_SIGN) {
+@@ -646,6 +646,11 @@ int EVP_PKEY_sign(EVP_PKEY_CTX *ctx,
+     if (ctx->op.sig.algctx == NULL)
+         goto legacy;
+ 
++    if (ctx->op.sig.signature->sign == NULL) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
++        return -2;
++    }
++
+     ret = ctx->op.sig.signature->sign(ctx->op.sig.algctx, sig, siglen,
+                                       (sig == NULL) ? 0 : *siglen, tbs, tbslen);
+ 
+@@ -678,8 +683,8 @@ int EVP_PKEY_verify(EVP_PKEY_CTX *ctx,
+     int ret;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     if (ctx->operation != EVP_PKEY_OP_VERIFY) {
+@@ -690,6 +695,11 @@ int EVP_PKEY_verify(EVP_PKEY_CTX *ctx,
+     if (ctx->op.sig.algctx == NULL)
+         goto legacy;
+ 
++    if (ctx->op.sig.signature->verify == NULL) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
++        return -2;
++    }
++
+     ret = ctx->op.sig.signature->verify(ctx->op.sig.algctx, sig, siglen,
+                                         tbs, tbslen);
+ 
+@@ -721,8 +731,8 @@ int EVP_PKEY_verify_recover(EVP_PKEY_CTX *ctx,
+     int ret;
+ 
+     if (ctx == NULL) {
+-        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
+-        return -2;
++        ERR_raise(ERR_LIB_EVP, ERR_R_PASSED_NULL_PARAMETER);
++        return -1;
+     }
+ 
+     if (ctx->operation != EVP_PKEY_OP_VERIFYRECOVER) {
+@@ -733,6 +743,11 @@ int EVP_PKEY_verify_recover(EVP_PKEY_CTX *ctx,
+     if (ctx->op.sig.algctx == NULL)
+         goto legacy;
+ 
++    if (ctx->op.sig.signature->verify_recover == NULL) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_OPERATION_NOT_SUPPORTED_FOR_THIS_KEYTYPE);
++        return -2;
++    }
++
+     ret = ctx->op.sig.signature->verify_recover(ctx->op.sig.algctx, rout,
+                                                 routlen,
+                                                 (rout == NULL ? 0 : *routlen),
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0005-Revert-Improved-detection-of-engine-provided-private.patch b/package/libs/openssl/patches/0005-Revert-Improved-detection-of-engine-provided-private.patch
new file mode 100644
index 0000000..03fa0cc
--- /dev/null
+++ b/package/libs/openssl/patches/0005-Revert-Improved-detection-of-engine-provided-private.patch
@@ -0,0 +1,82 @@
+From ad6cbe4b7f57a783a66a7ae883ea0d35ef5f82b6 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Fri, 15 Dec 2023 13:45:50 +0100
+Subject: [PATCH 05/76] Revert "Improved detection of engine-provided private
+ "classic" keys"
+
+This reverts commit 2b74e75331a27fc89cad9c8ea6a26c70019300b5.
+
+The commit was wrong. With 3.x versions the engines must be themselves
+responsible for creating their EVP_PKEYs in a way that they are treated
+as legacy - either by using the respective set1 calls or by setting
+non-default EVP_PKEY_METHOD.
+
+The workaround has caused more problems than it solved.
+
+Fixes #22945
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23063)
+
+(cherry picked from commit 39ea78379826fa98e8dc8c0d2b07e2c17cd68380)
+---
+ crypto/engine/eng_pkey.c | 42 ----------------------------------------
+ 1 file changed, 42 deletions(-)
+
+diff --git a/crypto/engine/eng_pkey.c b/crypto/engine/eng_pkey.c
+index f84fcde460..075a61b5bf 100644
+--- a/crypto/engine/eng_pkey.c
++++ b/crypto/engine/eng_pkey.c
+@@ -79,48 +79,6 @@ EVP_PKEY *ENGINE_load_private_key(ENGINE *e, const char *key_id,
+         ERR_raise(ERR_LIB_ENGINE, ENGINE_R_FAILED_LOADING_PRIVATE_KEY);
+         return NULL;
+     }
+-    /* We enforce check for legacy key */
+-    switch (EVP_PKEY_get_id(pkey)) {
+-    case EVP_PKEY_RSA:
+-        {
+-        RSA *rsa = EVP_PKEY_get1_RSA(pkey);
+-        EVP_PKEY_set1_RSA(pkey, rsa);
+-        RSA_free(rsa);
+-        }
+-        break;
+-#  ifndef OPENSSL_NO_EC
+-    case EVP_PKEY_SM2:
+-    case EVP_PKEY_EC:
+-        {
+-        EC_KEY *ec = EVP_PKEY_get1_EC_KEY(pkey);
+-        EVP_PKEY_set1_EC_KEY(pkey, ec);
+-        EC_KEY_free(ec);
+-        }
+-        break;
+-#  endif
+-#  ifndef OPENSSL_NO_DSA
+-    case EVP_PKEY_DSA:
+-        {
+-        DSA *dsa = EVP_PKEY_get1_DSA(pkey);
+-        EVP_PKEY_set1_DSA(pkey, dsa);
+-        DSA_free(dsa);
+-        }
+-        break;
+-#endif
+-#  ifndef OPENSSL_NO_DH
+-    case EVP_PKEY_DH:
+-        {
+-        DH *dh = EVP_PKEY_get1_DH(pkey);
+-        EVP_PKEY_set1_DH(pkey, dh);
+-        DH_free(dh);
+-        }
+-        break;
+-#endif
+-    default:
+-        /*Do nothing */
+-        break;
+-    }
+-
+     return pkey;
+ }
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0006-Document-the-implications-of-setting-engine-based-lo.patch b/package/libs/openssl/patches/0006-Document-the-implications-of-setting-engine-based-lo.patch
new file mode 100644
index 0000000..559a388
--- /dev/null
+++ b/package/libs/openssl/patches/0006-Document-the-implications-of-setting-engine-based-lo.patch
@@ -0,0 +1,37 @@
+From 41073fdc4266015bb5ed2f4e6e6bf43462632bee Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Wed, 27 Dec 2023 19:21:49 +0100
+Subject: [PATCH 06/76] Document the implications of setting engine-based
+ low-level methods
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23063)
+
+(cherry picked from commit dbb478a51d3f695ec713e9829a2353a0d2d61a59)
+---
+ doc/man7/migration_guide.pod | 8 ++++++++
+ 1 file changed, 8 insertions(+)
+
+diff --git a/doc/man7/migration_guide.pod b/doc/man7/migration_guide.pod
+index 61641324a7..1434f2fde2 100644
+--- a/doc/man7/migration_guide.pod
++++ b/doc/man7/migration_guide.pod
+@@ -136,6 +136,14 @@ To ensure the future compatibility, the engines should be turned to providers.
+ To prefer the provider-based hardware offload, you can specify the default
+ properties to prefer your provider.
+ 
++Setting engine-based or application-based default low-level crypto method such
++as B<RSA_METHOD> or B<EC_KEY_METHOD> is still possible and keys inside the
++default provider will use the engine-based implementation for the crypto
++operations. However B<EVP_PKEY>s created by decoding by using B<OSSL_DECODER>,
++B<PEM_> or B<d2i_> APIs will be provider-based. To create a fully legacy
++B<EVP_PKEY>s L<EVP_PKEY_set1_RSA(3)>, L<EVP_PKEY_set1_EC_KEY(3)> or similar
++functions must be used.
++
+ =head3 Versioning Scheme
+ 
+ The OpenSSL versioning scheme has changed with the OpenSSL 3.0 release. The new
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0007-Sync-pyca-workflow-with-master.patch b/package/libs/openssl/patches/0007-Sync-pyca-workflow-with-master.patch
new file mode 100644
index 0000000..bd8448c
--- /dev/null
+++ b/package/libs/openssl/patches/0007-Sync-pyca-workflow-with-master.patch
@@ -0,0 +1,24 @@
+From 87564fe437da6ca8239b6c7c036eed28d0c9f0a8 Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Wed, 31 Jan 2024 14:52:38 +0100
+Subject: [PATCH 07/76] Sync pyca workflow with master
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Todd Short <todd.short@me.com>
+(Merged from https://github.com/openssl/openssl/pull/23444)
+
+(cherry picked from commit 3b62e031418369ba5f62b32f12f9ccf3bdd3a3c0)
+---
+ pyca-cryptography | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/pyca-cryptography b/pyca-cryptography
+index c18d056738..7e33b0e773 160000
+--- a/pyca-cryptography
++++ b/pyca-cryptography
+@@ -1 +1 @@
+-Subproject commit c18d0567386414efa3caef7ed586c4ca75bf3a8b
++Subproject commit 7e33b0e7739d633c77b8c478620167f693ed13f4
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0008-Fix-a-few-incorrect-paths-in-some-build.info-files.patch b/package/libs/openssl/patches/0008-Fix-a-few-incorrect-paths-in-some-build.info-files.patch
new file mode 100644
index 0000000..cc7a25e
--- /dev/null
+++ b/package/libs/openssl/patches/0008-Fix-a-few-incorrect-paths-in-some-build.info-files.patch
@@ -0,0 +1,67 @@
+From 7b3eda56d7891aceef91867de64f24b20e3db212 Mon Sep 17 00:00:00 2001
+From: Richard Levitte <levitte@openssl.org>
+Date: Thu, 1 Feb 2024 10:57:51 +0100
+Subject: [PATCH 08/76] Fix a few incorrect paths in some build.info files
+
+The following files referred to ../liblegacy.a when they should have
+referred to ../../liblegacy.a.  This cause the creation of a mysterious
+directory 'crypto/providers', and because of an increased strictness
+with regards to where directories are created, configuration failure
+on some platforms.
+
+Fixes #23436
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23452)
+
+(cherry picked from commit 667b45454a47959ce2934b74c899662e686993de)
+---
+ crypto/aes/build.info | 2 +-
+ crypto/ec/build.info  | 2 +-
+ crypto/sha/build.info | 2 +-
+ 3 files changed, 3 insertions(+), 3 deletions(-)
+
+diff --git a/crypto/aes/build.info b/crypto/aes/build.info
+index b250903fa6..271015e35e 100644
+--- a/crypto/aes/build.info
++++ b/crypto/aes/build.info
+@@ -76,7 +76,7 @@ DEFINE[../../providers/libdefault.a]=$AESDEF
+ # already gets everything that the static libcrypto.a has, and doesn't need it
+ # added again.
+ IF[{- !$disabled{module} && !$disabled{shared} -}]
+-  DEFINE[../providers/liblegacy.a]=$AESDEF
++  DEFINE[../../providers/liblegacy.a]=$AESDEF
+ ENDIF
+ 
+ GENERATE[aes-ia64.s]=asm/aes-ia64.S
+diff --git a/crypto/ec/build.info b/crypto/ec/build.info
+index a511e887a9..6dd98e9f4f 100644
+--- a/crypto/ec/build.info
++++ b/crypto/ec/build.info
+@@ -77,7 +77,7 @@ DEFINE[../../providers/libdefault.a]=$ECDEF
+ # Otherwise, it already gets everything that the static libcrypto.a
+ # has, and doesn't need it added again.
+ IF[{- !$disabled{module} && !$disabled{shared} -}]
+-  DEFINE[../providers/liblegacy.a]=$ECDEF
++  DEFINE[../../providers/liblegacy.a]=$ECDEF
+ ENDIF
+ 
+ GENERATE[ecp_nistz256-x86.S]=asm/ecp_nistz256-x86.pl
+diff --git a/crypto/sha/build.info b/crypto/sha/build.info
+index d61f7de9b6..186ec13cc8 100644
+--- a/crypto/sha/build.info
++++ b/crypto/sha/build.info
+@@ -88,7 +88,7 @@ DEFINE[../../providers/libdefault.a]=$SHA1DEF $KECCAK1600DEF
+ # linked with libcrypto.  Otherwise, it already gets everything that
+ # the static libcrypto.a has, and doesn't need it added again.
+ IF[{- !$disabled{module} && !$disabled{shared} -}]
+-  DEFINE[../providers/liblegacy.a]=$SHA1DEF $KECCAK1600DEF
++  DEFINE[../../providers/liblegacy.a]=$SHA1DEF $KECCAK1600DEF
+ ENDIF
+ 
+ GENERATE[sha1-586.S]=asm/sha1-586.pl
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0009-Make-IV-buf-in-prov_cipher_ctx_st-aligned.patch b/package/libs/openssl/patches/0009-Make-IV-buf-in-prov_cipher_ctx_st-aligned.patch
new file mode 100644
index 0000000..f57298e
--- /dev/null
+++ b/package/libs/openssl/patches/0009-Make-IV-buf-in-prov_cipher_ctx_st-aligned.patch
@@ -0,0 +1,62 @@
+From a91c268853c4bda825a505629a873e21685490bf Mon Sep 17 00:00:00 2001
+From: "Hongren (Zenithal) Zheng" <i@zenithal.me>
+Date: Mon, 9 May 2022 19:42:39 +0800
+Subject: [PATCH 09/76] Make IV/buf in prov_cipher_ctx_st aligned
+
+Make IV/buf aligned will drastically improve performance
+as some architecture performs badly on misaligned memory
+access.
+
+Ref to
+https://gist.github.com/ZenithalHourlyRate/7b5175734f87acb73d0bbc53391d7140#file-2-openssl-long-md
+Ref to
+openssl#18197
+
+Signed-off-by: Hongren (Zenithal) Zheng <i@zenithal.me>
+
+Reviewed-by: Paul Dale <pauli@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+
+(cherry picked from commit 2787a709c984d3884e1726383c2f2afca428d795)
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23463)
+---
+ .../implementations/include/prov/ciphercommon.h     | 13 +++++++------
+ 1 file changed, 7 insertions(+), 6 deletions(-)
+
+diff --git a/providers/implementations/include/prov/ciphercommon.h b/providers/implementations/include/prov/ciphercommon.h
+index 383b759304..7f9a4a3bf2 100644
+--- a/providers/implementations/include/prov/ciphercommon.h
++++ b/providers/implementations/include/prov/ciphercommon.h
+@@ -42,6 +42,13 @@ typedef int (PROV_CIPHER_HW_FN)(PROV_CIPHER_CTX *dat, unsigned char *out,
+ #define PROV_CIPHER_FLAG_INVERSE_CIPHER   0x0200
+ 
+ struct prov_cipher_ctx_st {
++    /* place buffer at the beginning for memory alignment */
++    /* The original value of the iv */
++    unsigned char oiv[GENERIC_BLOCK_SIZE];
++    /* Buffer of partial blocks processed via update calls */
++    unsigned char buf[GENERIC_BLOCK_SIZE];
++    unsigned char iv[GENERIC_BLOCK_SIZE];
++
+     block128_f block;
+     union {
+         cbc128_f cbc;
+@@ -83,12 +90,6 @@ struct prov_cipher_ctx_st {
+      * manage partial blocks themselves.
+      */
+     unsigned int num;
+-
+-    /* The original value of the iv */
+-    unsigned char oiv[GENERIC_BLOCK_SIZE];
+-    /* Buffer of partial blocks processed via update calls */
+-    unsigned char buf[GENERIC_BLOCK_SIZE];
+-    unsigned char iv[GENERIC_BLOCK_SIZE];
+     const PROV_CIPHER_HW *hw; /* hardware specific functions */
+     const void *ks; /* Pointer to algorithm specific key data */
+     OSSL_LIB_CTX *libctx;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0010-Fix-testcases-to-run-on-duplicated-keys.patch b/package/libs/openssl/patches/0010-Fix-testcases-to-run-on-duplicated-keys.patch
new file mode 100644
index 0000000..2601da6
--- /dev/null
+++ b/package/libs/openssl/patches/0010-Fix-testcases-to-run-on-duplicated-keys.patch
@@ -0,0 +1,246 @@
+From f3875dad4bca7d62c54a24ca920c06492020ce64 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Fri, 12 Jan 2024 18:47:56 +0100
+Subject: [PATCH 10/76] Fix testcases to run on duplicated keys
+
+The existing loop pattern did not really run the expected
+tests on the duplicated keys.
+
+Fixes #23129
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23292)
+
+(cherry picked from commit 387b93e14907cd8203d6f2c9d78e49df01cb6e1f)
+---
+ test/evp_extra_test.c         |  6 +++-
+ test/evp_pkey_provided_test.c | 63 +++++++++++++++++++++++++----------
+ test/keymgmt_internal_test.c  |  8 +++--
+ 3 files changed, 56 insertions(+), 21 deletions(-)
+
+diff --git a/test/evp_extra_test.c b/test/evp_extra_test.c
+index 6b484f8711..e7b813493f 100644
+--- a/test/evp_extra_test.c
++++ b/test/evp_extra_test.c
+@@ -1100,7 +1100,7 @@ static int test_EC_priv_only_legacy(void)
+         goto err;
+     eckey = NULL;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         ctx = EVP_MD_CTX_new();
+         if (!TEST_ptr(ctx))
+@@ -1116,6 +1116,9 @@ static int test_EC_priv_only_legacy(void)
+         EVP_MD_CTX_free(ctx);
+         ctx = NULL;
+ 
++        if (dup_pk != NULL)
++            break;
++
+         if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pkey)))
+             goto err;
+         /* EVP_PKEY_eq() returns -2 with missing public keys */
+@@ -1125,6 +1128,7 @@ static int test_EC_priv_only_legacy(void)
+         if (!ret)
+             goto err;
+     }
++    ret = 1;
+ 
+  err:
+     EVP_MD_CTX_free(ctx);
+diff --git a/test/evp_pkey_provided_test.c b/test/evp_pkey_provided_test.c
+index 27f90e42a7..688a8c1c5e 100644
+--- a/test/evp_pkey_provided_test.c
++++ b/test/evp_pkey_provided_test.c
+@@ -389,7 +389,7 @@ static int test_fromdata_rsa(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 32)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 8)
+@@ -417,7 +417,10 @@ static int test_fromdata_rsa(void)
+         ret = test_print_key_using_pem("RSA", pk)
+               && test_print_key_using_encoder("RSA", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -602,7 +605,7 @@ static int test_fromdata_dh_named_group(void)
+                                                       &len)))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 2048)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 112)
+@@ -682,7 +685,10 @@ static int test_fromdata_dh_named_group(void)
+         ret = test_print_key_using_pem("DH", pk)
+               && test_print_key_using_encoder("DH", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -783,7 +789,7 @@ static int test_fromdata_dh_fips186_4(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 2048)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 112)
+@@ -857,7 +863,10 @@ static int test_fromdata_dh_fips186_4(void)
+         ret = test_print_key_using_pem("DH", pk)
+               && test_print_key_using_encoder("DH", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -1090,7 +1099,7 @@ static int test_fromdata_ecx(int tst)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), bits)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), security_bits)
+@@ -1145,7 +1154,10 @@ static int test_fromdata_ecx(int tst)
+             ret = test_print_key_using_pem(alg, pk)
+                   && test_print_key_using_encoder(alg, pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -1262,7 +1274,7 @@ static int test_fromdata_ec(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 256)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 128)
+@@ -1301,6 +1313,15 @@ static int test_fromdata_ec(void)
+             || !TEST_BN_eq(group_b, b))
+             goto err;
+ 
++        EC_GROUP_free(group);
++        group = NULL;
++        BN_free(group_p);
++        group_p = NULL;
++        BN_free(group_a);
++        group_a = NULL;
++        BN_free(group_b);
++        group_b = NULL;
++
+         if (!EVP_PKEY_get_utf8_string_param(pk, OSSL_PKEY_PARAM_GROUP_NAME,
+                                             out_curve_name,
+                                             sizeof(out_curve_name),
+@@ -1329,7 +1350,10 @@ static int test_fromdata_ec(void)
+         ret = test_print_key_using_pem(alg, pk)
+               && test_print_key_using_encoder(alg, pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+@@ -1575,7 +1599,7 @@ static int test_fromdata_dsa_fips186_4(void)
+                                           fromdata_params), 1))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         if (!TEST_int_eq(EVP_PKEY_get_bits(pk), 2048)
+             || !TEST_int_eq(EVP_PKEY_get_security_bits(pk), 112)
+@@ -1624,12 +1648,12 @@ static int test_fromdata_dsa_fips186_4(void)
+                                                  &pcounter_out))
+             || !TEST_int_eq(pcounter, pcounter_out))
+             goto err;
+-        BN_free(p);
+-        p = NULL;
+-        BN_free(q);
+-        q = NULL;
+-        BN_free(g);
+-        g = NULL;
++        BN_free(p_out);
++        p_out = NULL;
++        BN_free(q_out);
++        q_out = NULL;
++        BN_free(g_out);
++        g_out = NULL;
+         BN_free(j_out);
+         j_out = NULL;
+         BN_free(pub_out);
+@@ -1657,7 +1681,10 @@ static int test_fromdata_dsa_fips186_4(void)
+         ret = test_print_key_using_pem("DSA", pk)
+               && test_print_key_using_encoder("DSA", pk);
+ 
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+         ret = ret && TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+         EVP_PKEY_free(pk);
+diff --git a/test/keymgmt_internal_test.c b/test/keymgmt_internal_test.c
+index ce2e458f8c..78b1cd717e 100644
+--- a/test/keymgmt_internal_test.c
++++ b/test/keymgmt_internal_test.c
+@@ -224,7 +224,7 @@ static int test_pass_rsa(FIXTURE *fixture)
+         || !TEST_ptr_ne(km1, km2))
+         goto err;
+ 
+-    while (dup_pk == NULL) {
++    for (;;) {
+         ret = 0;
+         km = km3;
+         /* Check that we can't export an RSA key into an RSA-PSS keymanager */
+@@ -255,7 +255,11 @@ static int test_pass_rsa(FIXTURE *fixture)
+         }
+ 
+         ret = (ret == OSSL_NELEM(expected));
+-        if (!ret || !TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
++
++        if (!ret || dup_pk != NULL)
++            break;
++
++        if (!TEST_ptr(dup_pk = EVP_PKEY_dup(pk)))
+             goto err;
+ 
+         ret = TEST_int_eq(EVP_PKEY_eq(pk, dup_pk), 1);
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0011-Rearrange-terms-in-gf_mul-to-prevent-segfault.patch b/package/libs/openssl/patches/0011-Rearrange-terms-in-gf_mul-to-prevent-segfault.patch
new file mode 100644
index 0000000..333bfef
--- /dev/null
+++ b/package/libs/openssl/patches/0011-Rearrange-terms-in-gf_mul-to-prevent-segfault.patch
@@ -0,0 +1,36 @@
+From 59416d6fce255cd582fa753293bcaea4aad13be8 Mon Sep 17 00:00:00 2001
+From: Angel Baez <51308340+abaez004@users.noreply.github.com>
+Date: Wed, 7 Feb 2024 10:34:48 -0500
+Subject: [PATCH 11/76] Rearrange terms in gf_mul to prevent segfault
+
+CLA: trivial
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23512)
+
+(cherry picked from commit 76cecff5e9bedb2bafc60062283f99722697082a)
+---
+ crypto/ec/curve448/arch_64/f_impl64.c | 6 +++---
+ 1 file changed, 3 insertions(+), 3 deletions(-)
+
+diff --git a/crypto/ec/curve448/arch_64/f_impl64.c b/crypto/ec/curve448/arch_64/f_impl64.c
+index 8f7a7dd391..4555b3c29a 100644
+--- a/crypto/ec/curve448/arch_64/f_impl64.c
++++ b/crypto/ec/curve448/arch_64/f_impl64.c
+@@ -45,9 +45,9 @@ void gf_mul(gf_s * RESTRICT cs, const gf as, const gf bs)
+             accum0 += widemul(a[j + 4], b[i - j + 4]);
+         }
+         for (; j < 4; j++) {
+-            accum2 += widemul(a[j], b[i - j + 8]);
+-            accum1 += widemul(aa[j], bbb[i - j + 4]);
+-            accum0 += widemul(a[j + 4], bb[i - j + 4]);
++            accum2 += widemul(a[j], b[i + 8 - j]);
++            accum1 += widemul(aa[j], bbb[i + 4 - j]);
++            accum0 += widemul(a[j + 4], bb[i + 4 - j]);
+         }
+ 
+         accum1 -= accum2;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0012-Fix-memory-leaks-on-error-cases-during-drbg-initiali.patch b/package/libs/openssl/patches/0012-Fix-memory-leaks-on-error-cases-during-drbg-initiali.patch
new file mode 100644
index 0000000..52b4fc5
--- /dev/null
+++ b/package/libs/openssl/patches/0012-Fix-memory-leaks-on-error-cases-during-drbg-initiali.patch
@@ -0,0 +1,106 @@
+From 3732a8963d7aacde04f138204e235478609cba8a Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Wed, 7 Feb 2024 10:27:50 +0100
+Subject: [PATCH 12/76] Fix memory leaks on error cases during drbg
+ initializations
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23503)
+
+(cherry picked from commit cb4f7a6ee053e8c51cf3ac35fee333d1f25552c0)
+---
+ providers/implementations/rands/drbg.c       | 3 ++-
+ providers/implementations/rands/drbg_ctr.c   | 5 +++--
+ providers/implementations/rands/drbg_hash.c  | 3 ++-
+ providers/implementations/rands/drbg_hmac.c  | 3 ++-
+ providers/implementations/rands/drbg_local.h | 1 +
+ 5 files changed, 10 insertions(+), 5 deletions(-)
+
+diff --git a/providers/implementations/rands/drbg.c b/providers/implementations/rands/drbg.c
+index e30836c53c..09edce8eb4 100644
+--- a/providers/implementations/rands/drbg.c
++++ b/providers/implementations/rands/drbg.c
+@@ -765,6 +765,7 @@ int ossl_drbg_enable_locking(void *vctx)
+ PROV_DRBG *ossl_rand_drbg_new
+     (void *provctx, void *parent, const OSSL_DISPATCH *p_dispatch,
+      int (*dnew)(PROV_DRBG *ctx),
++     void (*dfree)(void *vctx),
+      int (*instantiate)(PROV_DRBG *drbg,
+                         const unsigned char *entropy, size_t entropylen,
+                         const unsigned char *nonce, size_t noncelen,
+@@ -844,7 +845,7 @@ PROV_DRBG *ossl_rand_drbg_new
+     return drbg;
+ 
+  err:
+-    ossl_rand_drbg_free(drbg);
++    dfree(drbg);
+     return NULL;
+ }
+ 
+diff --git a/providers/implementations/rands/drbg_ctr.c b/providers/implementations/rands/drbg_ctr.c
+index 451113c4d1..988a08bf93 100644
+--- a/providers/implementations/rands/drbg_ctr.c
++++ b/providers/implementations/rands/drbg_ctr.c
+@@ -581,7 +581,7 @@ err:
+     EVP_CIPHER_CTX_free(ctr->ctx_ecb);
+     EVP_CIPHER_CTX_free(ctr->ctx_ctr);
+     ctr->ctx_ecb = ctr->ctx_ctr = NULL;
+-    return 0;    
++    return 0;
+ }
+ 
+ static int drbg_ctr_new(PROV_DRBG *drbg)
+@@ -602,7 +602,8 @@ static int drbg_ctr_new(PROV_DRBG *drbg)
+ static void *drbg_ctr_new_wrapper(void *provctx, void *parent,
+                                    const OSSL_DISPATCH *parent_dispatch)
+ {
+-    return ossl_rand_drbg_new(provctx, parent, parent_dispatch, &drbg_ctr_new,
++    return ossl_rand_drbg_new(provctx, parent, parent_dispatch,
++                              &drbg_ctr_new, &drbg_ctr_free,
+                               &drbg_ctr_instantiate, &drbg_ctr_uninstantiate,
+                               &drbg_ctr_reseed, &drbg_ctr_generate);
+ }
+diff --git a/providers/implementations/rands/drbg_hash.c b/providers/implementations/rands/drbg_hash.c
+index 6deb0a2925..4acf9a9830 100644
+--- a/providers/implementations/rands/drbg_hash.c
++++ b/providers/implementations/rands/drbg_hash.c
+@@ -410,7 +410,8 @@ static int drbg_hash_new(PROV_DRBG *ctx)
+ static void *drbg_hash_new_wrapper(void *provctx, void *parent,
+                                    const OSSL_DISPATCH *parent_dispatch)
+ {
+-    return ossl_rand_drbg_new(provctx, parent, parent_dispatch, &drbg_hash_new,
++    return ossl_rand_drbg_new(provctx, parent, parent_dispatch,
++                              &drbg_hash_new, &drbg_hash_free,
+                               &drbg_hash_instantiate, &drbg_hash_uninstantiate,
+                               &drbg_hash_reseed, &drbg_hash_generate);
+ }
+diff --git a/providers/implementations/rands/drbg_hmac.c b/providers/implementations/rands/drbg_hmac.c
+index e68465a78c..571f5e6f7a 100644
+--- a/providers/implementations/rands/drbg_hmac.c
++++ b/providers/implementations/rands/drbg_hmac.c
+@@ -296,7 +296,8 @@ static int drbg_hmac_new(PROV_DRBG *drbg)
+ static void *drbg_hmac_new_wrapper(void *provctx, void *parent,
+                                    const OSSL_DISPATCH *parent_dispatch)
+ {
+-    return ossl_rand_drbg_new(provctx, parent, parent_dispatch, &drbg_hmac_new,
++    return ossl_rand_drbg_new(provctx, parent, parent_dispatch,
++                              &drbg_hmac_new, &drbg_hmac_free,
+                               &drbg_hmac_instantiate, &drbg_hmac_uninstantiate,
+                               &drbg_hmac_reseed, &drbg_hmac_generate);
+ }
+diff --git a/providers/implementations/rands/drbg_local.h b/providers/implementations/rands/drbg_local.h
+index 8bc5df89c2..a2d1ef5307 100644
+--- a/providers/implementations/rands/drbg_local.h
++++ b/providers/implementations/rands/drbg_local.h
+@@ -181,6 +181,7 @@ struct prov_drbg_st {
+ PROV_DRBG *ossl_rand_drbg_new
+     (void *provctx, void *parent, const OSSL_DISPATCH *parent_dispatch,
+      int (*dnew)(PROV_DRBG *ctx),
++     void (*dfree)(void *vctx),
+      int (*instantiate)(PROV_DRBG *drbg,
+                         const unsigned char *entropy, size_t entropylen,
+                         const unsigned char *nonce, size_t noncelen,
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0013-Fix-typos-found-by-codespell-in-openssl-3.0.patch b/package/libs/openssl/patches/0013-Fix-typos-found-by-codespell-in-openssl-3.0.patch
new file mode 100644
index 0000000..3104b03
--- /dev/null
+++ b/package/libs/openssl/patches/0013-Fix-typos-found-by-codespell-in-openssl-3.0.patch
@@ -0,0 +1,87 @@
+From 77c6fa6bc7aae11467ca467a5ffbe260551051d7 Mon Sep 17 00:00:00 2001
+From: Dimitri Papadopoulos
+ <3234522+DimitriPapadopoulos@users.noreply.github.com>
+Date: Sun, 11 Feb 2024 18:31:23 +0100
+Subject: [PATCH 13/76] Fix typos found by codespell in openssl-3.0
+
+Only modify doc/man* in the openssl-3.0 branch.
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23546)
+---
+ doc/internal/man3/OPTIONS.pod                     | 2 +-
+ doc/internal/man3/ossl_method_construct.pod       | 2 +-
+ doc/internal/man3/ossl_provider_new.pod           | 2 +-
+ doc/internal/man3/ossl_random_add_conf_module.pod | 2 +-
+ doc/internal/man7/EVP_PKEY.pod                    | 2 +-
+ 5 files changed, 5 insertions(+), 5 deletions(-)
+
+diff --git a/doc/internal/man3/OPTIONS.pod b/doc/internal/man3/OPTIONS.pod
+index 90593ca46f..fed879e528 100644
+--- a/doc/internal/man3/OPTIONS.pod
++++ b/doc/internal/man3/OPTIONS.pod
+@@ -155,7 +155,7 @@ on multiple lines; each entry should use B<OPT_MORE_STR>, like this:
+         {OPT_MORE_STR, 0, 0,
+          "This flag is not really needed on Unix systems"},
+         {OPT_MORE_STR, 0, 0,
+-         "(Unix and descendents for ths win!)"}
++         "(Unix and descendents for the win!)"}
+ 
+ Each subsequent line will be indented the correct amount.
+ 
+diff --git a/doc/internal/man3/ossl_method_construct.pod b/doc/internal/man3/ossl_method_construct.pod
+index 3683798b06..603930dc1f 100644
+--- a/doc/internal/man3/ossl_method_construct.pod
++++ b/doc/internal/man3/ossl_method_construct.pod
+@@ -93,7 +93,7 @@ This default store should be stored in the library context I<libctx>.
+ The method to be looked up should be identified with data found in I<data>
+ (which is the I<mcm_data> that was passed to ossl_construct_method()).
+ In other words, the ossl_method_construct() caller is entirely responsible
+-for ensuring the necesssary data is made available.
++for ensuring the necessary data is made available.
+ 
+ Optionally, I<prov> may be given as a search criterion, to narrow down the
+ search of a method belonging to just one provider.
+diff --git a/doc/internal/man3/ossl_provider_new.pod b/doc/internal/man3/ossl_provider_new.pod
+index 8bd5594c48..f33f07adfc 100644
+--- a/doc/internal/man3/ossl_provider_new.pod
++++ b/doc/internal/man3/ossl_provider_new.pod
+@@ -297,7 +297,7 @@ in a bitstring that's internal to I<provider>.
+ 
+ ossl_provider_test_operation_bit() checks if the bit operation I<bitnum>
+ is set (1) or not (0) in the internal I<provider> bitstring, and sets
+-I<*result> to 1 or 0 accorddingly.
++I<*result> to 1 or 0 accordingly.
+ 
+ ossl_provider_init_as_child() stores in the library context I<ctx> references to
+ the necessary upcalls for managing child providers. The I<handle> and I<in>
+diff --git a/doc/internal/man3/ossl_random_add_conf_module.pod b/doc/internal/man3/ossl_random_add_conf_module.pod
+index 6d4f5810dc..f1ea37a68c 100644
+--- a/doc/internal/man3/ossl_random_add_conf_module.pod
++++ b/doc/internal/man3/ossl_random_add_conf_module.pod
+@@ -15,7 +15,7 @@ ossl_random_add_conf_module - internal random configuration module
+ 
+ ossl_random_add_conf_module() adds the random configuration module
+ for providers.
+-This allows the type and parameters of the stardard setup of random number
++This allows the type and parameters of the standard setup of random number
+ generators to be configured with an OpenSSL L<config(5)> file.
+ 
+ =head1 RETURN VALUES
+diff --git a/doc/internal/man7/EVP_PKEY.pod b/doc/internal/man7/EVP_PKEY.pod
+index cc738b9c28..ffaff36553 100644
+--- a/doc/internal/man7/EVP_PKEY.pod
++++ b/doc/internal/man7/EVP_PKEY.pod
+@@ -19,7 +19,7 @@ private/public key pairs, but has had other uses as well.
+ 
+ =for comment "uses" could as well be "abuses"...
+ 
+-The private/public key pair that an B<EVP_PKEY> contains is refered to
++The private/public key pair that an B<EVP_PKEY> contains is referred to
+ as its "internal key" or "origin" (the reason for "origin" is
+ explained further down, in L</Export cache for provider operations>),
+ and it can take one of the following forms:
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0014-KDF_CTX_new-API-has-incorrect-signature-const-should.patch b/package/libs/openssl/patches/0014-KDF_CTX_new-API-has-incorrect-signature-const-should.patch
new file mode 100644
index 0000000..ab0ade8
--- /dev/null
+++ b/package/libs/openssl/patches/0014-KDF_CTX_new-API-has-incorrect-signature-const-should.patch
@@ -0,0 +1,41 @@
+From 112754183a720b4db0f2770a80a55805010b4e68 Mon Sep 17 00:00:00 2001
+From: Shakti Shah <shaktishah33@gmail.com>
+Date: Sun, 11 Feb 2024 01:09:10 +0530
+Subject: [PATCH 14/76] KDF_CTX_new API has incorrect signature (const should
+ not be there)
+
+https://www.openssl.org/docs/man3.1/man3/EVP_KDF_CTX.html
+
+The pages for 3.0/3.1/master seem to have the following
+EVP_KDF_CTX *EVP_KDF_CTX_new(const EVP_KDF *kdf);
+
+which does not match with the actual header which is
+EVP_KDF_CTX *EVP_KDF_CTX_new(EVP_KDF *kdf);
+
+Fixes #23532
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23541)
+
+(cherry picked from commit 4f6133f9db2b9b7ce5e59d8b8ec38202a154c524)
+---
+ doc/man3/EVP_KDF.pod | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/doc/man3/EVP_KDF.pod b/doc/man3/EVP_KDF.pod
+index 31d61b2a3d..9009fd21c1 100644
+--- a/doc/man3/EVP_KDF.pod
++++ b/doc/man3/EVP_KDF.pod
+@@ -20,7 +20,7 @@ EVP_KDF_CTX_gettable_params, EVP_KDF_CTX_settable_params - EVP KDF routines
+  typedef struct evp_kdf_st EVP_KDF;
+  typedef struct evp_kdf_ctx_st EVP_KDF_CTX;
+ 
+- EVP_KDF_CTX *EVP_KDF_CTX_new(const EVP_KDF *kdf);
++ EVP_KDF_CTX *EVP_KDF_CTX_new(EVP_KDF *kdf);
+  const EVP_KDF *EVP_KDF_CTX_kdf(EVP_KDF_CTX *ctx);
+  void EVP_KDF_CTX_free(EVP_KDF_CTX *ctx);
+  EVP_KDF_CTX *EVP_KDF_CTX_dup(const EVP_KDF_CTX *src);
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0015-Check-for-NULL-cleanup-function-before-using-it-in-e.patch b/package/libs/openssl/patches/0015-Check-for-NULL-cleanup-function-before-using-it-in-e.patch
new file mode 100644
index 0000000..ea9ecad
--- /dev/null
+++ b/package/libs/openssl/patches/0015-Check-for-NULL-cleanup-function-before-using-it-in-e.patch
@@ -0,0 +1,40 @@
+From 3baa3531be6374428ba0e6e650f9dc2c2b4827a6 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Sat, 16 Dec 2023 15:32:48 -0500
+Subject: [PATCH 15/76] Check for NULL cleanup function before using it in
+ encoder_process
+
+encoder_process assumes a cleanup function has been set in the currently
+in-use encoder during processing, which can lead to segfaults if said
+function hasn't been set
+
+Add a NULL check for this condition, returning -1 if it is not set
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23069)
+
+(cherry picked from commit cf57c3ecfa416afbc47d36633981034809ee6792)
+---
+ crypto/encode_decode/encoder_lib.c | 5 +++++
+ 1 file changed, 5 insertions(+)
+
+diff --git a/crypto/encode_decode/encoder_lib.c b/crypto/encode_decode/encoder_lib.c
+index 7a55c7ab9a..74cda1ff0b 100644
+--- a/crypto/encode_decode/encoder_lib.c
++++ b/crypto/encode_decode/encoder_lib.c
+@@ -59,6 +59,11 @@ int OSSL_ENCODER_to_bio(OSSL_ENCODER_CTX *ctx, BIO *out)
+         return 0;
+     }
+ 
++    if (ctx->cleanup == NULL || ctx->construct == NULL) {
++        ERR_raise(ERR_LIB_OSSL_ENCODER, ERR_R_INIT_FAIL);
++        return 0;
++    }
++
+     return encoder_process(&data) > 0;
+ }
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0016-Fixed-Visual-Studio-2008-compiler-errors.patch b/package/libs/openssl/patches/0016-Fixed-Visual-Studio-2008-compiler-errors.patch
new file mode 100644
index 0000000..a4f6a1a
--- /dev/null
+++ b/package/libs/openssl/patches/0016-Fixed-Visual-Studio-2008-compiler-errors.patch
@@ -0,0 +1,31 @@
+From 70d9a358b9f736e10f7a8fda50953ad58b13a19e Mon Sep 17 00:00:00 2001
+From: Marcel Gosmann <thafiredragonofdeath@gmail.com>
+Date: Wed, 14 Feb 2024 11:35:47 +0100
+Subject: [PATCH 16/76] Fixed Visual Studio 2008 compiler errors
+
+CLA: trivial
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23586)
+
+(cherry picked from commit c3e8d67885c0c4295cfd1df35a41bf1f3fa9dc37)
+---
+ crypto/property/property_parse.c | 1 +
+ 1 file changed, 1 insertion(+)
+
+diff --git a/crypto/property/property_parse.c b/crypto/property/property_parse.c
+index 19ea39a786..397510823e 100644
+--- a/crypto/property/property_parse.c
++++ b/crypto/property/property_parse.c
+@@ -14,6 +14,7 @@
+ #include <openssl/err.h>
+ #include "internal/propertyerr.h"
+ #include "internal/property.h"
++#include "internal/numbers.h"
+ #include "crypto/ctype.h"
+ #include "internal/nelem.h"
+ #include "property_local.h"
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0017-Correct-the-defined-name-of-the-parameter-micalg-in-.patch b/package/libs/openssl/patches/0017-Correct-the-defined-name-of-the-parameter-micalg-in-.patch
new file mode 100644
index 0000000..a42b1cd
--- /dev/null
+++ b/package/libs/openssl/patches/0017-Correct-the-defined-name-of-the-parameter-micalg-in-.patch
@@ -0,0 +1,38 @@
+From 88038f5aec58b138d45f33a745b732e6510eba33 Mon Sep 17 00:00:00 2001
+From: Bernd Ritter <ritter@b1-systems.de>
+Date: Sat, 17 Feb 2024 19:15:14 +0100
+Subject: [PATCH 17/76] Correct the defined name of the parameter "micalg" in
+ the documentation
+
+The EVP_DigestInit(3) manual page contains wrong name for the define
+macro for the OSSL_DIGEST_PARAM_MICALG param.
+
+Fixes #23580
+
+CLA: trivial
+
+Reviewed-by: Paul Yang <kaishen.yy@antfin.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23615)
+
+(cherry picked from commit 5e5c256bbad572cf8d8d9ef9127722ca028d2704)
+---
+ doc/man3/EVP_DigestInit.pod | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/doc/man3/EVP_DigestInit.pod b/doc/man3/EVP_DigestInit.pod
+index 1953df3c5e..58968c44cb 100644
+--- a/doc/man3/EVP_DigestInit.pod
++++ b/doc/man3/EVP_DigestInit.pod
+@@ -483,7 +483,7 @@ EVP_MD_CTX_get_params() can be used with the following OSSL_PARAM keys:
+ 
+ =over 4
+ 
+-=item "micalg" (B<OSSL_PARAM_DIGEST_KEY_MICALG>) <UTF8 string>.
++=item "micalg" (B<OSSL_DIGEST_PARAM_MICALG>) <UTF8 string>.
+ 
+ Gets the digest Message Integrity Check algorithm string. This is used when
+ creating S/MIME multipart/signed messages, as specified in RFC 3851.
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0018-Don-t-print-excessively-long-ASN1-items-in-fuzzer.patch b/package/libs/openssl/patches/0018-Don-t-print-excessively-long-ASN1-items-in-fuzzer.patch
new file mode 100644
index 0000000..f54fae5
--- /dev/null
+++ b/package/libs/openssl/patches/0018-Don-t-print-excessively-long-ASN1-items-in-fuzzer.patch
@@ -0,0 +1,47 @@
+From 878d31954738369c35cbafbaa65e9201e9fc6d4b Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Tue, 20 Feb 2024 15:11:26 +0000
+Subject: [PATCH 18/76] Don't print excessively long ASN1 items in fuzzer
+
+Prevent spurious fuzzer timeouts by not printing ASN1 which is excessively
+long.
+
+This fixes a false positive encountered by OSS-Fuzz.
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23640)
+
+(cherry picked from commit 4a6f70c03182b421d326831532edca32bcdb3fb1)
+---
+ fuzz/asn1.c | 14 ++++++++++----
+ 1 file changed, 10 insertions(+), 4 deletions(-)
+
+diff --git a/fuzz/asn1.c b/fuzz/asn1.c
+index ee602a08a3..d55554b7fd 100644
+--- a/fuzz/asn1.c
++++ b/fuzz/asn1.c
+@@ -312,10 +312,16 @@ int FuzzerTestOneInput(const uint8_t *buf, size_t len)
+         ASN1_VALUE *o = ASN1_item_d2i(NULL, &b, len, i);
+ 
+         if (o != NULL) {
+-            BIO *bio = BIO_new(BIO_s_null());
+-            if (bio != NULL) {
+-                ASN1_item_print(bio, o, 4, i, pctx);
+-                BIO_free(bio);
++            /*
++             * Don't print excessively long output to prevent spurious fuzzer
++             * timeouts.
++             */
++            if (b - buf < 10000) {
++                BIO *bio = BIO_new(BIO_s_null());
++                if (bio != NULL) {
++                    ASN1_item_print(bio, o, 4, i, pctx);
++                    BIO_free(bio);
++                }
+             }
+             if (ASN1_item_i2d(o, &der, i) > 0) {
+                 OPENSSL_free(der);
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0019-Add-atexit-configuration-option-to-using-atexit-in-l.patch b/package/libs/openssl/patches/0019-Add-atexit-configuration-option-to-using-atexit-in-l.patch
new file mode 100644
index 0000000..3d1038a
--- /dev/null
+++ b/package/libs/openssl/patches/0019-Add-atexit-configuration-option-to-using-atexit-in-l.patch
@@ -0,0 +1,154 @@
+From 73a68d8adde293ad73cb66444b4b683a5697d686 Mon Sep 17 00:00:00 2001
+From: "Randall S. Becker" <randall.becker@nexbridge.ca>
+Date: Thu, 25 Jan 2024 22:11:27 +0000
+Subject: [PATCH 19/76] Add atexit configuration option to using atexit() in
+ libcrypto at build-time.
+
+This fixes an issue with a mix of atexit() usage in DLL and statically linked
+libcrypto that came out in the test suite on NonStop, which has slightly
+different DLL unload processing semantics compared to Linux. The change
+allows a build configuration to select whether to register OPENSSL_cleanup()
+with atexit() or not, so avoid situations where atexit() registration causes
+SIGSEGV.
+
+INSTALL.md and CHANGES.md have been modified to include and describe this
+option.
+
+Signed-off-by: Randall S. Becker <randall.becker@nexbridge.ca>
+Signed-off-by: Tomas Mraz <tomas@openssl.org>
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23642)
+
+(cherry picked from commit 0e1989d4c7435809b60f614c23ba8c9a7c0373e8)
+---
+ .github/workflows/run-checker-ci.yml |  1 +
+ CHANGES.md                           |  6 +++++-
+ Configure                            |  1 +
+ INSTALL.md                           |  7 +++++++
+ NOTES-NONSTOP.md                     |  5 ++++-
+ crypto/init.c                        | 12 +++++++-----
+ test/recipes/90-test_shlibload.t     |  1 +
+ 7 files changed, 26 insertions(+), 7 deletions(-)
+
+diff --git a/.github/workflows/run-checker-ci.yml b/.github/workflows/run-checker-ci.yml
+index 101c44f1b2..1f033fdba9 100644
+--- a/.github/workflows/run-checker-ci.yml
++++ b/.github/workflows/run-checker-ci.yml
+@@ -17,6 +17,7 @@ jobs:
+       fail-fast: false
+       matrix:
+         opt: [
++          no-atexit,
+           no-cmp,
+           no-cms,
+           no-ct,
+diff --git a/CHANGES.md b/CHANGES.md
+index 91dd358db8..b42dd83bc0 100644
+--- a/CHANGES.md
++++ b/CHANGES.md
+@@ -30,7 +30,11 @@ breaking changes, and mappings for the large list of deprecated functions.
+ 
+ ### Changes between 3.0.13 and 3.0.14 [xx XXX xxxx]
+ 
+- * none yet
++ * New atexit configuration switch, which controls whether the OPENSSL_cleanup
++   is registered when libcrypto is unloaded. This can be used on platforms
++   where using atexit() from shared libraries causes crashes on exit.
++
++   *Randall S. Becker*
+ 
+ ### Changes between 3.0.12 and 3.0.13 [30 Jan 2024]
+ 
+diff --git a/Configure b/Configure
+index 84cc409464..ab90de6ccc 100755
+--- a/Configure
++++ b/Configure
+@@ -405,6 +405,7 @@ my @disablables = (
+     "asan",
+     "asm",
+     "async",
++    "atexit",
+     "autoalginit",
+     "autoerrinit",
+     "autoload-config",
+diff --git a/INSTALL.md b/INSTALL.md
+index fef408e9d1..045b13739b 100644
+--- a/INSTALL.md
++++ b/INSTALL.md
+@@ -546,6 +546,13 @@ be used even with this option.
+ 
+ Do not build support for async operations.
+ 
++### no-atexit
++
++Do not use `atexit()` in libcrypto builds.
++
++`atexit()` has varied semantics between platforms and can cause SIGSEGV in some
++circumstances. This options disables the atexit registration of OPENSSL_cleanup.
++
+ ### no-autoalginit
+ 
+ Don't automatically load all supported ciphers and digests.
+diff --git a/NOTES-NONSTOP.md b/NOTES-NONSTOP.md
+index 68438b9988..ab13de7d3a 100644
+--- a/NOTES-NONSTOP.md
++++ b/NOTES-NONSTOP.md
+@@ -56,7 +56,10 @@ relating to `atexit()` processing when a shared library is unloaded and when
+ the program terminates. This limitation applies to all OpenSSL shared library
+ components.
+ 
+-A resolution to this situation is under investigation.
++It is possible to configure the build with `no-atexit` to avoid the SIGSEGV.
++Preferably, you can explicitly call `OPENSSL_cleanup()` from your application.
++It is not mandatory as it just deallocates various global data structures
++OpenSSL allocated.
+ 
+ About Prefix and OpenSSLDir
+ ---------------------------
+diff --git a/crypto/init.c b/crypto/init.c
+index cacf637c89..994f752b4e 100644
+--- a/crypto/init.c
++++ b/crypto/init.c
+@@ -97,17 +97,19 @@ static int win32atexit(void)
+ 
+ DEFINE_RUN_ONCE_STATIC(ossl_init_register_atexit)
+ {
+-#ifdef OPENSSL_INIT_DEBUG
++#ifndef OPENSSL_NO_ATEXIT
++# ifdef OPENSSL_INIT_DEBUG
+     fprintf(stderr, "OPENSSL_INIT: ossl_init_register_atexit()\n");
+-#endif
+-#ifndef OPENSSL_SYS_UEFI
+-# if defined(_WIN32) && !defined(__BORLANDC__)
++# endif
++# ifndef OPENSSL_SYS_UEFI
++#  if defined(_WIN32) && !defined(__BORLANDC__)
+     /* We use _onexit() in preference because it gets called on DLL unload */
+     if (_onexit(win32atexit) == NULL)
+         return 0;
+-# else
++#  else
+     if (atexit(OPENSSL_cleanup) != 0)
+         return 0;
++#  endif
+ # endif
+ #endif
+ 
+diff --git a/test/recipes/90-test_shlibload.t b/test/recipes/90-test_shlibload.t
+index 8f691dee38..af6bae20af 100644
+--- a/test/recipes/90-test_shlibload.t
++++ b/test/recipes/90-test_shlibload.t
+@@ -23,6 +23,7 @@ plan skip_all => "Test is disabled on AIX" if config('target') =~ m|^aix|;
+ plan skip_all => "Test is disabled on NonStop" if config('target') =~ m|^nonstop|;
+ plan skip_all => "Test only supported in a dso build" if disabled("dso");
+ plan skip_all => "Test is disabled in an address sanitizer build" unless disabled("asan");
++plan skip_all => "Test is disabled if no-atexit is specified" if disabled("atexit");
+ 
+ plan tests => 10;
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0020-Minor-wording-fixes-related-to-no-atexit.patch b/package/libs/openssl/patches/0020-Minor-wording-fixes-related-to-no-atexit.patch
new file mode 100644
index 0000000..e245910
--- /dev/null
+++ b/package/libs/openssl/patches/0020-Minor-wording-fixes-related-to-no-atexit.patch
@@ -0,0 +1,44 @@
+From d3457f990c6acedf54a40e3ef9ada9d5904c66ef Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Tue, 20 Feb 2024 18:42:24 +0100
+Subject: [PATCH 20/76] Minor wording fixes related to no-atexit
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+(Merged from https://github.com/openssl/openssl/pull/23642)
+
+(cherry picked from commit 66e6f72c3e4221580a7f456ddeaa5027f0bbb8b7)
+---
+ INSTALL.md                       | 2 +-
+ test/recipes/90-test_shlibload.t | 2 +-
+ 2 files changed, 2 insertions(+), 2 deletions(-)
+
+diff --git a/INSTALL.md b/INSTALL.md
+index 045b13739b..21e82b4f91 100644
+--- a/INSTALL.md
++++ b/INSTALL.md
+@@ -551,7 +551,7 @@ Do not build support for async operations.
+ Do not use `atexit()` in libcrypto builds.
+ 
+ `atexit()` has varied semantics between platforms and can cause SIGSEGV in some
+-circumstances. This options disables the atexit registration of OPENSSL_cleanup.
++circumstances. This option disables the atexit registration of OPENSSL_cleanup.
+ 
+ ### no-autoalginit
+ 
+diff --git a/test/recipes/90-test_shlibload.t b/test/recipes/90-test_shlibload.t
+index af6bae20af..ccd7fa43e3 100644
+--- a/test/recipes/90-test_shlibload.t
++++ b/test/recipes/90-test_shlibload.t
+@@ -23,7 +23,7 @@ plan skip_all => "Test is disabled on AIX" if config('target') =~ m|^aix|;
+ plan skip_all => "Test is disabled on NonStop" if config('target') =~ m|^nonstop|;
+ plan skip_all => "Test only supported in a dso build" if disabled("dso");
+ plan skip_all => "Test is disabled in an address sanitizer build" unless disabled("asan");
+-plan skip_all => "Test is disabled if no-atexit is specified" if disabled("atexit");
++plan skip_all => "Test is disabled in no-atexit build" if disabled("atexit");
+ 
+ plan tests => 10;
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0021-s_cb.c-Add-missing-return-value-checks.patch b/package/libs/openssl/patches/0021-s_cb.c-Add-missing-return-value-checks.patch
new file mode 100644
index 0000000..240b9a8
--- /dev/null
+++ b/package/libs/openssl/patches/0021-s_cb.c-Add-missing-return-value-checks.patch
@@ -0,0 +1,45 @@
+From 6f794b461c6e16c8afb996ee190e084cbbddb6b8 Mon Sep 17 00:00:00 2001
+From: MrRurikov <96385824+MrRurikov@users.noreply.github.com>
+Date: Wed, 21 Feb 2024 11:11:34 +0300
+Subject: [PATCH 21/76] s_cb.c: Add missing return value checks
+
+Return value of function 'SSL_CTX_ctrl', that is called from
+SSL_CTX_set1_verify_cert_store() and SSL_CTX_set1_chain_cert_store(),
+is not checked, but it is usually checked for this function.
+
+CLA: trivial
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23647)
+---
+ apps/lib/s_cb.c | 6 ++++--
+ 1 file changed, 4 insertions(+), 2 deletions(-)
+
+diff --git a/apps/lib/s_cb.c b/apps/lib/s_cb.c
+index f2ddd94c3d..e869831e20 100644
+--- a/apps/lib/s_cb.c
++++ b/apps/lib/s_cb.c
+@@ -1318,7 +1318,8 @@ int ssl_load_stores(SSL_CTX *ctx,
+         if (vfyCAstore != NULL && !X509_STORE_load_store(vfy, vfyCAstore))
+             goto err;
+         add_crls_store(vfy, crls);
+-        SSL_CTX_set1_verify_cert_store(ctx, vfy);
++        if (SSL_CTX_set1_verify_cert_store(ctx, vfy) == 0)
++            goto err;
+         if (crl_download)
+             store_setup_crl_download(vfy);
+     }
+@@ -1332,7 +1333,8 @@ int ssl_load_stores(SSL_CTX *ctx,
+             goto err;
+         if (chCAstore != NULL && !X509_STORE_load_store(ch, chCAstore))
+             goto err;
+-        SSL_CTX_set1_chain_cert_store(ctx, ch);
++        if (SSL_CTX_set1_chain_cert_store(ctx, ch) == 0)
++            goto err;
+     }
+     rv = 1;
+  err:
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0022-SSL_set1_groups_list-Fix-memory-corruption-with-40-g.patch b/package/libs/openssl/patches/0022-SSL_set1_groups_list-Fix-memory-corruption-with-40-g.patch
new file mode 100644
index 0000000..5e212c1
--- /dev/null
+++ b/package/libs/openssl/patches/0022-SSL_set1_groups_list-Fix-memory-corruption-with-40-g.patch
@@ -0,0 +1,106 @@
+From d9d260eb95ec129b93a55965b6f2f392df0ed0a9 Mon Sep 17 00:00:00 2001
+From: Michael Baentsch <57787676+baentsch@users.noreply.github.com>
+Date: Mon, 19 Feb 2024 06:41:35 +0100
+Subject: [PATCH 22/76] SSL_set1_groups_list(): Fix memory corruption with 40
+ groups and more
+
+Fixes #23624
+
+The calculation of the size for gid_arr reallocation was wrong.
+A multiplication by gid_arr array item size was missing.
+
+Testcase is added.
+
+Reviewed-by: Nicola Tuveri <nic.tuv@gmail.com>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Cherry-pick from https://github.com/openssl/openssl/pull/23625)
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23661)
+---
+ ssl/t1_lib.c        |  3 ++-
+ test/sslapitest.c   | 15 ++++-----------
+ test/tls-provider.c |  7 +++++--
+ 3 files changed, 11 insertions(+), 14 deletions(-)
+
+diff --git a/ssl/t1_lib.c b/ssl/t1_lib.c
+index 8be00a4f34..d775ba56da 100644
+--- a/ssl/t1_lib.c
++++ b/ssl/t1_lib.c
+@@ -734,7 +734,8 @@ static int gid_cb(const char *elem, int len, void *arg)
+         return 0;
+     if (garg->gidcnt == garg->gidmax) {
+         uint16_t *tmp =
+-            OPENSSL_realloc(garg->gid_arr, garg->gidmax + GROUPLIST_INCREMENT);
++            OPENSSL_realloc(garg->gid_arr,
++                            (garg->gidmax + GROUPLIST_INCREMENT) * sizeof(*garg->gid_arr));
+         if (tmp == NULL)
+             return 0;
+         garg->gidmax += GROUPLIST_INCREMENT;
+diff --git a/test/sslapitest.c b/test/sslapitest.c
+index e0274f12f7..231f498199 100644
+--- a/test/sslapitest.c
++++ b/test/sslapitest.c
+@@ -9269,20 +9269,11 @@ static int test_pluggable_group(int idx)
+     OSSL_PROVIDER *tlsprov = OSSL_PROVIDER_load(libctx, "tls-provider");
+     /* Check that we are not impacted by a provider without any groups */
+     OSSL_PROVIDER *legacyprov = OSSL_PROVIDER_load(libctx, "legacy");
+-    const char *group_name = idx == 0 ? "xorgroup" : "xorkemgroup";
++    const char *group_name = idx == 0 ? "xorkemgroup" : "xorgroup";
+ 
+     if (!TEST_ptr(tlsprov))
+         goto end;
+ 
+-    if (legacyprov == NULL) {
+-        /*
+-         * In this case we assume we've been built with "no-legacy" and skip
+-         * this test (there is no OPENSSL_NO_LEGACY)
+-         */
+-        testresult = 1;
+-        goto end;
+-    }
+-
+     if (!TEST_true(create_ssl_ctx_pair(libctx, TLS_server_method(),
+                                        TLS_client_method(),
+                                        TLS1_3_VERSION,
+@@ -9292,7 +9283,9 @@ static int test_pluggable_group(int idx)
+                                              NULL, NULL)))
+         goto end;
+ 
+-    if (!TEST_true(SSL_set1_groups_list(serverssl, group_name))
++    /* ensure GROUPLIST_INCREMENT (=40) logic triggers: */
++    if (!TEST_true(SSL_set1_groups_list(serverssl, "xorgroup:xorkemgroup:dummy1:dummy2:dummy3:dummy4:dummy5:dummy6:dummy7:dummy8:dummy9:dummy10:dummy11:dummy12:dummy13:dummy14:dummy15:dummy16:dummy17:dummy18:dummy19:dummy20:dummy21:dummy22:dummy23:dummy24:dummy25:dummy26:dummy27:dummy28:dummy29:dummy30:dummy31:dummy32:dummy33:dummy34:dummy35:dummy36:dummy37:dummy38:dummy39:dummy40:dummy41:dummy42:dummy43"))
++    /* removing a single algorithm from the list makes the test pass */
+             || !TEST_true(SSL_set1_groups_list(clientssl, group_name)))
+         goto end;
+ 
+diff --git a/test/tls-provider.c b/test/tls-provider.c
+index 5c44b6812e..eff6f76150 100644
+--- a/test/tls-provider.c
++++ b/test/tls-provider.c
+@@ -210,6 +210,8 @@ static int tls_prov_get_capabilities(void *provctx, const char *capability,
+         }
+         dummygroup[0].data = dummy_group_names[i];
+         dummygroup[0].data_size = strlen(dummy_group_names[i]) + 1;
++        /* assign unique group IDs also to dummy groups for registration */
++        *((int *)(dummygroup[3].data)) = 65279 - NUM_DUMMY_GROUPS + i;
+         ret &= cb(dummygroup, arg);
+     }
+ 
+@@ -817,9 +819,10 @@ unsigned int randomize_tls_group_id(OSSL_LIB_CTX *libctx)
+         return 0;
+     /*
+      * Ensure group_id is within the IANA Reserved for private use range
+-     * (65024-65279)
++     * (65024-65279).
++     * Carve out NUM_DUMMY_GROUPS ids for properly registering those.
+      */
+-    group_id %= 65279 - 65024;
++    group_id %= 65279 - NUM_DUMMY_GROUPS - 65024;
+     group_id += 65024;
+ 
+     /* Ensure we did not already issue this group_id */
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0023-Ensure-MAKE-commands-and-CFLAGS-are-appropriately-qu.patch b/package/libs/openssl/patches/0023-Ensure-MAKE-commands-and-CFLAGS-are-appropriately-qu.patch
new file mode 100644
index 0000000..30bfd2b
--- /dev/null
+++ b/package/libs/openssl/patches/0023-Ensure-MAKE-commands-and-CFLAGS-are-appropriately-qu.patch
@@ -0,0 +1,103 @@
+From 1dea252221624542ca258231e5dc4c8bb528a97b Mon Sep 17 00:00:00 2001
+From: Hamilton Chapman <hamchapman@gmail.com>
+Date: Wed, 21 Feb 2024 13:47:19 +0000
+Subject: [PATCH 23/76] Ensure `$(MAKE)` commands and `CFLAGS` are
+ appropriately quoted in the Makefile.
+
+If a user's `make` command came from a path that contained a space then both the
+`$(MAKE)` variable (and parts of the generated `CFLAGS`, when building for iOS)
+would not be properly quoted and the build would fail.
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23663)
+
+(cherry picked from commit aba621934696ca52193bd41cd35816649b6b321b)
+---
+ Configurations/15-ios.conf        |  6 +++---
+ Configurations/unix-Makefile.tmpl | 14 +++++++-------
+ 2 files changed, 10 insertions(+), 10 deletions(-)
+
+diff --git a/Configurations/15-ios.conf b/Configurations/15-ios.conf
+index 54d37f63f4..81e3d68bc7 100644
+--- a/Configurations/15-ios.conf
++++ b/Configurations/15-ios.conf
+@@ -49,16 +49,16 @@ my %targets = (
+ #
+     "iphoneos-cross" => {
+         inherit_from     => [ "ios-common" ],
+-        cflags           => add("-isysroot \$(CROSS_TOP)/SDKs/\$(CROSS_SDK) -fno-common"),
++        cflags           => add("-isysroot \"\$(CROSS_TOP)/SDKs/\$(CROSS_SDK)\" -fno-common"),
+     },
+     "ios-cross" => {
+         inherit_from     => [ "ios-xcrun" ],
+         CC               => "cc",
+-        cflags           => add("-isysroot \$(CROSS_TOP)/SDKs/\$(CROSS_SDK)"),
++        cflags           => add("-isysroot \"\$(CROSS_TOP)/SDKs/\$(CROSS_SDK)\""),
+     },
+     "ios64-cross" => {
+         inherit_from     => [ "ios64-xcrun" ],
+         CC               => "cc",
+-        cflags           => add("-isysroot \$(CROSS_TOP)/SDKs/\$(CROSS_SDK)"),
++        cflags           => add("-isysroot \"\$(CROSS_TOP)/SDKs/\$(CROSS_SDK)\""),
+     },
+ );
+diff --git a/Configurations/unix-Makefile.tmpl b/Configurations/unix-Makefile.tmpl
+index 3754595d38..644540397d 100644
+--- a/Configurations/unix-Makefile.tmpl
++++ b/Configurations/unix-Makefile.tmpl
+@@ -21,7 +21,7 @@
+      sub dependmagic {
+          my $target = shift;
+ 
+-         return "$target: build_generated\n\t\$(MAKE) depend && \$(MAKE) _$target\n_$target";
++         return "$target: build_generated\n\t\"\$(MAKE)\" depend && \"\$(MAKE)\" _$target\n_$target";
+      }
+ 
+      our $COLUMNS = $ENV{COLUMNS};
+@@ -527,7 +527,7 @@ all: build_sw build_docs
+ 
+ test: tests
+ {- dependmagic('tests'); -}: build_programs_nodep build_modules_nodep link-utils
+-	$(MAKE) run_tests
++	"$(MAKE)" run_tests
+ run_tests: FORCE
+ 	@ : {- output_off() if $disabled{tests}; "" -}
+ 	( SRCTOP=$(SRCDIR) \
+@@ -542,7 +542,7 @@ run_tests: FORCE
+ 
+ list-tests:
+ 	@ : {- output_off() if $disabled{tests}; "" -}
+-	$(MAKE) run_tests TESTS=list
++	"$(MAKE)" run_tests TESTS=list
+ 	@ : {- if ($disabled{tests}) { output_on(); } else { output_off(); } "" -}
+ 	@echo "Tests are not supported with your chosen Configure options"
+ 	@ : {- output_on() if !$disabled{tests}; "" -}
+@@ -1193,12 +1193,12 @@ providers/fips.module.sources.new: configdata.pm
+ 	  cd sources-tmp \
+ 	  && $$srcdir/Configure --banner=Configured enable-fips -O0 \
+ 	  && ./configdata.pm --query 'get_sources("providers/fips")' > sources1 \
+-	  && $(MAKE) -sj 4 build_generated providers/fips.so \
++	  && "$(MAKE)" -sj 4 build_generated providers/fips.so \
+ 	  && find . -name '*.d' | xargs cat > dep1 \
+-          && $(MAKE) distclean \
++          && "$(MAKE)" distclean \
+ 	  && $$srcdir/Configure --banner=Configured enable-fips no-asm -O0 \
+ 	  && ./configdata.pm --query 'get_sources("providers/fips")' > sources2 \
+-	  && $(MAKE) -sj 4 build_generated providers/fips.so \
++	  && "$(MAKE)" -sj 4 build_generated providers/fips.so \
+ 	  && find . -name '*.d' | xargs cat > dep2 \
+ 	  && cat sources1 sources2 \
+ 	     | grep -v ' : \\$$' | grep -v util/providers.num \
+@@ -1332,7 +1332,7 @@ ordinals: build_generated
+                 $(SSLHEADERS)
+ 
+ test_ordinals:
+-	$(MAKE) run_tests TESTS=test_ordinals
++	"$(MAKE)" run_tests TESTS=test_ordinals
+ 
+ tags TAGS: FORCE
+ 	rm -f TAGS tags
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0024-Fix-off-by-one-issue-in-buf2hexstr_sep.patch b/package/libs/openssl/patches/0024-Fix-off-by-one-issue-in-buf2hexstr_sep.patch
new file mode 100644
index 0000000..c8a322e
--- /dev/null
+++ b/package/libs/openssl/patches/0024-Fix-off-by-one-issue-in-buf2hexstr_sep.patch
@@ -0,0 +1,32 @@
+From d44aa28b0db3ba355fe68c5971c90c9a1414788f Mon Sep 17 00:00:00 2001
+From: shridhar kalavagunta <coolshrid@hotmail.com>
+Date: Fri, 26 Jan 2024 21:10:32 -0600
+Subject: [PATCH 24/76] Fix off by one issue in buf2hexstr_sep()
+
+Fixes #23363
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23404)
+
+(cherry picked from commit c5cc9c419a0a8d97a44f01f95f0e213f56da4574)
+---
+ crypto/o_str.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/crypto/o_str.c b/crypto/o_str.c
+index 7fa487dd5f..bfbc2ca5e3 100644
+--- a/crypto/o_str.c
++++ b/crypto/o_str.c
+@@ -251,7 +251,7 @@ static int buf2hexstr_sep(char *str, size_t str_n, size_t *strlength,
+     *q = CH_ZERO;
+ 
+ #ifdef CHARSET_EBCDIC
+-    ebcdic2ascii(str, str, q - str - 1);
++    ebcdic2ascii(str, str, q - str);
+ #endif
+     return 1;
+ }
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0025-Dont-run-the-self-hosted-workflows-when-not-availabl.patch b/package/libs/openssl/patches/0025-Dont-run-the-self-hosted-workflows-when-not-availabl.patch
new file mode 100644
index 0000000..278bbbe
--- /dev/null
+++ b/package/libs/openssl/patches/0025-Dont-run-the-self-hosted-workflows-when-not-availabl.patch
@@ -0,0 +1,29 @@
+From 3d62e492e28686eaab00b432ec82c0602326bced Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Fri, 23 Feb 2024 12:04:38 +0100
+Subject: [PATCH 25/76] Dont run the self-hosted workflows when not available
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23678)
+
+(cherry picked from commit 74fd6823884e27c18ec3fe7bd99b9bc02e6f31f3)
+---
+ .github/workflows/ci.yml | 1 +
+ 1 file changed, 1 insertion(+)
+
+diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
+index ed5ffde089..6952a65ce7 100644
+--- a/.github/workflows/ci.yml
++++ b/.github/workflows/ci.yml
+@@ -93,6 +93,7 @@ jobs:
+       run: make test HARNESS_JOBS=${HARNESS_JOBS:-4}
+ 
+   self-hosted:
++    if: github.repository == 'openssl/openssl'
+     strategy:
+       matrix:
+         os: [freebsd-13.2, ubuntu-arm64-22.04]
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0026-Try-to-fix-intermittent-CI-failures-in-sslapitest.patch b/package/libs/openssl/patches/0026-Try-to-fix-intermittent-CI-failures-in-sslapitest.patch
new file mode 100644
index 0000000..f6eb3cc
--- /dev/null
+++ b/package/libs/openssl/patches/0026-Try-to-fix-intermittent-CI-failures-in-sslapitest.patch
@@ -0,0 +1,48 @@
+From f57a462abbf93f3fcdc25cf71e01fe005560e651 Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Wed, 28 Feb 2024 07:14:08 +0100
+Subject: [PATCH 26/76] Try to fix intermittent CI failures in sslapitest
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+(Merged from https://github.com/openssl/openssl/pull/23774)
+
+(cherry picked from commit 98dd1f7266d66614a4e04e921e74303f14cea7df)
+---
+ test/tls-provider.c | 6 +++++-
+ 1 file changed, 5 insertions(+), 1 deletion(-)
+
+diff --git a/test/tls-provider.c b/test/tls-provider.c
+index eff6f76150..57adcac783 100644
+--- a/test/tls-provider.c
++++ b/test/tls-provider.c
+@@ -185,6 +185,8 @@ static int tls_prov_get_capabilities(void *provctx, const char *capability,
+     }
+ 
+     /* Register our 2 groups */
++    OPENSSL_assert(xor_group.group_id >= 65024
++                   && xor_group.group_id < 65279 - NUM_DUMMY_GROUPS);
+     ret = cb(xor_group_params, arg);
+     ret &= cb(xor_kemgroup_params, arg);
+ 
+@@ -196,6 +198,7 @@ static int tls_prov_get_capabilities(void *provctx, const char *capability,
+ 
+     for (i = 0; i < NUM_DUMMY_GROUPS; i++) {
+         OSSL_PARAM dummygroup[OSSL_NELEM(xor_group_params)];
++        unsigned int dummygroup_id;
+ 
+         memcpy(dummygroup, xor_group_params, sizeof(xor_group_params));
+ 
+@@ -211,7 +214,8 @@ static int tls_prov_get_capabilities(void *provctx, const char *capability,
+         dummygroup[0].data = dummy_group_names[i];
+         dummygroup[0].data_size = strlen(dummy_group_names[i]) + 1;
+         /* assign unique group IDs also to dummy groups for registration */
+-        *((int *)(dummygroup[3].data)) = 65279 - NUM_DUMMY_GROUPS + i;
++        dummygroup_id = 65279 - NUM_DUMMY_GROUPS + i;
++        dummygroup[3].data = (unsigned char*)&dummygroup_id;
+         ret &= cb(dummygroup, arg);
+     }
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0027-FAQ.md-should-be-removed.patch b/package/libs/openssl/patches/0027-FAQ.md-should-be-removed.patch
new file mode 100644
index 0000000..3e2cd74
--- /dev/null
+++ b/package/libs/openssl/patches/0027-FAQ.md-should-be-removed.patch
@@ -0,0 +1,33 @@
+From e24965adffb87a9355cbab1d2a906bcb8ed98e0a Mon Sep 17 00:00:00 2001
+From: Alexandr Nedvedicky <sashan@openssl.org>
+Date: Fri, 1 Mar 2024 08:25:19 +0100
+Subject: [PATCH 27/76] FAQ.md should be removed
+
+the page the link refers to does not exist.
+Anyone objects to delete file?
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23719)
+
+(cherry picked from commit 854539889d31ed2ea63280256fd7aab66e828ae5)
+---
+ FAQ.md | 6 ------
+ 1 file changed, 6 deletions(-)
+ delete mode 100644 FAQ.md
+
+diff --git a/FAQ.md b/FAQ.md
+deleted file mode 100644
+index 30f5010ce3..0000000000
+--- a/FAQ.md
++++ /dev/null
+@@ -1,6 +0,0 @@
+-Frequently Asked Questions (FAQ)
+-================================
+-
+-The [Frequently Asked Questions][FAQ] are now maintained on the OpenSSL homepage.
+-
+-  [FAQ]: https://www.openssl.org/docs/faq.html
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0028-Doc-fix-style.patch b/package/libs/openssl/patches/0028-Doc-fix-style.patch
new file mode 100644
index 0000000..f740004
--- /dev/null
+++ b/package/libs/openssl/patches/0028-Doc-fix-style.patch
@@ -0,0 +1,61 @@
+From 650cac22ed95430d15cff9b0ade9edce6c4145aa Mon Sep 17 00:00:00 2001
+From: =?UTF-8?q?=E8=B0=AD=E4=B9=9D=E9=BC=8E?= <109224573@qq.com>
+Date: Sun, 10 Mar 2024 02:18:05 +0000
+Subject: [PATCH 28/76] Doc: fix style
+
+CLA: trivial
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23805)
+
+(cherry picked from commit 52a75f4088f2b2c59721152d9ec6ecf4d17c7e43)
+---
+ doc/man1/openssl-mac.pod.in | 15 ++++++++++-----
+ 1 file changed, 10 insertions(+), 5 deletions(-)
+
+diff --git a/doc/man1/openssl-mac.pod.in b/doc/man1/openssl-mac.pod.in
+index 5639747991..053c6910b2 100644
+--- a/doc/man1/openssl-mac.pod.in
++++ b/doc/man1/openssl-mac.pod.in
+@@ -123,26 +123,31 @@ To see the list of supported MAC's use the command C<openssl list
+ 
+ =head1 EXAMPLES
+ 
+-To create a hex-encoded HMAC-SHA1 MAC of a file and write to stdout: \
++To create a hex-encoded HMAC-SHA1 MAC of a file and write to stdout:
++
+  openssl mac -digest SHA1 \
+          -macopt hexkey:000102030405060708090A0B0C0D0E0F10111213 \
+          -in msg.bin HMAC
+ 
+-To create a SipHash MAC from a file with a binary file output: \
++To create a SipHash MAC from a file with a binary file output:
++
+  openssl mac -macopt hexkey:000102030405060708090A0B0C0D0E0F \
+          -in msg.bin -out out.bin -binary SipHash
+ 
+-To create a hex-encoded CMAC-AES-128-CBC MAC from a file:\
++To create a hex-encoded CMAC-AES-128-CBC MAC from a file:
++
+  openssl mac -cipher AES-128-CBC \
+          -macopt hexkey:77A77FAF290C1FA30C683DF16BA7A77B \
+          -in msg.bin CMAC
+ 
+ To create a hex-encoded KMAC128 MAC from a file with a Customisation String
+-'Tag' and output length of 16: \
++'Tag' and output length of 16:
++
+  openssl mac -macopt custom:Tag -macopt hexkey:40414243444546 \
+          -macopt size:16 -in msg.bin KMAC128
+ 
+-To create a hex-encoded GMAC-AES-128-GCM with a IV from a file: \
++To create a hex-encoded GMAC-AES-128-GCM with a IV from a file:
++
+  openssl mac -cipher AES-128-GCM -macopt hexiv:E0E00F19FED7BA0136A797F3 \
+          -macopt hexkey:77A77FAF290C1FA30C683DF16BA7A77B -in msg.bin GMAC
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0029-Fix-dasync_rsa_decrypt-to-call-EVP_PKEY_meth_get_dec.patch b/package/libs/openssl/patches/0029-Fix-dasync_rsa_decrypt-to-call-EVP_PKEY_meth_get_dec.patch
new file mode 100644
index 0000000..8c09ec9
--- /dev/null
+++ b/package/libs/openssl/patches/0029-Fix-dasync_rsa_decrypt-to-call-EVP_PKEY_meth_get_dec.patch
@@ -0,0 +1,33 @@
+From 17d12183797033f55aec03376ffd3969cd703c0e Mon Sep 17 00:00:00 2001
+From: Vladimirs Ambrosovs <rodriguez.twister@gmail.com>
+Date: Tue, 12 Mar 2024 18:23:55 +0200
+Subject: [PATCH 29/76] Fix dasync_rsa_decrypt to call
+ EVP_PKEY_meth_get_decrypt
+
+Signed-off-by: Vladimirs Ambrosovs <rodriguez.twister@gmail.com>
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23825)
+
+(cherry picked from commit c91f0ca95881d03a54aedee197bbf5ffffc02935)
+---
+ engines/e_dasync.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/engines/e_dasync.c b/engines/e_dasync.c
+index 7974106ae2..aa7b2bce2f 100644
+--- a/engines/e_dasync.c
++++ b/engines/e_dasync.c
+@@ -985,7 +985,7 @@ static int dasync_rsa_decrypt(EVP_PKEY_CTX *ctx, unsigned char *out,
+                              size_t inlen);
+ 
+     if (pdecrypt == NULL)
+-        EVP_PKEY_meth_get_encrypt(dasync_rsa_orig, NULL, &pdecrypt);
++        EVP_PKEY_meth_get_decrypt(dasync_rsa_orig, NULL, &pdecrypt);
+     return pdecrypt(ctx, out, outlen, in, inlen);
+ }
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0030-Fix-ASLR-to-be-smaller-during-asan-tsan-ubsan-runs.patch b/package/libs/openssl/patches/0030-Fix-ASLR-to-be-smaller-during-asan-tsan-ubsan-runs.patch
new file mode 100644
index 0000000..ef912e2
--- /dev/null
+++ b/package/libs/openssl/patches/0030-Fix-ASLR-to-be-smaller-during-asan-tsan-ubsan-runs.patch
@@ -0,0 +1,106 @@
+From f990d1684a674474d53c79531596e88861334e0c Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Thu, 14 Mar 2024 12:04:17 -0400
+Subject: [PATCH 30/76] Fix ASLR to be smaller during asan/tsan/ubsan runs
+
+Recently asan/tsan/ubsan runs have been failing randomly.  It appears
+that a recent runner update may have led to the Address Space Layout
+Randomization setting in the linux kernel of ubuntu-latest runner
+getting set to too high a value (it defaults to 30).  Such a setting
+leads to the possibility that a given application will have memory
+mapped to an address space that the sanitizer code typically uses to do
+its job.  Lowering this value allows a/t/ubsan to work consistently
+again
+
+Reviewed-by: Tim Hudson <tjh@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23842)
+
+(cherry picked from commit 37cd49f57f9ce4128381ca122b0ac8ca21395265)
+---
+ .github/workflows/ci.yml                | 16 ++++++++++++++++
+ .github/workflows/fuzz-checker.yml      |  4 ++++
+ .github/workflows/run-checker-merge.yml |  4 ++++
+ 3 files changed, 24 insertions(+)
+
+diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
+index 6952a65ce7..7e99dedf7c 100644
+--- a/.github/workflows/ci.yml
++++ b/.github/workflows/ci.yml
+@@ -161,6 +161,10 @@ jobs:
+     runs-on: ${{ github.server_url == 'https://github.com' && 'ubuntu-latest' || 'ubuntu-22.04-self-hosted' }}
+     steps:
+     - uses: actions/checkout@v4
++    - name: Adjust ASLR for sanitizer
++      run: |
++        sudo cat /proc/sys/vm/mmap_rnd_bits
++        sudo sysctl -w vm.mmap_rnd_bits=28
+     - name: config
+       run: ./config --banner=Configured --debug enable-asan enable-ubsan no-cached-fetch no-fips no-dtls no-tls1 no-tls1-method no-tls1_1 no-tls1_1-method no-async && perl configdata.pm --dump
+     - name: make
+@@ -172,6 +176,10 @@ jobs:
+     runs-on: ${{ github.server_url == 'https://github.com' && 'ubuntu-latest' || 'ubuntu-22.04-self-hosted' }}
+     steps:
+     - uses: actions/checkout@v4
++    - name: Adjust ASLR for sanitizer
++      run: |
++        sudo cat /proc/sys/vm/mmap_rnd_bits
++        sudo sysctl -w vm.mmap_rnd_bits=28
+     - name: config
+       run: ./config --banner=Configured --debug enable-asan enable-ubsan enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-fips -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION && perl configdata.pm --dump
+     - name: make
+@@ -183,6 +191,10 @@ jobs:
+     runs-on: ${{ github.server_url == 'https://github.com' && 'ubuntu-latest' || 'ubuntu-22.04-self-hosted' }}
+     steps:
+     - uses: actions/checkout@v4
++    - name: Adjust ASLR for sanitizer
++      run: |
++        sudo cat /proc/sys/vm/mmap_rnd_bits
++        sudo sysctl -w vm.mmap_rnd_bits=28
+     - name: config
+       # --debug -O1 is to produce a debug build that runs in a reasonable amount of time
+       run: CC=clang ./config --banner=Configured --debug -O1 -fsanitize=memory -DOSSL_SANITIZE_MEMORY -fno-optimize-sibling-calls enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-fips && perl configdata.pm --dump
+@@ -195,6 +207,10 @@ jobs:
+     runs-on: ${{ github.server_url == 'https://github.com' && 'ubuntu-latest' || 'ubuntu-22.04-self-hosted' }}
+     steps:
+     - uses: actions/checkout@v4
++    - name: Adjust ASLR for sanitizer
++      run: |
++        sudo cat /proc/sys/vm/mmap_rnd_bits
++        sudo sysctl -w vm.mmap_rnd_bits=28
+     - name: config
+       run: CC=clang ./config --banner=Configured no-fips --strict-warnings -fsanitize=thread && perl configdata.pm --dump
+     - name: make
+diff --git a/.github/workflows/fuzz-checker.yml b/.github/workflows/fuzz-checker.yml
+index 3e84fdbac6..8d48262265 100644
+--- a/.github/workflows/fuzz-checker.yml
++++ b/.github/workflows/fuzz-checker.yml
+@@ -48,6 +48,10 @@ jobs:
+       run: |
+         sudo apt-get update
+         sudo apt-get -yq --force-yes install ${{ matrix.fuzzy.install }}
++    - name: Adjust ASLR for sanitizer
++      run: |
++        sudo cat /proc/sys/vm/mmap_rnd_bits
++        sudo sysctl -w vm.mmap_rnd_bits=28
+     - uses: actions/checkout@v4
+ 
+     - name: config
+diff --git a/.github/workflows/run-checker-merge.yml b/.github/workflows/run-checker-merge.yml
+index 7154b6b62d..b18c62299f 100644
+--- a/.github/workflows/run-checker-merge.yml
++++ b/.github/workflows/run-checker-merge.yml
+@@ -32,6 +32,10 @@ jobs:
+         ]
+     runs-on: ubuntu-latest
+     steps:
++    - name: Adjust ASLR for sanitizer
++      run: |
++        sudo cat /proc/sys/vm/mmap_rnd_bits
++        sudo sysctl -w vm.mmap_rnd_bits=28
+     - uses: actions/checkout@v4
+     - name: config
+       run: CC=clang ./config --banner=Configured --strict-warnings ${{ matrix.opt }}
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0031-SSL_add_dir_cert_subjects_to_stack-Documented-return.patch b/package/libs/openssl/patches/0031-SSL_add_dir_cert_subjects_to_stack-Documented-return.patch
new file mode 100644
index 0000000..0a94b4d
--- /dev/null
+++ b/package/libs/openssl/patches/0031-SSL_add_dir_cert_subjects_to_stack-Documented-return.patch
@@ -0,0 +1,61 @@
+From a58bfb7a97aa2ed8cb78417ea2bcc779f1ac9c0a Mon Sep 17 00:00:00 2001
+From: Shakti Shah <shaktishah33@gmail.com>
+Date: Wed, 31 Jan 2024 00:26:32 +0530
+Subject: [PATCH 31/76] SSL_add_dir_cert_subjects_to_stack(): Documented return
+ values
+
+In the man page for SSL_add_dir_cert_subjects_to_stack(), the functions
+returning int have undocumented return values.
+
+Fixes #23171
+
+Signed-off-by: Shakti Shah <shaktishah33@gmail.com>
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23433)
+
+(cherry picked from commit 9f3a7ca2cfff948b21f8fdbe92069b3eea1c01fa)
+---
+ doc/man3/SSL_load_client_CA_file.pod | 18 +++++++++++++++++-
+ 1 file changed, 17 insertions(+), 1 deletion(-)
+
+diff --git a/doc/man3/SSL_load_client_CA_file.pod b/doc/man3/SSL_load_client_CA_file.pod
+index 988c7e8934..117f6bb1a9 100644
+--- a/doc/man3/SSL_load_client_CA_file.pod
++++ b/doc/man3/SSL_load_client_CA_file.pod
+@@ -54,7 +54,8 @@ it is not limited to CA certificates.
+ 
+ =head1 RETURN VALUES
+ 
+-The following return values can occur:
++The following return values can occur for SSL_load_client_CA_file_ex(), and
++SSL_load_client_CA_file():
+ 
+ =over 4
+ 
+@@ -68,6 +69,21 @@ Pointer to the subject names of the successfully read certificates.
+ 
+ =back
+ 
++The following return values can occur for SSL_add_file_cert_subjects_to_stack(),
++SSL_add_dir_cert_subjects_to_stack(), and SSL_add_store_cert_subjects_to_stack():
++
++=over 4
++
++=item 0 (Failure)
++
++The operation failed.
++
++=item 1 (Success)
++
++The operation succeeded.
++
++=back
++
+ =head1 EXAMPLES
+ 
+ Load names of CAs from file and use it as a client CA list:
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0032-Fix-unbounded-memory-growth-when-using-no-cached-fet.patch b/package/libs/openssl/patches/0032-Fix-unbounded-memory-growth-when-using-no-cached-fet.patch
new file mode 100644
index 0000000..ae5d3f3
--- /dev/null
+++ b/package/libs/openssl/patches/0032-Fix-unbounded-memory-growth-when-using-no-cached-fet.patch
@@ -0,0 +1,78 @@
+From a473d59db1ce6943c010c5ba842e7c17fbe81aab Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Wed, 13 Mar 2024 15:19:43 +0000
+Subject: [PATCH 32/76] Fix unbounded memory growth when using no-cached-fetch
+
+When OpenSSL has been compiled with no-cached-fetch we do not cache
+algorithms fetched from a provider. When we export an EVP_PKEY to a
+provider we cache the details of that export in the operation cache for
+that EVP_PKEY. Amoung the details we cache is the EVP_KEYMGMT that we used
+for the export. When we come to reuse the key in the same provider that
+we have previously exported the key to, we check the operation cache for
+the cached key data. However because the EVP_KEYMGMT instance was not
+cached then instance will be different every time and we were not
+recognising that we had already exported the key to the provider.
+
+This causes us to re-export the key to the same provider everytime the key
+is used. Since this consumes memory we end up with unbounded memory growth.
+
+The fix is to be more intelligent about recognising that we have already
+exported key data to a given provider even if the EVP_KEYMGMT instance is
+different.
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+(Merged from https://github.com/openssl/openssl/pull/23841)
+
+(cherry picked from commit dc9bc6c8e1bd329ead703417a2235ab3e97557ec)
+---
+ crypto/evp/keymgmt_lib.c |  7 ++++++-
+ crypto/evp/p_lib.c       | 10 +++++++++-
+ 2 files changed, 15 insertions(+), 2 deletions(-)
+
+diff --git a/crypto/evp/keymgmt_lib.c b/crypto/evp/keymgmt_lib.c
+index 8369d9578c..3226786bb5 100644
+--- a/crypto/evp/keymgmt_lib.c
++++ b/crypto/evp/keymgmt_lib.c
+@@ -243,10 +243,15 @@ OP_CACHE_ELEM *evp_keymgmt_util_find_operation_cache(EVP_PKEY *pk,
+     /*
+      * A comparison and sk_P_CACHE_ELEM_find() are avoided to not cause
+      * problems when we've only a read lock.
++     * A keymgmt is a match if the |keymgmt| pointers are identical or if the
++     * provider and the name ID match
+      */
+     for (i = 0; i < end; i++) {
+         p = sk_OP_CACHE_ELEM_value(pk->operation_cache, i);
+-        if (keymgmt == p->keymgmt && (p->selection & selection) == selection)
++        if ((p->selection & selection) == selection
++                && (keymgmt == p->keymgmt
++                    || (keymgmt->name_id == p->keymgmt->name_id
++                        && keymgmt->prov == p->keymgmt->prov)))
+             return p;
+     }
+     return NULL;
+diff --git a/crypto/evp/p_lib.c b/crypto/evp/p_lib.c
+index 04b148a912..119d80fa00 100644
+--- a/crypto/evp/p_lib.c
++++ b/crypto/evp/p_lib.c
+@@ -1902,7 +1902,15 @@ void *evp_pkey_export_to_provider(EVP_PKEY *pk, OSSL_LIB_CTX *libctx,
+              * If |tmp_keymgmt| is present in the operation cache, it means
+              * that export doesn't need to be redone.  In that case, we take
+              * token copies of the cached pointers, to have token success
+-             * values to return.
++             * values to return. It is possible (e.g. in a no-cached-fetch
++             * build), for op->keymgmt to be a different pointer to tmp_keymgmt
++             * even though the name/provider must be the same. In other words
++             * the keymgmt instance may be different but still equivalent, i.e.
++             * same algorithm/provider instance - but we make the simplifying
++             * assumption that the keydata can be used with either keymgmt
++             * instance. Not doing so introduces significant complexity and
++             * probably requires refactoring - since we would have to ripple
++             * the change in keymgmt instance up the call chain.
+              */
+             if (op != NULL && op->keymgmt != NULL) {
+                 keydata = op->keydata;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0033-Update-FIPS-hmac-key-documentation.patch b/package/libs/openssl/patches/0033-Update-FIPS-hmac-key-documentation.patch
new file mode 100644
index 0000000..4f04ecb
--- /dev/null
+++ b/package/libs/openssl/patches/0033-Update-FIPS-hmac-key-documentation.patch
@@ -0,0 +1,35 @@
+From b7732a85415bba3f907d3280e1671bcc26794505 Mon Sep 17 00:00:00 2001
+From: Matt Hauck <matt@thehaucks.xyz>
+Date: Thu, 14 Mar 2024 18:25:11 -0700
+Subject: [PATCH 33/76] Update FIPS hmac key documentation
+
+The documentation is slightly incorrect about the FIPS hmac key.
+
+CLA: trivial
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tim Hudson <tjh@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23846)
+
+(cherry picked from commit 53ef123f48d402aff7c27f8ec15191cb1cde4105)
+---
+ INSTALL.md | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/INSTALL.md b/INSTALL.md
+index 21e82b4f91..c0dae491c9 100644
+--- a/INSTALL.md
++++ b/INSTALL.md
+@@ -480,7 +480,7 @@ Setting the FIPS HMAC key
+ 
+ As part of its self-test validation, the FIPS module must verify itself
+ by performing a SHA-256 HMAC computation on itself. The default key is
+-the SHA256 value of "the holy handgrenade of antioch" and is sufficient
++the SHA256 value of "holy hand grenade of antioch" and is sufficient
+ for meeting the FIPS requirements.
+ 
+ To change the key to a different value, use this flag. The value should
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0034-Add-M1-macOS-runner-to-some-workflows.patch b/package/libs/openssl/patches/0034-Add-M1-macOS-runner-to-some-workflows.patch
new file mode 100644
index 0000000..6d88ced
--- /dev/null
+++ b/package/libs/openssl/patches/0034-Add-M1-macOS-runner-to-some-workflows.patch
@@ -0,0 +1,48 @@
+From 4b4cb314b578469365d049360b1ca2c7d898c6be Mon Sep 17 00:00:00 2001
+From: Dmitry Misharov <dmitry@openssl.org>
+Date: Fri, 1 Mar 2024 16:59:07 +0100
+Subject: [PATCH 34/76] Add M1 macOS runner to some workflows
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23724)
+
+(cherry picked from commit ada9d8c785cce8e75a88675622dd5ec79e9aa6d7)
+---
+ .github/workflows/ci.yml | 12 ++++++++++--
+ 1 file changed, 10 insertions(+), 2 deletions(-)
+
+diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
+index 7e99dedf7c..8f6e0fb7fc 100644
+--- a/.github/workflows/ci.yml
++++ b/.github/workflows/ci.yml
+@@ -146,8 +146,12 @@ jobs:
+       run: make test HARNESS_JOBS=${HARNESS_JOBS:-4}
+ 
+   no-shared-macos:
+-    runs-on: macos-latest
++    strategy:
++      fail-fast: false
++      matrix:
++        os: [macos-13, macos-14]
+     if: github.server_url == 'https://github.com'
++    runs-on: ${{ matrix.os }}
+     steps:
+     - uses: actions/checkout@v4
+     - name: config
+@@ -310,7 +314,11 @@ jobs:
+       working-directory: ./build
+ 
+   out-of-readonly-source-and-install-macos:
+-    runs-on: macos-latest
++    strategy:
++      fail-fast: false
++      matrix:
++        os: [macos-13, macos-14]
++    runs-on: ${{ matrix.os }}
+     if: github.server_url == 'https://github.com'
+     steps:
+     - uses: actions/checkout@v4
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0035-Fixed-a-typo-and-grammar-in-openssl-ts.pod.patch b/package/libs/openssl/patches/0035-Fixed-a-typo-and-grammar-in-openssl-ts.pod.patch
new file mode 100644
index 0000000..5c3c083
--- /dev/null
+++ b/package/libs/openssl/patches/0035-Fixed-a-typo-and-grammar-in-openssl-ts.pod.patch
@@ -0,0 +1,35 @@
+From 348832c396cecc24d25dd9de42d1c6ebe9869199 Mon Sep 17 00:00:00 2001
+From: olszomal <Malgorzata.Olszowka@stunnel.org>
+Date: Thu, 21 Mar 2024 11:10:04 +0100
+Subject: [PATCH 35/76] Fixed a typo and grammar in openssl-ts.pod
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Kurt Roeckx <kurt@roeckx.be>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23913)
+
+(cherry picked from commit f1c14f1853d2df94e339208eed1df823c2238389)
+---
+ doc/man1/openssl-ts.pod.in | 6 +++---
+ 1 file changed, 3 insertions(+), 3 deletions(-)
+
+diff --git a/doc/man1/openssl-ts.pod.in b/doc/man1/openssl-ts.pod.in
+index 3e7f7c4be9..de87400dce 100644
+--- a/doc/man1/openssl-ts.pod.in
++++ b/doc/man1/openssl-ts.pod.in
+@@ -163,9 +163,9 @@ use its own default policy. (Optional)
+ =item B<-no_nonce>
+ 
+ No nonce is specified in the request if this option is
+-given. Otherwise a 64 bit long pseudo-random none is
+-included in the request. It is recommended to use nonce to
+-protect against replay-attacks. (Optional)
++given. Otherwise, a 64-bit long pseudo-random nonce is
++included in the request. It is recommended to use a nonce to
++protect against replay attacks. (Optional)
+ 
+ =item B<-cert>
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0036-Replace-unsigned-with-int.patch b/package/libs/openssl/patches/0036-Replace-unsigned-with-int.patch
new file mode 100644
index 0000000..6210d8f
--- /dev/null
+++ b/package/libs/openssl/patches/0036-Replace-unsigned-with-int.patch
@@ -0,0 +1,49 @@
+From 99a1c93efa751f8c9ee06aafe877a2d8bdbdf990 Mon Sep 17 00:00:00 2001
+From: Jiasheng Jiang <jiasheng@purdue.edu>
+Date: Thu, 21 Mar 2024 19:55:34 +0000
+Subject: [PATCH 36/76] Replace unsigned with int
+
+Replace the type of "digest_length" with int to avoid implicit conversion when it is assigned by EVP_MD_get_size().
+Otherwise, it may pass the following check and cause the integer overflow error when EVP_MD_get_size() returns negative numbers.
+Signed-off-by: Jiasheng Jiang <jiasheng@purdue.edu>
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23922)
+
+(cherry picked from commit f13ddaab69def0b453b75a8f2deb80e1f1634f42)
+---
+ demos/digest/EVP_MD_demo.c  | 2 +-
+ demos/digest/EVP_MD_stdin.c | 2 +-
+ 2 files changed, 2 insertions(+), 2 deletions(-)
+
+diff --git a/demos/digest/EVP_MD_demo.c b/demos/digest/EVP_MD_demo.c
+index 99589bd344..7cb7936b59 100644
+--- a/demos/digest/EVP_MD_demo.c
++++ b/demos/digest/EVP_MD_demo.c
+@@ -83,7 +83,7 @@ int demonstrate_digest(void)
+     const char *option_properties = NULL;
+     EVP_MD *message_digest = NULL;
+     EVP_MD_CTX *digest_context = NULL;
+-    unsigned int digest_length;
++    int digest_length;
+     unsigned char *digest_value = NULL;
+     int j;
+ 
+diff --git a/demos/digest/EVP_MD_stdin.c b/demos/digest/EVP_MD_stdin.c
+index 71a3d325a3..07813acdc9 100644
+--- a/demos/digest/EVP_MD_stdin.c
++++ b/demos/digest/EVP_MD_stdin.c
+@@ -38,7 +38,7 @@ int demonstrate_digest(BIO *input)
+     const char * option_properties = NULL;
+     EVP_MD *message_digest = NULL;
+     EVP_MD_CTX *digest_context = NULL;
+-    unsigned int digest_length;
++    int digest_length;
+     unsigned char *digest_value = NULL;
+     unsigned char buffer[512];
+     int ii;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0037-Add-NULL-check-before-accessing-PKCS7-encrypted-algo.patch b/package/libs/openssl/patches/0037-Add-NULL-check-before-accessing-PKCS7-encrypted-algo.patch
new file mode 100644
index 0000000..d21a60e
--- /dev/null
+++ b/package/libs/openssl/patches/0037-Add-NULL-check-before-accessing-PKCS7-encrypted-algo.patch
@@ -0,0 +1,82 @@
+From 95dfb4244a8b6f23768714619f4f4640d51dc3ff Mon Sep 17 00:00:00 2001
+From: =?UTF-8?q?Viliam=20Lej=C4=8D=C3=ADk?= <lejcik@gmail.com>
+Date: Mon, 19 Feb 2024 21:39:05 +0100
+Subject: [PATCH 37/76] Add NULL check before accessing PKCS7 encrypted
+ algorithm
+
+Printing content of an invalid test certificate causes application crash, because of NULL dereference:
+
+user@user:~/openssl$ openssl pkcs12 -in test/recipes/80-test_pkcs12_data/bad2.p12 -passin pass: -info
+MAC: sha256, Iteration 2048
+MAC length: 32, salt length: 8
+PKCS7 Encrypted data: Segmentation fault (core dumped)
+
+Added test cases for pkcs12 bad certificates
+
+Reviewed-by: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23632)
+
+(cherry picked from commit a4cbffcd8998180b98bb9f7ce6065ed37d079d8b)
+---
+ apps/pkcs12.c                 |  6 +++++-
+ test/recipes/80-test_pkcs12.t | 14 +++++++++++++-
+ 2 files changed, 18 insertions(+), 2 deletions(-)
+
+diff --git a/apps/pkcs12.c b/apps/pkcs12.c
+index b442d358f8..af4f9fce04 100644
+--- a/apps/pkcs12.c
++++ b/apps/pkcs12.c
+@@ -855,7 +855,11 @@ int dump_certs_keys_p12(BIO *out, const PKCS12 *p12, const char *pass,
+         } else if (bagnid == NID_pkcs7_encrypted) {
+             if (options & INFO) {
+                 BIO_printf(bio_err, "PKCS7 Encrypted data: ");
+-                alg_print(p7->d.encrypted->enc_data->algorithm);
++                if (p7->d.encrypted == NULL) {
++                    BIO_printf(bio_err, "<no data>\n");
++                } else {
++                    alg_print(p7->d.encrypted->enc_data->algorithm);
++                }
+             }
+             bags = PKCS12_unpack_p7encdata(p7, pass, passlen);
+         } else {
+diff --git a/test/recipes/80-test_pkcs12.t b/test/recipes/80-test_pkcs12.t
+index 4c5bb5744b..de26cbdca4 100644
+--- a/test/recipes/80-test_pkcs12.t
++++ b/test/recipes/80-test_pkcs12.t
+@@ -54,7 +54,7 @@ if (eval { require Win32::API; 1; }) {
+ }
+ $ENV{OPENSSL_WIN32_UTF8}=1;
+ 
+-plan tests => 17;
++plan tests => 20;
+ 
+ # Test different PKCS#12 formats
+ ok(run(test(["pkcs12_format_test"])), "test pkcs12 formats");
+@@ -162,11 +162,23 @@ with({ exit_checker => sub { return shift == 1; } },
+                     "-nomacver"])),
+            "test bad pkcs12 file 1 (nomacver)");
+ 
++        ok(run(app(["openssl", "pkcs12", "-in", $bad1, "-password", "pass:",
++                    "-info"])),
++           "test bad pkcs12 file 1 (info)");
++
+         ok(run(app(["openssl", "pkcs12", "-in", $bad2, "-password", "pass:"])),
+            "test bad pkcs12 file 2");
+ 
++        ok(run(app(["openssl", "pkcs12", "-in", $bad2, "-password", "pass:",
++                    "-info"])),
++           "test bad pkcs12 file 2 (info)");
++
+         ok(run(app(["openssl", "pkcs12", "-in", $bad3, "-password", "pass:"])),
+            "test bad pkcs12 file 3");
++
++        ok(run(app(["openssl", "pkcs12", "-in", $bad3, "-password", "pass:",
++                    "-info"])),
++           "test bad pkcs12 file 3 (info)");
+      });
+ 
+ SetConsoleOutputCP($savedcp) if (defined($savedcp));
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0038-Explicitly-state-what-keys-does.patch b/package/libs/openssl/patches/0038-Explicitly-state-what-keys-does.patch
new file mode 100644
index 0000000..73f681c
--- /dev/null
+++ b/package/libs/openssl/patches/0038-Explicitly-state-what-keys-does.patch
@@ -0,0 +1,33 @@
+From 6ae0220c96f78ba362ba75a93c023122ebba2bdf Mon Sep 17 00:00:00 2001
+From: Simo Sorce <simo@redhat.com>
+Date: Thu, 21 Mar 2024 10:00:52 -0400
+Subject: [PATCH 38/76] Explicitly state what -keys does
+
+Signed-off-by: Simo Sorce <simo@redhat.com>
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+(Merged from https://github.com/openssl/openssl/pull/23919)
+
+(cherry picked from commit 693c479a2ca671e0dfca8d1ad14e789169b982ff)
+---
+ doc/man1/openssl-storeutl.pod.in | 3 +++
+ 1 file changed, 3 insertions(+)
+
+diff --git a/doc/man1/openssl-storeutl.pod.in b/doc/man1/openssl-storeutl.pod.in
+index 26d5ee28e6..512055c9f7 100644
+--- a/doc/man1/openssl-storeutl.pod.in
++++ b/doc/man1/openssl-storeutl.pod.in
+@@ -79,6 +79,9 @@ returned.
+ Note that all options must be given before the I<uri> argument.
+ Otherwise they are ignored.
+ 
++Note I<-keys> selects exclusively private keys, there is no selector for public
++keys only.
++
+ =item B<-subject> I<arg>
+ 
+ Search for an object having the subject name I<arg>.
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0039-Bump-actions-setup-python-from-5.0.0-to-5.1.0.patch b/package/libs/openssl/patches/0039-Bump-actions-setup-python-from-5.0.0-to-5.1.0.patch
new file mode 100644
index 0000000..7e6f4ad
--- /dev/null
+++ b/package/libs/openssl/patches/0039-Bump-actions-setup-python-from-5.0.0-to-5.1.0.patch
@@ -0,0 +1,45 @@
+From c3a008ea937e5a052d06a3576c5c7583033f0c6c Mon Sep 17 00:00:00 2001
+From: "dependabot[bot]" <49699333+dependabot[bot]@users.noreply.github.com>
+Date: Tue, 26 Mar 2024 17:39:00 +0000
+Subject: [PATCH 39/76] Bump actions/setup-python from 5.0.0 to 5.1.0
+
+Bumps [actions/setup-python](https://github.com/actions/setup-python) from 5.0.0 to 5.1.0.
+- [Release notes](https://github.com/actions/setup-python/releases)
+- [Commits](https://github.com/actions/setup-python/compare/v5.0.0...v5.1.0)
+
+---
+updated-dependencies:
+- dependency-name: actions/setup-python
+  dependency-type: direct:production
+  update-type: version-update:semver-minor
+...
+
+Signed-off-by: dependabot[bot] <support@github.com>
+CLA: trivial
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23977)
+
+(cherry picked from commit de85587911dcd41dc3546b348acf9c9f15dd7c3d)
+---
+ .github/workflows/ci.yml | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
+index 8f6e0fb7fc..b3f95e1d2e 100644
+--- a/.github/workflows/ci.yml
++++ b/.github/workflows/ci.yml
+@@ -387,7 +387,7 @@ jobs:
+     - name: make
+       run: make -s -j4
+     - name: Setup Python
+-      uses: actions/setup-python@v5.0.0
++      uses: actions/setup-python@v5.1.0
+       with:
+         python-version: ${{ matrix.PYTHON }}
+     - uses: dtolnay/rust-toolchain@master
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0040-Fix-openssl-req-with-addext-subjectAltName-dirName.patch b/package/libs/openssl/patches/0040-Fix-openssl-req-with-addext-subjectAltName-dirName.patch
new file mode 100644
index 0000000..92c1279
--- /dev/null
+++ b/package/libs/openssl/patches/0040-Fix-openssl-req-with-addext-subjectAltName-dirName.patch
@@ -0,0 +1,77 @@
+From 845e6824098cd0845c85af0f19afc904b8f48111 Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Fri, 23 Feb 2024 10:32:14 +0100
+Subject: [PATCH 40/76] Fix openssl req with -addext subjectAltName=dirName
+
+The syntax check of the -addext fails because the
+X509V3_CTX is used to lookup the referenced section,
+but the wrong configuration file is used, where only
+a default section with all passed in -addext lines is available.
+Thus it was not possible to use the subjectAltName=dirName:section
+as an -addext parameter.  Probably other extensions as well.
+
+This change affects only the syntax check, the real extension
+was already created with correct parameters.
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23669)
+
+(cherry picked from commit 387418893e45e588d1cbd4222549b5113437c9ab)
+---
+ apps/req.c                 | 2 +-
+ test/recipes/25-test_req.t | 3 ++-
+ test/test.cnf              | 6 ++++++
+ 3 files changed, 9 insertions(+), 2 deletions(-)
+
+diff --git a/apps/req.c b/apps/req.c
+index c7d4c7822c..2fc53d4bfc 100644
+--- a/apps/req.c
++++ b/apps/req.c
+@@ -569,7 +569,7 @@ int req_main(int argc, char **argv)
+         X509V3_CTX ctx;
+ 
+         X509V3_set_ctx_test(&ctx);
+-        X509V3_set_nconf(&ctx, addext_conf);
++        X509V3_set_nconf(&ctx, req_conf);
+         if (!X509V3_EXT_add_nconf(addext_conf, &ctx, "default", NULL)) {
+             BIO_printf(bio_err, "Error checking extensions defined using -addext\n");
+             goto end;
+diff --git a/test/recipes/25-test_req.t b/test/recipes/25-test_req.t
+index fe02d29c63..932635f4b2 100644
+--- a/test/recipes/25-test_req.t
++++ b/test/recipes/25-test_req.t
+@@ -15,7 +15,7 @@ use OpenSSL::Test qw/:DEFAULT srctop_file/;
+ 
+ setup("test_req");
+ 
+-plan tests => 49;
++plan tests => 50;
+ 
+ require_ok(srctop_file('test', 'recipes', 'tconversion.pl'));
+ 
+@@ -53,6 +53,7 @@ ok(!run(app([@addext_args, "-addext", $val, "-addext", $val2])));
+ ok(!run(app([@addext_args, "-addext", $val, "-addext", $val3])));
+ ok(!run(app([@addext_args, "-addext", $val2, "-addext", $val3])));
+ ok(run(app([@addext_args, "-addext", "SXNetID=1:one, 2:two, 3:three"])));
++ok(run(app([@addext_args, "-addext", "subjectAltName=dirName:dirname_sec"])));
+ 
+ # If a CSR is provided with neither of -key or -CA/-CAkey, this should fail.
+ ok(!run(app(["openssl", "req", "-x509",
+diff --git a/test/test.cnf b/test/test.cnf
+index 8b2f92ad8e..8f68982a9f 100644
+--- a/test/test.cnf
++++ b/test/test.cnf
+@@ -72,3 +72,9 @@ commonName			= CN field
+ commonName_value		= Eric Young
+ emailAddress			= email field
+ emailAddress_value		= eay@mincom.oz.au
++
++[ dirname_sec ]
++C  = UK
++O  = My Organization
++OU = My Unit
++CN = My Name
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0041-Fix-handling-of-NULL-sig-parameter-in-ECDSA_sign-and.patch b/package/libs/openssl/patches/0041-Fix-handling-of-NULL-sig-parameter-in-ECDSA_sign-and.patch
new file mode 100644
index 0000000..675b59a
--- /dev/null
+++ b/package/libs/openssl/patches/0041-Fix-handling-of-NULL-sig-parameter-in-ECDSA_sign-and.patch
@@ -0,0 +1,173 @@
+From 2fe6c0fbb5ae7e2279e80d7cdff99a1bd2a45733 Mon Sep 17 00:00:00 2001
+From: Bernd Edlinger <bernd.edlinger@hotmail.de>
+Date: Thu, 8 Feb 2024 22:21:55 +0100
+Subject: [PATCH 41/76] Fix handling of NULL sig parameter in ECDSA_sign and
+ similar
+
+The problem is, that it almost works to pass sig=NULL to the
+ECDSA_sign, ECDSA_sign_ex and DSA_sign, to compute the necessary
+space for the resulting signature.
+But since the ECDSA signature is non-deterministic
+(except when ECDSA_sign_setup/ECDSA_sign_ex are used)
+the resulting length may be different when the API is called again.
+This can easily cause random memory corruption.
+Several internal APIs had the same issue, but since they are
+never called with sig=NULL, it is better to make them return an
+error in that case, instead of making the code more complex.
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23529)
+
+(cherry picked from commit 1fa2bf9b1885d2e87524421fea5041d40149cffa)
+---
+ crypto/dsa/dsa_sign.c  |  7 ++++++-
+ crypto/ec/ecdsa_ossl.c |  5 +++++
+ crypto/sm2/sm2_sign.c  |  7 ++++++-
+ test/dsatest.c         |  8 ++++++--
+ test/ecdsatest.c       | 28 ++++++++++++++++++++++++++--
+ 5 files changed, 49 insertions(+), 6 deletions(-)
+
+diff --git a/crypto/dsa/dsa_sign.c b/crypto/dsa/dsa_sign.c
+index ddfbfa18af..2f963af8e1 100644
+--- a/crypto/dsa/dsa_sign.c
++++ b/crypto/dsa/dsa_sign.c
+@@ -156,6 +156,11 @@ int ossl_dsa_sign_int(int type, const unsigned char *dgst, int dlen,
+ {
+     DSA_SIG *s;
+ 
++    if (sig == NULL) {
++        *siglen = DSA_size(dsa);
++        return 1;
++    }
++
+     /* legacy case uses the method table */
+     if (dsa->libctx == NULL || dsa->meth != DSA_get_default_method())
+         s = DSA_do_sign(dgst, dlen, dsa);
+@@ -165,7 +170,7 @@ int ossl_dsa_sign_int(int type, const unsigned char *dgst, int dlen,
+         *siglen = 0;
+         return 0;
+     }
+-    *siglen = i2d_DSA_SIG(s, sig != NULL ? &sig : NULL);
++    *siglen = i2d_DSA_SIG(s, &sig);
+     DSA_SIG_free(s);
+     return 1;
+ }
+diff --git a/crypto/ec/ecdsa_ossl.c b/crypto/ec/ecdsa_ossl.c
+index 0bf4635e2f..0bdf45e6e7 100644
+--- a/crypto/ec/ecdsa_ossl.c
++++ b/crypto/ec/ecdsa_ossl.c
+@@ -70,6 +70,11 @@ int ossl_ecdsa_sign(int type, const unsigned char *dgst, int dlen,
+ {
+     ECDSA_SIG *s;
+ 
++    if (sig == NULL && (kinv == NULL || r == NULL)) {
++        *siglen = ECDSA_size(eckey);
++        return 1;
++    }
++
+     s = ECDSA_do_sign_ex(dgst, dlen, kinv, r, eckey);
+     if (s == NULL) {
+         *siglen = 0;
+diff --git a/crypto/sm2/sm2_sign.c b/crypto/sm2/sm2_sign.c
+index ff5be9b73e..09e542990b 100644
+--- a/crypto/sm2/sm2_sign.c
++++ b/crypto/sm2/sm2_sign.c
+@@ -442,6 +442,11 @@ int ossl_sm2_internal_sign(const unsigned char *dgst, int dgstlen,
+     int sigleni;
+     int ret = -1;
+ 
++    if (sig == NULL) {
++        ERR_raise(ERR_LIB_SM2, ERR_R_PASSED_NULL_PARAMETER);
++        goto done;
++    }
++
+     e = BN_bin2bn(dgst, dgstlen, NULL);
+     if (e == NULL) {
+        ERR_raise(ERR_LIB_SM2, ERR_R_BN_LIB);
+@@ -454,7 +459,7 @@ int ossl_sm2_internal_sign(const unsigned char *dgst, int dgstlen,
+         goto done;
+     }
+ 
+-    sigleni = i2d_ECDSA_SIG(s, sig != NULL ? &sig : NULL);
++    sigleni = i2d_ECDSA_SIG(s, &sig);
+     if (sigleni < 0) {
+        ERR_raise(ERR_LIB_SM2, ERR_R_INTERNAL_ERROR);
+        goto done;
+diff --git a/test/dsatest.c b/test/dsatest.c
+index 5fa83020f8..73c6827bb0 100644
+--- a/test/dsatest.c
++++ b/test/dsatest.c
+@@ -332,6 +332,7 @@ static int test_dsa_sig_infinite_loop(void)
+     BIGNUM *p = NULL, *q = NULL, *g = NULL, *priv = NULL, *pub = NULL, *priv2 = NULL;
+     BIGNUM *badq = NULL, *badpriv = NULL;
+     const unsigned char msg[] = { 0x00 };
++    unsigned int signature_len0;
+     unsigned int signature_len;
+     unsigned char signature[64];
+ 
+@@ -375,10 +376,13 @@ static int test_dsa_sig_infinite_loop(void)
+         goto err;
+ 
+     /* Test passing signature as NULL */
+-    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), NULL, &signature_len, dsa)))
++    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), NULL, &signature_len0, dsa))
++        || !TEST_int_gt(signature_len0, 0))
+         goto err;
+ 
+-    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), signature, &signature_len, dsa)))
++    if (!TEST_true(DSA_sign(0, msg, sizeof(msg), signature, &signature_len, dsa))
++        || !TEST_int_gt(signature_len, 0)
++        || !TEST_int_le(signature_len, signature_len0))
+         goto err;
+ 
+     /* Test using a private key of zero fails - this causes an infinite loop without the retry test */
+diff --git a/test/ecdsatest.c b/test/ecdsatest.c
+index 33a52eb1b5..ded41be5bd 100644
+--- a/test/ecdsatest.c
++++ b/test/ecdsatest.c
+@@ -350,15 +350,39 @@ static int test_builtin_as_sm2(int n)
+ static int test_ecdsa_sig_NULL(void)
+ {
+     int ret;
++    unsigned int siglen0;
+     unsigned int siglen;
+     unsigned char dgst[128] = { 0 };
+     EC_KEY *eckey = NULL;
++    unsigned char *sig = NULL;
++    BIGNUM *kinv = NULL, *rp = NULL;
+ 
+     ret = TEST_ptr(eckey = EC_KEY_new_by_curve_name(NID_X9_62_prime256v1))
+           && TEST_int_eq(EC_KEY_generate_key(eckey), 1)
+-          && TEST_int_eq(ECDSA_sign(0, dgst, sizeof(dgst), NULL, &siglen, eckey), 1)
+-          && TEST_int_gt(siglen, 0);
++          && TEST_int_eq(ECDSA_sign(0, dgst, sizeof(dgst), NULL, &siglen0,
++                                    eckey), 1)
++          && TEST_int_gt(siglen0, 0)
++          && TEST_ptr(sig = OPENSSL_malloc(siglen0))
++          && TEST_int_eq(ECDSA_sign(0, dgst, sizeof(dgst), sig, &siglen,
++                                    eckey), 1)
++          && TEST_int_gt(siglen, 0)
++          && TEST_int_le(siglen, siglen0)
++          && TEST_int_eq(ECDSA_verify(0, dgst, sizeof(dgst), sig, siglen,
++                                      eckey), 1)
++          && TEST_int_eq(ECDSA_sign_setup(eckey, NULL, &kinv, &rp), 1)
++          && TEST_int_eq(ECDSA_sign_ex(0, dgst, sizeof(dgst), NULL, &siglen,
++                                       kinv, rp, eckey), 1)
++          && TEST_int_gt(siglen, 0)
++          && TEST_int_le(siglen, siglen0)
++          && TEST_int_eq(ECDSA_sign_ex(0, dgst, sizeof(dgst), sig, &siglen0,
++                                       kinv, rp, eckey), 1)
++          && TEST_int_eq(siglen, siglen0)
++          && TEST_int_eq(ECDSA_verify(0, dgst, sizeof(dgst), sig, siglen,
++                                      eckey), 1);
+     EC_KEY_free(eckey);
++    OPENSSL_free(sig);
++    BN_free(kinv);
++    BN_free(rp);
+     return ret;
+ }
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0042-Align-openssl-req-string_mask-docs-to-how-the-softwa.patch b/package/libs/openssl/patches/0042-Align-openssl-req-string_mask-docs-to-how-the-softwa.patch
new file mode 100644
index 0000000..73ef7ff
--- /dev/null
+++ b/package/libs/openssl/patches/0042-Align-openssl-req-string_mask-docs-to-how-the-softwa.patch
@@ -0,0 +1,62 @@
+From 442d861cb3cf4b7579f2cd99586c2d2aa7618edf Mon Sep 17 00:00:00 2001
+From: Job Snijders <job@sobornost.net>
+Date: Tue, 27 Feb 2024 19:14:32 +0000
+Subject: [PATCH 42/76] Align 'openssl req' string_mask docs to how the
+ software really works
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23699)
+
+(cherry picked from commit 2410cb42e62c3be69dcf1aad1bdf1eb0233b670f)
+---
+ doc/man1/openssl-req.pod.in | 33 +++++++++++++++++++++++----------
+ 1 file changed, 23 insertions(+), 10 deletions(-)
+
+diff --git a/doc/man1/openssl-req.pod.in b/doc/man1/openssl-req.pod.in
+index 31fd714187..81181bdb4e 100644
+--- a/doc/man1/openssl-req.pod.in
++++ b/doc/man1/openssl-req.pod.in
+@@ -472,16 +472,29 @@ any digest that has been set.
+ =item B<string_mask>
+ 
+ This option masks out the use of certain string types in certain
+-fields. Most users will not need to change this option.
+-
+-It can be set to several values B<default> which is also the default
+-option uses PrintableStrings, T61Strings and BMPStrings if the
+-B<pkix> value is used then only PrintableStrings and BMPStrings will
+-be used. This follows the PKIX recommendation in RFC2459. If the
+-B<utf8only> option is used then only UTF8Strings will be used: this
+-is the PKIX recommendation in RFC2459 after 2003. Finally the B<nombstr>
+-option just uses PrintableStrings and T61Strings: certain software has
+-problems with BMPStrings and UTF8Strings: in particular Netscape.
++fields. Most users will not need to change this option. It can be set to
++several values:
++
++=over 4
++
++=item B<utf8only>
++- only UTF8Strings are used (this is the default value)
++
++=item B<pkix>
++- any string type except T61Strings
++
++=item B<nombstr>
++- any string type except BMPStrings and UTF8Strings
++
++=item B<default>
++- any kind of string type
++
++=back
++
++Note that B<utf8only> is the PKIX recommendation in RFC2459 after 2003, and the
++default B<string_mask>; B<default> is not the default option. The B<nombstr>
++value is a workaround for some software that has problems with variable-sized
++BMPStrings and UTF8Strings.
+ 
+ =item B<req_extensions>
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0043-Add-documentation-policy-link-to-CONTRIBUTING-guide.patch b/package/libs/openssl/patches/0043-Add-documentation-policy-link-to-CONTRIBUTING-guide.patch
new file mode 100644
index 0000000..02085c5
--- /dev/null
+++ b/package/libs/openssl/patches/0043-Add-documentation-policy-link-to-CONTRIBUTING-guide.patch
@@ -0,0 +1,40 @@
+From 5405606234ede0ce8dbda24d329327bfa3c430c4 Mon Sep 17 00:00:00 2001
+From: slontis <shane.lontis@oracle.com>
+Date: Mon, 18 Mar 2024 11:46:12 +1100
+Subject: [PATCH 43/76] Add 'documentation policy' link to CONTRIBUTING guide.
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23875)
+
+(cherry picked from commit e817766c0f46f371fabe344fba60d13afcfc3da9)
+---
+ CONTRIBUTING.md | 4 +++-
+ 1 file changed, 3 insertions(+), 1 deletion(-)
+
+diff --git a/CONTRIBUTING.md b/CONTRIBUTING.md
+index 15490fd9f6..0066e7e8ad 100644
+--- a/CONTRIBUTING.md
++++ b/CONTRIBUTING.md
+@@ -67,7 +67,8 @@ guidelines:
+     often. We do not accept merge commits, you will have to remove them
+     (usually by rebasing) before it will be acceptable.
+ 
+- 4. Code provided should follow our [coding style] and compile without warnings.
++ 4. Code provided should follow our [coding style] and [documentation policy]
++    and compile without warnings.
+     There is a [Perl tool](util/check-format.pl) that helps
+     finding code formatting mistakes and other coding style nits.
+     Where `gcc` or `clang` is available, you should use the
+@@ -77,6 +78,7 @@ guidelines:
+     whenever a PR is created or updated by committers.
+ 
+     [coding style]: https://www.openssl.org/policies/technical/coding-style.html
++    [documentation policy]: https://openssl.org/policies/technical/documentation-policy.html
+ 
+  5. When at all possible, code contributions should include tests. These can
+     either be added to an existing test, or completely new.  Please see
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0044-Backported-.gitignore-changes-from-master.patch b/package/libs/openssl/patches/0044-Backported-.gitignore-changes-from-master.patch
new file mode 100644
index 0000000..5fbda1a
--- /dev/null
+++ b/package/libs/openssl/patches/0044-Backported-.gitignore-changes-from-master.patch
@@ -0,0 +1,87 @@
+From c79e37a2cd9b51041265d48409a71e79f2224043 Mon Sep 17 00:00:00 2001
+From: dgbkn <anandrambkn@gmail.com>
+Date: Fri, 15 Mar 2024 10:03:14 +0530
+Subject: [PATCH 44/76] Backported .gitignore changes from master
+
+CLA: trivial
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23847)
+---
+ .gitignore | 21 ++++++++++++++++++++-
+ 1 file changed, 20 insertions(+), 1 deletion(-)
+
+diff --git a/.gitignore b/.gitignore
+index 4f5857df86..5a61fcd1a0 100644
+--- a/.gitignore
++++ b/.gitignore
+@@ -6,13 +6,20 @@
+ /Makefile
+ /MINFO
+ /TABLE
+-/*.pc
+ /rehash.time
+ /inc.*
+ /makefile.*
+ /out.*
+ /tmp.*
+ /configdata.pm
++/builddata.pm
++/installdata.pm
++
++# Exporters
++/*.pc
++/OpenSSLConfig*.cmake
++/exporters/*.pc
++/exporters/OpenSSLConfig*.cmake
+ 
+ # Links under apps
+ /apps/CA.pl
+@@ -48,6 +55,11 @@
+ /include/openssl/x509.h
+ /include/openssl/x509v3.h
+ /include/openssl/x509_vfy.h
++# /include/openssl/core_names.h
++/include/internal/param_names.h
++
++# Auto generated parameter name files
++/crypto/params_idx.c
+ 
+ # Auto generated doc files
+ doc/man1/openssl-*.pod
+@@ -102,6 +114,7 @@ providers/common/include/prov/der_sm2.h
+ /test/evp_extra_test2
+ /test/evp_pkey_ctx_new_from_name
+ /test/threadstest_fips
++/test/timing_load_creds
+ 
+ # Certain files that get created by tests on the fly
+ /test-runs
+@@ -126,6 +139,7 @@ providers/common/include/prov/der_sm2.h
+ /tools/c_rehash.pl
+ /util/shlib_wrap.sh
+ /util/wrap.pl
++/util/quicserver
+ /tags
+ /TAGS
+ *.map
+@@ -230,6 +244,7 @@ Makefile.save
+ *.bak
+ cscope.*
+ *.d
++!.ctags.d
+ *.d.tmp
+ pod2htmd.tmp
+ MAKE0[0-9][0-9][0-9].@@@
+@@ -237,3 +252,7 @@ MAKE0[0-9][0-9][0-9].@@@
+ # Windows manifest files
+ *.manifest
+ doc-nits
++
++# LSP (Language Server Protocol) support
++.cache/
++compile_commands.json
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0045-DEFINE_STACK_OF.pod-Fix-prototypes-of-sk_TYPE_free-z.patch b/package/libs/openssl/patches/0045-DEFINE_STACK_OF.pod-Fix-prototypes-of-sk_TYPE_free-z.patch
new file mode 100644
index 0000000..1290564
--- /dev/null
+++ b/package/libs/openssl/patches/0045-DEFINE_STACK_OF.pod-Fix-prototypes-of-sk_TYPE_free-z.patch
@@ -0,0 +1,36 @@
+From 90fe7b2b90346c3123f139e7b6d67334856b0c5a Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Tue, 2 Apr 2024 16:43:27 +0200
+Subject: [PATCH 45/76] DEFINE_STACK_OF.pod: Fix prototypes of
+ sk_TYPE_free/zero()
+
+They take non-const STACK_OF(TYPE)* argument.
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+(Merged from https://github.com/openssl/openssl/pull/24023)
+
+(cherry picked from commit e898c367312c3ab6eb5eaac9b4be768f0d2e4b0e)
+---
+ doc/man3/DEFINE_STACK_OF.pod | 4 ++--
+ 1 file changed, 2 insertions(+), 2 deletions(-)
+
+diff --git a/doc/man3/DEFINE_STACK_OF.pod b/doc/man3/DEFINE_STACK_OF.pod
+index 0775214fb5..e29e0c8be0 100644
+--- a/doc/man3/DEFINE_STACK_OF.pod
++++ b/doc/man3/DEFINE_STACK_OF.pod
+@@ -41,8 +41,8 @@ OPENSSL_sk_unshift, OPENSSL_sk_value, OPENSSL_sk_zero
+  STACK_OF(TYPE) *sk_TYPE_new(sk_TYPE_compfunc compare);
+  STACK_OF(TYPE) *sk_TYPE_new_null(void);
+  int sk_TYPE_reserve(STACK_OF(TYPE) *sk, int n);
+- void sk_TYPE_free(const STACK_OF(TYPE) *sk);
+- void sk_TYPE_zero(const STACK_OF(TYPE) *sk);
++ void sk_TYPE_free(STACK_OF(TYPE) *sk);
++ void sk_TYPE_zero(STACK_OF(TYPE) *sk);
+  TYPE *sk_TYPE_delete(STACK_OF(TYPE) *sk, int i);
+  TYPE *sk_TYPE_delete_ptr(STACK_OF(TYPE) *sk, TYPE *ptr);
+  int sk_TYPE_push(STACK_OF(TYPE) *sk, const TYPE *ptr);
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0046-openssl-crl-1-The-verify-option-is-implied-by-CA-opt.patch b/package/libs/openssl/patches/0046-openssl-crl-1-The-verify-option-is-implied-by-CA-opt.patch
new file mode 100644
index 0000000..a2cc9af
--- /dev/null
+++ b/package/libs/openssl/patches/0046-openssl-crl-1-The-verify-option-is-implied-by-CA-opt.patch
@@ -0,0 +1,32 @@
+From e7b511d31878d5260e90aa009e4ee64c6ef30620 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Tue, 2 Apr 2024 18:47:26 +0200
+Subject: [PATCH 46/76] openssl-crl(1): The -verify option is implied by -CA*
+ options
+
+Reviewed-by: Dmitry Belyavskiy <beldmit@gmail.com>
+Reviewed-by: Todd Short <todd.short@me.com>
+(Merged from https://github.com/openssl/openssl/pull/24024)
+
+(cherry picked from commit a16f2e7651b22ee992bb0c279e25164b519c1e80)
+---
+ doc/man1/openssl-crl.pod.in | 3 +++
+ 1 file changed, 3 insertions(+)
+
+diff --git a/doc/man1/openssl-crl.pod.in b/doc/man1/openssl-crl.pod.in
+index 7e15f6445a..25af2483e7 100644
+--- a/doc/man1/openssl-crl.pod.in
++++ b/doc/man1/openssl-crl.pod.in
+@@ -95,6 +95,9 @@ Print out the CRL in text form.
+ 
+ Verify the signature in the CRL.
+ 
++This option is implicitly enabled if any of B<-CApath>, B<-CAfile>
++or B<-CAstore> is specified.
++
+ =item B<-noout>
+ 
+ Don't output the encoded version of the CRL.
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0047-downgrade-upload-artifact-action-to-v3.patch b/package/libs/openssl/patches/0047-downgrade-upload-artifact-action-to-v3.patch
new file mode 100644
index 0000000..7585a6b
--- /dev/null
+++ b/package/libs/openssl/patches/0047-downgrade-upload-artifact-action-to-v3.patch
@@ -0,0 +1,48 @@
+From 3cd67d10b6bd182a8006dfc04bb48d4dedce82e5 Mon Sep 17 00:00:00 2001
+From: Dmitry Misharov <dmitry@openssl.org>
+Date: Wed, 3 Apr 2024 13:47:39 +0200
+Subject: [PATCH 47/76] downgrade upload-artifact action to v3
+
+GitHub Enterpise Server is not compatible with upload-artifact@v4+.
+https://github.com/actions/upload-artifact/tree/v4
+
+Reviewed-by: Hugo Landau <hlandau@openssl.org>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24029)
+
+(cherry picked from commit 089271601a1d085f33ef7b7d8c3b6879045be370)
+---
+ .github/workflows/fips-checksums.yml | 2 +-
+ .github/workflows/main.yml           | 2 +-
+ 2 files changed, 2 insertions(+), 2 deletions(-)
+
+diff --git a/.github/workflows/fips-checksums.yml b/.github/workflows/fips-checksums.yml
+index a9777a2394..1b56755bfb 100644
+--- a/.github/workflows/fips-checksums.yml
++++ b/.github/workflows/fips-checksums.yml
+@@ -69,7 +69,7 @@ jobs:
+       - name: save PR number
+         run: echo ${{ github.event.number }} > ./artifact/pr_num
+       - name: save artifact
+-        uses: actions/upload-artifact@v4
++        uses: actions/upload-artifact@v3
+         with:
+           name: fips_checksum
+           path: artifact/
+diff --git a/.github/workflows/main.yml b/.github/workflows/main.yml
+index 1d187f0dd2..5850c0e4f3 100644
+--- a/.github/workflows/main.yml
++++ b/.github/workflows/main.yml
+@@ -26,7 +26,7 @@ jobs:
+         fuzz-seconds: 600
+         dry-run: false
+     - name: Upload Crash
+-      uses: actions/upload-artifact@v4
++      uses: actions/upload-artifact@v3
+       if: failure()
+       with:
+         name: artifacts
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0048-Add-a-test-for-session-cache-handling.patch b/package/libs/openssl/patches/0048-Add-a-test-for-session-cache-handling.patch
new file mode 100644
index 0000000..32eeb71
--- /dev/null
+++ b/package/libs/openssl/patches/0048-Add-a-test-for-session-cache-handling.patch
@@ -0,0 +1,132 @@
+From 2af85c2b8fd6799924a56eb5907cc6110b450467 Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Mon, 4 Mar 2024 13:45:23 +0000
+Subject: [PATCH 48/76] Add a test for session cache handling
+
+Repeatedly create sessions to be added to the cache and ensure we never
+exceed the expected size.
+
+Related to CVE-2024-2511
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24044)
+
+(cherry picked from commit 5f5b9e1ca1fad0215f623b8bd4955a2e8101f306)
+---
+ test/sslapitest.c | 92 +++++++++++++++++++++++++++++++++++++++++++++++
+ 1 file changed, 92 insertions(+)
+
+diff --git a/test/sslapitest.c b/test/sslapitest.c
+index 231f498199..56229e51b9 100644
+--- a/test/sslapitest.c
++++ b/test/sslapitest.c
+@@ -10436,6 +10436,97 @@ end:
+     return testresult;
+ }
+ 
++/*
++ * Test multiple resumptions and cache size handling
++ * Test 0: TLSv1.3 (max_early_data set)
++ * Test 1: TLSv1.3 (SSL_OP_NO_TICKET set)
++ * Test 2: TLSv1.3 (max_early_data and SSL_OP_NO_TICKET set)
++ * Test 3: TLSv1.2
++ */
++static int test_multi_resume(int idx)
++{
++    SSL_CTX *sctx = NULL, *cctx = NULL;
++    SSL *serverssl = NULL, *clientssl = NULL;
++    SSL_SESSION *sess = NULL;
++    int max_version = TLS1_3_VERSION;
++    int i, testresult = 0;
++
++    if (idx == 3)
++        max_version = TLS1_2_VERSION;
++
++    if (!TEST_true(create_ssl_ctx_pair(libctx, TLS_server_method(),
++                                       TLS_client_method(), TLS1_VERSION,
++                                       max_version, &sctx, &cctx, cert,
++                                       privkey)))
++        goto end;
++
++    /*
++     * TLSv1.3 only uses a session cache if either max_early_data > 0 (used for
++     * replay protection), or if SSL_OP_NO_TICKET is in use
++     */
++    if (idx == 0 || idx == 2)  {
++        if (!TEST_true(SSL_CTX_set_max_early_data(sctx, 1024)))
++            goto end;
++    }
++    if (idx == 1 || idx == 2)
++        SSL_CTX_set_options(sctx, SSL_OP_NO_TICKET);
++
++    SSL_CTX_sess_set_cache_size(sctx, 5);
++
++    for (i = 0; i < 30; i++) {
++        if (!TEST_true(create_ssl_objects(sctx, cctx, &serverssl, &clientssl,
++                                                NULL, NULL))
++                || !TEST_true(SSL_set_session(clientssl, sess)))
++            goto end;
++
++        /*
++         * Recreate a bug where dynamically changing the max_early_data value
++         * can cause sessions in the session cache which cannot be deleted.
++         */
++        if ((idx == 0 || idx == 2) && (i % 3) == 2)
++            SSL_set_max_early_data(serverssl, 0);
++
++        if (!TEST_true(create_ssl_connection(serverssl, clientssl, SSL_ERROR_NONE)))
++            goto end;
++
++        if (sess == NULL || (idx == 0 && (i % 3) == 2)) {
++            if (!TEST_false(SSL_session_reused(clientssl)))
++                goto end;
++        } else {
++            if (!TEST_true(SSL_session_reused(clientssl)))
++                goto end;
++        }
++        SSL_SESSION_free(sess);
++
++        /* Do a full handshake, followed by two resumptions */
++        if ((i % 3) == 2) {
++            sess = NULL;
++        } else {
++            if (!TEST_ptr((sess = SSL_get1_session(clientssl))))
++                goto end;
++        }
++
++        SSL_shutdown(clientssl);
++        SSL_shutdown(serverssl);
++        SSL_free(serverssl);
++        SSL_free(clientssl);
++        serverssl = clientssl = NULL;
++    }
++
++    /* We should never exceed the session cache size limit */
++    if (!TEST_long_le(SSL_CTX_sess_number(sctx), 5))
++        goto end;
++
++    testresult = 1;
++ end:
++    SSL_free(serverssl);
++    SSL_free(clientssl);
++    SSL_CTX_free(sctx);
++    SSL_CTX_free(cctx);
++    SSL_SESSION_free(sess);
++    return testresult;
++}
++
+ OPT_TEST_DECLARE_USAGE("certfile privkeyfile srpvfile tmpfile provider config dhfile\n")
+ 
+ int setup_tests(void)
+@@ -10708,6 +10799,7 @@ int setup_tests(void)
+     ADD_ALL_TESTS(test_pipelining, 7);
+ #endif
+     ADD_ALL_TESTS(test_handshake_retry, 16);
++    ADD_ALL_TESTS(test_multi_resume, 4);
+     return 1;
+ 
+  err:
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0049-Extend-the-multi_resume-test-for-simultaneous-resump.patch b/package/libs/openssl/patches/0049-Extend-the-multi_resume-test-for-simultaneous-resump.patch
new file mode 100644
index 0000000..a5336ba
--- /dev/null
+++ b/package/libs/openssl/patches/0049-Extend-the-multi_resume-test-for-simultaneous-resump.patch
@@ -0,0 +1,161 @@
+From c1e462ee4bd61867ee391fc13110ca41e4889535 Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Tue, 5 Mar 2024 15:35:51 +0000
+Subject: [PATCH 49/76] Extend the multi_resume test for simultaneous
+ resumptions
+
+Test what happens if the same session gets resumed multiple times at the
+same time - and one of them gets marked as not_resumable.
+
+Related to CVE-2024-2511
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24044)
+
+(cherry picked from commit 031b11a4054c972a5e2f07dfa81ce1842453253e)
+---
+ test/sslapitest.c | 89 ++++++++++++++++++++++++++++++++++++++++++++---
+ 1 file changed, 85 insertions(+), 4 deletions(-)
+
+diff --git a/test/sslapitest.c b/test/sslapitest.c
+index 56229e51b9..24fb95e4b6 100644
+--- a/test/sslapitest.c
++++ b/test/sslapitest.c
+@@ -10436,12 +10436,63 @@ end:
+     return testresult;
+ }
+ 
++struct resume_servername_cb_data {
++    int i;
++    SSL_CTX *cctx;
++    SSL_CTX *sctx;
++    SSL_SESSION *sess;
++    int recurse;
++};
++
++/*
++ * Servername callback. We use it here to run another complete handshake using
++ * the same session - and mark the session as not_resuamble at the end
++ */
++static int resume_servername_cb(SSL *s, int *ad, void *arg)
++{
++    struct resume_servername_cb_data *cbdata = arg;
++    SSL *serverssl = NULL, *clientssl = NULL;
++    int ret = SSL_TLSEXT_ERR_ALERT_FATAL;
++
++    if (cbdata->recurse)
++        return SSL_TLSEXT_ERR_ALERT_FATAL;
++
++    if ((cbdata->i % 3) != 1)
++        return SSL_TLSEXT_ERR_OK;
++
++    cbdata->recurse = 1;
++
++    if (!TEST_true(create_ssl_objects(cbdata->sctx, cbdata->cctx, &serverssl,
++                                      &clientssl, NULL, NULL))
++            || !TEST_true(SSL_set_session(clientssl, cbdata->sess)))
++        goto end;
++
++    ERR_set_mark();
++    /*
++     * We expect this to fail - because the servername cb will fail. This will
++     * mark the session as not_resumable.
++     */
++    if (!TEST_false(create_ssl_connection(serverssl, clientssl, SSL_ERROR_NONE))) {
++        ERR_clear_last_mark();
++        goto end;
++    }
++    ERR_pop_to_mark();
++
++    ret = SSL_TLSEXT_ERR_OK;
++ end:
++    SSL_free(serverssl);
++    SSL_free(clientssl);
++    cbdata->recurse = 0;
++    return ret;
++}
++
+ /*
+  * Test multiple resumptions and cache size handling
+  * Test 0: TLSv1.3 (max_early_data set)
+  * Test 1: TLSv1.3 (SSL_OP_NO_TICKET set)
+  * Test 2: TLSv1.3 (max_early_data and SSL_OP_NO_TICKET set)
+- * Test 3: TLSv1.2
++ * Test 3: TLSv1.3 (SSL_OP_NO_TICKET, simultaneous resumes)
++ * Test 4: TLSv1.2
+  */
+ static int test_multi_resume(int idx)
+ {
+@@ -10450,9 +10501,19 @@ static int test_multi_resume(int idx)
+     SSL_SESSION *sess = NULL;
+     int max_version = TLS1_3_VERSION;
+     int i, testresult = 0;
++    struct resume_servername_cb_data cbdata;
+ 
+-    if (idx == 3)
++#if defined(OPENSSL_NO_TLS1_2)
++    if (idx == 4)
++        return TEST_skip("TLSv1.2 is disabled in this build");
++#else
++    if (idx == 4)
+         max_version = TLS1_2_VERSION;
++#endif
++#if defined(OSSL_NO_USABLE_TLS1_3)
++    if (idx != 4)
++        return TEST_skip("No usable TLSv1.3 in this build");
++#endif
+ 
+     if (!TEST_true(create_ssl_ctx_pair(libctx, TLS_server_method(),
+                                        TLS_client_method(), TLS1_VERSION,
+@@ -10468,17 +10529,37 @@ static int test_multi_resume(int idx)
+         if (!TEST_true(SSL_CTX_set_max_early_data(sctx, 1024)))
+             goto end;
+     }
+-    if (idx == 1 || idx == 2)
++    if (idx == 1 || idx == 2 || idx == 3)
+         SSL_CTX_set_options(sctx, SSL_OP_NO_TICKET);
+ 
+     SSL_CTX_sess_set_cache_size(sctx, 5);
+ 
++    if (idx == 3) {
++        SSL_CTX_set_tlsext_servername_callback(sctx, resume_servername_cb);
++        SSL_CTX_set_tlsext_servername_arg(sctx, &cbdata);
++        cbdata.cctx = cctx;
++        cbdata.sctx = sctx;
++        cbdata.recurse = 0;
++    }
++
+     for (i = 0; i < 30; i++) {
+         if (!TEST_true(create_ssl_objects(sctx, cctx, &serverssl, &clientssl,
+                                                 NULL, NULL))
+                 || !TEST_true(SSL_set_session(clientssl, sess)))
+             goto end;
+ 
++        /*
++         * Check simultaneous resumes. We pause the connection part way through
++         * the handshake by (mis)using the servername_cb. The pause occurs after
++         * session resumption has already occurred, but before any session
++         * tickets have been issued. While paused we run another complete
++         * handshake resuming the same session.
++         */
++        if (idx == 3) {
++            cbdata.i = i;
++            cbdata.sess = sess;
++        }
++
+         /*
+          * Recreate a bug where dynamically changing the max_early_data value
+          * can cause sessions in the session cache which cannot be deleted.
+@@ -10799,7 +10880,7 @@ int setup_tests(void)
+     ADD_ALL_TESTS(test_pipelining, 7);
+ #endif
+     ADD_ALL_TESTS(test_handshake_retry, 16);
+-    ADD_ALL_TESTS(test_multi_resume, 4);
++    ADD_ALL_TESTS(test_multi_resume, 5);
+     return 1;
+ 
+  err:
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0050-Fix-unconstrained-session-cache-growth-in-TLSv1.3.patch b/package/libs/openssl/patches/0050-Fix-unconstrained-session-cache-growth-in-TLSv1.3.patch
new file mode 100644
index 0000000..0e299de
--- /dev/null
+++ b/package/libs/openssl/patches/0050-Fix-unconstrained-session-cache-growth-in-TLSv1.3.patch
@@ -0,0 +1,121 @@
+From b52867a9f618bb955bed2a3ce3db4d4f97ed8e5d Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Tue, 5 Mar 2024 15:43:53 +0000
+Subject: [PATCH 50/76] Fix unconstrained session cache growth in TLSv1.3
+
+In TLSv1.3 we create a new session object for each ticket that we send.
+We do this by duplicating the original session. If SSL_OP_NO_TICKET is in
+use then the new session will be added to the session cache. However, if
+early data is not in use (and therefore anti-replay protection is being
+used), then multiple threads could be resuming from the same session
+simultaneously. If this happens and a problem occurs on one of the threads,
+then the original session object could be marked as not_resumable. When we
+duplicate the session object this not_resumable status gets copied into the
+new session object. The new session object is then added to the session
+cache even though it is not_resumable.
+
+Subsequently, another bug means that the session_id_length is set to 0 for
+sessions that are marked as not_resumable - even though that session is
+still in the cache. Once this happens the session can never be removed from
+the cache. When that object gets to be the session cache tail object the
+cache never shrinks again and grows indefinitely.
+
+CVE-2024-2511
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24044)
+
+(cherry picked from commit 7e4d731b1c07201ad9374c1cd9ac5263bdf35bce)
+---
+ ssl/ssl_lib.c            |  5 +++--
+ ssl/ssl_sess.c           | 28 ++++++++++++++++++++++------
+ ssl/statem/statem_srvr.c |  5 ++---
+ 3 files changed, 27 insertions(+), 11 deletions(-)
+
+diff --git a/ssl/ssl_lib.c b/ssl/ssl_lib.c
+index 2c8479eb5f..eed649c6fd 100644
+--- a/ssl/ssl_lib.c
++++ b/ssl/ssl_lib.c
+@@ -3736,9 +3736,10 @@ void ssl_update_cache(SSL *s, int mode)
+ 
+     /*
+      * If the session_id_length is 0, we are not supposed to cache it, and it
+-     * would be rather hard to do anyway :-)
++     * would be rather hard to do anyway :-). Also if the session has already
++     * been marked as not_resumable we should not cache it for later reuse.
+      */
+-    if (s->session->session_id_length == 0)
++    if (s->session->session_id_length == 0 || s->session->not_resumable)
+         return;
+ 
+     /*
+diff --git a/ssl/ssl_sess.c b/ssl/ssl_sess.c
+index d836b33ed0..75adbd9e52 100644
+--- a/ssl/ssl_sess.c
++++ b/ssl/ssl_sess.c
+@@ -152,16 +152,11 @@ SSL_SESSION *SSL_SESSION_new(void)
+     return ss;
+ }
+ 
+-SSL_SESSION *SSL_SESSION_dup(const SSL_SESSION *src)
+-{
+-    return ssl_session_dup(src, 1);
+-}
+-
+ /*
+  * Create a new SSL_SESSION and duplicate the contents of |src| into it. If
+  * ticket == 0 then no ticket information is duplicated, otherwise it is.
+  */
+-SSL_SESSION *ssl_session_dup(const SSL_SESSION *src, int ticket)
++static SSL_SESSION *ssl_session_dup_intern(const SSL_SESSION *src, int ticket)
+ {
+     SSL_SESSION *dest;
+ 
+@@ -285,6 +280,27 @@ SSL_SESSION *ssl_session_dup(const SSL_SESSION *src, int ticket)
+     return NULL;
+ }
+ 
++SSL_SESSION *SSL_SESSION_dup(const SSL_SESSION *src)
++{
++    return ssl_session_dup_intern(src, 1);
++}
++
++/*
++ * Used internally when duplicating a session which might be already shared.
++ * We will have resumed the original session. Subsequently we might have marked
++ * it as non-resumable (e.g. in another thread) - but this copy should be ok to
++ * resume from.
++ */
++SSL_SESSION *ssl_session_dup(const SSL_SESSION *src, int ticket)
++{
++    SSL_SESSION *sess = ssl_session_dup_intern(src, ticket);
++
++    if (sess != NULL)
++        sess->not_resumable = 0;
++
++    return sess;
++}
++
+ const unsigned char *SSL_SESSION_get_id(const SSL_SESSION *s, unsigned int *len)
+ {
+     if (len)
+diff --git a/ssl/statem/statem_srvr.c b/ssl/statem/statem_srvr.c
+index a9e67f9d32..6c942e6bce 100644
+--- a/ssl/statem/statem_srvr.c
++++ b/ssl/statem/statem_srvr.c
+@@ -2338,9 +2338,8 @@ int tls_construct_server_hello(SSL *s, WPACKET *pkt)
+      * so the following won't overwrite an ID that we're supposed
+      * to send back.
+      */
+-    if (s->session->not_resumable ||
+-        (!(s->ctx->session_cache_mode & SSL_SESS_CACHE_SERVER)
+-         && !s->hit))
++    if (!(s->ctx->session_cache_mode & SSL_SESS_CACHE_SERVER)
++            && !s->hit)
+         s->session->session_id_length = 0;
+ 
+     if (usetls13) {
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0051-Add-a-CHANGES.md-NEWS.md-entry-for-the-unbounded-mem.patch b/package/libs/openssl/patches/0051-Add-a-CHANGES.md-NEWS.md-entry-for-the-unbounded-mem.patch
new file mode 100644
index 0000000..817c0ee
--- /dev/null
+++ b/package/libs/openssl/patches/0051-Add-a-CHANGES.md-NEWS.md-entry-for-the-unbounded-mem.patch
@@ -0,0 +1,80 @@
+From daee101e39073d4b65a68faeb2f2de5ad7b05c36 Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Tue, 5 Mar 2024 16:01:20 +0000
+Subject: [PATCH 51/76] Add a CHANGES.md/NEWS.md entry for the unbounded memory
+ growth bug
+
+Related to CVE-2024-2511
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24044)
+
+(cherry picked from commit e32ad41b48c28d82339de064b05d5e269e5aed97)
+---
+ CHANGES.md | 19 +++++++++++++++++++
+ NEWS.md    |  4 +++-
+ 2 files changed, 22 insertions(+), 1 deletion(-)
+
+diff --git a/CHANGES.md b/CHANGES.md
+index b42dd83bc0..5590704670 100644
+--- a/CHANGES.md
++++ b/CHANGES.md
+@@ -30,6 +30,24 @@ breaking changes, and mappings for the large list of deprecated functions.
+ 
+ ### Changes between 3.0.13 and 3.0.14 [xx XXX xxxx]
+ 
++ * Fixed an issue where some non-default TLS server configurations can cause
++   unbounded memory growth when processing TLSv1.3 sessions. An attacker may
++   exploit certain server configurations to trigger unbounded memory growth that
++   would lead to a Denial of Service
++
++   This problem can occur in TLSv1.3 if the non-default SSL_OP_NO_TICKET option
++   is being used (but not if early_data is also configured and the default
++   anti-replay protection is in use). In this case, under certain conditions,
++   the session cache can get into an incorrect state and it will fail to flush
++   properly as it fills. The session cache will continue to grow in an unbounded
++   manner. A malicious client could deliberately create the scenario for this
++   failure to force a Denial of Service. It may also happen by accident in
++   normal operation.
++
++   ([CVE-2024-2511])
++
++   *Matt Caswell*
++
+  * New atexit configuration switch, which controls whether the OPENSSL_cleanup
+    is registered when libcrypto is unloaded. This can be used on platforms
+    where using atexit() from shared libraries causes crashes on exit.
+@@ -19832,6 +19850,7 @@ ndif
+ 
+ <!-- Links -->
+ 
++[CVE-2024-2511]: https://www.openssl.org/news/vulnerabilities.html#CVE-2024-2511
+ [CVE-2024-0727]: https://www.openssl.org/news/vulnerabilities.html#CVE-2024-0727
+ [CVE-2023-6237]: https://www.openssl.org/news/vulnerabilities.html#CVE-2023-6237
+ [CVE-2023-6129]: https://www.openssl.org/news/vulnerabilities.html#CVE-2023-6129
+diff --git a/NEWS.md b/NEWS.md
+index 11fc8b10b0..a06d9694c1 100644
+--- a/NEWS.md
++++ b/NEWS.md
+@@ -20,7 +20,8 @@ OpenSSL 3.0
+ 
+ ### Major changes between OpenSSL 3.0.13 and OpenSSL 3.0.14 [under development]
+ 
+-  * none
++  * Fixed unbounded memory growth with session handling in TLSv1.3
++    ([CVE-2024-2511])
+ 
+ ### Major changes between OpenSSL 3.0.12 and OpenSSL 3.0.13 [30 Jan 2024]
+ 
+@@ -1474,6 +1475,7 @@ OpenSSL 0.9.x
+ 
+ <!-- Links -->
+ 
++[CVE-2024-2511]: https://www.openssl.org/news/vulnerabilities.html#CVE-2024-2511
+ [CVE-2024-0727]: https://www.openssl.org/news/vulnerabilities.html#CVE-2024-0727
+ [CVE-2023-6237]: https://www.openssl.org/news/vulnerabilities.html#CVE-2023-6237
+ [CVE-2023-6129]: https://www.openssl.org/news/vulnerabilities.html#CVE-2023-6129
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0052-Hardening-around-not_resumable-sessions.patch b/package/libs/openssl/patches/0052-Hardening-around-not_resumable-sessions.patch
new file mode 100644
index 0000000..7c9f7c5
--- /dev/null
+++ b/package/libs/openssl/patches/0052-Hardening-around-not_resumable-sessions.patch
@@ -0,0 +1,38 @@
+From cc9ece9118eeacccc3571c2ee852f8ba067d0607 Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Fri, 15 Mar 2024 17:58:42 +0000
+Subject: [PATCH 52/76] Hardening around not_resumable sessions
+
+Make sure we can't inadvertently use a not_resumable session
+
+Related to CVE-2024-2511
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24044)
+
+(cherry picked from commit c342f4b8bd2d0b375b0e22337057c2eab47d9b96)
+---
+ ssl/ssl_sess.c | 6 ++++++
+ 1 file changed, 6 insertions(+)
+
+diff --git a/ssl/ssl_sess.c b/ssl/ssl_sess.c
+index 75adbd9e52..d0b72b7880 100644
+--- a/ssl/ssl_sess.c
++++ b/ssl/ssl_sess.c
+@@ -531,6 +531,12 @@ SSL_SESSION *lookup_sess_in_cache(SSL *s, const unsigned char *sess_id,
+         ret = s->session_ctx->get_session_cb(s, sess_id, sess_id_len, &copy);
+ 
+         if (ret != NULL) {
++            if (ret->not_resumable) {
++                /* If its not resumable then ignore this session */
++                if (!copy)
++                    SSL_SESSION_free(ret);
++                return NULL;
++            }
+             ssl_tsan_counter(s->session_ctx,
+                              &s->session_ctx->stats.sess_cb_hit);
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0053-Add-a-test-for-session-cache-overflow.patch b/package/libs/openssl/patches/0053-Add-a-test-for-session-cache-overflow.patch
new file mode 100644
index 0000000..a356dbd
--- /dev/null
+++ b/package/libs/openssl/patches/0053-Add-a-test-for-session-cache-overflow.patch
@@ -0,0 +1,171 @@
+From ea821878c0cc04d292c1f8d1ff3c5e112da91f08 Mon Sep 17 00:00:00 2001
+From: Matt Caswell <matt@openssl.org>
+Date: Fri, 15 Jul 2022 13:26:33 +0100
+Subject: [PATCH 53/76] Add a test for session cache overflow
+
+Test sessions behave as we expect even in the case that an overflow
+occurs when adding a new session into the session cache.
+
+Related to CVE-2024-2511
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24044)
+
+(cherry picked from commit ddead0935d77ba9b771d632ace61b145d7153f18)
+---
+ test/sslapitest.c | 124 +++++++++++++++++++++++++++++++++++++++++++++-
+ 1 file changed, 123 insertions(+), 1 deletion(-)
+
+diff --git a/test/sslapitest.c b/test/sslapitest.c
+index 24fb95e4b6..cb098a46f5 100644
+--- a/test/sslapitest.c
++++ b/test/sslapitest.c
+@@ -2402,7 +2402,6 @@ static int test_session_wo_ca_names(void)
+ #endif
+ }
+ 
+-
+ #ifndef OSSL_NO_USABLE_TLS1_3
+ static SSL_SESSION *sesscache[6];
+ static int do_cache;
+@@ -8954,6 +8953,126 @@ static int test_session_timeout(int test)
+     return testresult;
+ }
+ 
++/*
++ * Test that a session cache overflow works as expected
++ * Test 0: TLSv1.3, timeout on new session later than old session
++ * Test 1: TLSv1.2, timeout on new session later than old session
++ * Test 2: TLSv1.3, timeout on new session earlier than old session
++ * Test 3: TLSv1.2, timeout on new session earlier than old session
++ */
++#if !defined(OSSL_NO_USABLE_TLS1_3) || !defined(OPENSSL_NO_TLS1_2)
++static int test_session_cache_overflow(int idx)
++{
++    SSL_CTX *sctx = NULL, *cctx = NULL;
++    SSL *serverssl = NULL, *clientssl = NULL;
++    int testresult = 0;
++    SSL_SESSION *sess = NULL;
++
++#ifdef OSSL_NO_USABLE_TLS1_3
++    /* If no TLSv1.3 available then do nothing in this case */
++    if (idx % 2 == 0)
++        return TEST_skip("No TLSv1.3 available");
++#endif
++#ifdef OPENSSL_NO_TLS1_2
++    /* If no TLSv1.2 available then do nothing in this case */
++    if (idx % 2 == 1)
++        return TEST_skip("No TLSv1.2 available");
++#endif
++
++    if (!TEST_true(create_ssl_ctx_pair(libctx, TLS_server_method(),
++                                       TLS_client_method(), TLS1_VERSION,
++                                       (idx % 2 == 0) ? TLS1_3_VERSION
++                                                      : TLS1_2_VERSION,
++                                       &sctx, &cctx, cert, privkey))
++            || !TEST_true(SSL_CTX_set_options(sctx, SSL_OP_NO_TICKET)))
++        goto end;
++
++    SSL_CTX_sess_set_get_cb(sctx, get_session_cb);
++    get_sess_val = NULL;
++
++    SSL_CTX_sess_set_cache_size(sctx, 1);
++
++    if (!TEST_true(create_ssl_objects(sctx, cctx, &serverssl, &clientssl,
++                                      NULL, NULL)))
++        goto end;
++
++    if (!TEST_true(create_ssl_connection(serverssl, clientssl, SSL_ERROR_NONE)))
++        goto end;
++
++    if (idx > 1) {
++        sess = SSL_get_session(serverssl);
++        if (!TEST_ptr(sess))
++            goto end;
++
++        /*
++         * Cause this session to have a longer timeout than the next session to
++         * be added.
++         */
++        if (!TEST_true(SSL_SESSION_set_timeout(sess, LONG_MAX / 2))) {
++            sess = NULL;
++            goto end;
++        }
++        sess = NULL;
++    }
++
++    SSL_shutdown(serverssl);
++    SSL_shutdown(clientssl);
++    SSL_free(serverssl);
++    SSL_free(clientssl);
++    serverssl = clientssl = NULL;
++
++    /*
++     * Session cache size is 1 and we already populated the cache with a session
++     * so the next connection should cause an overflow.
++     */
++
++    if (!TEST_true(create_ssl_objects(sctx, cctx, &serverssl, &clientssl,
++                                      NULL, NULL)))
++        goto end;
++
++    if (!TEST_true(create_ssl_connection(serverssl, clientssl, SSL_ERROR_NONE)))
++        goto end;
++
++    /*
++     * The session we just negotiated may have been already removed from the
++     * internal cache - but we will return it anyway from our external cache.
++     */
++    get_sess_val = SSL_get_session(serverssl);
++    if (!TEST_ptr(get_sess_val))
++        goto end;
++    sess = SSL_get1_session(clientssl);
++    if (!TEST_ptr(sess))
++        goto end;
++
++    SSL_shutdown(serverssl);
++    SSL_shutdown(clientssl);
++    SSL_free(serverssl);
++    SSL_free(clientssl);
++    serverssl = clientssl = NULL;
++
++    if (!TEST_true(create_ssl_objects(sctx, cctx, &serverssl, &clientssl,
++                                      NULL, NULL)))
++        goto end;
++
++    if (!TEST_true(SSL_set_session(clientssl, sess)))
++        goto end;
++
++    if (!TEST_true(create_ssl_connection(serverssl, clientssl, SSL_ERROR_NONE)))
++        goto end;
++
++    testresult = 1;
++
++ end:
++    SSL_free(serverssl);
++    SSL_free(clientssl);
++    SSL_CTX_free(sctx);
++    SSL_CTX_free(cctx);
++    SSL_SESSION_free(sess);
++
++    return testresult;
++}
++#endif /* !defined(OSSL_NO_USABLE_TLS1_3) || !defined(OPENSSL_NO_TLS1_2) */
++
+ /*
+  * Test 0: Client sets servername and server acknowledges it (TLSv1.2)
+  * Test 1: Client sets servername and server does not acknowledge it (TLSv1.2)
+@@ -10872,6 +10991,9 @@ int setup_tests(void)
+     ADD_TEST(test_set_verify_cert_store_ssl_ctx);
+     ADD_TEST(test_set_verify_cert_store_ssl);
+     ADD_ALL_TESTS(test_session_timeout, 1);
++#if !defined(OSSL_NO_USABLE_TLS1_3) || !defined(OPENSSL_NO_TLS1_2)
++    ADD_ALL_TESTS(test_session_cache_overflow, 4);
++#endif
+     ADD_TEST(test_load_dhfile);
+ #if !defined(OPENSSL_NO_TLS1_2) && !defined(OSSL_NO_USABLE_TLS1_3)
+     ADD_ALL_TESTS(test_serverinfo_custom, 4);
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0054-Fix-EVP_PKEY_CTX_add1_hkdf_info-behavior.patch b/package/libs/openssl/patches/0054-Fix-EVP_PKEY_CTX_add1_hkdf_info-behavior.patch
new file mode 100644
index 0000000..8a2c138
--- /dev/null
+++ b/package/libs/openssl/patches/0054-Fix-EVP_PKEY_CTX_add1_hkdf_info-behavior.patch
@@ -0,0 +1,309 @@
+From 4953ab1aefd14db7038e28d62c0e3efb22ddb199 Mon Sep 17 00:00:00 2001
+From: Todd Short <todd.short@me.com>
+Date: Thu, 1 Feb 2024 23:09:38 -0500
+Subject: [PATCH 54/76] Fix EVP_PKEY_CTX_add1_hkdf_info() behavior
+
+Fix #23448
+
+`EVP_PKEY_CTX_add1_hkdf_info()` behaves like a `set1` function.
+
+Fix the setting of the parameter in the params code.
+Update the TLS_PRF code to also use the params code.
+Add tests.
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23456)
+
+(cherry picked from commit 6b566687b58fde08b28e3331377f050768fad89b)
+---
+ crypto/evp/pmeth_lib.c                        | 65 ++++++++++++++++++-
+ providers/implementations/exchange/kdf_exch.c | 42 ++++++++++++
+ providers/implementations/kdfs/hkdf.c         |  8 +++
+ test/pkey_meth_kdf_test.c                     | 53 +++++++++++----
+ 4 files changed, 156 insertions(+), 12 deletions(-)
+
+diff --git a/crypto/evp/pmeth_lib.c b/crypto/evp/pmeth_lib.c
+index ba1971ce46..d0eeaf7137 100644
+--- a/crypto/evp/pmeth_lib.c
++++ b/crypto/evp/pmeth_lib.c
+@@ -1028,6 +1028,69 @@ static int evp_pkey_ctx_set1_octet_string(EVP_PKEY_CTX *ctx, int fallback,
+     return EVP_PKEY_CTX_set_params(ctx, octet_string_params);
+ }
+ 
++static int evp_pkey_ctx_add1_octet_string(EVP_PKEY_CTX *ctx, int fallback,
++                                          const char *param, int op, int ctrl,
++                                          const unsigned char *data,
++                                          int datalen)
++{
++    OSSL_PARAM os_params[2];
++    unsigned char *info = NULL;
++    size_t info_len = 0;
++    size_t info_alloc = 0;
++    int ret = 0;
++
++    if (ctx == NULL || (ctx->operation & op) == 0) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_COMMAND_NOT_SUPPORTED);
++        /* Uses the same return values as EVP_PKEY_CTX_ctrl */
++        return -2;
++    }
++
++    /* Code below to be removed when legacy support is dropped. */
++    if (fallback)
++        return EVP_PKEY_CTX_ctrl(ctx, -1, op, ctrl, datalen, (void *)(data));
++    /* end of legacy support */
++
++    if (datalen < 0) {
++        ERR_raise(ERR_LIB_EVP, EVP_R_INVALID_LENGTH);
++        return 0;
++    }
++
++    /* Get the original value length */
++    os_params[0] = OSSL_PARAM_construct_octet_string(param, NULL, 0);
++    os_params[1] = OSSL_PARAM_construct_end();
++
++    if (!EVP_PKEY_CTX_get_params(ctx, os_params))
++        return 0;
++
++    /* Older provider that doesn't support getting this parameter */
++    if (os_params[0].return_size == OSSL_PARAM_UNMODIFIED)
++        return evp_pkey_ctx_set1_octet_string(ctx, fallback, param, op, ctrl, data, datalen);
++
++    info_alloc = os_params[0].return_size + datalen;
++    if (info_alloc == 0)
++        return 0;
++    info = OPENSSL_zalloc(info_alloc);
++    if (info == NULL)
++        return 0;
++    info_len = os_params[0].return_size;
++
++    os_params[0] = OSSL_PARAM_construct_octet_string(param, info, info_alloc);
++
++    /* if we have data, then go get it */
++    if (info_len > 0) {
++        if (!EVP_PKEY_CTX_get_params(ctx, os_params))
++            goto error;
++    }
++
++    /* Copy the input data */
++    memcpy(&info[info_len], data, datalen);
++    ret = EVP_PKEY_CTX_set_params(ctx, os_params);
++
++ error:
++    OPENSSL_clear_free(info, info_alloc);
++    return ret;
++}
++
+ int EVP_PKEY_CTX_set1_tls1_prf_secret(EVP_PKEY_CTX *ctx,
+                                       const unsigned char *sec, int seclen)
+ {
+@@ -1078,7 +1141,7 @@ int EVP_PKEY_CTX_set1_hkdf_key(EVP_PKEY_CTX *ctx,
+ int EVP_PKEY_CTX_add1_hkdf_info(EVP_PKEY_CTX *ctx,
+                                       const unsigned char *info, int infolen)
+ {
+-    return evp_pkey_ctx_set1_octet_string(ctx, ctx->op.kex.algctx == NULL,
++    return evp_pkey_ctx_add1_octet_string(ctx, ctx->op.kex.algctx == NULL,
+                                           OSSL_KDF_PARAM_INFO,
+                                           EVP_PKEY_OP_DERIVE,
+                                           EVP_PKEY_CTRL_HKDF_INFO,
+diff --git a/providers/implementations/exchange/kdf_exch.c b/providers/implementations/exchange/kdf_exch.c
+index 527a866c3d..4bc81026b2 100644
+--- a/providers/implementations/exchange/kdf_exch.c
++++ b/providers/implementations/exchange/kdf_exch.c
+@@ -28,9 +28,13 @@ static OSSL_FUNC_keyexch_derive_fn kdf_derive;
+ static OSSL_FUNC_keyexch_freectx_fn kdf_freectx;
+ static OSSL_FUNC_keyexch_dupctx_fn kdf_dupctx;
+ static OSSL_FUNC_keyexch_set_ctx_params_fn kdf_set_ctx_params;
++static OSSL_FUNC_keyexch_get_ctx_params_fn kdf_get_ctx_params;
+ static OSSL_FUNC_keyexch_settable_ctx_params_fn kdf_tls1_prf_settable_ctx_params;
+ static OSSL_FUNC_keyexch_settable_ctx_params_fn kdf_hkdf_settable_ctx_params;
+ static OSSL_FUNC_keyexch_settable_ctx_params_fn kdf_scrypt_settable_ctx_params;
++static OSSL_FUNC_keyexch_gettable_ctx_params_fn kdf_tls1_prf_gettable_ctx_params;
++static OSSL_FUNC_keyexch_gettable_ctx_params_fn kdf_hkdf_gettable_ctx_params;
++static OSSL_FUNC_keyexch_gettable_ctx_params_fn kdf_scrypt_gettable_ctx_params;
+ 
+ typedef struct {
+     void *provctx;
+@@ -169,6 +173,13 @@ static int kdf_set_ctx_params(void *vpkdfctx, const OSSL_PARAM params[])
+     return EVP_KDF_CTX_set_params(pkdfctx->kdfctx, params);
+ }
+ 
++static int kdf_get_ctx_params(void *vpkdfctx, OSSL_PARAM params[])
++{
++    PROV_KDF_CTX *pkdfctx = (PROV_KDF_CTX *)vpkdfctx;
++
++    return EVP_KDF_CTX_get_params(pkdfctx->kdfctx, params);
++}
++
+ static const OSSL_PARAM *kdf_settable_ctx_params(ossl_unused void *vpkdfctx,
+                                                  void *provctx,
+                                                  const char *kdfname)
+@@ -197,6 +208,34 @@ KDF_SETTABLE_CTX_PARAMS(tls1_prf, "TLS1-PRF")
+ KDF_SETTABLE_CTX_PARAMS(hkdf, "HKDF")
+ KDF_SETTABLE_CTX_PARAMS(scrypt, "SCRYPT")
+ 
++static const OSSL_PARAM *kdf_gettable_ctx_params(ossl_unused void *vpkdfctx,
++                                                 void *provctx,
++                                                 const char *kdfname)
++{
++    EVP_KDF *kdf = EVP_KDF_fetch(PROV_LIBCTX_OF(provctx), kdfname,
++                                 NULL);
++    const OSSL_PARAM *params;
++
++    if (kdf == NULL)
++        return NULL;
++
++    params = EVP_KDF_gettable_ctx_params(kdf);
++    EVP_KDF_free(kdf);
++
++    return params;
++}
++
++#define KDF_GETTABLE_CTX_PARAMS(funcname, kdfname) \
++    static const OSSL_PARAM *kdf_##funcname##_gettable_ctx_params(void *vpkdfctx, \
++                                                                  void *provctx) \
++    { \
++        return kdf_gettable_ctx_params(vpkdfctx, provctx, kdfname); \
++    }
++
++KDF_GETTABLE_CTX_PARAMS(tls1_prf, "TLS1-PRF")
++KDF_GETTABLE_CTX_PARAMS(hkdf, "HKDF")
++KDF_GETTABLE_CTX_PARAMS(scrypt, "SCRYPT")
++
+ #define KDF_KEYEXCH_FUNCTIONS(funcname) \
+     const OSSL_DISPATCH ossl_kdf_##funcname##_keyexch_functions[] = { \
+         { OSSL_FUNC_KEYEXCH_NEWCTX, (void (*)(void))kdf_##funcname##_newctx }, \
+@@ -205,8 +244,11 @@ KDF_SETTABLE_CTX_PARAMS(scrypt, "SCRYPT")
+         { OSSL_FUNC_KEYEXCH_FREECTX, (void (*)(void))kdf_freectx }, \
+         { OSSL_FUNC_KEYEXCH_DUPCTX, (void (*)(void))kdf_dupctx }, \
+         { OSSL_FUNC_KEYEXCH_SET_CTX_PARAMS, (void (*)(void))kdf_set_ctx_params }, \
++        { OSSL_FUNC_KEYEXCH_GET_CTX_PARAMS, (void (*)(void))kdf_get_ctx_params }, \
+         { OSSL_FUNC_KEYEXCH_SETTABLE_CTX_PARAMS, \
+         (void (*)(void))kdf_##funcname##_settable_ctx_params }, \
++        { OSSL_FUNC_KEYEXCH_GETTABLE_CTX_PARAMS, \
++        (void (*)(void))kdf_##funcname##_gettable_ctx_params }, \
+         { 0, NULL } \
+     };
+ 
+diff --git a/providers/implementations/kdfs/hkdf.c b/providers/implementations/kdfs/hkdf.c
+index 25819ea239..2b22de2fa7 100644
+--- a/providers/implementations/kdfs/hkdf.c
++++ b/providers/implementations/kdfs/hkdf.c
+@@ -340,6 +340,13 @@ static int kdf_hkdf_get_ctx_params(void *vctx, OSSL_PARAM params[])
+             return 0;
+         return OSSL_PARAM_set_size_t(p, sz);
+     }
++    if ((p = OSSL_PARAM_locate(params, OSSL_KDF_PARAM_INFO)) != NULL) {
++        if (ctx->info == NULL || ctx->info_len == 0) {
++            p->return_size = 0;
++            return 1;
++        }
++        return OSSL_PARAM_set_octet_string(p, ctx->info, ctx->info_len);
++    }
+     return -2;
+ }
+ 
+@@ -348,6 +355,7 @@ static const OSSL_PARAM *kdf_hkdf_gettable_ctx_params(ossl_unused void *ctx,
+ {
+     static const OSSL_PARAM known_gettable_ctx_params[] = {
+         OSSL_PARAM_size_t(OSSL_KDF_PARAM_SIZE, NULL),
++        OSSL_PARAM_octet_string(OSSL_KDF_PARAM_INFO, NULL, 0),
+         OSSL_PARAM_END
+     };
+     return known_gettable_ctx_params;
+diff --git a/test/pkey_meth_kdf_test.c b/test/pkey_meth_kdf_test.c
+index f816d24fb5..c09e2f3830 100644
+--- a/test/pkey_meth_kdf_test.c
++++ b/test/pkey_meth_kdf_test.c
+@@ -16,7 +16,7 @@
+ #include <openssl/kdf.h>
+ #include "testutil.h"
+ 
+-static int test_kdf_tls1_prf(void)
++static int test_kdf_tls1_prf(int index)
+ {
+     int ret = 0;
+     EVP_PKEY_CTX *pctx;
+@@ -40,10 +40,23 @@ static int test_kdf_tls1_prf(void)
+         TEST_error("EVP_PKEY_CTX_set1_tls1_prf_secret");
+         goto err;
+     }
+-    if (EVP_PKEY_CTX_add1_tls1_prf_seed(pctx,
+-                                        (unsigned char *)"seed", 4) <= 0) {
+-        TEST_error("EVP_PKEY_CTX_add1_tls1_prf_seed");
+-        goto err;
++    if (index == 0) {
++        if (EVP_PKEY_CTX_add1_tls1_prf_seed(pctx,
++                                            (unsigned char *)"seed", 4) <= 0) {
++            TEST_error("EVP_PKEY_CTX_add1_tls1_prf_seed");
++            goto err;
++        }
++    } else {
++        if (EVP_PKEY_CTX_add1_tls1_prf_seed(pctx,
++                                            (unsigned char *)"se", 2) <= 0) {
++            TEST_error("EVP_PKEY_CTX_add1_tls1_prf_seed");
++            goto err;
++        }
++        if (EVP_PKEY_CTX_add1_tls1_prf_seed(pctx,
++                                            (unsigned char *)"ed", 2) <= 0) {
++            TEST_error("EVP_PKEY_CTX_add1_tls1_prf_seed");
++            goto err;
++        }
+     }
+     if (EVP_PKEY_derive(pctx, out, &outlen) <= 0) {
+         TEST_error("EVP_PKEY_derive");
+@@ -65,7 +78,7 @@ err:
+     return ret;
+ }
+ 
+-static int test_kdf_hkdf(void)
++static int test_kdf_hkdf(int index)
+ {
+     int ret = 0;
+     EVP_PKEY_CTX *pctx;
+@@ -94,10 +107,23 @@ static int test_kdf_hkdf(void)
+         TEST_error("EVP_PKEY_CTX_set1_hkdf_key");
+         goto err;
+     }
+-    if (EVP_PKEY_CTX_add1_hkdf_info(pctx, (const unsigned char *)"label", 5)
++    if (index == 0) {
++        if (EVP_PKEY_CTX_add1_hkdf_info(pctx, (const unsigned char *)"label", 5)
+             <= 0) {
+-        TEST_error("EVP_PKEY_CTX_set1_hkdf_info");
+-        goto err;
++            TEST_error("EVP_PKEY_CTX_add1_hkdf_info");
++            goto err;
++        }
++    } else {
++        if (EVP_PKEY_CTX_add1_hkdf_info(pctx, (const unsigned char *)"lab", 3)
++            <= 0) {
++            TEST_error("EVP_PKEY_CTX_add1_hkdf_info");
++            goto err;
++        }
++        if (EVP_PKEY_CTX_add1_hkdf_info(pctx, (const unsigned char *)"el", 2)
++            <= 0) {
++            TEST_error("EVP_PKEY_CTX_add1_hkdf_info");
++            goto err;
++        }
+     }
+     if (EVP_PKEY_derive(pctx, out, &outlen) <= 0) {
+         TEST_error("EVP_PKEY_derive");
+@@ -195,8 +221,13 @@ err:
+ 
+ int setup_tests(void)
+ {
+-    ADD_TEST(test_kdf_tls1_prf);
+-    ADD_TEST(test_kdf_hkdf);
++    int tests = 1;
++
++    if (fips_provider_version_ge(NULL, 3, 3, 1))
++        tests = 2;
++
++    ADD_ALL_TESTS(test_kdf_tls1_prf, tests);
++    ADD_ALL_TESTS(test_kdf_hkdf, tests);
+ #ifndef OPENSSL_NO_SCRYPT
+     ADD_TEST(test_kdf_scrypt);
+ #endif
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0055-Fix-Error-finalizing-cipher-loop-when-running-openss.patch b/package/libs/openssl/patches/0055-Fix-Error-finalizing-cipher-loop-when-running-openss.patch
new file mode 100644
index 0000000..58ea240
--- /dev/null
+++ b/package/libs/openssl/patches/0055-Fix-Error-finalizing-cipher-loop-when-running-openss.patch
@@ -0,0 +1,59 @@
+From 3aa6b409b021c388c87096d2aca2758e954f8358 Mon Sep 17 00:00:00 2001
+From: Tom Cosgrove <tom.cosgrove@arm.com>
+Date: Mon, 26 Feb 2024 17:14:48 +0000
+Subject: [PATCH 55/76] Fix "Error finalizing cipher loop" when running openssl
+ speed -evp -decrypt
+
+When using CCM, openssl speed uses the loop function EVP_Update_loop_ccm() which
+sets a (fake) tag when decrypting. When using -aead (which benchmarks a different
+sequence than normal, to be comparable to TLS operation), the loop function
+EVP_Update_loop_aead() is used, which also sets a tag when decrypting.
+
+However, when using defaults, the loop function EVP_Update_loop() is used, which
+does not set a tag on decryption, leading to "Error finalizing cipher loop".
+
+To fix this, set a fake tag value if we're doing decryption on an AEAD cipher in
+EVP_Update_loop(). We don't check the return value: this shouldn't really be able
+to fail, and if it does, the following EVP_DecryptUpdate() is almost certain to
+fail, so that can catch it.
+
+The decryption is certain to fail (well, almost certain, but with a very low
+probability of success), but this is no worse than at present. This minimal
+change means that future benchmarking data should be comparable to previous
+benchmarking data.
+
+(This is benchmarking code: don't write real apps like this!)
+
+Fixes #23657
+
+Change-Id: Id581cf30503c1eb766464e315b1f33914040dcf7
+
+Reviewed-by: Paul Yang <kaishen.yy@antfin.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23757)
+
+(cherry picked from commit b3be6cc89e4dcfafe8f8be97e9519c26af2d19f5)
+---
+ apps/speed.c | 4 ++++
+ 1 file changed, 4 insertions(+)
+
+diff --git a/apps/speed.c b/apps/speed.c
+index 1113d775b8..6b3befa60d 100644
+--- a/apps/speed.c
++++ b/apps/speed.c
+@@ -727,8 +727,12 @@ static int EVP_Update_loop(void *args)
+     unsigned char *buf = tempargs->buf;
+     EVP_CIPHER_CTX *ctx = tempargs->ctx;
+     int outl, count, rc;
++    unsigned char faketag[16] = { 0xcc };
+ 
+     if (decrypt) {
++        if (EVP_CIPHER_get_flags(EVP_CIPHER_CTX_get0_cipher(ctx)) & EVP_CIPH_FLAG_AEAD_CIPHER) {
++            (void)EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_AEAD_SET_TAG, sizeof(faketag), faketag);
++        }
+         for (count = 0; COND(c[D_EVP][testnum]); count++) {
+             rc = EVP_DecryptUpdate(ctx, buf, &outl, buf, lengths[testnum]);
+             if (rc != 1) {
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0056-APPS-Add-missing-OPENSSL_free-and-combine-the-error-.patch b/package/libs/openssl/patches/0056-APPS-Add-missing-OPENSSL_free-and-combine-the-error-.patch
new file mode 100644
index 0000000..232d359
--- /dev/null
+++ b/package/libs/openssl/patches/0056-APPS-Add-missing-OPENSSL_free-and-combine-the-error-.patch
@@ -0,0 +1,60 @@
+From 4394a70b8f1a6a6a5cd84b662effe72caedab5cf Mon Sep 17 00:00:00 2001
+From: Jiasheng Jiang <jiasheng@purdue.edu>
+Date: Sat, 16 Mar 2024 21:27:14 +0000
+Subject: [PATCH 56/76] APPS: Add missing OPENSSL_free() and combine the error
+ handler
+
+Add the OPENSSL_free() in the error handler to release the "*md_value"
+allocated by app_malloc(). To make the code clear and avoid possible
+future errors, combine the error handler in the "err" tag.
+Then, we only need to use "goto err" instead of releasing the memory
+separately.
+
+Since the EVP_MD_get_size() may return negative numbers when an error occurs,
+create_query() may fail to catch the error since it only considers 0 as an
+error code.
+
+Therefore, unifying the error codes of create_digest() from non-positive
+numbers to 0 is better, which also benefits future programming.
+
+Fixes: c7235be ("RFC 3161 compliant time stamp request creation, response generation and response verification.")
+Signed-off-by: Jiasheng Jiang <jiasheng@purdue.edu>
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+(Merged from https://github.com/openssl/openssl/pull/23873)
+
+(cherry picked from commit beb82177ddcd4b536544ceec92bb53f4d85d8e91)
+---
+ apps/ts.c | 9 ++++++---
+ 1 file changed, 6 insertions(+), 3 deletions(-)
+
+diff --git a/apps/ts.c b/apps/ts.c
+index 57292e187c..96d16d4bd5 100644
+--- a/apps/ts.c
++++ b/apps/ts.c
+@@ -535,15 +535,18 @@ static int create_digest(BIO *input, const char *digest, const EVP_MD *md,
+ 
+         *md_value = OPENSSL_hexstr2buf(digest, &digest_len);
+         if (*md_value == NULL || md_value_len != digest_len) {
+-            OPENSSL_free(*md_value);
+-            *md_value = NULL;
+             BIO_printf(bio_err, "bad digest, %d bytes "
+                        "must be specified\n", md_value_len);
+-            return 0;
++            goto err;
+         }
+     }
+     rv = md_value_len;
+  err:
++    if (rv <= 0) {
++        OPENSSL_free(*md_value);
++        *md_value = NULL;
++        rv = 0;
++    }
+     EVP_MD_CTX_free(md_ctx);
+     return rv;
+ }
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0057-man-EVP_PKEY_CTX_set_params-document-params-is-a-lis.patch b/package/libs/openssl/patches/0057-man-EVP_PKEY_CTX_set_params-document-params-is-a-lis.patch
new file mode 100644
index 0000000..6c1e5e0
--- /dev/null
+++ b/package/libs/openssl/patches/0057-man-EVP_PKEY_CTX_set_params-document-params-is-a-lis.patch
@@ -0,0 +1,34 @@
+From e1b8d911b47f256d973fffccdf421a6368c2b87d Mon Sep 17 00:00:00 2001
+From: Hubert Kario <hkario@redhat.com>
+Date: Wed, 27 Mar 2024 17:44:42 +0100
+Subject: [PATCH 57/76] man EVP_PKEY_CTX_set_params: document params is a list
+
+Signed-off-by: Hubert Kario <hkario@redhat.com>
+
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23986)
+
+(cherry picked from commit 9b87c5a3ffa1ca233be96dd0bce812c04bad53fe)
+---
+ doc/man3/EVP_PKEY_CTX_set_params.pod | 4 +++-
+ 1 file changed, 3 insertions(+), 1 deletion(-)
+
+diff --git a/doc/man3/EVP_PKEY_CTX_set_params.pod b/doc/man3/EVP_PKEY_CTX_set_params.pod
+index c02151654c..2cc6846b1d 100644
+--- a/doc/man3/EVP_PKEY_CTX_set_params.pod
++++ b/doc/man3/EVP_PKEY_CTX_set_params.pod
+@@ -23,7 +23,9 @@ The EVP_PKEY_CTX_get_params() and EVP_PKEY_CTX_set_params() functions allow
+ transfer of arbitrary key parameters to and from providers.
+ Not all parameters may be supported by all providers.
+ See L<OSSL_PROVIDER(3)> for more information on providers.
+-See L<OSSL_PARAM(3)> for more information on parameters.
++The I<params> field is a pointer to a list of B<OSSL_PARAM> structures,
++terminated with a L<OSSL_PARAM_END(3)> struct.
++See L<OSSL_PARAM(3)> for information about passing parameters.
+ These functions must only be called after the EVP_PKEY_CTX has been initialised
+ for use in an operation.
+ These methods replace the EVP_PKEY_CTX_ctrl() mechanism. (EVP_PKEY_CTX_ctrl now
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0058-Fix-socket-descriptor-checks-on-Windows.patch b/package/libs/openssl/patches/0058-Fix-socket-descriptor-checks-on-Windows.patch
new file mode 100644
index 0000000..2b3b721
--- /dev/null
+++ b/package/libs/openssl/patches/0058-Fix-socket-descriptor-checks-on-Windows.patch
@@ -0,0 +1,53 @@
+From b32efb6f018e660281c8648f8a20cd1f53b0b7de Mon Sep 17 00:00:00 2001
+From: olszomal <Malgorzata.Olszowka@stunnel.org>
+Date: Thu, 4 Apr 2024 11:34:33 +0200
+Subject: [PATCH 58/76] Fix socket descriptor checks on Windows
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24035)
+
+(cherry picked from commit c89baf871030c811ba316ccbdcea26c294f605ae)
+---
+ crypto/bio/bio_lib.c  | 8 ++++++--
+ crypto/bio/bio_sock.c | 4 ++++
+ 2 files changed, 10 insertions(+), 2 deletions(-)
+
+diff --git a/crypto/bio/bio_lib.c b/crypto/bio/bio_lib.c
+index c86b9ac198..10278496c1 100644
+--- a/crypto/bio/bio_lib.c
++++ b/crypto/bio/bio_lib.c
+@@ -869,8 +869,12 @@ static int bio_wait(BIO *bio, time_t max_time, unsigned int nap_milliseconds)
+         return 1;
+ 
+ #ifndef OPENSSL_NO_SOCK
+-    if (BIO_get_fd(bio, &fd) > 0 && fd < FD_SETSIZE)
+-        return BIO_socket_wait(fd, BIO_should_read(bio), max_time);
++    if (BIO_get_fd(bio, &fd) > 0) {
++        int ret = BIO_socket_wait(fd, BIO_should_read(bio), max_time);
++
++        if (ret != -1)
++            return ret;
++    }
+ #endif
+     /* fall back to polling since no sockets are available */
+ 
+diff --git a/crypto/bio/bio_sock.c b/crypto/bio/bio_sock.c
+index 476cbcc5ce..6537a5062f 100644
+--- a/crypto/bio/bio_sock.c
++++ b/crypto/bio/bio_sock.c
+@@ -396,7 +396,11 @@ int BIO_socket_wait(int fd, int for_read, time_t max_time)
+     struct timeval tv;
+     time_t now;
+ 
++#ifdef _WIN32
++    if ((SOCKET)fd == INVALID_SOCKET)
++#else
+     if (fd < 0 || fd >= FD_SETSIZE)
++#endif
+         return -1;
+     if (max_time == 0)
+         return 1;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0059-Document-that-private-and-pairwise-checks-are-not-bo.patch b/package/libs/openssl/patches/0059-Document-that-private-and-pairwise-checks-are-not-bo.patch
new file mode 100644
index 0000000..c594481
--- /dev/null
+++ b/package/libs/openssl/patches/0059-Document-that-private-and-pairwise-checks-are-not-bo.patch
@@ -0,0 +1,34 @@
+From 2be64a7dc14e11a8b546e739a7ef3ad16590b803 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Fri, 5 Apr 2024 16:31:05 +0200
+Subject: [PATCH 59/76] Document that private and pairwise checks are not
+ bounded by key size
+
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+Reviewed-by: Shane Lontis <shane.lontis@oracle.com>
+(Merged from https://github.com/openssl/openssl/pull/24049)
+
+(cherry picked from commit 27005cecc75ec7a22a673d57fc35a11dea30ac0a)
+---
+ doc/man3/EVP_PKEY_check.pod | 5 +++++
+ 1 file changed, 5 insertions(+)
+
+diff --git a/doc/man3/EVP_PKEY_check.pod b/doc/man3/EVP_PKEY_check.pod
+index a16fdbbd50..198a0923c5 100644
+--- a/doc/man3/EVP_PKEY_check.pod
++++ b/doc/man3/EVP_PKEY_check.pod
+@@ -61,6 +61,11 @@ It is not necessary to call these functions after locally calling an approved ke
+ generation method, but may be required for assurance purposes when receiving
+ keys from a third party.
+ 
++The EVP_PKEY_pairwise_check() and EVP_PKEY_private_check() might not be bounded
++by any key size limits as private keys are not expected to be supplied by
++attackers. For that reason they might take an unbounded time if run on
++arbitrarily large keys.
++
+ =head1 RETURN VALUES
+ 
+ All functions return 1 for success or others for failure.
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0060-make_addressPrefix-Fix-a-memory-leak-in-error-case.patch b/package/libs/openssl/patches/0060-make_addressPrefix-Fix-a-memory-leak-in-error-case.patch
new file mode 100644
index 0000000..f4b754f
--- /dev/null
+++ b/package/libs/openssl/patches/0060-make_addressPrefix-Fix-a-memory-leak-in-error-case.patch
@@ -0,0 +1,37 @@
+From 0f7276865c54af41e99d1cc9f38b52a72b081b27 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Thu, 11 Apr 2024 09:40:18 +0200
+Subject: [PATCH 60/76] make_addressPrefix(): Fix a memory leak in error case
+
+Fixes #24098
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24102)
+
+(cherry picked from commit 682ed1b86ebe97036ab37897d528343d0e4def69)
+---
+ crypto/x509/v3_addr.c | 4 ++--
+ 1 file changed, 2 insertions(+), 2 deletions(-)
+
+diff --git a/crypto/x509/v3_addr.c b/crypto/x509/v3_addr.c
+index 4930f33124..20f3d2ba70 100644
+--- a/crypto/x509/v3_addr.c
++++ b/crypto/x509/v3_addr.c
+@@ -397,11 +397,11 @@ static int make_addressPrefix(IPAddressOrRange **result, unsigned char *addr,
+                               const int prefixlen, const int afilen)
+ {
+     int bytelen = (prefixlen + 7) / 8, bitlen = prefixlen % 8;
+-    IPAddressOrRange *aor = IPAddressOrRange_new();
++    IPAddressOrRange *aor;
+ 
+     if (prefixlen < 0 || prefixlen > (afilen * 8))
+         return 0;
+-    if (aor == NULL)
++    if ((aor = IPAddressOrRange_new()) == NULL)
+         return 0;
+     aor->type = IPAddressOrRange_addressPrefix;
+     if (aor->u.addressPrefix == NULL &&
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0061-list_provider_info-Fix-leak-on-error.patch b/package/libs/openssl/patches/0061-list_provider_info-Fix-leak-on-error.patch
new file mode 100644
index 0000000..33819ff
--- /dev/null
+++ b/package/libs/openssl/patches/0061-list_provider_info-Fix-leak-on-error.patch
@@ -0,0 +1,31 @@
+From 5e63050602e00640a3ff114b9cfddbc2189ff166 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Thu, 11 Apr 2024 17:49:53 +0200
+Subject: [PATCH 61/76] list_provider_info(): Fix leak on error
+
+Fixes #24110
+
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+(Merged from https://github.com/openssl/openssl/pull/24117)
+
+(cherry picked from commit 993c2407d04956ffdf9b32cf0a7e4938ace816dc)
+---
+ apps/list.c | 1 +
+ 1 file changed, 1 insertion(+)
+
+diff --git a/apps/list.c b/apps/list.c
+index 0fcbcbb083..ad5f45742c 100644
+--- a/apps/list.c
++++ b/apps/list.c
+@@ -1230,6 +1230,7 @@ static void list_provider_info(void)
+     }
+ 
+     if (OSSL_PROVIDER_do_all(NULL, &collect_providers, providers) != 1) {
++        sk_OSSL_PROVIDER_free(providers);
+         BIO_printf(bio_err, "ERROR: Memory allocation\n");
+         return;
+     }
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0062-doc-fingerprints.txt-Add-the-future-OpenSSL-release-.patch b/package/libs/openssl/patches/0062-doc-fingerprints.txt-Add-the-future-OpenSSL-release-.patch
new file mode 100644
index 0000000..f2b74a1
--- /dev/null
+++ b/package/libs/openssl/patches/0062-doc-fingerprints.txt-Add-the-future-OpenSSL-release-.patch
@@ -0,0 +1,34 @@
+From 5fbb133d6a7bbbcb1f904e4ba229dc2abed6f0c8 Mon Sep 17 00:00:00 2001
+From: Richard Levitte <levitte@openssl.org>
+Date: Mon, 8 Apr 2024 15:14:40 +0200
+Subject: [PATCH 62/76] doc/fingerprints.txt: Add the future OpenSSL release
+ key
+
+This will be used for future releases
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24063)
+
+(cherry picked from commit 4ffef97d3755a0425d5d72680daebfa07383b05c)
+---
+ doc/fingerprints.txt | 3 +++
+ 1 file changed, 3 insertions(+)
+
+diff --git a/doc/fingerprints.txt b/doc/fingerprints.txt
+index 9a26f7c667..9613cbac98 100644
+--- a/doc/fingerprints.txt
++++ b/doc/fingerprints.txt
+@@ -15,6 +15,9 @@ currently in use to sign OpenSSL distributions:
+ OpenSSL OMC:
+ EFC0 A467 D613 CB83 C7ED 6D30 D894 E2CE 8B3D 79F5
+ 
++OpenSSL:
++BA54 73A2 B058 7B07 FB27 CF2D 2160 94DF D0CB 81EF
++
+ Richard Levitte:
+ 7953 AC1F BC3D C8B3 B292 393E D5E9 E43F 7DF9 EE8C
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0063-Handle-empty-param-in-EVP_PKEY_CTX_add1_hkdf_info.patch b/package/libs/openssl/patches/0063-Handle-empty-param-in-EVP_PKEY_CTX_add1_hkdf_info.patch
new file mode 100644
index 0000000..197e8da
--- /dev/null
+++ b/package/libs/openssl/patches/0063-Handle-empty-param-in-EVP_PKEY_CTX_add1_hkdf_info.patch
@@ -0,0 +1,94 @@
+From 45c2a82041a2ed9f732b0c9c9d7c3bf07cd00835 Mon Sep 17 00:00:00 2001
+From: trinity-1686a <trinity@deuxfleurs.fr>
+Date: Mon, 15 Apr 2024 11:13:14 +0200
+Subject: [PATCH 63/76] Handle empty param in EVP_PKEY_CTX_add1_hkdf_info
+
+Fixes #24130
+The regression was introduced in PR #23456.
+
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24141)
+
+(cherry picked from commit 299996fb1fcd76eeadfd547958de2a1b822f37f5)
+---
+ crypto/evp/pmeth_lib.c |  2 ++
+ test/evp_extra_test.c  | 42 ++++++++++++++++++++++++++++++++++++++++++
+ 2 files changed, 44 insertions(+)
+
+diff --git a/crypto/evp/pmeth_lib.c b/crypto/evp/pmeth_lib.c
+index d0eeaf7137..bce1ebc84e 100644
+--- a/crypto/evp/pmeth_lib.c
++++ b/crypto/evp/pmeth_lib.c
+@@ -1053,6 +1053,8 @@ static int evp_pkey_ctx_add1_octet_string(EVP_PKEY_CTX *ctx, int fallback,
+     if (datalen < 0) {
+         ERR_raise(ERR_LIB_EVP, EVP_R_INVALID_LENGTH);
+         return 0;
++    } else if (datalen == 0) {
++        return 1;
+     }
+ 
+     /* Get the original value length */
+diff --git a/test/evp_extra_test.c b/test/evp_extra_test.c
+index e7b813493f..7e97e2d34d 100644
+--- a/test/evp_extra_test.c
++++ b/test/evp_extra_test.c
+@@ -2587,6 +2587,47 @@ static int test_emptyikm_HKDF(void)
+     return ret;
+ }
+ 
++static int test_empty_salt_info_HKDF(void)
++{
++    EVP_PKEY_CTX *pctx;
++    unsigned char out[20];
++    size_t outlen;
++    int ret = 0;
++    unsigned char salt[] = "";
++    unsigned char key[] = "012345678901234567890123456789";
++    unsigned char info[] = "";
++    const unsigned char expected[] = {
++	0x67, 0x12, 0xf9, 0x27, 0x8a, 0x8a, 0x3a, 0x8f, 0x7d, 0x2c, 0xa3, 0x6a,
++	0xaa, 0xe9, 0xb3, 0xb9, 0x52, 0x5f, 0xe0, 0x06,
++    };
++    size_t expectedlen = sizeof(expected);
++
++    if (!TEST_ptr(pctx = EVP_PKEY_CTX_new_from_name(testctx, "HKDF", testpropq)))
++        goto done;
++
++    outlen = sizeof(out);
++    memset(out, 0, outlen);
++
++    if (!TEST_int_gt(EVP_PKEY_derive_init(pctx), 0)
++            || !TEST_int_gt(EVP_PKEY_CTX_set_hkdf_md(pctx, EVP_sha256()), 0)
++            || !TEST_int_gt(EVP_PKEY_CTX_set1_hkdf_salt(pctx, salt,
++                                                        sizeof(salt) - 1), 0)
++            || !TEST_int_gt(EVP_PKEY_CTX_set1_hkdf_key(pctx, key,
++                                                       sizeof(key) - 1), 0)
++            || !TEST_int_gt(EVP_PKEY_CTX_add1_hkdf_info(pctx, info,
++                                                        sizeof(info) - 1), 0)
++            || !TEST_int_gt(EVP_PKEY_derive(pctx, out, &outlen), 0)
++            || !TEST_mem_eq(out, outlen, expected, expectedlen))
++        goto done;
++
++    ret = 1;
++
++ done:
++    EVP_PKEY_CTX_free(pctx);
++
++    return ret;
++}
++
+ #ifndef OPENSSL_NO_EC
+ static int test_X509_PUBKEY_inplace(void)
+ {
+@@ -5385,6 +5426,7 @@ int setup_tests(void)
+ #endif
+     ADD_TEST(test_HKDF);
+     ADD_TEST(test_emptyikm_HKDF);
++    ADD_TEST(test_empty_salt_info_HKDF);
+ #ifndef OPENSSL_NO_EC
+     ADD_TEST(test_X509_PUBKEY_inplace);
+     ADD_TEST(test_X509_PUBKEY_dup);
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0064-Fix-migration-guide-mappings-for-i2o-o2i_ECPublicKey.patch b/package/libs/openssl/patches/0064-Fix-migration-guide-mappings-for-i2o-o2i_ECPublicKey.patch
new file mode 100644
index 0000000..4a53ea2
--- /dev/null
+++ b/package/libs/openssl/patches/0064-Fix-migration-guide-mappings-for-i2o-o2i_ECPublicKey.patch
@@ -0,0 +1,69 @@
+From 721d007cdf11583475cef48f72ff3a6f722ebf09 Mon Sep 17 00:00:00 2001
+From: slontis <shane.lontis@oracle.com>
+Date: Fri, 5 Apr 2024 15:32:23 +1100
+Subject: [PATCH 64/76] Fix migration guide mappings for i2o/o2i_ECPublicKey
+
+Fixes #23854
+
+Reviewed-by: Nicola Tuveri <nic.tuv@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Neil Horman <nhorman@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24041)
+
+(cherry picked from commit 6594baf6457c64f6fce3ec60cb2617f75d98d159)
+---
+ doc/man7/migration_guide.pod | 18 ++++++++++++++++--
+ 1 file changed, 16 insertions(+), 2 deletions(-)
+
+diff --git a/doc/man7/migration_guide.pod b/doc/man7/migration_guide.pod
+index 1434f2fde2..5bbf852dd2 100644
+--- a/doc/man7/migration_guide.pod
++++ b/doc/man7/migration_guide.pod
+@@ -1306,7 +1306,7 @@ d2i_DSAPrivateKey_bio(), d2i_DSAPrivateKey_fp(), d2i_DSA_PUBKEY(),
+ d2i_DSA_PUBKEY_bio(), d2i_DSA_PUBKEY_fp(), d2i_DSAPublicKey(),
+ d2i_ECParameters(), d2i_ECPrivateKey(), d2i_ECPrivateKey_bio(),
+ d2i_ECPrivateKey_fp(), d2i_EC_PUBKEY(), d2i_EC_PUBKEY_bio(),
+-d2i_EC_PUBKEY_fp(), o2i_ECPublicKey(), d2i_RSAPrivateKey(),
++d2i_EC_PUBKEY_fp(), d2i_RSAPrivateKey(),
+ d2i_RSAPrivateKey_bio(), d2i_RSAPrivateKey_fp(), d2i_RSA_PUBKEY(),
+ d2i_RSA_PUBKEY_bio(), d2i_RSA_PUBKEY_fp(), d2i_RSAPublicKey(),
+ d2i_RSAPublicKey_bio(), d2i_RSAPublicKey_fp()
+@@ -1315,6 +1315,13 @@ See L</Deprecated i2d and d2i functions for low-level key types>
+ 
+ =item *
+ 
++o2i_ECPublicKey()
++
++Use L<EVP_PKEY_set1_encoded_public_key(3)>.
++See L</Deprecated low-level key parameter setters>
++
++=item *
++
+ DES_crypt(), DES_fcrypt(), DES_encrypt1(), DES_encrypt2(), DES_encrypt3(),
+ DES_decrypt3(), DES_ede3_cbc_encrypt(), DES_ede3_cfb64_encrypt(),
+ DES_ede3_cfb_encrypt(),DES_ede3_ofb64_encrypt(),
+@@ -1865,13 +1872,20 @@ and L<d2i_RSAPrivateKey(3)/Migration>
+ 
+ i2d_ECParameters(), i2d_ECPrivateKey(), i2d_ECPrivateKey_bio(),
+ i2d_ECPrivateKey_fp(), i2d_EC_PUBKEY(), i2d_EC_PUBKEY_bio(),
+-i2d_EC_PUBKEY_fp(), i2o_ECPublicKey()
++i2d_EC_PUBKEY_fp()
+ 
+ See L</Deprecated low-level key reading and writing functions>
+ and L<d2i_RSAPrivateKey(3)/Migration>
+ 
+ =item *
+ 
++i2o_ECPublicKey()
++
++Use L<EVP_PKEY_get1_encoded_public_key(3)>.
++See L</Deprecated low-level key parameter getters>
++
++=item *
++
+ i2d_RSAPrivateKey(), i2d_RSAPrivateKey_bio(), i2d_RSAPrivateKey_fp(),
+ i2d_RSA_PUBKEY(), i2d_RSA_PUBKEY_bio(), i2d_RSA_PUBKEY_fp(),
+ i2d_RSAPublicKey(), i2d_RSAPublicKey_bio(), i2d_RSAPublicKey_fp()
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0065-Invoke-tear_down-when-exiting-test_encode_tls_sct-pr.patch b/package/libs/openssl/patches/0065-Invoke-tear_down-when-exiting-test_encode_tls_sct-pr.patch
new file mode 100644
index 0000000..826f871
--- /dev/null
+++ b/package/libs/openssl/patches/0065-Invoke-tear_down-when-exiting-test_encode_tls_sct-pr.patch
@@ -0,0 +1,46 @@
+From 34eb9d8270959621d15322f8d526986d15ae2583 Mon Sep 17 00:00:00 2001
+From: shridhar kalavagunta <coolshrid@hotmail.com>
+Date: Sun, 21 Apr 2024 18:48:33 -0500
+Subject: [PATCH 65/76] Invoke tear_down when exiting test_encode_tls_sct()
+ prematurely
+
+Fixes #24121
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24222)
+
+(cherry picked from commit 264ff64b9443e60c7c93af0ced2b22fdf622d179)
+---
+ test/ct_test.c | 9 +++++++--
+ 1 file changed, 7 insertions(+), 2 deletions(-)
+
+diff --git a/test/ct_test.c b/test/ct_test.c
+index 26d5bc1084..7bf4e94029 100644
+--- a/test/ct_test.c
++++ b/test/ct_test.c
+@@ -450,13 +450,18 @@ static int test_encode_tls_sct(void)
+ 
+     fixture->sct_list = sk_SCT_new_null();
+     if (fixture->sct_list == NULL)
+-	    return 0;
++    {
++        tear_down(fixture);
++        return 0;
++    }
+ 
+     if (!TEST_ptr(sct = SCT_new_from_base64(SCT_VERSION_V1, log_id,
+                                             CT_LOG_ENTRY_TYPE_X509, timestamp,
+                                             extensions, signature)))
+-
++    {
++        tear_down(fixture);
+         return 0;
++    }
+ 
+     sk_SCT_push(fixture->sct_list, sct);
+     fixture->sct_dir = ct_dir;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0066-Update-perl-actions-install-with-cpanm-version-in-CI.patch b/package/libs/openssl/patches/0066-Update-perl-actions-install-with-cpanm-version-in-CI.patch
new file mode 100644
index 0000000..df2b7af
--- /dev/null
+++ b/package/libs/openssl/patches/0066-Update-perl-actions-install-with-cpanm-version-in-CI.patch
@@ -0,0 +1,30 @@
+From e6df53d3a9c5f62bdce47f1824cadb563eb98b72 Mon Sep 17 00:00:00 2001
+From: Tomas Mraz <tomas@openssl.org>
+Date: Fri, 16 Feb 2024 16:24:49 +0100
+Subject: [PATCH 66/76] Update perl-actions/install-with-cpanm version in CI
+
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Reviewed-by: David von Oheimb <david.von.oheimb@siemens.com>
+(Merged from https://github.com/openssl/openssl/pull/23613)
+
+(cherry picked from commit 599bc929baa3c5496342641e028e4c482aed7449)
+---
+ .github/workflows/ci.yml | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
+index b3f95e1d2e..7881154ff3 100644
+--- a/.github/workflows/ci.yml
++++ b/.github/workflows/ci.yml
+@@ -356,7 +356,7 @@ jobs:
+         sudo apt-get update
+         sudo apt-get -yq install bison gettext keyutils ldap-utils libldap2-dev libkeyutils-dev python3 python3-paste python3-pyrad slapd tcsh python3-virtualenv virtualenv python3-kdcproxy
+     - name: install cpanm and Test2::V0 for gost_engine testing
+-      uses: perl-actions/install-with-cpanm@v1
++      uses: perl-actions/install-with-cpanm@stable
+       with:
+         install: Test2::V0
+     - name: setup hostname workaround
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0067-Add-an-Apple-privacy-info-file-for-OpenSSL.patch b/package/libs/openssl/patches/0067-Add-an-Apple-privacy-info-file-for-OpenSSL.patch
new file mode 100644
index 0000000..0c7f94f
--- /dev/null
+++ b/package/libs/openssl/patches/0067-Add-an-Apple-privacy-info-file-for-OpenSSL.patch
@@ -0,0 +1,49 @@
+From f0115d45072ae7c4e2e3658ec0db43195b31251c Mon Sep 17 00:00:00 2001
+From: Takehiko Yokota <skirnir@gmail.com>
+Date: Wed, 24 Apr 2024 18:03:59 +0900
+Subject: [PATCH 67/76] Add an Apple privacy info file for OpenSSL
+
+Added PrivacyInfo.xcprivacy to os-dep/Apple/ dir.
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24260)
+
+(cherry picked from commit bde66e828dd2869d02225e4aab01d0983f242ae3)
+---
+ os-dep/Apple/PrivacyInfo.xcprivacy | 23 +++++++++++++++++++++++
+ 1 file changed, 23 insertions(+)
+ create mode 100644 os-dep/Apple/PrivacyInfo.xcprivacy
+
+diff --git a/os-dep/Apple/PrivacyInfo.xcprivacy b/os-dep/Apple/PrivacyInfo.xcprivacy
+new file mode 100644
+index 0000000000..285dd5beba
+--- /dev/null
++++ b/os-dep/Apple/PrivacyInfo.xcprivacy
+@@ -0,0 +1,23 @@
++<?xml version="1.0" encoding="UTF-8"?>
++<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
++<plist version="1.0">
++<dict>
++	<key>NSPrivacyAccessedAPITypes</key>
++	<array>
++		<dict>
++			<key>NSPrivacyAccessedAPIType</key>
++			<string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
++			<key>NSPrivacyAccessedAPITypeReasons</key>
++			<array>
++				<string>C617.1</string>
++			</array>
++		</dict>
++	</array>
++	<key>NSPrivacyCollectedDataTypes</key>
++	<array/>
++	<key>NSPrivacyTrackingDomains</key>
++	<array/>
++	<key>NSPrivacyTracking</key>
++	<false/>
++</dict>
++</plist>
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0068-set-module-path-from-template.patch b/package/libs/openssl/patches/0068-set-module-path-from-template.patch
new file mode 100644
index 0000000..6a227c3
--- /dev/null
+++ b/package/libs/openssl/patches/0068-set-module-path-from-template.patch
@@ -0,0 +1,44 @@
+From b6456af5c043397998997a4f91348fb0aeca2625 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Tue, 2 Apr 2024 15:02:51 -0400
+Subject: [PATCH 68/76] set module path from template
+
+Modules that aren't activated at conf load time don't seem to set the
+module path from the template leading to load failures.  Make sure to
+set that
+
+Fixes #24020
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+
+(cherry picked from commit bc9595963a45e28e6a8b2de45a6719c252bd3a3d)
+
+(Merged from https://github.com/openssl/openssl/pull/24198)
+
+(cherry picked from commit 71e5bb982f9c9563567ea8ae9f6e29492e9146ca)
+---
+ crypto/provider_core.c | 5 ++++-
+ 1 file changed, 4 insertions(+), 1 deletion(-)
+
+diff --git a/crypto/provider_core.c b/crypto/provider_core.c
+index 4cadb6a9f0..fb93f9fbe0 100644
+--- a/crypto/provider_core.c
++++ b/crypto/provider_core.c
+@@ -567,8 +567,11 @@ OSSL_PROVIDER *ossl_provider_new(OSSL_LIB_CTX *libctx, const char *name,
+     }
+ 
+     /* provider_new() generates an error, so no need here */
+-    if ((prov = provider_new(name, template.init, template.parameters)) == NULL)
++    prov = provider_new(name, template.init, template.parameters);
++    if (!ossl_provider_set_module_path(prov, template.path)) {
++        ossl_provider_free(prov);
+         return NULL;
++    }
+ 
+     prov->libctx = libctx;
+ #ifndef FIPS_MODULE
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0069-Add-test-for-OSSL_PROVIDER_load-with-module-path-set.patch b/package/libs/openssl/patches/0069-Add-test-for-OSSL_PROVIDER_load-with-module-path-set.patch
new file mode 100644
index 0000000..655566b
--- /dev/null
+++ b/package/libs/openssl/patches/0069-Add-test-for-OSSL_PROVIDER_load-with-module-path-set.patch
@@ -0,0 +1,158 @@
+From 74f551e90c3415bd391add232a93d433fb052b55 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Wed, 3 Apr 2024 15:18:33 -0400
+Subject: [PATCH 69/76] Add test for OSSL_PROVIDER_load with module path set
+
+Ensure that, with the modulepath setting set in a config field, that we
+are able to load a provider from the path relative to OPENSSL_MODULES
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+
+(cherry picked from commit 91a77cbf66c575345cf1eab31717e8edafcd1633)
+
+(Merged from https://github.com/openssl/openssl/pull/24198)
+
+(cherry picked from commit db163245097bc813235403c234795721d4e5c4eb)
+---
+ test/build.info                    |  1 +
+ test/pathed.cnf                    | 22 ++++++++++++++++
+ test/prov_config_test.c            | 42 ++++++++++++++++++++++++++++++
+ test/recipes/30-test_prov_config.t |  6 +++--
+ 4 files changed, 69 insertions(+), 2 deletions(-)
+ create mode 100644 test/pathed.cnf
+
+diff --git a/test/build.info b/test/build.info
+index 416c227077..25ab0430b7 100644
+--- a/test/build.info
++++ b/test/build.info
+@@ -874,6 +874,7 @@ IF[{- !$disabled{tests} -}]
+   ENDIF
+   IF[{- $disabled{module} || !$target{dso_scheme} -}]
+     DEFINE[provider_test]=NO_PROVIDER_MODULE
++    DEFINE[prov_config_test]=NO_PROVIDER_MODULE
+     DEFINE[provider_internal_test]=NO_PROVIDER_MODULE
+   ENDIF
+   DEPEND[]=provider_internal_test.cnf
+diff --git a/test/pathed.cnf b/test/pathed.cnf
+new file mode 100644
+index 0000000000..07bdc1fdb2
+--- /dev/null
++++ b/test/pathed.cnf
+@@ -0,0 +1,22 @@
++openssl_conf = openssl_init
++
++# Comment out the next line to ignore configuration errors
++config_diagnostics = 1
++
++[openssl_init]
++providers = provider_sect
++
++[provider_sect]
++default = default_sect
++legacy  = legacy_sect
++test    = test_sect
++
++[test_sect]
++module = ../test/p_test.so
++activate = false
++
++[default_sect]
++activate = true
++
++[legacy_sect]
++activate = false
+diff --git a/test/prov_config_test.c b/test/prov_config_test.c
+index b44ec78d8d..d59a954667 100644
+--- a/test/prov_config_test.c
++++ b/test/prov_config_test.c
+@@ -13,6 +13,7 @@
+ 
+ static char *configfile = NULL;
+ static char *recurseconfigfile = NULL;
++static char *pathedconfig = NULL;
+ 
+ /*
+  * Test to make sure there are no leaks or failures from loading the config
+@@ -70,6 +71,34 @@ static int test_recursive_config(void)
+     return testresult;
+ }
+ 
++#if !defined(OPENSSL_SYS_WINDOWS) && !defined(OPENSSL_SYS_MACOSX) && !defined(NO_PROVIDER_MODULE)
++static int test_path_config(void)
++{
++    OSSL_LIB_CTX *ctx = OSSL_LIB_CTX_new();
++    OSSL_PROVIDER *prov;
++    int testresult = 0;
++
++    if (!TEST_ptr(pathedconfig))
++        return 0;
++    if (!TEST_ptr(ctx))
++        return 0;
++
++    if (!TEST_true(OSSL_LIB_CTX_load_config(ctx, pathedconfig)))
++        goto err;
++
++    /* attempt to manually load the test provider */
++    if (!TEST_ptr(prov = OSSL_PROVIDER_load(ctx, "test")))
++        goto err;
++
++    OSSL_PROVIDER_unload(prov);
++
++    testresult = 1;
++ err:
++    OSSL_LIB_CTX_free(ctx);
++    return testresult;
++}
++#endif
++
+ OPT_TEST_DECLARE_USAGE("configfile\n")
+ 
+ int setup_tests(void)
+@@ -85,7 +114,20 @@ int setup_tests(void)
+     if (!TEST_ptr(recurseconfigfile = test_get_argument(1)))
+         return 0;
+ 
++    if (!TEST_ptr(pathedconfig = test_get_argument(2)))
++        return 0;
++
+     ADD_TEST(test_recursive_config);
+     ADD_TEST(test_double_config);
++#if !defined(OPENSSL_SYS_WINDOWS) && !defined(OPENSSL_SYS_MACOSX) && !defined(NO_PROVIDER_MODULE)
++    /*
++     * This test has to specify a module path to a file
++     * Which is setup as ../test/p_test.so
++     * Since windows/macos doesn't build with that extension
++     * just skip the test here
++     * Additionally skip it if we're not building provider modules
++     */
++    ADD_TEST(test_path_config);
++#endif
+     return 1;
+ }
+diff --git a/test/recipes/30-test_prov_config.t b/test/recipes/30-test_prov_config.t
+index 7f6350fd84..8884d07f3a 100644
+--- a/test/recipes/30-test_prov_config.t
++++ b/test/recipes/30-test_prov_config.t
+@@ -23,13 +23,15 @@ my $no_fips = disabled('fips') || ($ENV{NO_FIPS} // 0);
+ plan tests => 2;
+ 
+ ok(run(test(["prov_config_test", srctop_file("test", "default.cnf"),
+-                                 srctop_file("test", "recursive.cnf")])),
++                                 srctop_file("test", "recursive.cnf"),
++                                 srctop_file("test", "pathed.cnf")])),
+     "running prov_config_test default.cnf");
+ 
+ SKIP: {
+     skip "Skipping FIPS test in this build", 1 if $no_fips;
+ 
+     ok(run(test(["prov_config_test", srctop_file("test", "fips.cnf"),
+-                                     srctop_file("test", "recursive.cnf")])),
++                                     srctop_file("test", "recursive.cnf"),
++                                     srctop_file("test", "pathed.cnf")])),
+        "running prov_config_test fips.cnf");
+ }
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0070-Update-modulepath-test-for-provider-config-to-skip-i.patch b/package/libs/openssl/patches/0070-Update-modulepath-test-for-provider-config-to-skip-i.patch
new file mode 100644
index 0000000..e841719
--- /dev/null
+++ b/package/libs/openssl/patches/0070-Update-modulepath-test-for-provider-config-to-skip-i.patch
@@ -0,0 +1,83 @@
+From f663322bd61312a07d678fe3b22e517180653a37 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Thu, 4 Apr 2024 15:39:17 -0400
+Subject: [PATCH 70/76] Update modulepath test for provider config to skip if
+ not present
+
+If the p_test.so library isn't present, don't run the test
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+
+(cherry picked from commit b80fed3f27ebe156b17246f7c12c5178cbe6834e)
+
+(Merged from https://github.com/openssl/openssl/pull/24198)
+
+(cherry picked from commit 83c649996c18e5185f9439172d5908ad7fef9146)
+---
+ test/prov_config_test.c | 20 ++++++++------------
+ 1 file changed, 8 insertions(+), 12 deletions(-)
+
+diff --git a/test/prov_config_test.c b/test/prov_config_test.c
+index d59a954667..2fac741a3d 100644
+--- a/test/prov_config_test.c
++++ b/test/prov_config_test.c
+@@ -7,6 +7,7 @@
+  * https://www.openssl.org/source/license.html
+  */
+ 
++#include <sys/stat.h>
+ #include <openssl/evp.h>
+ #include <openssl/conf.h>
+ #include "testutil.h"
+@@ -71,15 +72,20 @@ static int test_recursive_config(void)
+     return testresult;
+ }
+ 
+-#if !defined(OPENSSL_SYS_WINDOWS) && !defined(OPENSSL_SYS_MACOSX) && !defined(NO_PROVIDER_MODULE)
+ static int test_path_config(void)
+ {
+-    OSSL_LIB_CTX *ctx = OSSL_LIB_CTX_new();
++    OSSL_LIB_CTX *ctx = NULL;
+     OSSL_PROVIDER *prov;
+     int testresult = 0;
++    struct stat sbuf;
++
++    if (stat("../test/p_test.so", &sbuf) == -1)
++        return TEST_skip("Skipping modulepath test as provider not present");
+ 
+     if (!TEST_ptr(pathedconfig))
+         return 0;
++
++    ctx = OSSL_LIB_CTX_new();
+     if (!TEST_ptr(ctx))
+         return 0;
+ 
+@@ -97,7 +103,6 @@ static int test_path_config(void)
+     OSSL_LIB_CTX_free(ctx);
+     return testresult;
+ }
+-#endif
+ 
+ OPT_TEST_DECLARE_USAGE("configfile\n")
+ 
+@@ -119,15 +124,6 @@ int setup_tests(void)
+ 
+     ADD_TEST(test_recursive_config);
+     ADD_TEST(test_double_config);
+-#if !defined(OPENSSL_SYS_WINDOWS) && !defined(OPENSSL_SYS_MACOSX) && !defined(NO_PROVIDER_MODULE)
+-    /*
+-     * This test has to specify a module path to a file
+-     * Which is setup as ../test/p_test.so
+-     * Since windows/macos doesn't build with that extension
+-     * just skip the test here
+-     * Additionally skip it if we're not building provider modules
+-     */
+     ADD_TEST(test_path_config);
+-#endif
+     return 1;
+ }
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0071-Fix-up-path-generation-to-use-OPENSSL_MODULES.patch b/package/libs/openssl/patches/0071-Fix-up-path-generation-to-use-OPENSSL_MODULES.patch
new file mode 100644
index 0000000..b2865f3
--- /dev/null
+++ b/package/libs/openssl/patches/0071-Fix-up-path-generation-to-use-OPENSSL_MODULES.patch
@@ -0,0 +1,70 @@
+From 25e1d8dcdedaa0e99218b4dd24f82a11f2a470eb Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Fri, 5 Apr 2024 09:06:10 -0400
+Subject: [PATCH 71/76] Fix up path generation to use OPENSSL_MODULES
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+
+(cherry picked from commit 4e3c1e6206251c59855362d6d2edab4621c31dec)
+
+(Merged from https://github.com/openssl/openssl/pull/24198)
+
+(cherry picked from commit 163202f0b95cfc7e666e45cafc55a505f51f6153)
+---
+ crypto/provider_core.c  |  4 ++++
+ test/prov_config_test.c | 15 ++++++++++++++-
+ 2 files changed, 18 insertions(+), 1 deletion(-)
+
+diff --git a/crypto/provider_core.c b/crypto/provider_core.c
+index fb93f9fbe0..4fccac7ab5 100644
+--- a/crypto/provider_core.c
++++ b/crypto/provider_core.c
+@@ -568,6 +568,10 @@ OSSL_PROVIDER *ossl_provider_new(OSSL_LIB_CTX *libctx, const char *name,
+ 
+     /* provider_new() generates an error, so no need here */
+     prov = provider_new(name, template.init, template.parameters);
++
++    if (prov == NULL)
++        return NULL;
++
+     if (!ossl_provider_set_module_path(prov, template.path)) {
+         ossl_provider_free(prov);
+         return NULL;
+diff --git a/test/prov_config_test.c b/test/prov_config_test.c
+index 2fac741a3d..fee2dffdb2 100644
+--- a/test/prov_config_test.c
++++ b/test/prov_config_test.c
+@@ -72,14 +72,27 @@ static int test_recursive_config(void)
+     return testresult;
+ }
+ 
++#define P_TEST_PATH "/../test/p_test.so"
+ static int test_path_config(void)
+ {
+     OSSL_LIB_CTX *ctx = NULL;
+     OSSL_PROVIDER *prov;
+     int testresult = 0;
+     struct stat sbuf;
++    char *module_path = getenv("OPENSSL_MODULES");
++    char *full_path = NULL;
++    int rc;
+ 
+-    if (stat("../test/p_test.so", &sbuf) == -1)
++    full_path = OPENSSL_zalloc(strlen(module_path) + strlen(P_TEST_PATH) + 1);
++    if (!TEST_ptr(full_path))
++        return 0;
++
++    strcpy(full_path, module_path);
++    full_path = strcat(full_path, P_TEST_PATH);
++    TEST_info("full path is %s", full_path);
++    rc = stat(full_path, &sbuf);
++    OPENSSL_free(full_path);
++    if (rc == -1)
+         return TEST_skip("Skipping modulepath test as provider not present");
+ 
+     if (!TEST_ptr(pathedconfig))
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0072-Fix-missing-NULL-check-in-prov_config_test.patch b/package/libs/openssl/patches/0072-Fix-missing-NULL-check-in-prov_config_test.patch
new file mode 100644
index 0000000..d7cfacd
--- /dev/null
+++ b/package/libs/openssl/patches/0072-Fix-missing-NULL-check-in-prov_config_test.patch
@@ -0,0 +1,36 @@
+From 491ff1b13bdabad24384cc0c19c6dd7532693613 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Fri, 19 Apr 2024 10:17:54 -0400
+Subject: [PATCH 72/76] Fix missing NULL check in prov_config_test
+
+coverity-1596500 caught a missing null check.  We should never hit it as
+the test harness always sets the environment variable, but lets add the
+check for safety
+
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24198)
+
+(cherry picked from commit a380ec952f138f644d227637eeba90fd1e17f72f)
+---
+ test/prov_config_test.c | 3 +++
+ 1 file changed, 3 insertions(+)
+
+diff --git a/test/prov_config_test.c b/test/prov_config_test.c
+index fee2dffdb2..4f0cbc247b 100644
+--- a/test/prov_config_test.c
++++ b/test/prov_config_test.c
+@@ -83,6 +83,9 @@ static int test_path_config(void)
+     char *full_path = NULL;
+     int rc;
+ 
++    if (!TEST_ptr(module_path))
++        return 0;
++
+     full_path = OPENSSL_zalloc(strlen(module_path) + strlen(P_TEST_PATH) + 1);
+     if (!TEST_ptr(full_path))
+         return 0;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0073-doc-clarify-SSL_CIPHER_description-allocation.patch b/package/libs/openssl/patches/0073-doc-clarify-SSL_CIPHER_description-allocation.patch
new file mode 100644
index 0000000..07ada51
--- /dev/null
+++ b/package/libs/openssl/patches/0073-doc-clarify-SSL_CIPHER_description-allocation.patch
@@ -0,0 +1,46 @@
+From d76fc993a9a83ce251040f3fe30f5f38a980b115 Mon Sep 17 00:00:00 2001
+From: Daniel McCarney <daniel@binaryparadox.net>
+Date: Thu, 21 Mar 2024 15:41:11 -0400
+Subject: [PATCH 73/76] doc: clarify SSL_CIPHER_description allocation
+
+Previously the documentation for `SSL_CIPHER_description` said:
+> If buf is provided, it must be at least 128 bytes, otherwise a buffer
+> will be allocated using OPENSSL_malloc().
+
+In reality, `OPENSSL_malloc` is only invoked if the provided `buf`
+argument is `NULL`. If the `buf` arg is not `NULL`, but smaller than
+128 bytes, the function returns `NULL` without attempting to allocate
+a new buffer for the description.
+
+This commit adjusts the documentation to better describe the implemented
+behaviour.
+
+CLA: trivial
+
+Reviewed-by: Matt Caswell <matt@openssl.org>
+Reviewed-by: Tom Cosgrove <tom.cosgrove@arm.com>
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/23921)
+
+(cherry picked from commit 6a4a714045415be6720f4165c4d70a0ff229a26a)
+---
+ doc/man3/SSL_CIPHER_get_name.pod | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/doc/man3/SSL_CIPHER_get_name.pod b/doc/man3/SSL_CIPHER_get_name.pod
+index e22a85a063..c3109279a7 100644
+--- a/doc/man3/SSL_CIPHER_get_name.pod
++++ b/doc/man3/SSL_CIPHER_get_name.pod
+@@ -109,7 +109,7 @@ cipher B<c>.
+ 
+ SSL_CIPHER_description() returns a textual description of the cipher used
+ into the buffer B<buf> of length B<len> provided.  If B<buf> is provided, it
+-must be at least 128 bytes, otherwise a buffer will be allocated using
++must be at least 128 bytes. If B<buf> is NULL it will be allocated using
+ OPENSSL_malloc().  If the provided buffer is too small, or the allocation fails,
+ B<NULL> is returned.
+ 
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0074-ess_lib.c-Changed-ERR_LIB_CMS-to-ERR_LIB_ESS.patch b/package/libs/openssl/patches/0074-ess_lib.c-Changed-ERR_LIB_CMS-to-ERR_LIB_ESS.patch
new file mode 100644
index 0000000..287970d
--- /dev/null
+++ b/package/libs/openssl/patches/0074-ess_lib.c-Changed-ERR_LIB_CMS-to-ERR_LIB_ESS.patch
@@ -0,0 +1,36 @@
+From 8d0d05e9cb132d6baec7c1e9aa9c0bf4ebfeebee Mon Sep 17 00:00:00 2001
+From: leerubin13 <lhr9392@rit.edu>
+Date: Sun, 28 Apr 2024 17:50:32 -0400
+Subject: [PATCH 74/76] ess_lib.c: Changed ERR_LIB_CMS to ERR_LIB_ESS
+
+This fixes an incorrect error message.
+
+Fixes #24224
+CLA: trivial
+
+Reviewed-by: Paul Dale <ppzgs1@gmail.com>
+Reviewed-by: Richard Levitte <levitte@openssl.org>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24290)
+
+(cherry picked from commit 2d29a8a7e8ef42050d2b08ca8cec9e4d9f0a0bb7)
+---
+ crypto/ess/ess_lib.c | 2 +-
+ 1 file changed, 1 insertion(+), 1 deletion(-)
+
+diff --git a/crypto/ess/ess_lib.c b/crypto/ess/ess_lib.c
+index 65444d383f..3d59fc2151 100644
+--- a/crypto/ess/ess_lib.c
++++ b/crypto/ess/ess_lib.c
+@@ -293,7 +293,7 @@ int OSSL_ESS_check_signing_certs(const ESS_SIGNING_CERT *ss,
+     int i, ret;
+ 
+     if (require_signing_cert && ss == NULL && ssv2 == NULL) {
+-        ERR_raise(ERR_LIB_CMS, ESS_R_MISSING_SIGNING_CERTIFICATE_ATTRIBUTE);
++        ERR_raise(ERR_LIB_ESS, ESS_R_MISSING_SIGNING_CERTIFICATE_ATTRIBUTE);
+         return -1;
+     }
+     if (n_v1 == 0 || n_v2 == 0) {
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0075-Add-check-for-public-key-presence-on-sm2-signing.patch b/package/libs/openssl/patches/0075-Add-check-for-public-key-presence-on-sm2-signing.patch
new file mode 100644
index 0000000..bd32021
--- /dev/null
+++ b/package/libs/openssl/patches/0075-Add-check-for-public-key-presence-on-sm2-signing.patch
@@ -0,0 +1,117 @@
+From 2a5010e31c6b9c5b4b570e038a0e3baec8268931 Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Mon, 18 Mar 2024 14:59:32 -0400
+Subject: [PATCH 75/76] Add check for public key presence on sm2 signing
+
+SM2 requires that the public EC_POINT be present in a key when signing.
+If its not there we crash on a NULL pointer.  Add a check to ensure that
+its present, and raise an error if its not
+
+Reviewed-by: Paul Yang <kaishen.yy@antfin.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24078)
+
+(cherry picked from commit 1316aa05aae57cf47d8c8bfca38aaa042db1518f)
+---
+ crypto/sm2/sm2_sign.c    |  9 ++++++++-
+ test/sm2_internal_test.c | 35 ++++++++++++++++++++++++++++-------
+ 2 files changed, 36 insertions(+), 8 deletions(-)
+
+diff --git a/crypto/sm2/sm2_sign.c b/crypto/sm2/sm2_sign.c
+index 09e542990b..2042ee030b 100644
+--- a/crypto/sm2/sm2_sign.c
++++ b/crypto/sm2/sm2_sign.c
+@@ -29,6 +29,7 @@ int ossl_sm2_compute_z_digest(uint8_t *out,
+ {
+     int rc = 0;
+     const EC_GROUP *group = EC_KEY_get0_group(key);
++    const EC_POINT *pubkey = EC_KEY_get0_public_key(key);
+     BN_CTX *ctx = NULL;
+     EVP_MD_CTX *hash = NULL;
+     BIGNUM *p = NULL;
+@@ -43,6 +44,12 @@ int ossl_sm2_compute_z_digest(uint8_t *out,
+     uint16_t entl = 0;
+     uint8_t e_byte = 0;
+ 
++    /* SM2 Signatures require a public key, check for it */
++    if (pubkey == NULL) {
++        ERR_raise(ERR_LIB_SM2, ERR_R_PASSED_NULL_PARAMETER);
++        goto done;
++    }
++
+     hash = EVP_MD_CTX_new();
+     ctx = BN_CTX_new_ex(ossl_ec_key_get_libctx(key));
+     if (hash == NULL || ctx == NULL) {
+@@ -118,7 +125,7 @@ int ossl_sm2_compute_z_digest(uint8_t *out,
+             || BN_bn2binpad(yG, buf, p_bytes) < 0
+             || !EVP_DigestUpdate(hash, buf, p_bytes)
+             || !EC_POINT_get_affine_coordinates(group,
+-                                                EC_KEY_get0_public_key(key),
++                                                pubkey,
+                                                 xA, yA, ctx)
+             || BN_bn2binpad(xA, buf, p_bytes) < 0
+             || !EVP_DigestUpdate(hash, buf, p_bytes)
+diff --git a/test/sm2_internal_test.c b/test/sm2_internal_test.c
+index 4899d5e213..8953915ec1 100644
+--- a/test/sm2_internal_test.c
++++ b/test/sm2_internal_test.c
+@@ -305,7 +305,8 @@ static int test_sm2_sign(const EC_GROUP *group,
+                          const char *message,
+                          const char *k_hex,
+                          const char *r_hex,
+-                         const char *s_hex)
++                         const char *s_hex,
++                         int omit_pubkey)
+ {
+     const size_t msg_len = strlen(message);
+     int ok = 0;
+@@ -327,11 +328,13 @@ static int test_sm2_sign(const EC_GROUP *group,
+             || !TEST_true(EC_KEY_set_private_key(key, priv)))
+         goto done;
+ 
+-    pt = EC_POINT_new(group);
+-    if (!TEST_ptr(pt)
+-            || !TEST_true(EC_POINT_mul(group, pt, priv, NULL, NULL, NULL))
+-            || !TEST_true(EC_KEY_set_public_key(key, pt)))
+-        goto done;
++    if (omit_pubkey == 0) {
++        pt = EC_POINT_new(group);
++        if (!TEST_ptr(pt)
++                || !TEST_true(EC_POINT_mul(group, pt, priv, NULL, NULL, NULL))
++                || !TEST_true(EC_KEY_set_public_key(key, pt)))
++            goto done;
++    }
+ 
+     start_fake_rand(k_hex);
+     sig = ossl_sm2_do_sign(key, EVP_sm3(), (const uint8_t *)userid,
+@@ -392,7 +395,25 @@ static int sm2_sig_test(void)
+                         "006CB28D99385C175C94F94E934817663FC176D925DD72B727260DBAAE1FB2F96F"
+                         "007c47811054c6f99613a578eb8453706ccb96384fe7df5c171671e760bfa8be3a",
+                         "40F1EC59F793D9F49E09DCEF49130D4194F79FB1EED2CAA55BACDB49C4E755D1",
+-                        "6FC6DAC32C5D5CF10C77DFB20F7C2EB667A457872FB09EC56327A67EC7DEEBE7")))
++                        "6FC6DAC32C5D5CF10C77DFB20F7C2EB667A457872FB09EC56327A67EC7DEEBE7", 0)))
++        goto done;
++
++    /* Make sure we fail if we omit the public portion of the key */
++    if (!TEST_false(test_sm2_sign(
++                     test_group,
++                     /* the default ID specified in GM/T 0009-2012 (Sec. 10).*/
++                     SM2_DEFAULT_USERID,
++                     /* privkey */
++                     "3945208F7B2144B13F36E38AC6D39F95889393692860B51A42FB81EF4DF7C5B8",
++                     /* plaintext message */
++                     "message digest",
++                     /* ephemeral nonce k */
++                     "59276E27D506861A16680F3AD9C02DCCEF3CC1FA3CDBE4CE6D54B80DEAC1BC21",
++                     /* expected signature, */
++                     /* signature R, 0x20 bytes */
++                     "F5A03B0648D2C4630EEAC513E1BB81A15944DA3827D5B74143AC7EACEEE720B3",
++                     /* signature S, 0x20 bytes */
++                     "B1B6AA29DF212FD8763182BC0D421CA1BB9038FD1F7F42D4840B69C485BBC1AA", 1)))
+         goto done;
+ 
+     testresult = 1;
+-- 
+2.38.1.windows.1
+
diff --git a/package/libs/openssl/patches/0076-Add-docs-noting-requirements-for-SM2-signing.patch b/package/libs/openssl/patches/0076-Add-docs-noting-requirements-for-SM2-signing.patch
new file mode 100644
index 0000000..55b121d
--- /dev/null
+++ b/package/libs/openssl/patches/0076-Add-docs-noting-requirements-for-SM2-signing.patch
@@ -0,0 +1,32 @@
+From 8beb0e3cc976b42ae12284aa1fd3b3c8eeb2030c Mon Sep 17 00:00:00 2001
+From: Neil Horman <nhorman@openssl.org>
+Date: Tue, 19 Mar 2024 04:52:57 -0400
+Subject: [PATCH 76/76] Add docs noting requirements for SM2 signing
+
+Reviewed-by: Paul Yang <kaishen.yy@antfin.com>
+Reviewed-by: Tomas Mraz <tomas@openssl.org>
+Reviewed-by: Matt Caswell <matt@openssl.org>
+(Merged from https://github.com/openssl/openssl/pull/24078)
+
+(cherry picked from commit 54673b93594a71c9f8052a1df1a7c6bf07c49f4d)
+---
+ doc/man7/EVP_PKEY-SM2.pod | 3 +++
+ 1 file changed, 3 insertions(+)
+
+diff --git a/doc/man7/EVP_PKEY-SM2.pod b/doc/man7/EVP_PKEY-SM2.pod
+index 8bdc506cec..b073dc8b05 100644
+--- a/doc/man7/EVP_PKEY-SM2.pod
++++ b/doc/man7/EVP_PKEY-SM2.pod
+@@ -38,6 +38,9 @@ Getter that returns the default digest name.
+ B<SM2> signatures can be generated by using the 'DigestSign' series of APIs, for
+ instance, EVP_DigestSignInit(), EVP_DigestSignUpdate() and EVP_DigestSignFinal().
+ Ditto for the verification process by calling the 'DigestVerify' series of APIs.
++Note that the SM2 algorithm requires the presence of the public key for signatures,
++as such the B<OSSL_PKEY_PARAM_PUB_KEY> option must be set on any key used in signature
++generation.
+ 
+ Before computing an B<SM2> signature, an B<EVP_PKEY_CTX> needs to be created,
+ and an B<SM2> ID must be set for it, like this:
+-- 
+2.38.1.windows.1
+
-- 
2.38.1.windows.1
