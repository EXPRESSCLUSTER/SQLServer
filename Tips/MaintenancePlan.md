# How to create Mantenance Plan on SQL Server cluster with shared disk
When you create Maintenance Plan on SQL Server cluster with shared disk configuration, please follow the steps below.

### When creating Maintenance Plan
1. Confirm that failover group is activated.
2. Start SQL Server Management Studio(SSMS).
3. Connect to Server with the following parameters:  
	- Server name:  
      Cluster fip address or vcom/ddns ddns virtual hostname
	- Authentication:  
      An account which is available on all cluster servers and has a permission to connect to DB and create MaintenancePlan  
  		e.g) sa account or domain administrator
4. Create Maintenance Plan on SSMS

### When executing Maintenance Plan
1. Start SSMS.
2. Connect to Server with the same parameters as when creating Maintenance Plan.
3. Execute Maintenance Plan on SSMS

### Note
If Server name or Authentication account is different between creating and executing Maintenance Plan, you will fail to execute it.


### Information
I have tested the above in the following environment:
```bat
Windows Server 2012 R2
SQL Server 2014
EXPRESSCLUSTER X 3.3
```
And to configure SQL Server cluster, I followed [this setup guide](https://github.com/EXPRESSCLUSTER/SQLServer/blob/master/SQLserver2016SSRS.md).
