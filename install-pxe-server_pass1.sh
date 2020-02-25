#!/bin/bash

######################################################################
#
# v2020-02-25
#
# known issues:
#

BACKUP_FILE=backup.tar.xz

tar -ravf $BACKUP_FILE -C / boot/cmdline.txt

######################################################################
grep -q max_loop /boot/cmdline.txt &>/dev/null || {
    echo -e "\e[32msetup cmdline.txt for more loop devices\e[0m";
    sudo sed -i '1 s/$/ max_loop=64/' /boot/cmdline.txt;
}

######################################################################
grep -q net.ifnames /boot/cmdline.txt &>/dev/null || {
    echo -e "\e[32msetup cmdline.txt for old style network interface names\e[0m";
    sudo sed -i '1 s/$/ net.ifnames=0/' /boot/cmdline.txt;
}

######################################################################
grep -q quiet /boot/cmdline.txt &>/dev/null && {
    echo -e "\e[32msetup cmdline.txt for more boot output\e[0m";
    sudo sed -i '1 s/ quiet//' /boot/cmdline.txt;
}

######################################################################
grep -q splash /boot/cmdline.txt &>/dev/null && {
    echo -e "\e[32msetup cmdline.txt for no splash screen\e[0m";
    sudo sed -i '1 s/ splash//' /boot/cmdline.txt;
}


######################################################################
echo -e "\e[32msync...\e[0m" && sudo sync \
&& echo -e "\e[32mupdate...\e[0m" && sudo apt update \
&& echo -e "\e[32mupgrade...\e[0m" && sudo apt full-upgrade -y \
&& echo -e "\e[32mautoremove...\e[0m" && sudo apt autoremove -y --purge \
&& echo -e "\e[32mautoclean...\e[0m" && sudo apt autoclean \
&& echo -e "\e[32msync...\e[0m" && sudo sync \
&& echo -e "\e[32mDone.\e[0m" \
&& sync \
;


######################################################################
echo -e "\e[32minstall debconf-utils\e[0m";
sudo apt install -y --no-install-recommends debconf-utils;


######################################################################
echo -e "\e[32minstall uuid\e[0m";
sudo apt install -y --no-install-recommends uuid;


######################################################################
echo -e "\e[32minstall nfs-kernel-server for pxe\e[0m";
sudo apt install -y --no-install-recommends nfs-kernel-server;
sudo systemctl enable nfs-kernel-server.service;
sudo systemctl restart nfs-kernel-server.service;


######################################################################
echo -e "\e[32menable port mapping\e[0m";
sudo systemctl enable rpcbind.service;
sudo systemctl restart rpcbind.service;


######################################################################
echo -e "\e[32minstall dnsmasq for pxe\e[0m";
sudo apt install -y --no-install-recommends dnsmasq
sudo systemctl enable dnsmasq.service;
sudo systemctl restart dnsmasq.service;


######################################################################
echo -e "\e[32minstall samba\e[0m";
echo "samba-common	samba-common/dhcp	boolean	false" | sudo debconf-set-selections;
sudo apt install -y --no-install-recommends samba;


######################################################################
echo -e "\e[32minstall rsync\e[0m";
sudo apt install -y --no-install-recommends rsync;


######################################################################
echo -e "\e[32minstall syslinux-common for pxe\e[0m";
sudo apt install -y --no-install-recommends pxelinux syslinux-common syslinux-efi;


######################################################################
echo -e "\e[32minstall lighttpd\e[0m";
sudo apt install -y --no-install-recommends lighttpd;
grep -q mod_install_server /etc/lighttpd/lighttpd.conf &>/dev/null || {
    tar -ravf $BACKUP_FILE -C / etc/lighttpd/lighttpd.conf
    cat << EOF | sudo tee -a /etc/lighttpd/lighttpd.conf &>/dev/null
########################################
## mod_install_server
dir-listing.activate = "enable"
dir-listing.external-css = ""
dir-listing.external-js = ""
dir-listing.set-footer = "&nbsp;<br />"
dir-listing.exclude = ( "[.]*\.url" )
EOF
}
tar -ravf $BACKUP_FILE -C / var/www/html/index.lighttpd.html
sudo rm /var/www/html/index.lighttpd.html


######################################################################
echo -e "\e[32minstall wlan access point\e[0m";
sudo apt install -y --no-install-recommends hostapd


######################################################################
echo -e "\e[32minstall iptables for network address translation (NAT)\e[0m";
echo "iptables-persistent     iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections;
echo "iptables-persistent     iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections;
sudo apt install -y --no-install-recommends iptables iptables-persistent


######################################################################
$(dpkg --get-selections | grep -q -E "^(ntp|ntpd)[[:blank:]]*install$") || {
    echo -e "\e[32minstall chrony as ntp client and ntp server\e[0m";
    sudo apt install -y --no-install-recommends chrony;
    sudo systemctl enable chronyd.service;
    sudo systemctl restart chronyd.service;
}

######################################################################
######################################################################
echo -e "\e[32minstall real-vnc-server\e[0m";
sudo apt install -y --no-install-recommends realvnc-vnc-server realvnc-vnc-viewer
sudo systemctl enable vncserver-x11-serviced.service;
sudo systemctl restart vncserver-x11-serviced.service;


######################################################################
## optional
#echo -e "\e[32minstall apt-cacher-ng\e[0m";
#sudo apt install -y --no-install-recommends apt-cacher-ng;


######################################################################
## optional
#echo -e "\e[32minstall bindfs\e[0m";
#sudo apt install -y --no-install-recommends fuse bindfs;


######################################################################
## optional
#bridge#echo -e "\e[32minstall network bridge\e[0m";
#bridge#sudo apt install -y --no-install-recommends bridge-utils


######################################################################
## optional
echo -e "\e[32minstall wireshark\e[0m";
echo "wireshark-common        wireshark-common/install-setuid boolean true" | sudo debconf-set-selections;
sudo apt install -y --no-install-recommends tshark wireshark
sudo usermod -a -G wireshark $USER

echo -e "\e[32minstall other useful stuff\e[0m";
sudo apt install -y --no-install-recommends xterm transmission-gtk

echo -e "\e[32mreduce annoying networktraffic\e[0m";
sudo systemctl stop avahi-daemon.service
sudo systemctl disable avahi-daemon.service
sudo systemctl stop minissdpd.service
sudo systemctl disable minissdpd.service


######################################################################
## optional
grep -q logo.nologo /boot/cmdline.txt 2> /dev/null || {
echo -e "\e[32msetup cmdline.txt for no logo\e[0m";
sudo sed -i '1 s/$/ logo.nologo/' /boot/cmdline.txt;
}


######################################################################
## optional
echo -e "\e[32mchange hostname\e[0m";
tar -ravf $BACKUP_FILE -C / etc/hostname
echo pxe-server | sudo tee /etc/hostname &>/dev/null
tar -ravf $BACKUP_FILE -C / etc/hosts
sudo sed -i "s/127.0.1.1.*$(hostname)/127.0.1.1\tpxe-server/g" /etc/hosts


######################################################################
sync
echo -e "\e[32mDone.\e[0m";
echo -e "\e[1;31mPlease reboot\e[0m";
