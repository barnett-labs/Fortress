#!/bin/sh

#Version 1.02

#Curtesy of http://guylabs.ch/2013/09/18/install-clamav-antivirus-in-ubuntu-server-and-client/

#Update ClamAV
freshclam 

#Restart PortSentry and run logcheck for good measure (Defunct)
#service portsentry restart
#sudo -u logcheck logcheck

 
# emtpy the old scanlog and do a virus scan
rm -R /home/clamav/clamav-scan.log
touch /home/clamav/clamav-scan.log
clamdscan /home/ /etc/ /opt/ /var/ /root/ --fdpass --log=/home/root/clamav/clamav-scan.log --infected --multiscan
 
### Send the email
if grep -rl 'Infected files: 0' /home/clamav/clamav-scan.log
then echo "No virus found"
else cat /home/clamav/clamav-scan.log | mail -s subject emailadd
fi

