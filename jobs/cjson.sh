echo "[*] Copying cJSON to sysroot"
chmod a+w $sysroot_dir/usr/include
chmod a+w $sysroot_dir/usr/include/cJSON.h
cp ./cJSON/cJSON.h $sysroot_dir/usr/include/cJSON.h
chmod a-w $sysroot_dir/usr/include
chmod a-w $sysroot_dir/usr/include/cJSON.h