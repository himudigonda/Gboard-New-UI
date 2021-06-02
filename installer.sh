# #!/sbin/ash
# Author : @rehund
echo "ui_print > " > "$OUTFD"
#echo "ui_print > Adding smoothprops to $PROPLOC" > "$OUTFD"

block=/dev/block/bootdevice/by-name/system
device_abpartition=false
system_as_root=`getprop ro.build.system_root_image`
if [ "$system_as_root" == "true" ]; then
  echo "ui_print > Device is system-as-root" > "$OUTFD"
  active_slot=`getprop ro.boot.slot_suffix`
  if [ ! -z "$active_slot" ]; then
    device_abpartition=true
    block=/dev/block/bootdevice/by-name/system$active_slot
  fi
  SYSTEM_MOUNT=/system_root
  SYSTEM=$SYSTEM_MOUNT/system
  VENDOR=/vendor
else
  SYSTEM_MOUNT=/system
  SYSTEM=$SYSTEM_MOUNT
  VENDOR=/vendor
fi

mounting() {
  echo "ui_print > Mounting Partitions" > "$OUTFD"
  mounts=""
  for p in "/vendor" "$SYSTEM_MOUNT"; do
    if [ -d "$p" ] && grep -q "$p" "/etc/fstab" && ! mountpoint -q "$p"; then
      if [ -z "$mounts" ]; then
        mounts="$p"
      else
        mounts="$mounts $p"
      fi
    fi
  done

  for m in $mounts; do
    if [ "$m" -eq "/product" ]; then
      mount -o rw "$m"
    else
      mount "$m"
    fi
  done

  # Mount whatever $SYSTEM_MOUNT is, sometimes remount is necessary if mounted read-only
  grep -q "/system.*ro[\s,]" /proc/mounts && mount -o remount,rw $SYSTEM_MOUNT || mount -o rw "$block" $SYSTEM_MOUNT
}

unmount_all() {
  echo "ui_print > Unmount Partitions" > "$OUTFD"
  if [ "$device_abpartition" == "true" ]; then
      mount -o ro $SYSTEM_MOUNT
      mount -o ro $VENDOR
  else
      umount $SYSTEM_MOUNT
      umount $VENDOR
  fi;
}

export PROPLOC="/$SYSTEM/build.prop"

mounting;
echo "ui_print > Checking if Smooth Props is already added" > "$OUTFD"

grep "# Smooth Props Section" -q $PROPLOC && echo "ui_print > Smooth Props (#) Already Present! Skipping" > "$OUTFD" || echo "# Smooth Props Section" >> $PROPLOC
grep "debug.sf.latch_unsignaled=1" -q $PROPLOC && echo "ui_print > Smooth Props (A) Already Present! Skipping" > "$OUTFD" || echo "debug.sf.latch_unsignaled=1" >> $PROPLOC
grep "debug.sf.disable_backpressure=1" -q $PROPLOC && echo "ui_print > Smooth Props (B) Already Present! Skipping" > "$OUTFD" || echo "debug.sf.disable_backpressure=1" >> $PROPLOC

grep "# Recx Props Section" -q $PROPLOC && echo "ui_print > Recx Props (#) Already Present! Skipping" > "$OUTFD" || echo "# Recx Props Section" >> $PROPLOC
grep "debug.sf.enable_hwc_vds=0" -q $PROPLOC && echo "ui_print > Screenrecx Props (A) Already Present! Skipping" > "$OUTFD" || echo "debug.sf.enable_hwc_vds=0" >> $PROPLOC
grep "debug.sf.latch_unsignaled=0" -q $PROPLOC && echo "ui_print > Screenrecx Props (B) Already Present! Skipping" > "$OUTFD" || echo "debug.sf.latch_unsignaled=0" >> $PROPLOC

#debug.sf.enable_hwc_vds=0
#debug.sf.latch_unsignaled=0

echo "ui_print > Patched $PROPLOC"  > "$OUTFD"

echo "" >> $PROPLOC

unmount_all;

echo "ui_print + Installation complete!" > "$OUTFD"
echo "ui_print + Reboot to see your new gboard UI!" > "$OUTFD"
echo "ui_print + Incase, you want to revert back to original, clear Gboard's user data!" > "$OUTFD"
echo "ui_print :) by ruhend " > "$OUTFD"
