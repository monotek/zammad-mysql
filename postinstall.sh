#!/bin/bash
#
# packager.io postinstall script
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:

ZAMMAD_DIR="/opt/zammad-mysql"
DB="zammad_production"
DB_USER="zammad"
DB_HOST="localhost"
MY_CNF="/etc/mysql/debian.cnf"

# check which init system is used
if [ -n "$(which initctl)" ]; then
    INIT_CMD="initctl"
elif [ -n "$(which systemctl)" ]; then
    INIT_CMD="systemctl"
else
    function sysvinit () {
	service $2 $1
    }
    INIT_CMD="sysvinit"
fi


# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/database.yml ]; then
    # db migration
    echo "# database.yml exists. Nothing to do..."
else
    DB_PASS="$(apg -x10|head -1)"

    if [ -f "${MY_CNF}" ]; then
	MYSQL_CREDENTIALS="--defaults-file=${MY_CNF}"
    else
	echo -n "Please enter your MySQL root password:"
	read -s MYSQL_ROOT_PASS
	MYSQL_CREDENTIALS="-u root -p${MYSQL_ROOT_PASS}"
    fi
    
    echo "creating zammad mysql user and db"
    mysql ${MYSQL_CREDENTIALS} -e "CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASS}';CREATE DATABASE '${DB}' DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci; GRANT ALL PRIVILEGES ON ${DB}.* TO '${DB_USER}'@'${DB_HOST}'; FLUSH PRIVILEGES;"

    # update configfile
    sed "s/.*password:.*/  password: ${DB_PASS}/" < ${ZAMMAD_DIR}/database.mysql > ${ZAMMAD_DIR}/database.yml
fi