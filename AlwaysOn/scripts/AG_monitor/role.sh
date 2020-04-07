result=`sqlcmd -S $1 -U SA -P $2 -Q "select role_desc from sys.dm_hadr_availability_replica_states where replica_id='$3'"`
echo $result | awk -F ' ' '{print $3}'
