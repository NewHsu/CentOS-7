# KVM配置文件

## cat /etc/libvirt/qemu
```
……
// kvm guest 定义开始
<domain type='qemu'>   

//guest OS的name。由字母和数字组成，不能包含空格  
<name>centos7.0</name>

// uuid，由命令行工具 uuidgen生成,唯一标识名称
  <uuid>b93af911-d994-4b1d-a7a8-4490029601cc</uuid>

//在不reboot guest的情况下，guset可以使用的最大内存，以KB为单位
  <memory unit='KiB'>1048576</memory>

// guest启动时内存，可以通过virsh setmem来调整内存，但不能大于最大可使用内存
  <currentMemory unit='KiB'>1048576</currentMemory>

//分配的虚拟cpu
  <vcpu placement='static'>1</vcpu>

//有关OS,架构：i686、x86_64,machine：宿主机的操作系统
//boot:指定启动设备，可以重复多行，指定不同的值，作为一个启动设备列表。
  <os>
    <type arch='x86_64' machine='pc-i440fx-rhel7.0.0'>hvm</type>
    <boot dev='hd'/>
  </os>
//处理器特性
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
//时钟。使用UTC时间
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
//定义了在kvm环境中power off，reboot，或crash时的默认的动作分别为destroy和//restart。其他允许的动作包括： preserve，rename-restart.。
//destroy：停止该虚拟机。相当于关闭电源。
//restart重启虚拟机。
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
//设备定义开始
  <devices>
//模拟元素，此处写法用于kvm的guest

<emulator>/usr/libexec/qemu-kvm</emulator>
//用于kvm存储的文件。在这个例子中，在guest中显示为VirtualIO设备。
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/kvm/centos7.img'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
</disk>

    <disk type='block' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <target dev='hda' bus='ide'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
</controller>
//使用网桥类型。确保每个kvm guest的mac地址唯一。将创建tun设备，名称为vnetx（x为0,1,2...）
    <interface type='bridge'>
      <mac address='52:54:00:6c:4d:d8'/>
      <source bridge='br0'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
</console>
//输入设备
    <input type='tablet' bus='usb'/>
    <input type='mouse' bus='ps2'/>
<input type='keyboard' bus='ps2'/>
//定义与guset交互的图形设备。
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
    <video>
      <model type='cirrus' vram='16384' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
</memballoon>
//设备定义结束
  </devices>
//KVM定义结束
</domain>
```