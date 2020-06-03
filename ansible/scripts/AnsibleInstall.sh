#!/bin/bash
#===============================================================================
#2020-05-06 by yangyuntian
#===============================================================================
export LANG="zh_CN.UTF-8"
###背景###
back_title="基础软件安装v1.0"
###时间###
Date=$(date +%Y%m%d%H%M)
###系统类型###
sys_ver=` cat /etc/redhat-release |sed -r 's|^([^.]+).*$|\1|; s|^[^0-9]*([0-9]+).*$|\1|'`
CURRENT_PATH=$(
  cd $(dirname $0)
  pwd
)
ANSIBLE_PACKAGES="${CURRENT_PATH}/../lib"
ANSIBLE_LOG="${CURRENT_PATH}/../logs"
ANSIBLE_INSTALLDIR="${CURRENT_PATH}/../package"

if [ ! -d "${ANSIBLE_LOG}" ]; then
  mkdir -p ${ANSIBLE_LOG}
fi
if [ ! -d "${ANSIBLE_INSTALLDIR}" ]; then
  mkdir -p ${ANSIBLE_INSTALLDIR}
fi

function ProgressBar() {
  sl='sleep 0.2'
  echo "开始$1,请稍候..."
  while true; do
    echo -e '*'"\b\c"
    $sl
    echo -e "*\c"
    $sl
  done
}

function logger() {
  echo -e "\n"
  echo -e "$1\n"
}
function install_python_275() {
  if [ "${sys_ver}" -eq "7" ];then
    rpm -Uvh ${ANSIBLE_PACKAGES}/base.rpm/*.rpm --nodeps --force >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
  fi
  #logger 'logger '开始安装python 2.7.5'
  version_old=$(python -V 2>&1)
  if [ $? -eq '0' -a "${version_old}" == 'Python 2.7.5' ]; then
    logger '检测到python2.7已经存在，跳过此步骤' >>${ANSIBLE_LOG}/CheckResult-${Date}.log
  else
    ProgressBar "安装python 2.7.5" &
    ProgressBar_pid=$!
    tar -zxvf ${ANSIBLE_PACKAGES}/Python-2.7.5.tgz -C ${ANSIBLE_INSTALLDIR} >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    cd ${ANSIBLE_INSTALLDIR}/Python-2.7.5 >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    ./configure --prefix=/usr/local &>>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    make --jobs=$(grep processor /proc/cpuinfo | wc -l) &>>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    make install &>>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    cd /usr/local/include/python2.7.5 >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    cp -a ./* /usr/local/include/ >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    #备份旧的Python
    cd /usr/bin >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    yes | mv ./python ./python2.6 >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    ln -s /usr/local/bin/python /usr/bin/python >>${ANSIBLE_LOG}/PythonRunning-${Date}.log 2>&1
    #恢复yum功能
    sed -i "s#/usr/bin/python#/usr/bin/python2\.6#"g /usr/bin/yum

    version_new=$(python -V 2>&1)
    if [ $? -eq '0' -a "${version_new}" == 'Python 2.7.5' ]; then
      echo "#------python 2.7.5 安装情况------#" >>${ANSIBLE_LOG}/VerificationResult-${Date}.log
      python -V &>>${ANSIBLE_LOG}/VerificationResult-${Date}.log
      echo -e "\n" >>${ANSIBLE_LOG}/VerificationResult-${Date}.log
      logger 'python2.7.5安装成功'
    else
      logger 'python2.7.5安装失败'
    fi
    kill -9 ${ProgressBar_pid}
  fi
}

#安装Python相关模块
function install_python_module() {
  moduleName=$1
  if [ ! -n "$2" ]; then
    packageName=${moduleName}
  else
    packageName=$2
  fi
  #logger "开始安装 ${packageName}"
  #1. 检测模块是否已安装
  python -c "import ${packageName}" >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
  if [ $? -eq 0 ]; then
    logger "${moduleName} 已安装，跳过此步骤" >>${ANSIBLE_LOG}/CheckResult-${Date}.log
    if [ ${packageName} == "ansible" ]; then
      CheckInstalledResults "ansible 环境检查结果" "${ANSIBLE_LOG}/CheckResult-${Date}.log"
      Msgbox "${moduleName} 已安装，跳过此步骤"
    fi
  else
    ProgressBar "安装 ${packageName}" &
    ProgressBar_pid=$!
    zipFile=$(ls ${ANSIBLE_PACKAGES} | grep ${moduleName})
    unzipDir=${zipFile%.tar.gz}
    if [ -f "${ANSIBLE_PACKAGES}/${zipFile}" ]; then
      cd ${ANSIBLE_PACKAGES} >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
      tar -zxvf ${ANSIBLE_PACKAGES}/${zipFile} -C ${ANSIBLE_INSTALLDIR} >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
      cd ${ANSIBLE_INSTALLDIR} >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
      yes | mv ${unzipDir} ${moduleName} >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
      cd ${moduleName} >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
      python setup.py install &>>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
      if [ $? -eq 0 ]; then
        logger "${moduleName} 安装成功"
        if [ "${packageName}" == "ansible" -a "!" -d "/etc/ansible" ]; then
          mkdir -p /etc/ansible >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
          yes | cp ${CURRENT_PATH}/../ansible.cfg /etc/ansible/ >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
          sed -i "s#inventory \= \/etc\/ansible\/hosts#inventory \= ${CURRENT_PATH}/../hosts#g" /etc/ansible/ansible.cfg >>${ANSIBLE_LOG}/${packageName}-${Date}.log 2>&1
          echo "#------ansible 安装情况------#" >>${ANSIBLE_LOG}/VerificationResult-${Date}.log
          ansible --version &>>${ANSIBLE_LOG}/VerificationResult-${Date}.log
          echo -e "\n" >>${ANSIBLE_LOG}/VerificationResult-${Date}.log
          kill -9 ${ProgressBar_pid} &>/dev/null 2>&1
          CheckInstalledResults "ansible 安装结果" "${ANSIBLE_LOG}/VerificationResult-${Date}.log"
        fi
      else
        logger "${moduleName} 安装失败"
        exit 1
      fi
    else
      logger "{$moduleName} 安装目录下未找到对应安装文件"
      exit 1
    fi
    kill -9 ${ProgressBar_pid}
  fi
}

#安装必要的动态链接库
function install_lib() {
  libName=$1
  ls_result=`ls /usr/local/lib|grep ${libName}`
  file_result="/usr/local/bin/${libName}"
  if [ -n "${ls_result}" -o -f "${file_result}" ]; then
    logger "${libName} 已安装，跳过此步骤" >>${ANSIBLE_LOG}/CheckResult-${Date}.log
  else
    ProgressBar "安装 ${libName}" &
    ProgressBar_pid=$!
    zipFile=$(ls ${ANSIBLE_PACKAGES} | grep ${libName})
    unzipDir=${zipFile%.tar.gz}
    if [ -f ${ANSIBLE_PACKAGES}/${zipFile} ]; then
      cd ${ANSIBLE_PACKAGES} >>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      tar -zxvf ${ANSIBLE_PACKAGES}/${zipFile} -C ${ANSIBLE_INSTALLDIR} >>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      cd ${ANSIBLE_INSTALLDIR} >>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      yes | mv ${unzipDir} ${libName} >>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      cd ${libName} >>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      ./configure --prefix=/usr/local &>>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      make --jobs=$(grep process /proc/cpuinfo | wc -l) &>>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      make install &>>${ANSIBLE_LOG}/${libName}-${Date}.log 2>&1
      if [ $? -eq 0 ]; then
        logger "${libName} 安装成功"
      else
        logger "${libName} 安装失败"
        exit 1
      fi
    else
      logger "${libName} 安装目录下未找到对应安装文件"
      exit 1
    fi
    kill -9 ${ProgressBar_pid}
  fi
}
# 添加环境变量
function add_env_path() {
  echo $PATH | grep /usr/local/bin >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "环境变量已存在，跳过配置" >>${ANSIBLE_LOG}/CheckResult-${Date}.log
  else
    echo 'export PATH=$PATH:/usr/local/bin' >>/etc/profile
    source /etc/profile
    echo "#------设置环境变量------#" >>${ANSIBLE_LOG}/VerificationResult-${Date}.log
    echo -e "添加/usr/local/bin到PATH环境变量\n" >>${ANSIBLE_LOG}/VerificationResult-${Date}.log
  fi
}

function Msgbox() {
  whiptail --title "消息" --yes-button "确定" --no-button "取消" --yesno "$1" 10 60 --fb --backtitle "${back_title}"
  if [ $? -ne 0 ]; then
    exit
  fi
}

#检查安装结果
function CheckInstalledResults() {
  INSTALL=$(cat ${2} 2>/dev/null)
  whiptail --title "${1}" --yes-button "确定" --no-button "取消" --yesno "${INSTALL}" 32 80 --scrolltext --fb --backtitle "${back_title}"
  if [ $? -ne 0 ]; then
    exit 1
  fi
}
#
PS4='+[$LINENO:${FUNCNAME[0]:-$0}()]'
###############################################################
Msgbox "开始初始化ansible环境"
add_env_path
install_python_275 2> /dev/null
install_python_module 'setuptools' 2> /dev/null
install_python_module ' pycrypto' 'Crypto' 2> /dev/null
install_lib 'sshpass'  2> /dev/null
install_lib 'yaml' 2> /dev/null
install_python_module 'PyYAML' 'yaml' 2> /dev/null
install_python_module 'MarkupSafe' 'markupsafe' &> /dev/null
install_python_module 'Jinja2' 'jinja2' 2> /dev/null
install_python_module 'ecdsa' 2> /dev/null
install_python_module 'paramiko' 2> /dev/null
install_python_module 'simplejson' 2> /dev/null
if [ "${sys_ver}" -eq "6" ];then
  install_python_module 'ansible-2.3.0' 'ansible' 2> /dev/null
else
  install_python_module 'pycparser' 2> /dev/null
  install_python_module 'cffi' 2> /dev/null
  install_python_module 'ipaddress' 2> /dev/null
  install_python_module 'enum34' 'enum' 2> /dev/null
  install_python_module 'six' 2> /dev/null
  install_python_module 'idna' 2> /dev/null
  install_python_module 'pyasn1' 2> /dev/null
  install_python_module 'asn1crypto' 2> /dev/null
  install_python_module 'cryptography' 2> /dev/null
  install_python_module 'ansible-2.9.6' 'ansible' 2> /dev/null
fi
source /etc/profile
