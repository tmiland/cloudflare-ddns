#!/usr/bin/env bash

# modified by jfro from http://www.cnysupport.com/index.php/linode-dynamic-dns-ddn$
# Update: changed because the old IP-service wasn't working anymore
# Uses curl to be compatible with machines that don't have wget by default
# modified by Ross Hosman for use with cloudflare.
# modified by Jon Egerton to add logging
# modified by Jon Egerton to update to cloud flare api v4 (see https://api.cloudflare.com)
#
# This version is working as at 8-Aug-2018
# As/When cloudflare change their API amendments may be required
# Latest versions of these scripts are here: https://github.com/jonegerton/cloudflare-ddns
#
# To schedule:
# run `crontab -e` and add next line (without the leading #):
# */5 * * * * bash {set file location here}/cf-ddns.sh >/dev/null 2>&1
# this will run the script every 5 minutes. The IP is cached, so requests are only sent
# when the WAN IP has changed. Log output is minimal, so shouldn't grow too large.
#
# Use strictly at your own risk

load_conf() {
  CONF="cf-ddns.conf"
  if [ -f "$CONF" ] && [ ! "$CONF" == "" ]; then
    source $CONF
  else
    echo "\$CONF not found."
    exit 1
  fi
}

showhelp() {
  echo 'Usage: cf-ddns.sh [OPTION]'
  echo
  echo 'OPTIONS:'
  echo '-h  | --help: Show this help screen'
  echo '-rw | --readwan: Get ID of the wan host entry'
  echo '-rp | --readprivate: Get ID of the private host entry'
  echo '-w  | --wan: Update WAN IP'
  echo '-p  | --private: Update Private IP'
}

# Load user settings
load_conf

cf_read_wan_hostkey() {
  curl -X GET "https://api.cloudflare.com/client/v4/zones/$cfzonekey/dns_records?type=A&name=$cf_wan_host" \
    -H "X-Auth-Key: $cfkey " \
    -H "X-Auth-Email: $cfuser" \
    -H "Content-Type: application/json" > ./cf_wan_hostkey.json

  cf_wan_hostkey=$(cat cf_wan_hostkey.json | grep -Po '(?<="id":")[^"]*' | head -1)
  sed -i "s/cf_wan_hostkey=/cf_wan_hostkey=$cf_wan_hostkey/g" $CONF
  rm -f ./cf_wan_hostkey.json
}

cf_read_private_hostkey() {
  curl -X GET "https://api.cloudflare.com/client/v4/zones/$cfzonekey/dns_records?type=A&name=$cf_private_host" \
    -H "X-Auth-Key: $cfkey " \
    -H "X-Auth-Email: $cfuser" \
    -H "Content-Type: application/json" > ./cf_private_hostkey.json

  cf_private_hostkey=$(cat cf_private_hostkey.json | grep -Po '(?<="id":")[^"]*' | head -1)
  sed -i "s/cf_private_hostkey=/cf_private_hostkey=$cf_private_hostkey/g" $CONF
  rm -f ./cf_private_hostkey.json
}

date +"%F %T" >> $log

update_wan_ip() {
  WAN_IP=$(curl -s $wan_ip_url)
  if [ -f wan_ip-cf.txt ]; then
    OLD_WAN_IP=$(cat wan_ip-cf.txt)
  else
    echo "No file, need IP" >> $log
    OLD_WAN_IP=""
  fi

  if [ "$WAN_IP" = "$OLD_WAN_IP" ]; then
    echo  "WAN IP Unchanged" >> $log
  else
    echo $WAN_IP > wan_ip-cf.txt
    echo "Updating DNS to $WAN_IP" >> $log

    wan_data="{\"type\":\"A\",\"name\":\"$cf_wan_host\",\"content\":\"$WAN_IP\",\"ttl\":$cfttl,\"proxied\":$cfproxied}"
    echo "data: $wan_data" >> $log
  fi
  curl -X PUT "https://api.cloudflare.com/client/v4/zones/$cfzonekey/dns_records/$cf_wan_hostkey" \
    -H "X-Auth-Key: $cfkey" \
    -H "X-Auth-Email: $cfuser" \
    -H "Content-Type: application/json" \
    --data $wan_data >> $log
}

update_private_ip() {
  PRIVATE_IP=$(curl -s $private_ip_url)
  if [ -f private_ip-cf.txt ]; then
    OLD_WAN_IP=$(cat private_ip-cf.txt)
  else
    echo "No file, need IP" >> $log
    OLD_WAN_IP=""
  fi

  if [ "$PRIVATE_IP" = "$OLD_WAN_IP" ]; then
    echo  "PRIVATE IP Unchanged" >> $log
  else
    echo $PRIVATE_IP > private_ip-cf.txt
    echo "Updating DNS to $PRIVATE_IP" >> $log

    private_data="{\"type\":\"A\",\"name\":\"$cf_private_host\",\"content\":\"$PRIVATE_IP\",\"ttl\":$cfttl,\"proxied\":$cfproxied}"
    echo "data: $private_data" >> $log

    curl -X PUT "https://api.cloudflare.com/client/v4/zones/$cfzonekey/dns_records/$cf_private_hostkey" \
      -H "X-Auth-Key: $cfkey" \
      -H "X-Auth-Email: $cfuser" \
      -H "Content-Type: application/json" \
      --data $private_data >> $log
  fi
}

# Check if super user is executing the
# script and exit with message if not.
su_required() {
  user_id=$(id -u)

  if [ "$user_id" != "0" ]; then
    echo "You need super user priviliges for this."
    exit
  fi
}

while [ "$1" ]; do
  case $1 in
    '-h' | '--help' | '?' )
      showhelp
      exit
      ;;
    '--readwan' | '-rw' )
      cf_read_wan_hostkey
      exit
      ;;
    '--readprivate' | '-rp' )
      cf_read_private_hostkey
      exit
      ;;
    '--wan' | '-w' )
      update_wan_ip
      exit
      ;;
    '--private' | '-p' )
      update_private_ip
      exit
      ;;
    * )
      showhelp
      exit
      ;;
  esac

  shift
done

su_required
showhelp

exit 0
