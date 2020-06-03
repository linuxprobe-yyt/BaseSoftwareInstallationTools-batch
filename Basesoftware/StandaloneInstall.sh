#!/bin/bash
#===============================================================================
#2020-03-02 by yangyuntian 
#===============================================================================

export LANG="zh_CN.UTF-8"

####通用消息接口###

function Msgbox
{
	whiptail --title "消息" --yes-button "确定" --no-button "取消"  --yesno "$1" 10 60 --fb --backtitle  "${back_title}"
	if [ $? -ne 0 ];then
		CheckRunningResults
	fi
}

####检查操作系统###

function OS_version
{
	LOADING "检测操作系统版本.........." 0.015
	sys_ver_detail=`cat /etc/redhat-release`
	sys_ver=` cat /etc/redhat-release |sed -r 's|^([^.]+).*$|\1|; s|^[^0-9]*([0-9]+).*$|\1|'`

	whiptail --title "确认操作系统" --yes-button "确定" --no-button "取消"  --yesno "${sys_ver_detail}" 10 60 --fb --backtitle  "${back_title}"
	if [ $? -eq 0 ];then 
		source ${DIR_INSTALL}/scripts/ProgressBar
		source ${DIR_INSTALL}/scripts/CheckResults
		source ${DIR_INSTALL}/scripts/CheckGccInstalled
		source ${DIR_INSTALL}/scripts/AddUsers
		source ${DIR_INSTALL}/scripts/GlibcUpgrade
		source ${DIR_INSTALL}/scripts/DpdkInstall 
		source ${DIR_INSTALL}/scripts/GCCInstall 
		source ${DIR_INSTALL}/scripts/IftopInstall 
		source ${DIR_INSTALL}/scripts/IotopInstall 
		source ${DIR_INSTALL}/scripts/JDKInstallOrUpgrade 
		source ${DIR_INSTALL}/scripts/LrzszInstall 
		source ${DIR_INSTALL}/scripts/PfringInstall 
		source ${DIR_INSTALL}/scripts/PostgresqlInstall 
		source ${DIR_INSTALL}/scripts/SnmpInstall 
		source ${DIR_INSTALL}/scripts/SysstatInstall
		source ${DIR_INSTALL}/scripts/TomcatInstallOrUpgrade
		CheckGccInstalled
		Home_page
	else
		exit
	fi
}

#=====系统主界面=====#

function Home_page
{
	while true
	do
	trap "" 1 2 3;
    soft_list=$(whiptail --title "基础软件" --checklist \
    "请选择要安装的软件" 30 70 16 \
    "UserAddpgadmin" "pgadmin" OFF \
    "UserAddtomcat" "tomcat" OFF \
    "JDK" "${JDK_package}" OFF \
    "Tomcat" "${Tomcat_package}" OFF \
    "Postgresql" "${Postgresql_package}" OFF \
    "Iftop" "`eval echo '$'{Iftop_package_${sys_ver}}`" OFF \
    "Iotop" "`eval echo '$'{Iotop_package_${sys_ver}}`" OFF \
    "Sysstat" "${Sysstat_package}" OFF \
    "Lrzsz" "${Lrzsz_package}" OFF \
	  "Glibc" "${glibc_package}" OFF \
	  "Dpdk" "${dpdk_package}" OFF \
    "Pf_ring" "${Pf_ring_package}" OFF --fb --backtitle  "${back_title}" 3>&1 1>&2 2>&3)
	   if [ $? = 0 ]; then
	     if [ ! -n "${soft_list}" ]; then
		     Msgbox "至少选择一个软件"
		     Home_page
	     else
		     list_soft=$(echo  ${soft_list} |sed  's/"//g' )
		     Msgbox "默认选择项全部安装"
		     SelectBasicSoftware "${list_soft}"
			   CheckRunningResults "核查软件安装情况"
	     fi
	   else
	     exit
       fi
	done
	clear
}

function SelectBasicSoftware
{
for softlist in $1
do
	if [ "${softlist}" == "AllUserAdd" ];then
		AllUserAdd
	elif [ "${softlist}" == "UserAddpgadmin" ];then
		UserAddpgadmin
	elif [ "${softlist}" == "UserAddtomcat" ];then
		UserAddtomcat
	elif [ "${softlist}" == "JDK" ];then
		Msgbox "开始安装JDK"
		JDKInstall
	elif [ "${softlist}" == "Tomcat" ];then
		Msgbox "开始安装Tomcat"
		TomcatInstall_centos${sys_ver}
	elif [ "${softlist}" == "Postgresql" ];then
		Msgbox "开始安装Postgresql"
		PostgresqlInstall_centos${sys_ver}
	elif [ "${softlist}" == "Iftop" ];then
		Msgbox "开始安装Iftop"
		IftopInstall_centos${sys_ver}
	elif [ "${softlist}" == "Iotop" ];then
		Msgbox "开始安装Iotop"
		IotopInstall_centos${sys_ver}
	elif [ "${softlist}" == "Sysstat" ];then
		Msgbox "开始安装Sysstat"
		SysstatInstall
	elif [ "${softlist}" == "Lrzsz" ];then
		Msgbox "开始安装Lrzsz"
		LrzszInstall
	elif [ "${softlist}" == "gcc" ];then
		Msgbox "开始安装gcc"
		GCCInstall_centos${sys_ver}
	elif [ "${softlist}" == "snmp" ];then
		Msgbox "开始安装snmp"
		SnmpInstall
	elif [ "${softlist}" == "JDK_Upgrade" ];then
		Msgbox "开始升级JDK"
		JDKUpgrade
	elif [ "${softlist}" == "Tomcat_Upgrade" ];then
		Msgbox "开始升级Tomcat"
		TomcatUpdate_centos${sys_ver}
	elif [ "${softlist}" == "Glibc" ];then
		Msgbox "检测glibc版本"
		CheckGlibcVersion
	elif [ "${softlist}" == "Dpdk" ];then
		if [ -f ${installlogsPath}/VerificationResult-${Date}.log ];then
			CheckRunningResults "核查软件安装情况"
			Msgbox "开始安装 Dpdk"
			CheckNetworkcardModel
		else
			Msgbox "开始安装 Dpdk"
			CheckNetworkcardModel
		fi
	elif [ "${softlist}" == "Pf_ring" ];then
		Msgbox "开始安装 Pf_ring"
		PfringInstall
	fi
done
}

function InstallBasicSoftware_Collector_Pfring
{
    soft_list=$(whiptail --title "采集服务器基础软件" --checklist \
    "请选择要安装的软件" 30 70 16 \
    "UserAddpgadmin" "pgadmin" OFF \
    "JDK" "${JDK_package}" OFF \
    "Dpdk" "${dpdk_package}" OFF \
	"Glibc" "${glibc_package}" ON \
    "Pf_ring" "${Pf_ring_package}" ON \
    "Tomcat" "${Tomcat_package}" OFF \
    "Postgresql" "${Postgresql_package}" OFF \
    "Iftop" "`eval echo '$'{Iftop_package_${sys_ver}}`" OFF \
    "Iotop" "`eval echo '$'{Iotop_package_${sys_ver}}`" OFF \
    "Sysstat" "${Sysstat_package}" OFF \
    "Lrzsz" "${Lrzsz_package}" OFF --fb --backtitle  "${back_title}" 3>&1 1>&2 2>&3)

    if [ $? = 0 ]; then
	    if [ ! -n "${soft_list}" ]; then
		    Msgbox "至少选择一个软件"
		    InstallBasicSoftware_Collector
	    else
		    list_soft=$(echo  ${soft_list} |sed  's/"//g' )
		    Msgbox "默认选择项全部安装"
		    SelectBasicSoftware "${list_soft}"
		    CheckRunningResults "核查软件安装情况"
	    fi
    fi
}
####main####

back_title="基础软件安装v1.0"

##时间###
Date=`date +%Y%m%d%H%M`

#脚本存放路径#
DIR_INSTALL=$(cd $(dirname $0);pwd)

#加载配置文件#
installPath=${DIR_INSTALL}/packages
installlogsPath=${DIR_INSTALL}/logs
source ${DIR_INSTALL}/BaseSoftware.conf
source ${DIR_INSTALL}/scripts/ProgressBar
OS_version







