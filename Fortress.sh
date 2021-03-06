#!/bin/bash

#Created by Barnett Labs
#website: http://barnett-labs.com
#email: info@barnett-labs.com
#
###################################################################################
###################################################################################
#Copyright (c) 2015 Barnett Labs
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#
###################################################################################
###################################################################################
#
#
#Version 2.01
#
#Removed OSSEC installation, see Fortress-with-Ossec if OSSEC is desired
#
#
#Version 2.00
#
#Disabled OSSEC installation, will be removed in next update, see Fortress-with-ossec if ossec is desired
#
#Minor bugifxes
#
#
#Version 1.02
#
#Features: Auto updates and installs ClamAV, PortSentry, OSSEC, and UFW
#
#Future: UFW is planned for future versions(Now Implemented)
#
#
#
#
#
###################################################################################
###################################################################################
#Courtesy of http://bobcopeland.com/blog/2012/10/goto-in-bash/
function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

start=${1:-"start"}

jumpto $start
###################################################################################
###################################################################################


start:
#Evaluate minimum system requirements
memory=$(free -m | grep Mem | awk '{ print $2 }')
min=1280

 if [ "${memory}" \< "${min}" ]
           then
                       echo "You do not meet minimum requirements, use './fortress.sh force' argument to overide"
					   exit 1

           else
                       echo "Your system meets minimum requirments and should perform as expected."
					   echo "Please press enter to continue"
					   read continue
					  jumpto force
           fi




force:

#Gather Custom Data
	echo "Set ClamAV Email Alert Subject Line Using Quotes: (ex: 'Virus Detected')"
	read subject
	echo "Set ClamAV Email Alert Recipient"
	read emailadd

#Update the repository and install pre-reqs:
	apt-get update
	apt-get -y upgrade
	apt-get -y install nano syslog-summary logcheck portsentry syslog-summary python-magic-dbg python-gdbm-dbg python-tk-dbg clamav clamav-daemon ufw
	/etc/init.d/apache2 restart

#Rebuild locale info, this eliminates errors in logs
	update-locale

#Configure PortSentry and Logcheck
	sed -i 's/BLOCK_TCP="0"/BLOCK_TCP="1"/g' /etc/portsentry/portsentry.conf
	sed -i 's/SENDMAILTO="logcheck"/SENDMAILTO="$emailadd"/g' /etc/logcheck/logcheck.conf
	sed -i 's/#ATTACKSUBJECT="Security Alerts"/ATTACKSUBJECT="Security Alerts"/g' /etc/logcheck/logcheck.conf
	sed -i 's/#SECURITYSUBJECT="Security Events"/SECURITYSUBJECT="Security Events"/g' /etc/logcheck/logcheck.conf
	sed -i 's/#EVENTSSUBJECT="System Events"/EVENTSSUBJECT="System Events"/g' /etc/logcheck/logcheck.conf

#Configure ClamAV
	#dpkg-reconfigure clamav-base (Depreciated in this script)
	wget http://barnett-labs.com/Software/clamd.conf
	wget https://barnett-labs.com/Software/freshclam.conf
	mv clamd.conf /etc/clamav/
	mv freshclam.conf /etc/clamav/

#Update and Restart ClamAV
	freshclam
	/etc/init.d/clamav-daemon start

#Download Clamav_Scan and make executable 
	mkdir /home/clamav/
	wget https://barnett-labs.com/Software/clamav-scan.sh
	chmod +x clamav-scan.sh
	mv clamav-scan.sh /home/clamav/

#Configure Clamav_Scan
	sed -i "s/subject/$subject/g" /home/clamav/clamav-scan.sh
	sed -i "s/emailadd/$emailadd/g" /home/clamav/clamav-scan.sh

#Configure Crontab to run Clamav_Scan daily at 1500
	crontab -l >> crondump
	echo '00 03 * * * /root/clamav-scan.sh' >> crondump
	crontab /root/crondump

#Apply portsentry changes
	service portsentry restart

#Configure UFW
	ufw default deny
	ufw allow 22
	ufw allow 25
	ufw allow 53
	ufw allow 80
	ufw allow 443
	ufw allow 1514

#Enable UFW
	ufw enable

help:
	#echo "test"

