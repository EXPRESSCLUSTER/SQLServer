result=`sqlcmd -S $1 -U SA -P $2 -Q"select replica_id from sys.dm_hadr_availability_replica_cluster_states where replica_server_name='$3'"`
echo $result | awk -F ' ' '{print $3}'
