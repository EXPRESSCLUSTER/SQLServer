result=`sqlcmd -S $1 -U SA -P $2 -Q "select is_failover_ready from sys.dm_hadr_database_replica_cluster_states where replica_id='$3'"`
echo $result | awk -F ' ' '{print $3}'
