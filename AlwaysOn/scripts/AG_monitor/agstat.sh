#!/bin/bash

# Set parameters
server_list=("<ag server1 hostname>" "<ag server2 hostname>" "<ag server3 hostname>")
ip_list=("<ag server1 IP address>" "<ag server2 IP address>" "<ag server3 IP address>")
pass="<SQL Server SA user password>"

# Do NOT edit from here

# Get my hostname
myhostname=`hostname`

# Get my IP address
for ((i=0;i<${#ip_list[@]};i++))
do
ifconfig | grep ${ip_list[$i]} > /dev/null
if [ $? -eq 1 ]
then
  myip=${ip_list[$1]}
fi
done

# Get each servers replica IDs
replica_list=()

for ((i=0;i<${#server_list[@]}; i++))
do
id=`sh ./replica_id.sh $myip $pass ${server_list[$i]}`
replica_list+=( $id )
done

# Show Availability Group Status

echo ""
for ((i=0;i<${#server_list[@]}; i++))
do

operation=`./operational_state.sh $myip $pass ${replica_list[$i]}`
if [ $operation = "NULL" ]
then
  operation="-"
fi
connect=`sh ./connected_state.sh $myip $pass ${replica_list[$i]}`
role=`sh ./role.sh $myip $pass ${replica_list[$i]}`
fo=`sh ./is_failover_ready.sh $myip $pass ${replica_list[$i]}`
if [ $fo -eq 1 ];
then
  fo_desc="READY"
else
  fo_desc="NOT_READY"
fi
sync=`sh ./synchronization_state.sh $myip $pass ${replica_list[$i]}`
recovery_lsn=`sh ./recovery_lsn.sh $myip $pass ${replica_list[$i]}`
db=`sh ./database_state.sh $myip $pass ${replica_list[$i]}`
if [ $db = "NULL" ]
then
  db="-"
fi

if [ ${server_list[$i]} = $myhostname ]
then
  echo "* ${server_list[$i]}"
else
  echo "  ${server_list[$i]}"
fi
echo "    Status:        $operation"
echo "    Role:          $role"
echo "    Connect:       $connect"
echo "    Failover:      $fo_desc"
echo "    Sync:          $sync"
echo "    Database:      $db"
echo "    Recovery LSN:  $recovery_lsn"

done

exit 0
