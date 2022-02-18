#!/bin/bash -e
#
#

#### Start Editable Variables ####
username=foobarUserName
password=foobarUserName
source /foobarLocation/

baseurl=https://localhost:8443
output=/foobarLocation
filename=`date +%Y%m%d%H%M`.unf
keep_days=1
#### End Editable Variables ####

# create output directory
mkdir -p $output

curl_cmd="curl --cookie /tmp/cookie --cookie-jar /tmp/cookie --insecure --fail"

# authenticate against unifi controller 
if ! $curl_cmd --data '{"username": "'$username'","password": "'$password'","remember": true,"strict": true}' $baseurl/api/login > /dev/null; then
  echo Login failed
  exit 1
fi

# get Csrf-Token
value=`cat /tmp/cookie`
token="${value: -32}"

# ask controller to do a backup, response contains the path to the backup file 
path=`$curl_cmd -H "X-Csrf-Token: $token" --data 'json={"cmd":"backup","days":"-1"}' $baseurl/api/s/default/cmd/backup | sed -n 's/.*\(\/dl.*unf\).*/\1/p'`

# download the backup to the destinated output file 
$curl_cmd $baseurl$path -o $output/$filename

# logout 
$curl_cmd $baseurl/logout

# delete outdated backups
find $output -ctime +$keep_days -type f -delete

echo Backup successful