Store the OpenWrt `usign` key pair in files called `secret.key` and `public.key` in this directory. Such a key pair can be generated using `usign -G -c "TorSH signing key" -s ./keys/secret.key -p ./keys/public.key`.

Add the public key to the OpenWrt instance by running:
1. `echo "src/gz torshrepo http://10.42.0.1:8000/download/openwrt" >> /etc/opkg.conf`
2. `echo $'untrusted comment: XYZ' > /public.key`
3. `opkg-key add /public.key`
4. `opkg update`
