#!/usr/bin/env bash

# NOTE: ensure you have run `s3cmd --configure` before running this script!
# NOTE: run this script as root

localdir="$1"
bucket="$2"
remotedir="s3://$bucket/"

if [ -z "$localdir" ] || [ -z "$bucket" ]; then
	echo "Usage: s3.sh <directory> <bucketname>"
	exit 1
fi

if [ ! -e "$localdir" ]; then
	echo "Invalid directory"
	exit 1
fi

# s3cmd will look in this directory for the s3 configuration
export HOME=/home/richard
 
s3cmd sync --delete-removed "$localdir" "$remotedir"
if [ $? -ne 0 ]; then
	echo "s3cmd sync failed!"
	exit 1
fi
