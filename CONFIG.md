# crosstool-ng

### ./ct-ng menuconfig

- Paths and misc options -> change Maximum log level to see to -> DEBUG
- Operating system -> Version of Linux -> 6.3.2
- C compiler -> Version of gcc -> 12.3.0
- C compiler -> C++ -> y
- Debug facilites -> disable all options for now as it takes forever to compile.  

<br/>  
<br/>





# U-Boot

### make menuconfig

- Boot images -> Support Flattened Image Tree -> y  

<br/>  
<br/>





# buildroot

### make menuconfig
    
- Target options -> Target Architecture -> Aarch64 (Little endian)
- Target options -> Floating point strategy -> FP-ARMv8  

<br/>

- Toolchain -> Toolchain type -> External toolchain.  
- Toolchain -> Toolchain -> Custom toolchain
- Toolchain -> Toolchain path -> And enter the path to the      toolchain. Ex: /home/rock/x-tools/aarch64-rpi3-linux-gnu
- Toolchain -> Toolchain has SSP support -> y
- Toolchain -> Toolchain has RPC support -> N
- Toolchain -> Toolchain prefix -> $(ARCH)-rpi3-linux-gnu
- Toolchain -> External toolchain gcc version -> 12.x
- Toolchain -> External toolchain kernel headers series -> 6.1.x or later.
- Toolchain -> External toolchain C library -> glibc/eglibc
- Toolchain -> Toolchain has C++ support -> y       

<br/>

- System configuration -> System hostname -> buildroot
- System configuration -> Init system -> BusyBox
- System configuration -> support extended attributes in device tables -> y
- System configuration -> Enable root login with password -> y
- System configuration -> Root password -> 1234
- System configuration -> bash
- System configuration -> Run a getty (login prompt) after boot -> TTY port -> tty1

<br/>

- kernel -> kernel version -> Custom local directory
- kernel -> URL of custom local directory -> /home/rock/raspberrypi/linux-6.1.32
- kernel -> Defconfig name -> bcmrpi3  

<br/>

- Target packages -> Networking applications -> dropbears

<br/>

- Filesystem images -> cpio the root filesystem (for use as an initial RAM filesyste) -> y
- Filesystem images -> Compression method -> gzip
- Filesystem images -> exact size -> 256M  

    
    
    
    
    




 
  
  
