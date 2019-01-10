# !/bin/bash
# check program exist
# if not exist   yum install -y this
function shellInitRely(){
    yum install jq  
}
function programExist(){
    tmp=`rpm -qa $1`
    if [ -e "/usr/bin/${1}" ];then
        return 0
    fi
    if [ -z $tmp ];then
        yum install -y $1
        tmp=`rpm -qa $1`
        if [ -e "/usr/bin/${1}" ];then
            return 0
        fi
        if [ -z $tmp ];then
            echo "依赖 $1 安装失败,请手动安装依赖~"
            exit 1
            return 0
        else return 1
        fi
    else return 1
    fi
}

# get source code and unzip
function getSource(){
    programExist git
    programExist unzip
    programExist gzip
    programExist bzip2
    programExist xz
    # sftp
    local_dir=/data/software/
    if [ ! -e $local_dir ];then
        mkdir -p $local_dir
    fi
    cd ${local_dir} 
    wget http://hk2.php.net/distributions/php-5.4.26.tar.bz2 -O php.tar.bz2
    wget https://github.com/nginx/nginx/archive/release-1.9.12.zip -O nginx.zip
    wget https://github.com/phpredis/phpredis/archive/2.2.7.zip -O phpredis.zip
    wget https://github.com/laruence/yaf/archive/yaf-2.2.9.zip -O yaf.zip
    wget https://github.com/laruence/yar/archive/yar-1.2.3.zip -O yar.zip
    unzip nginx.zip
    unzip phpredis.zip
    unzip yaf.zip
    unzip yar.zip
    tar -xjf php.tar.bz2
    return 0
}

# change yum repo for aliyun 
function changeRepo(){
    programExist wget
    # programExist vim
    cp  /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak 
    wget http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
    yum clean all && yum makecache && yum update
    if [ $? -eq 0 ];then
        return 0
    else
        return 1
    fi
}

# disable firewall
function disableFirewall(){
    systemctl stop firewalld||systemctl disable firewalld
    echo "firewalld is disabled~"
    return 0
}

# disable ipv6
# function disableIpv6(){

# }

# change dns to 114.114.114.114
function changeDns(){
    cp /etc/resolv.conf /etc/resolv.conf.bak
    sed -i '/^nameserver\s*[0-9\.]*/cnameserver 114.114.114.114' /etc/resolv.conf 
    echo "DNS is change to 114.114.114.114, you can use :vim /etc/resolv.conf to edit"
    return 0
}

# init rely
function initRely(){
    yum install -y make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget crontabs libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libzip-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz expat-devel libaio-devel rpcgen libtirpc-devel perl openldap openldap-devel epel-release pcre pcre-devel glibc-devel gd2 openldap-servers glibc nss_ldap freetype-devel perl-CPAN openldap-clients freetype gd2-devel libt1-devel && yum -y install libmcrypt-devel 
    if [ $? -eq 0 ];then
        echo "编译依赖安装完成"
    else
        echo "编译依赖安装未完成,请手动安装依赖"
    fi
}

# getSvnInfo
function getSvnInfo(){
    for file in `find $1 -type d -name .svn`
    do 
        cd $file
        cd ..
        echo "${pwd} "`svn info|grep URL|sed "s/URL: //g" ` >> /root/svn_src
    done
    echo "get svn info is over~ the svn_src in /root/svn_src"
}

# php Compile install
function phpCompile()
{
    php_dir='/data/software/php-src-PHP-5.4.26'
    # yaolifeng code
    cd $php_dir && ./configure --prefix=/data/webserver/php --with-config-file-path=/data/webserver/php/etc --with-config-file-scan-dir=/data/webserver/php/etc/php.d --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-fpm --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --enable-pdo --with-gettext --with-bz2 && make &&  make install 
    if [ $? -eq 0 ];then
        echo "php compile success ~"
        ln /data/webserver/php/bin/* /usr/bin/
        ln /data/webserver/php/sbin/* /usr/bin/
        cp /data/webserver/php/etc/php-fpm.conf.default /data/webserver/php/etc/php-fpm.conf 
        return 0
    else
        echo "php compile error ~ please check your server"
        return 1
    fi
}

# checkPhpInstall
function checkPhpInstall()
{
    php_path='/data/webserver/php'
    if [ -e ${php_path} ]
    then
        return 0
    else
        echo "php not install or not in /data/webserver,please reinstall php"
        return 1
    fi
}

# nginx Compile install
function nginxCompile()
{
    nginx_dir='/data/software/nginx-release-1.9.12'
    cd $nginx_dir && ./auto/configure --prefix=/data/webserver/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_mp4_module --with-http_flv_module && make && make install
    if [ $? -eq 0 ];then
        echo "nginx compile success ~"
        ln /data/webserver/nginx/sbin/* /usr/bin/
        return 0
    else
        echo "nginx compile error ~ please check your server"
        return 1
    fi
}

# Yaf compile install 
function YafCompile()
{
    yaf_dir="/data/software/yaf-yaf-2.2.9/"
    checkPhpInstall && cd $yaf_dir && /data/webserver/php/bin/phpize && ./configure --with-php-config=/data/webserver/php/bin/php-config && make && make install && mkdir -p /data/webserver/php/etc/php.d/ && echo -e 'extension=/data/webserver/php/lib/php/extensions/no-debug-non-zts-20100525/yaf.so\nyaf.library="/home/www/ekwing/lib"\nyaf.cache_config=1' > /data/webserver/php/etc/php.d/yaf.ini && rm -f /usr/bin/php /usr/bin/php-fpm && ln /data/webserver/php/bin/php /usr/bin && ln /data/webserver/php/sbin/php-fpm /usr/bin
    if [ $? -eq 0 ];then
        echo "php extension yaf compile success ~"
        return 0
    else
        echo "php extension yaf compile error ~ please check your server"
        return 1
    fi
}

# yar compile install 
function yarCompile()
{
    yaf_dir="/data/software/yar-yar-1.2.3"
    checkPhpInstall && cd $yaf_dir && /data/webserver/php/bin/phpize && ./configure --with-php-config=/data/webserver/php/bin/php-config && make && make install && mkdir -p /data/webserver/php/etc/php.d/ && echo 'extension=/data/webserver/php/lib/php/extensions/no-debug-non-zts-20100525/yar.so' > /data/webserver/php/etc/php.d/yar.ini  && rm -f /usr/bin/php /usr/bin/php-fpm && ln /data/webserver/php/bin/php /usr/bin && ln /data/webserver/php/sbin/php-fpm /usr/bin
    if [ $? -eq 0 ];then
        echo "php extension yar compile success ~"
        return 0
    else
        echo "php extension yar compile error ~ please check your server"
        return 1
    fi
}

# svn checkout project code
function svnCheckout(){
    cd `dirname $0`
    programExist svn    
    programExist curl
    read -p "please enter your svn username: " svn_username 
    if [ ! -n "${svn_username}" ]
    then
        echo "username can not empty"
        read -p "please enter your svn username again: " svn_username
    fi
    if [ ! -n "${svn_username}" ]
    then
        echo "username can not empty"
        read -p "please enter your svn username again: " svn_username
    fi
    if [ ! -n "${svn_username}" ]
    then
        echo "you try too many times, you will quit."
        return 1
    fi

    read -p "please enter your svn svn_password: " svn_password  
    if [ ! -n "${svn_password}" ]
    then
        echo "svn_password can not empty"
        read -p "please enter your svn svn_password again: " svn_password
    fi
    if [ ! -n "${svn_password}" ]
    then
        echo "svn_password can not empty"
        read -p "please enter your svn svn_password again: " svn_password
    fi
    if [ ! -n "${svn_password}" ]
    then
        echo "you try too many times, you will quit."
        return 1
    fi
    # awk 'BEGIN{}!/^#/{print $2" /home/www/ekwing"$1}' ${pwdd}/src_success|xargs svn co --username $svn_username --password $svn_password 
    awk 'BEGIN{}!/^#/{print $2" /home/www/ekwing"$1}' ${pwdd}/svn|xargs -n2 svn co --no-auth-cache --username $svn_username --password $svn_password
    # curl -s http://www.niugang.xyz/svn|awk 'BEGIN{}!/^#/{print $2" /home/www/ekwing"$1}'|xargs -n2 svn co --no-auth-cache --username $svn_username --password $svn_password
}

# php extension redis compile 
function redisCompile() {
    redis_dir=/data/software/phpredis-2.2.7
    checkPhpInstall && cd $redis_dir && /data/webserver/php/bin/phpize && ./configure --with-php-config=/data/webserver/php/bin/php-config && make && make install && mkdir -p /data/webserver/php/etc/php.d/ && echo 'extension=/data/webserver/php/lib/php/extensions/no-debug-non-zts-20100525/redis.so' > /data/webserver/php/etc/php.d/redis.ini  && rm -f /usr/bin/php /usr/bin/php-fpm && ln /data/webserver/php/bin/php /usr/bin && ln /data/webserver/php/sbin/php-fpm /usr/bin
    if [ $? -eq 0 ];then
        echo "php extension redis compile success ~ "
        return  0
    else
        echo "php extension redis compile error ~ please check your server"
        return 1
    fi
}

function showHelp()
{
    echo -e "code 1: Initialize the server environment (update ali yum repo & disable firewalld & change dns) (初始化环境)"
    echo -e "code 2: get program source code (获取编译源码)"
    echo -e "code 3: Initialize php/nginx compile rely (初始化依赖)"
    echo -e "code 4: php compile (编译php)"
    echo -e "code 5: php extension Yaf compile (编译 Yaf)"
    echo -e "code 6: php extension Yar compile (编译 Yar)"
    echo -e "code 7: nginx compile (编译 nginx)"
    echo -e "code 8: php extension redis compile (编译 php-redis)"
    echo -e "code 9: svn checkout (检出项目源码)"
    echo -e "code 10: exit"
    echo -e "enter to show this help"

}

pwdd=`pwd`

function main()
{
clear
echo "+------------------------------------------------------------------------+"
echo "|PHP-5.4.26(extend yaf-2.2.9 && yar-1.2.3 && redis-2.2.7) && NGINX-1.14.2|"
echo "+------------------------------------------------------------------------+"
echo "|      A tool to auto-compile & install ekwing environment on CentOS     |"
echo "+------------------------------------------------------------------------+"
echo "|                   author:niugang    version:2.2                        |"
echo "+------------------------------------------------------------------------+"
showHelp
    while [[ 1 ]]; do
        read -p "please enter command number: " cmd
        case $cmd in 
            1 ) changeRepo && disableFirewall && changeDns 
            read -p "输入回车继续"
            ;;
            2 ) getSource
            read -p "输入回车继续"
            ;;
            3 ) initRely 
            read -p "输入回车继续"
            ;;
            4 ) phpCompile
            read -p "输入回车继续"
            ;;
            5 ) YafCompile
            read -p "输入回车继续"
            ;;
            6 ) yarCompile
            read -p "输入回车继续"
            ;;
            7 ) nginxCompile
            read -p "输入回车继续"
            ;;
            8 ) redisCompile
            read -p "输入回车继续"
            ;;
            9 ) svnCheckout
            read -p "输入回车继续"
            ;;
            10 ) exit 1
            ;;
            * ) clear
        esac
        showHelp
    done
}

main 
