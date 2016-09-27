create a debian package

# The great idea


Create a debian package for my old Raspberrypi model B1.
The build will be performed in a "raspberrypi" virtual machine.

## Steps

* generate development VM (raspbian)
* fix the build script to generate the package
* generate the package
* install it on the Raspberrypi
* test.

## Future

* generic debian package (some day?)

# get raspberrypi environement

## preliminary warning
This section contains lots of copy and paste comming from:
* https://github.com/dhruvvyas90/qemu-rpi-kernel/wiki
* http://www.jdhp.org/docs/tutoriel_rpi_qemu/tutoriel_rpi_qemu.html
* http://dhruvvyas.com/blog/?p=49
* https://www.raspberrypi.org/forums/viewtopic.php?f=29&t=37386
* http://www.wilderssecurity.com/threads/working-with-raspian-vms-in-qemu-in-ubuntu-14-04-x64.373224/
* http://embedonix.com/articles/linux/emulating-raspberry-pi-on-linux/


The setup is for a debian jessie.

```bash
# install requiered packages
sudo apt-get update
sudo apt-get install qemu-system-arm
```


```bash
# download raspbian image
wget https://downloads.raspberrypi.org/raspbian_lite_latest -o raspbian_lite_latest.zip
# get qemu kernel
git clone https://github.com/dhruvvyas90/qemu-rpi-kernel.git
```


## prepare the image
The resapbian image needs some tweaks to boot in qemu correctly.

Requirements:
* The file `2016-05-27-raspbian-jessie-lite.img`

```bash
file -k 2016-05-27-raspbian-jessie-lite.img 
```
returns
```
2016-05-27-raspbian-jessie-lite.img: x86 boot sector; partition 1: ID=0xc, starthead 130, startsector 8192, 129024 sectors; partition 2: ID=0x83, starthead 138, startsector 137216, 2572288 sectors
```
Takes the *startsector* of *partition 2* , multiply by *512* and give it as offset to the mount command.

```bash
mkdir mnt
sudo mount -v -o offset=70254592  2016-05-27-raspbian-jessie-lite.img mnt
sudo vim mnt/etc/ld.so.preload
# comment all the lines
sudo vim mnt/etc/fstab
# comment second and third line
# (the /boot and / mount points)
sudo umount mnt

```

Resize disk image:
```bash
qemu-img resize 2016-05-27-raspbian-jessie-lite.img +5G
```


## first launch

Firt, copy kernel from https://github.com/dhruvvyas90/qemu-rpi-kernel.git



First boot
```bash
qemu-system-arm -kernel  kernel-qemu-4.1.7-jessie   -cpu arm1176 -m 256 -M versatilepb -serial stdio -append "root=/dev/sda2 rootfstype=ext4 rw" -hda 2016-05-27-raspbian-jessie-lite.img -redir tcp:2222::22
#once booted, login (pi)
sudo mount /dev/sda1 /boot
sudo raspi-config
# configure keyboard, enable openssh
sudo reboot
# login again
sudo apt install -f parted
sudo parted
resizepart 2
# enter 7G here
df -h
sudo resize2fs /dev/sda2
df -h
# you see plenty of free space!
```

You can connect to the VM with ssh and the following command:
```bash
ssh -Y -p 2222 pi@127.0.0.1
```

Reconfigure locales.

```bash
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales
```

# configure developmenent machine
## prerequisites
```bash
sudo apt update
sudo apt install  build-essential curl dnsutils git gnupg  libcurl4-openssl-dev libjpeg-dev libxml2-dev libxslt1-dev ntpdate openssh-server openssl python-dev python-jinja2 python-lxml python-pgpdump python-pip python-virtualenv rsyslog wget zlib1g-dev tmux packaging-dev lintian zsh
```
## setup build environement
The working directory will be in directory ```$OMB```

```bash
export OMB=$HOME/OMB
export GITHUB_ROOT=https://github.com/apre
export OMB_TARGET_DIR=$OMB/Omb-debstrap/target
# feel free to change vhe values above
mkdir -p $OMB
cd $OMB
git clone $GITHUB_ROOT/Omb-debstrap
cd $OMB/Omb-debstrap
mkdir ext
cd ext
git clone $GITHUB_ROOT/Omb-cs-com
git clone $GITHUB_ROOT/Omb-ihm
git clone $GITHUB_ROOT/Omb-Mailpile
git clone $GITHUB_ROOT/ttdnsd
```


# debian Packaging
## build

Execute build-deb.sh
```bash
cd $OMB/Omb-debstrap
./build-deb.sh
```



## package
To be done. read:
* http://packaging.ubuntu.com/html/packaging-new-software.html
* http://alp.developpez.com/tutoriels/debian/creer-paquet/
* https://openclassrooms.com/courses/creer-un-paquet-deb


In shell startup file:

```bash
export DEBFULLNAME="your name here"
export DEBEMAIL="your email@your domain"
```


```bash
cd $OMB/Omb-debstrap
chmod 755 target/DEBIAN/post*
chmod 755 target/DEBIAN/pre*
sudo dpkg-deb --build target own-mailbox.deb
```


## future work
Bellow, some random ideas
* use exim ?
* use [flatpak](http://flatpak.org/)
* nginx as webserver
* remove mysql (use sqlite/postgres/user-defined choice)
