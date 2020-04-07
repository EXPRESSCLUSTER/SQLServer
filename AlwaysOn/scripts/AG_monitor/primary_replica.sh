result=`sqlcmd -S $1 -U SA -P $2 -Q "select primary_replica from sys.dm_hadr_availability_group_states"`
echo $result | awk -F ' ' '{print $3}'
