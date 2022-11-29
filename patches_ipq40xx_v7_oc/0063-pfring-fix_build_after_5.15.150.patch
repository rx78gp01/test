diff --git a/feeds/packages/libs/libpfring/patches/101-5.15.150.patch b/feeds/packages/libs/libpfring/patches/101-5.15.150.patch
new file mode 100644
index 0000000..a974b16
--- /dev/null
+++ b/feeds/packages/libs/libpfring/patches/101-5.15.150.patch
@@ -0,0 +1,25 @@
+diff --git a/kernel/pf_ring.c b/kernel/pf_ring.c
+index 0ec7e4e..436ea95 100644
+--- a/kernel/pf_ring.c
++++ b/kernel/pf_ring.c
+@@ -5610,7 +5610,7 @@ static int packet_ring_bind(struct sock *sk, char *dev_name)
+ static int ring_bind(struct socket *sock, struct sockaddr *sa, int addr_len)
+ {
+   struct sock *sk = sock->sk;
+-  char name[sizeof(sa->sa_data)+1];
++  char name[sizeof(sa->sa_data_min)+1];
+ 
+   debug_printk(2, "ring_bind() called\n");
+ 
+@@ -5621,7 +5621,7 @@ static int ring_bind(struct socket *sock, struct sockaddr *sa, int addr_len)
+   if(sa->sa_family != PF_RING)
+     return(-EINVAL);
+ 
+-  memcpy(name, sa->sa_data, sizeof(sa->sa_data));
++  memcpy(name, sa->sa_data, sizeof(sa->sa_data_min));
+ 
+   /* Add trailing zero if missing */
+   name[sizeof(name)-1] = '\0';
+-- 
+2.38.1.windows.1
+
-- 
2.38.1.windows.1

