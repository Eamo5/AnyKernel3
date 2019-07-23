# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Endurance Kernel - Galaxy S9 / S9+ / N9
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=starlte
device.name2=star2lte
device.name3=crownlte
device.name4=
device.name5=
supported.versions=9.0
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/platform/11120000.ufs/by-name/BOOT;
is_slot_device=0;
ramdisk_compression=auto;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;


## AnyKernel install
dump_boot;

# begin ramdisk changes

# Backup
backup_file $ramdisk/init.rc;
backup_file $ramdisk/init.samsungexynos9810.rc;
backup_file $ramdisk/fstab.samsungexynos9810;
backup_file $ramdisk/init.samsungexynos9810.usb.rc;
backup_file $split_img/boot.img-oslevel

# Stop process authentication
insert_line $ramdisk/init.rc "import /init.local.rc" after "import /init.container.rc" "import /init.local.rc";
append_file $ramdisk/init.rc "start sysinit" $patch/init.d.patch

# Ramdisk changes - Set split_img OSLevel depending on ROM
(grep -w ro.build.version.security_patch | cut -d= -f2) </system/build.prop > $home/rom_oslevel
ROM_OSLEVEL=`cat $home/rom_oslevel`
echo $ROM_OSLEVEL | rev | cut -c4- | rev > $home/rom_oslevel
ROM_OSLEVEL=`cat $home/rom_oslevel`
ui_print "Setting security patch level to $ROM_OSLEVEL to ensure greater compatiblity."
echo $ROM_OSLEVEL > $split_img/boot.img-oslevel

# SELinux Enforcing Mode
replace_string $ramdisk/init.rc "setenforce 1" "setenforce 0" "setenforce 1"
replace_string $ramdisk/init.rc "SELINUX=enforcing" "SELINUX=permissive" "SELINUX=enforcing"

# Disable vaultkeeper on starlte
device=$(getprop ro.product.device);
if [ "$device" == "starlte" ] || [ "$device" == "star2lte" ]; then
		replace_line $ramdisk/init.rc "mkdir /dev/socket/vaultkeeper 0770 system system" "# mkdir /dev/socket/vaultkeeper 0770 system system";
		replace_line $ramdisk/init.rc "chown system system /dev/socket/vaultkeeper" "# chown system system /dev/socket/vaultkeeper";
		replace_line $ramdisk/init.rc "chmod 0770 /dev/socket/vaultkeeper" "# chmod 0770 /dev/socket/vaultkeeper";
		replace_line $ramdisk/init.rc "service vaultkeeperd /system/bin/vaultkeeperd" "# service vaultkeeperd /system/bin/vaultkeeperd";
		replace_line $ramdisk/init.rc "    class core" "#     class core";
fi;	

# Remove Google FRP & reactivation lock
replace_line $ramdisk/init.samsungexynos9810.rc "symlink /dev/block/DUMMY /dev/block/steady" "# symlink /dev/block/DUMMY /dev/block/steady";
replace_line $ramdisk/init.samsungexynos9810.rc "symlink /dev/block/DUMMY /dev/block/persistent" "# symlink /dev/block/DUMMY /dev/block/persistent";

# Remove forced encryption and add F2FS support
patch_fstab $ramdisk/fstab.samsungexynos9810 /system ext4 flags "forceencrypt=footer" "encryptable=footer";
insert_line $ramdisk/fstab.samsungexynos9810 "/dev/block/platform/11120000.ufs/by-name/CACHE          /cache      f2fs" after "/dev/block/platform/11120000.ufs/by-name/CACHE          /cache      ext4    noatime,nosuid,nodev,noauto_da_alloc,discard,journal_checksum,data=ordered,errors=panic       wait,check" "/dev/block/platform/11120000.ufs/by-name/CACHE          /cache      f2fs    noatime,nosuid,nodev,discard                                                                  wait,check";
insert_line $ramdisk/fstab.samsungexynos9810 "/dev/block/platform/11120000.ufs/by-name/USERDATA       /data       f2fs" after "/dev/block/platform/11120000.ufs/by-name/USERDATA       /data       ext4    noatime,nosuid,nodev,noauto_da_alloc,discard,journal_checksum,data=ordered,errors=panic       wait,check,encryptable=footer,quota" "/dev/block/platform/11120000.ufs/by-name/USERDATA       /data       f2fs    noatime,nosuid,nodev,discard                                                                  wait,check,encryptable=footer,quota";

# DriveDroid
insert_line $ramdisk/init.samsungexynos9810.usb.rc "mkdir /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0" after "mkdir /sys/kernel/config/usb_gadget/g1/functions/ncm.0" "mkdir /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0";
insert_line $ramdisk/init.samsungexynos9810.usb.rc "symlink /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/mass_storage.0" after "symlink /sys/kernel/config/usb_gadget/g1/functions/ncm.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/ncm.0" "symlink /sys/kernel/config/usb_gadget/g1/functions/mass_storage.0 /sys/kernel/config/usb_gadget/g1/configs/c.1/mass_storage.0";

# end ramdisk changes

write_boot;
## end install

