# linux_maker
The project is used to build an image that can boot a linux system 

<br/>  
<br/>

# Workflow

```
initial  -+->  firmware   busybox   kernel   -+->  uboot  ->  deploy -> qemu 
          |                                   ^
          |                                   |
          +-            buildroot            -+
```

<br/>  
<br/>
