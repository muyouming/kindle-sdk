echo "[*] Copying openlipc to sysroot"
chmod a+w $sysroot_dir/usr/include
chmod a+w $sysroot_dir/usr/include/lipc.h
cp ./openlipc/include/openlipc.h $sysroot_dir/usr/include/lipc.h
chmod a-w $sysroot_dir/usr/include/lipc.h
chmod a-w $sysroot_dir/usr/include