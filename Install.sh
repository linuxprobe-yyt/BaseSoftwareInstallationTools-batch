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
		exit
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
		source ${ansible_dir}/scripts/CheckGccInstalled
		source ${ansible_dir}/scripts/GCCInstall
		source ${ansible_dir}/scripts/CheckResultLog
		source ${ansible_dir}/scripts/EditPlaybook
		source ${ansible_dir}/scripts/configure
		source ${ansible_dir}/scripts/PingHosts
		CheckGccInstalled
		${ansible_dir}/scripts/AnsibleInstall.sh
		if [ $? -eq "1" ];then
		  exit
		else
		  PingHosts
		  EditPlaybook
		  Home_page
		fi
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
	DISTROS=$(whiptail  --title "${sys_ver_detail} 版本主菜单页面"   --menu "按服务器角色选择安装：" 30 70 16 \
	1 "   [ DNVWeb服务器 ]" \
	2 "   [ 数据库服务器 ]" \
	3 "   [ 采集服务器 ]" \
	4 "   [ DataX汇聚服务器 ]" \
	5 "   [ 自主选择主机、主机组和基础软件 ]" --fb --backtitle "${back_title}" 3>&1 1>&2 2>&3)
	[ $? -eq 0 ] && Main ${DISTROS} || exit
	done
	clear
}

#=====首页配置=====#

### Main ###

function Main
{
	while true
	do
	clear
		case ${DISTROS} in
		1)
		InstallBasicSoftware_DNVWeb
		;;
		2)
		InstallBasicSoftware_DataBase
		;;
		3)
		InstallBasicSoftware_Collector
		;;
		4)
		InstallBasicSoftware_Trans
		;;
		5)
		HostsOrGroup
		;;
		esac
		[ $? -eq 0 ] && break || break
	done
}

####main####

back_title="基础软件安装v1.0"

##时间###
Date=$(date +%Y%m%d%H%M)

#脚本存放路径#
DIR_INSTALL=$(cd $(dirname $0);pwd)

#加载配置文件#
basesoft_dir=${DIR_INSTALL}/Basesoftware
ansible_dir=${DIR_INSTALL}/ansible
installlogsPath=${DIR_INSTALL}/logs
source ${ansible_dir}/scripts/BaseSoftware.conf
source ${ansible_dir}/scripts/ProgressBar
source ${ansible_dir}/login.conf
OS_version







