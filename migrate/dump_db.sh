#!/usr/bin/env bash

root_password="root"
user="$1"
port="$2"
dbname="$3"
file="/tmp/mysql_dump_$user.sql"
host="$user.proxima.cc"

usage() {
	echo "Usage: dump_db.sh <user> <port> <dbname>"
}

if [ -z "$user" ] || [ -z "$port" ] || [ -z "$dbname" ]; then
	usage
	exit 1
fi

mysql_user="$user""_"
mysqldump -u root -p"$root_password" --databases $dbname > "$file"

cat "$file" | ssh -p "$port" root@new.proxima.cc mysql -u root -p"$root_password"
