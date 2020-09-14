# MSSQL Update Procedure In ECX Cluster Invironment

This document has three solutions for upgrade MSSQL server in cluster environment.

## Contents
[A) In the case that masterdb is stored on local disk.](#caseA)

[B) In the case that masterdb is stored on Mirror Disk.](#caseB)

[C) In the case that All databases stored in Mirror Disk and no need to chang any configuration ECX.](#caseC)

## A) In the case that masterdb is stored on local disk (*)

\* You can check the database path by:

- Start SQL Server Configuration Manager
- Select "SQL Server Services"
- Right click "SQL Server (\<Instance name\>)" and select Properties
- Go to "Startup Parameters" tab 

### Preparatoin
1. Backup Database on Active Server
1. Confirm that cluster staus is normal and group is active on Primary Server.
1. Change the following cluster setting to disable Recovery Action while SQL Server upgrading.
	- Cluster Properties
	  - Recovery tab
	  - Disable Recovery Action Caused by Monitor Recource Failure: Check
	- Apply cluster configuration

### Upgrade
1. Stop a resource which controls SQL Server Instance Service.
1. Upgrade SQL Server on Primary Server.
1. If reboot is required, reboot Primary Server.
   If not required, move failover group to Secondary Server.
1 Upgrade SQL Server on Secondary Server.
1. If reboot is required, reboot Secondary Server.
   If not required, move failover group to Primary Server.
1. If you use SQL monitor resource (*) and ODBC driver is upgraded, change the following setting:
	- SQL monitor Properties
	  -> Monitor(special) tab
	  -> Change "ODBC Driver Name"
	
    \* SQL monitor is available with DB Agent Option License:
		https://www.manuals.nec.co.jp/contents/system/files/nec_manuals/node/504/W42_RG_EN/W_RG_04.html#monitor-special-tab-sql-server-monitor-resources
1. Change the following setting:
	- Cluster Properties
	  -> Recovery tab
	  -> Disable Recovery Action Caused by Monitor Recource Failure: Uncheck
1. Apply the configuration.

## B) In the case that masterdb is stored on Mirror Disk

### Preparation
1. Backup Database on Active Server
1. Confirm that cluster staus is normal and group is active on Primary Server.
1. Change the following cluster setting to disable Recovery Action while SQL Server upgrading and auto failover group startup.
	- Cluster Properties
	    - Recovery tab
	    - Disable Recovery Action Caused by Monitor Recource Failure: Check
	- Failover group Propertis
	    - Attribute tab
	    - Startup Attribute
	    - Select "Manual Startup"
	- Apply cluster configuration
  
### Procedure
1. Stop a resource which controls SQL Server Instance Service.
1. Shutdown Secondary Server to stop mirroring. (*)
1. Upgrade SQL Server on Primary Server.
1. Shutdown Primary Server.
1. Boot Secondary Server.
1. Confirm that cluster service starts and Secondary Server status gets Online.
1. Execute the following command to open Mirror Disk on Secondary Server:

    ```
	mdopen <md resource name>
	-------------------
	Sample
	-------------------
	C:\Users\administrator>mdopen md
	Command succeeded.
	-------------------
    ```

1. Upgrade SQL Server on Secondary Server.
1. Shutdown Secondary Server
1. Boot both Primary and Secondary Servers.
1. Confirm that Fast Recovery runs and completes from Primary to Secondary Server.
1. Change the following cluster setting to disable Recovery Action while SQL Server upgrading and auto failover group startup.
	- Cluster Properties
	  - Recovery tab
	  - Disable Recovery Action Caused by Monitor Recource Failure: Check
	- Failover group Propertis
	  - Attribute tab
	  - Startup Attribute
	  - Select "Manual Startup"
	- Apply cluster configuration
1. If you use SQL monitor resource (*) and ODBC driver is upgraded, change the following setting:
	- SQL monitor Properties
	  - Monitor(special) tab
	  - Change "ODBC Driver Name"

	\* SQL monitor is is available with DB Agent Option License:
		https://www.manuals.nec.co.jp/contents/system/files/nec_manuals/node/504/W42_RG_EN/W_RG_04.html#monitor-special-tab-sql-server-monitor-resources
1. Change the following setting:
	- Cluster Properties
	  - Recovery tab
	  - Disable Recovery Action Caused by Monitor Recource Failure: Uncheck
	- Failover group Propertis
	  - Attribute tab
	  - Startup Attribute
	  - Select "Manual Startup"
	- Apply cluster configuration
    
## C) In the case that All databases stored in Mirror Disk and no need to chang any configuration ECX.
1. Backup Database on Active Server.
1. Confirm that cluster staus is normal and group is active on Primary Server.
1. Stop the Failover Group then start Mirror Disk resource only.
1. Shutdown Secondary Server to stop mirroring.
1. Upgrade SQL Server on Primary Server.
1. Shutdown Primary Server.
1. Boot Secondary Server.
1. Confirm that cluster service started and status online in Secondary Server.
1.  You will find crashed Mirror disk resource then stop the failover group  
1. Marked the latest data on secondary server.
   - Right click on Mirror disk and select Details.
	  - Select Mirror Disk icon of Secondary server in Mirror disk helper.
 	  - Click on Execute. 
	  - Close.
1.  Start the Mirror Disk resource on secondary server.
1.  Update MSSQL server on secondary server.
1.  Restart the secondary server by the help of ECX web manger.
1.  After restarted secondary server wait till get online in ECX web manager.
1.  When you find the failover group is online then check MSSQL databases.
1.  Boot the Primary server.
1.  Check fast recovery of mirror disk completed automatically.
1.  Then move the failover group from secondary server to primary server.
1.  Check the SQL database.

