#!/bin/bash

set -x

./cleanup.sh
./required-packages.sh
if [ "$?" -ne "0" ]; then
  echo "Error while installing required debian packages."
  echo "Please check your apt-get config."
  exit 1
fi

# the next sectiion (install-repositories.sh) is made by build-deb.sh

#./install-repositories.sh
#if [ "$?" -ne "0" ]; then
#  echo "Error while installing Own-Mailbox git repositories."
#  exit 1
#fi

# startup scripts moved to /usr/share/omb/
./setup-startup.sh
#if [ "$?" -ne "0" ]; then
#  echo "Error while setting up startup."
#  exit 1
#fi

./setup-rng-tool.sh
if [ "$?" -ne "0" ]; then
  echo "Error while setting up rng-tools."
  exit 1
fi

./setup-hostname.sh
if [ "$?" -ne "0" ]; then
  echo "Error while setting up hostname."
  exit 1
fi

pkill python2
su mailpile -c ./setup-mailpile.sh
if [ "$?" -ne "0" ]; then
  echo "Error while setting up mailpile."
  exit 1
fi

pip install -r /home/mailpile/Mailpile/requirements.txt
if [ "$?" -ne "0" ]; then
  echo "Error while setting up mailpile."
  exit 1
fi

mkdir /etc/omb/
chown www-data /etc/omb/
echo "nameserver 127.0.0.1" > /etc/resolv.conf.head

cp torrc /etc/tor/torrc
touch /var/log/tor.log
chown tor /var/log/tor.log
echo "AllowInbound 1" >> /etc/tor/torsocks.conf
if [ "$?" -ne "0" ]; then
  echo "Error while setting up torsocks."
  exit 1
fi

./setup-iptables.sh
if [ "$?" -ne "0" ] && [ "$DOCKER" != "yes" ]; then
  echo "Error while setting up iptables."
  exit 1
fi

# Temporarily use google dns server and flush iptables
# to make sure the upgrade will be overwritten at first startup
echo "nameserver 8.8.8.8" > /etc/resolv.conf
iptables -F
ip6tables -F
apt-get upgrade -y

# Make sure to fetch time every hour in the crontab
(crontab -l 2>/dev/null; echo "00 * * * * service ntp stop; ntpdate -s ntp.univ-lyon1.fr; service ntp start") | crontab -

# Make sure to sync every minute
(crontab -l 2>/dev/null; echo "* * * * * sync") | crontab -

if [ "$DOCKER" != "yes" ]; then
  echo "Rebooting in 5 seconds..."
  sleep 5
  reboot
fi

exit 0
