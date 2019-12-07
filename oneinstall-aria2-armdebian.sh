#!/bin/bash

Red="\033[31m" 
Font="\033[0m"
Blue="\033[36m"

echo -e "================================================="
echo -e "${Blue}Aria2一键安装脚本 Debian for ARM ${Font}"
echo -e "${Blue}By QQ354766707${Font}"
echo -e "================================================="

[[ ${EUID} -ne 0 ]] && echo -e "${Red}请使用root用户运行该脚本！${Font}" && exit 1;

source /etc/os-release; [[ ${ID} != debian ]] && echo -e "${Red}该脚本只支持Debian系统，安装退出！${Font}" && exit 1;

[[ ${VERSION_ID} -le 7 ]] && echo -e "${Red}该脚本只支持Debian 8+系统，安装退出！${Font}" && exit 1;

echo $(uname -m) | grep -i aarch; [[ $? -ne 0 ]] && echo -e "${Red}该脚本只支持ARM架构，安装退出！${Font}" && exit 1;

echo -e "${Blue}检测到你的系统为${ID} ${VERSION_ID} for $(uname -m)符合安装要求，即将为你开启安装模式！${Font}" && sleep 3;

EXEC="$(command -v aria2c)"; [[ -n ${EXEC} ]] && echo -e "${Red}检测到你已安装过Aria2，安装退出！${Font}" && exit 1;

apt update && apt install aria2 cron -y; EXEC="$(command -v aria2c)"; [[ -z ${EXEC} ]] && echo -e "${Red}Aria2安装失败，安装退出！${Font}" && exit 1;

mkdir -p /opt/aria2/download && passwd="$(head /dev/urandom |cksum |md5sum |cut -c 1-10)";

wget -N --no-check-certificate https://www.moerats.com/usr/shell/Aria2/dht.dat -P '/opt/aria2/'; [[ ! -s /opt/aria2/dht.dat ]] && echo -e "${Red}dht.dat下载失败，安装退出！${Font}" && exit 1;

cat > /opt/aria2/aria2.conf << EOF
#Setting
dir=/opt/aria2/download
dht-file-path=/opt/aria2/dht.dat
save-session-interval=15
force-save=false
log-level=error

# Advanced Options
disable-ipv6=true
file-allocation=none
max-download-result=35
max-download-limit=20M
 
# RPC Options
enable-rpc=true
rpc-secret=${passwd}
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-save-upload-metadata=true
rpc-secure=false
rpc-max-request-size=100M

# see --split option
continue=true
max-concurrent-downloads=10
max-overall-download-limit=0
max-overall-upload-limit=5
max-upload-limit=1
 
# Http/FTP options
split=64
connect-timeout=120
max-connection-per-server=64
max-file-not-found=2
min-split-size=10M
check-certificate=false
http-no-cache=true
 
#BT options
bt-enable-lpd=true
bt-max-peers=80
bt-require-crypto=true
follow-torrent=true
listen-port=6881-6999
bt-request-peer-speed-limit=256K
bt-hash-check-seed=true
bt-seed-unverified=true
bt-save-metadata=true
enable-dht=true
enable-peer-exchange=true
seed-time=0
EOF

cat > /opt/aria2/trackers-list-aria2.sh <<'EOF'
#!/bin/bash
systemctl stop aria2
list=`wget -qO- https://trackerslist.com/trackers_all_aria2.txt | awk NF | sed ":a;N;s/\n/,/g;ta"`
if [[ -z "`grep "bt-tracker" /opt/aria2/aria2.conf`" ]]; then
    sed -i '$a bt-tracker='${list} /opt/aria2/aria2.conf
else
    sed -i "s@bt-tracker.*@bt-tracker=$list@g" /opt/aria2/aria2.conf
fi
systemctl start aria2
EOF

cat > /etc/systemd/system/aria2.service << EOF
[Unit]
Description=Aria2 server
After=network.target
Wants=network.target

[Service]
Type=simple
PIDFile=/var/run/aria2.pid
ExecStart=$(command -v aria2c) --conf-path=/opt/aria2/aria2.conf
RestartPreventExitStatus=23
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl start aria2 && systemctl enable aria2; chmod +x /opt/aria2/trackers-list-aria2.sh && bash /opt/aria2/trackers-list-aria2.sh;

crontab -l > aria2.crontab; [[ ! -s aria2.crontab ]] && echo 1 > init.crontab && crontab -e < init.crontab && rm -rf init.crontab;

echo "0 3 */7 * * /opt/aria2/trackers-list-aria2.sh" >> aria2.crontab && crontab aria2.crontab && rm -rf aria2.crontab;

ip=$(curl ipinfo.io/ip); [[ -z "${ip}" ]] && ip=$(curl whatismyip.akamai.com);

echo -e "———————————————————————————————————————"
echo -e "${Blue}Aria2安装完成！${Font}"
echo -e "${Blue}连接ip：${ip} ${Font}"
echo -e "${Blue}连接密匙：${passwd} ${Font}"
echo -e "———————————————————————————————————————"