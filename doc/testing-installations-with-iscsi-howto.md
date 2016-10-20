## Description

This document try to be a guide for dummies to help testing iSCSI involved installations.

## Preparing your laboratory

Our tests needs **libvirt with KVM** so it is a prerequisite that you should be fulfilled first of all.

The next step we need to accomplish is: [Install a iSCSI Target](#install-target-system). 

If you are new to iSCSI and need to know more about it or do you want to install target and client without YaST, Steffen wrote a [guide](iscsi-for-beginners.md) that could help you and if you already wants to look deeper into it here you have an IBM [redbook](http://www.redbooks.ibm.com/redbooks/pdfs/sg247986.pdf#G9.458935). 

kobliha's [doc](https://docs.google.com/document/d/1SuZd6MArrsLKeRYyTODuW3rzS4DqQcebRobnq1O1NFs) is still valid but in our case we will just follow the official documentation [Mass Storage over IP Networks: iSCSI](https://www.suse.com/documentation/sles-12/stor_admin/data/cha_iscsi.html) adding animated gifs to some of the steps.

### Install Target System

- If you want to go further just install it with [AY](#autoyast-target-installation) if not, just continue reading...
- Download and install latest SLE 12 SP2 build (I used 2072 but RC2 is 2091).
- Configure a Static IP, I'm launching my installation with option `ifcfg=eth0=192.168.122.50/24,192.168.122.1,192.168.122.1,suse.com`
- Partition the disk with LVM (it was just my choice) creating a partition called lun with enough space to install a system there as for example:
```
  LV           VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lun1_lv      system -wi-a-----  8.00g                                                    
  lun2_lv      system -wi-a-----  8.00g                                                    
  lun3_lv      system -wi-a-----  8.00g                                                    
  root         system -wi-ao----  8.98g                                                    
  swap         system -wi-ao----  2.00g
  ```
- Finish your installation and reboot.
- Install **yast2-iscsi-lio-server**
- Launch your server with `yast2 iscsi-lio-server` and just see the steps you need to export a lun for initiator name **iqn:2016-08.com.example:01:client1** without authentication.

![add_lun1](https://cloud.githubusercontent.com/assets/7056681/18148872/58d10180-6fd4-11e6-9d4c-2c41e3a4fd92.gif)

## Common installation

We should check all the scenarios with the iscsi client (via linuxrc option **WithiSCSI=1**) and just configuring the client in the partition dialog althought it should be the same.

When the iscsi dialog is launched it will create a new initiator name, just modify it with the one we added during target configuration **(iqn:2016-08.com.example:01:client1)** and connect to it.

### With iSCI client enable (WithiSCSI=1)

As the initialization and rename of the initiator takes some time the video starts just after it and for that reason it does not need modifications. We have selected started onboot because the first scenario will be with root in the configured target.


![iscsi_dialog](https://cloud.githubusercontent.com/assets/7056681/18149691/a9ab5c9a-6fd9-11e6-9eaf-457abc337873.gif)

We can check with different scheme partitions. I have tested it with these:

- With the whole disk in iSCSI (not bootable if iPXE is not used)
- With the iSCSI device mounted in **/var**. (probably not supported [bsc#996257](https://bugzilla.suse.com/show_bug.cgi?id=996257) crazy config)
- With the iSCSI device mounted in **/opt** or other not DEPENDENT mount_point (works fine)
- With **/** in the iSCSI device and **/boot** in local. (it tooks sometime to dracut to init but works).

### Without iSCI client enable

In this case we have to launch the iSCSI client from the disks partition dialog, once we launch the iSCSI client the process is exactly the same.

## AutoYast installation **(AY)**

For AutoYast we could use the same scenarios tested manually generating a profile with `yast2 clone_system`. There should be an **iscsi-client** section like this one.
```
  <iscsi-client>
    <initiatorname>iqn.2016-08.com.example:01:client1</initiatorname>
    <targets config:type="list">
      <listentry>
        <authmethod>None</authmethod>
        <iface>default</iface>
        <portal>192.168.122.50:3260</portal>
        <startup>automatic</startup>
        <target>iqn.2016-08.com.example:68774a8c-cbb3-47ae-b0e2-0931b38761d3</target>
      </listentry>
    </targets>
    <version>1.0</version>
  </iscsi-client>
```
In case you would like to start from an AutoYast installation or just you have deleted your previous installation not being able to generate a new profile you could use [this one](https://w3.nue.suse.com/~kanderssen/sle12_client_example.xml) adapting it. This one install **root** in the iSCSI device.

From here we just repeat the same test that we did with manual installation **(same partitions schemes)**.

## AutoUpgrade and Upgrade

Once we have installed our systems is time to test upgrades. The recommended battery of tests should be something like: **Manual installation** -> **generate profile** -> **Automatic installation** -> **Create Snapshot*+ -> **Manual upgrade (using the snapshot)** -> **Automatic upgrade (with all the scenarios using the snapshot)**.

The scenarios to be tested with AY are:
- Use the profile from an url or other media that update installer support.
  - With and without the self_update_url in the profile
- Use the profile from a local disk
- Use the profile from a iSCSI device.

## Tips & Tricks

### Modifying installation workflow (control.xml)

This file controls the workflow of the installation apart of many other things, just read more about it [here](https://github.com/yast/yast-installation/blob/master/doc/control-file.md) to know more about what it does.

For the new **update installer** workflow we needed to modify the current control.xml and test it. We could just copy it in each installation but is something very tedious so we will see how we could modify it with a [dud](https://github.com/openSUSE/mkdud).

Just create your own dud with the packages, duds or files you need and also add the inst-sys folder with the control.xml file.
```
mkdud --create inst.dud --dist sle12          \
  yast2-installation-3.1.213-1.noarch.rpm     \
  yast2-3.1.205-1.x86_64.rpm                  \
  autoyast2-installation-3.1.149-1.noarch.rpm \
  yast2-update-3.1.42-1.x86_64.rpm            \
  yast2-storage-3.1.102-1.x86_64.rpm          \
  yast2-registration-3.1.187-1.noarch.rpm     \
  inst-sys
```
Now just launch a new installation with the dud parameter and the location of your dud.
```
-x "dud=http://10.163.0.227/dud/inst.dud insecure=1"
```

### Autoyast Target installation

You are too lazy? If it is your case and you prefer to install the machine with just one click you can use Huha's [virt-installer](https://github.com/shundhammer/virt-installer) or some of other available scripts. I use a very simple one that Imo shares some time ago
```
export DISPLAY=:0

ISO="/home/knut/isos/SLE-12-SP2-Server-DVD-x86_64-Build2091-Media1.iso"
NAME="sle12_test"
INFO="info.txt"

virsh destroy $NAME
virsh undefine $NAME

virt-install --vnc --os-variant sles12 --vcpus=2 --ram=2048 --name $NAME \
    --network bridge=virbr0,model=rtl8139 --location=$ISO \
    -x "textmode=0 info=http://192.168.122.1/dud/$INFO" \
    --disk path=/var/lib/libvirt/images/$NAME,size=30
```

You can use this [profile](https://w3.nue.suse.com/~kanderssen/sle12_iscsi_example.xml) which creates the partitions and installs the needed packages for you, just modify it with your own requirements.
