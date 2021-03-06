#!/usr/bin/env bash

root_password="root"
user="$1"
port="$2"
file="/tmp/mysql_dump_$user.sql"
host="$user.proxima.cc"

usage() {
	echo "Usage: dump_db.sh <user> <port>"
}

if [ -z "$user" ] || [ -z "$port" ]; then
	usage
	exit 1
fi

mysql_user="$user""_"
mysqldump -u root -p"$root_password" --databases $(
	mysql -u root -p"$root_password" -N information_schema -e "
		SELECT DISTINCT(TABLE_SCHEMA) 
		FROM tables WHERE TABLE_SCHEMA 
		LIKE '$mysql_user%'"
) > "$file"

grants=$(mysql -u root -p"$root_password" -B -N -e"SHOW GRANTS FOR '$user'@localhost")

# add semicolons and strip extra backslashes
echo "$grants" |  sed '/; *$/!s/$/;/' | sed 's/\(\\\)//g' >> "$file"

cat "$file" | ssh -p "$port" root@NEWHOST mysql -u root -p"$root_password"
