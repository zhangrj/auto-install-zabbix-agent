#!/bin/bash

usage() { 
	echo "Usage: $0 [-s <zabbix server ip(s)>] [-n <zabbix host name>]" 1>&2
	exit 1
}

if [ ! "$#" == "4" ]; then 
	usage
fi

while getopts ":s:n:" o; do
    case "${o}" in
        s)
            server=${OPTARG}
            ;;
        n)
            hostname=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

echo "[Start to Install Zabbix Agent...]"
echo "[1、Detecting OS Version...]"

# Only Support RHEL/CentOS/SUSE
if [ -e "/etc/redhat-release" ]; then
	OS=RHEL_Series
	OS_VERSION=`cat /etc/redhat-release|sed -r 's/.* ([0-9]+)\..*/\1/'`
elif [ -e "/etc/issue" ] && [[ "$(cat /etc/issue|sed -n '2p')" == *"SUSE"* ]];then
	OS=SUSE
	OS_VERSION=`cat /etc/issue|sed -r 's/.* ([0-9]+) .*/\1/'|sed -n '2p'`
else
	echo "Does not support this OS!!!"
	exit 1
fi

if [ "$OS_VERSION" != "5" ] && [ "$OS_VERSION" != "6" ] && [ "$OS_VERSION" != "7" ] && [ "$OS_VERSION" != "9" ] && [ "$OS_VERSION" != "11" ]; then
	echo "Does not support this OS!!!"
	exit 1
fi	

if [ "$(getconf WORD_BIT)" == "32" ] && [ "$(getconf LONG_BIT)" == "64" ]; then
	OS_BIT=64
else
	OS_BIT=32
fi

echo "......$OS $OS_VERSION $OS_BIT bit detected......"

case $OS in
	RHEL_Series)
		echo "[2、RHEL/CentOS Detected, start install form .rpm...]"
		case $OS_VERSION in
			5)
				if [ $OS_BIT == 32 ]; then
					rpm -ivh http://192.168.128.181/rhel/5/i386/zabbix-agent-4.2.1-1.el5.i386.rpm
				else
					rpm -ivh http://192.168.128.181/rhel/5/x86_64/zabbix-agent-4.2.1-1.el5.x86_64.rpm
				fi
				;;
			6)
				if [ $OS_BIT == 32 ]; then
					rpm -ivh http://192.168.128.181/rhel/6/i386/zabbix-agent-4.2.1-1.el6.i686.rpm
				else
					rpm -ivh http://192.168.128.181/rhel/6/x86_64/zabbix-agent-4.2.1-1.el6.x86_64.rpm
				fi
				;;
			7)
				rpm -ivh http://192.168.128.181/rhel/7/x86_64/zabbix-agent-4.2.1-1.el7.x86_64.rpm
				;;
			*)
				;;
		esac
		echo "......Successfully installed Zabbix-agent on Centos......"
		;;
	SUSE)
		echo "[2、SUSE Enterprise Linux Detected, start install from source code...]"
		case $OS_VERSION in
			9)
				groupadd zabbix 
				useradd -g zabbix zabbix 
				cd /root
				wget http://192.168.128.181/zabbix-4.2.1.tar.gz
				rpm -ivh http://192.168.128.181/sles/9/glibc-devel-2.3.3-98.94.i586.rpm
				if [ `rpm -qa | grep libstdc++-3.3.3 | wc -l` -eq 0 ];then
					rpm -ivh http://192.168.128.181/sles/9/libstdc++-3.3.3-43.54.i586.rpm
				fi
				if [ `rpm -qa | grep libstdc++-devel | wc -l` -eq 0 ];then
					rpm -ivh http://192.168.128.181/sles/9/libstdc++-devel-3.3.3-43.54.i586.rpm
				fi
				rpm -ivh http://192.168.128.181/sles/9/pcre-devel-4.4-109.12.i586.rpm
				if [ $? -eq 0 ]; then
					tar -zxvf zabbix-4.2.1.tar.gz >/dev/null 2>&1
					cd zabbix-4.2.1 
					./configure --prefix=/usr/local/zabbix --enable-agent >/dev/null 2>&1
					if [ $? -eq 0 ];then
						make install >/dev/null 2>&1
						cp /root/zabbix-4.2.1/misc/init.d/suse/9.2/zabbix_agentd /etc/init.d/
						chmod +x /etc/init.d/zabbix_agentd
						ln -s /usr/local/zabbix/sbin/* /usr/local/sbin/
						ln -s /usr/local/zabbix/bin/* /usr/local/bin/
					else
						"......Configure zabbix-agent failed, Please contact administrator....."
						exit 1
					fi
				else
					echo "......Can not install zabbix-agent Automatically, Please contact Administrator......"
					exit 1
				fi
				;;
			11) 
				groupadd zabbix 
				useradd -g zabbix zabbix 
				cd /root
				wget http://192.168.128.181/zabbix-4.2.1.tar.gz
				rpm -ivh http://192.168.128.181/sles/11/glibc-devel-2.11.3-17.31.1.x86_64.rpm
				if [ `rpm -qa | grep libstdc++43-devel | wc -l` -eq 0 ];then
					rpm -ivh http://192.168.128.181/sles/11/libstdc++43-devel-4.3.4_20091019-0.22.17.x86_64.rpm
				fi
				if [ `rpm -qa | grep libstdc++-devel | wc -l` -eq 0 ];then
					rpm -ivh http://192.168.128.181/sles/11/libstdc++-devel-4.3-62.198.x86_64.rpm
				fi
				rpm -ivh http://192.168.128.181/sles/11/pcre-devel-6.4-14.1.x86_64.rpm
				if  [ $? -eq 0 ];then
					tar -zxvf zabbix-4.2.1.tar.gz >/dev/null 2>&1
					cd zabbix-4.2.1 
					./configure --prefix=/usr/local/zabbix --enable-agent >/dev/null 2>&1
					if [ $? -eq 0 ];then
						make install >/dev/null 2>&1
						cp /root/zabbix-4.2.1/misc/init.d/suse/9.2/zabbix_agentd /etc/init.d/
						chmod +x /etc/init.d/zabbix_agentd
						ln -s /usr/local/zabbix/sbin/* /usr/local/sbin/
						ln -s /usr/local/zabbix/bin/* /usr/local/bin/
					else
						"......Configure zabbix-agent failed, Please contact administrator....."
						exit 1
					fi
				else
					echo "......Can not install zabbix-agent Automatically......"
					echo "......You can install use rpm -ivh http://192.168.128.181/sles/11/zabbix-agent-2.2.14-2.1.x86_64.rpm......"
					echo "......Or you can contact administrator......"
					exit 1	
				fi
				;;
			*)
				;;
		esac
		echo "......Successfully installed Zabbix-agent on SUSE......"	
		;;
	*)
		echo "Error! Do not support this system, Please contact administrator."
		exit 1
		;;
esac

echo "[3、Editing the config file zabbix_agentd.conf...]"
edit_config_file(){
	sed -i "s/Server=127.0.0.1/Server=$server/g" $1
	sed -i "s/ServerActive=127.0.0.1/ServerActive=$server/g" $1
	sed -i "s/Hostname=Zabbix server/Hostname=$hostname/g" $1
}

case $OS in
	RHEL_Series)
		if [ -e "/etc/zabbix/zabbix_agentd.conf" ]; then
			edit_config_file /etc/zabbix/zabbix_agentd.conf
			echo "......Successfully edit zabbix_agentd.conf......"
		else
			echo "......zabbix_agent.conf not exist, zabbix-agent is not correctly installed......"
			exit 1
		fi
		;;
	SUSE)
		if [ -e "/usr/local/zabbix/etc/zabbix_agentd.conf" ]; then
			edit_config_file /usr/local/zabbix/etc/zabbix_agentd.conf
			echo "......Successfully edit zabbix_agentd.conf......"
		else
			echo "......zabbix_agent.conf not exist, zabbix-agent is not correctly installed......"
			exit 1
		fi		
		;;
esac

echo "[4、Adding zabbix-agent service to chkconfig...]"
case $OS in
	RHEL_Series)
		case $OS_VERSION in
			5)
				chkconfig zabbix-agent on
				echo "......Successfully add zabbix-agent to chkconfig......"
				;;
			6)
				chkconfig zabbix-agent on
				echo "......Successfully add zabbix-agent to chkconfig......"
				;;
			7)
				systemctl enable zabbix-agent
				echo "......Successfully add zabbix-agent to chkconfig......"
				;;
		esac
		;;
	SUSE)
		chkconfig --add zabbix_agentd
		chkconfig --level 235 zabbix_agentd on
		echo "......Successfully add zabbix-agent to chkconfig......"
		;;
esac

echo "[5、Starting zabbix agent...]"
case $OS in
	RHEL_Series)
		case $OS_VERSION in
			5)
				service zabbix-agent start
				if [ $? -eq 0 ];then
					echo "......Successfully start zabbix-agent......"
				else
					echo "......Start zabbix-agent failed..."
					exit 1
				fi
				;;
			6)
				service zabbix-agent start
				if [ $? -eq 0 ];then
					echo "......Successfully start zabbix-agent......"
				else
					echo "......Start zabbix-agent failed..."
					exit 1
				fi
				;;
			7)
				systemctl start zabbix-agent
				if [ $? -eq 0 ];then
					echo "......Successfully start zabbix-agent......"
				else
					echo "......Start zabbix-agent failed..."
				fi
				;;
		esac
		;;
	SUSE)
		/etc/init.d/zabbix_agentd start
		if [ $? -eq 0 ];then
			echo "......Successfully start zabbix_agentd......"
		else 
			echo "......Start zabbix_agentd failed..."
			echo "......Please check if SELinux is enable or firewall prevent port 10050/tcp......"
			exit 1
		fi
		;;
esac

echo "[6、Checking if zabbix agent is running...]"
if [ `netstat -ntpl | grep 10050 | wc -l` -gt 0 ];then
	echo "......zabbix-agent is listening on port 10050/tcp......"
else
	echo "......zabbix-agent is not running correctly......"
	exit 1
fi


echo ""
echo "************************************************"
echo "* check zabbix agent status                    *"
echo "* 1、tail -f /var/log/zabbix/zabbix_agentd.log *"
echo "* 2、netstat -ntpl|grep 10050                  *"
echo "************************************************"
echo ""
echo "if the system is running iptables/firewalld, Please reference http://192.168.128.181/Set_iptables_or_firewalld.docx"
echo ""