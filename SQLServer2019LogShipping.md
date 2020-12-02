# How to integrate SQL Server cluster with Log Shipping
This article shows how to integrate Microsoft SQL Server cluster with Log Shipping feature for DR solution.

## SQL Server Log Shipping overview
Log Shipping provides asychronous database replication from Primary Server Instance to Secondary Server Instance by transaction log backup and restoring. 

When configuring Log Shipping, target databased (Primary Database) backup is created, the backup file is copied to Secondary Server and restored to Secondary Server Instance for first synchrnonization.  

After that, on Primary Server, Primary Database transaction log backup log is created. (Backup)  
The transaction log backup files are copied from Primary to Secondary Server. (Copy)  
On Secondary Server, the copied files are restored to Secondary Database. (Restore)  
By executing these three Backup/Copy/Restore jobs peridically, Log Shipping provides asychronous database replication.  

In Backup job, the transaction log backup files are created in a shared foler on Primary Server (Backup Share folder).  
In Copy job, Secondary Server access to Backup Share folder and copies the files to local folder (Destination folder).  
Therefore, Primary Server should have a shared folder which is accessible from Secondary Server.  
In order to swith Primary ans Secondary Server roles, it is recommended to share Destination folder for Primary Server as well.  

For more detail about Log Shipping, please see [Microsoft Log Shipping Guide](https://docs.microsoft.com/en-us/sql/database-engine/log-shipping/about-log-shipping-sql-server?view=sql-server-ver15)

## About SQL Server cluster with Log Shipping
At DC site, SQL Server Primary Server is stored and it is clustered by EXPRESSCLUSTER for HA.  
At DR site, SQL Server Secondary Server is stored and Log Shipping is configured between clustered Primary Server and Secondary Server for DR.

Between Primary Server cluster, auto failover is provided by EXPRESSCLUSTER.  
Between Primary Server and Secondary Server, manual failover following SQL Server procedure is required.

## Target
If EXPRESSCLUSTER Hybrid cluster is too expensive and manual failover/failback between DC site and DR site is allowed, this solution is applicable.  

## System Configuration
```bat
            <Public LAN>
              |
              | <Private LAN>  
              |   |
              |   |  +--------------------------------+
              +------| Primary Server1                |
              |   |  | - Windows Server 2019          |
              |   |  | - EXPRESSCLUSTER X 4           |
              |   +--| - SQL Server 2019              |
              |   |  | - SQL Server Management Studio |
 DC site      |   |  +--------------------------------+
              |   |
              |   |  +--------------------------------+
              +------| Primary Server2                |
              |   |  | - Windows Server 2019          |
              |   |  | - EXPRESSCLUSTER X 4           |
              |   +--| - SQL Server 2019              |
              |   |  | - SQL Server Management Studio |
              |      +--------------------------------+
              |
           [Gateway]
              |
              :
              :
              |
           [Gateway]
              |
              |  +--------------------------------+
              +--| DR Server                      |
 DR site      |  | - Windows Server 2019          |
              |  | - SQL Server 2019              |
              |  | - SQL Server Management Studio |
              |  +--------------------------------+
              |
              |
```

### Prerequisites
- All Primary Server1, Primary Server2 and Secondary Server sould be reachable with IP address.
- In order to use fip resource and vcom resource, Primary Server1 and Primary Server2 should belong a same nework.
- On Primary Server1 and Primary Server2, ports which EXPRESSCLUSTER requires should be opend.
	- You can open ports by executing OpenPort.bat([X4.1](https://github.com/EXPRESSCLUSTER/Tools/blob/master/OpenPorts.bat)/[X4.2](https://github.com/EXPRESSCLUSTER/Tools/blob/master/OpenPorts_X42.bat)) on both servers
- On Primary Server1 and Primary Server2, 2 partitions are required for Mirror Disk Data Partition and Cluster Partition.
	- Data Partition: Depends on mirrored data size (NTFS)
	- Cluster Partition: 1GB, RAW (do not format this partition)
	- **Note**
		- It is not supported to mirror C: drive and please do NOT sprecify C: for Data Partition.
		- Dynamic disk is not supported for Data Partition and Cluster Partition.
		- Data on Secondary Server Data Partition will be removed for initial Mirror Disk synchroniation (Initial Recovery).

### Sample configuration
- Primary Server1/Server2
	- OS: Windows Server 2019
	- EXPRESSCLUSTER X: 4.1/4.2
	- SQL Server 2019
	- SQL Server Management Studio
	- CPU: 2
	- Memory: 8MB
	- Disk
		- Disk0: System Drive
			- C:
		- Disk1: Mirror Disk
			- X:
				- Size: 1GB
				- File system: RAW (do NOT format)
			- E:
				- Size: Depending on database and transaction log size
				- File system: NTFS

- Secondary Server
	- OS: Windows Server 2019
	- SQL Server 2019
	- SQL Server Management Studio
	- CPU: 2
	- Memory: 8MB
	- Disk
		- Disk0: System Drive
			- C:
			- E:
				- Size: Depending on database and transaction log size
				- File system: NTFS

### Sample parameters
- IP address  

| |Public IP |Private IP |
|-----------------|-----------------|-----------------|
|Server1 |10.1.1.11 |192.168.1.11 |
|Server2 |10.1.1.12 |192.168.1.12 |
|fip |10.1.1.21 |- |
|Gateway |10.1.1.1 |- |
|Secondary Server |10.2.1.11 |- |

- Virtual hostname on Primary Server1 and Primary Server2: primary

- Folder path:
  - Backup Share folder: E:\LogShipping
  - Destination folder: E:\LogShipping 

### Cluster configuration
- failover group
	- Attribute
		- Startup Attribue: Manual Stratup
	- Resources
		- fip
		- md
			- Cluster Partition: X drive
			- Data Partition: E drive
		- vcom
		- cifs
			- For Backup Share folder
		- service1
			- For SQL Server Primary Instance service
		- service2
			- For SQL Server Agent service
		- **Note**
			- If you need to enable SQL Server Browser service, add one more service resource (service3)

### EXPRESSCLUSTER Licenses
- For Server1/Server2
	- In the case of physical servers
		- Core license: 4CPUs
		- Replicator Option license: 2 nodes
		- (Optional) Other Option licenses: 2 nodes
    
	- In the case of virtual machines or Cloud instances
		- Core license for VM: 2 nodes
		- Replicator Option license: 2 nodes
		- (Optional) Other Option licenses: 2 nodes

## Setup

### 1. SQL Server Installation

#### Primary Server1/Server2 at DC site
1. Setup Primary Server1 and Server2 with following [SQL Server on Windows cluster Quick Start Guide](https://github.com/EXPRESSCLUSTER/SQLServer/blob/master/SQLServer2019onWindows.md).
	- **Note**
		- Replace "Primary Server" and "Secondary Server" in the Quick Start Guide with "Primary Server1" and "Primary Server2" in this article.
		- Install SQL Server 2019 CU2 or later because it includes a fix for Log Shipping known issue. ([Microsoft KB 4537869](https://support.microsoft.com/ja-jp/help/4537869/kb4537869-fix-log-shipping-agent-is-not-able-to-log-history-and-error))
			- If you have already installed CU1 or earlier, apply CU2 or later update with following [Upgrade procedure](https://github.com/EXPRESSCLUSTER/SQLServer/blob/master/SQLServer2019onWindows.md#upgrade).
1. On Active Server, create a folder for Backup Share:
	1. Create a folder on Mirror Disk:
		- e.g. E:\LogShipping
	1. Edit access permission of the folder (E:\LogShipping) and give Full Control for "NT Service\SQLSERVERAGENT" account.  
		Because Log Shipping jobs are executed by SQL Server Agent (NT Service\SQLSERVERAGENT).
1. On Active Server, edit cluster configuration.
	1. Start Cluster WebUI Config Mode.
	1. Add resources to existing failver group:
		- cifs resource
			- Info
				- Type: cifs resource
				- Name: cifs
			- Dependency
				- Default
			- Recovery Operaiton
				- Default or as you like
			- Details
				- Shared Name: LogShipping
				- Folder: E:\LogShipping
				- When folder is shared not as activity failure: Check
		- vcom resource
			- Info
				- Type: vcom resource
				- Name: vcom
			- Dependency
				- Default
			- Recovery Operaiton
				- Default or as you like
			- Details
				- Virtual Computer Name: primary
				- Target FIP Resource Name: fip
	1. Edit failover group Properties
		- Attribute tab
			- Startup Attribute: Manual Startup
				- To avoid connections to Primary Database from clients while you take over the database to Secondary Server, manual startup is required for database consistency.
	1. Apply cluster configuration.
	1. Start all resources on Server1.
1. On Active Server, change server name on SQL Server.
	1. Start Command Prompt.
	1. Connect to Primary instance with administrator account and change servername:
		```bat
		sqlcmd -S <Server1> -U <usename> -P <password>
		1> use master
		2> go
		Changed database context to 'master'.
		1> select @@servername
		2> go
		-------------------------------------------------------------------------
		<Server1 hostname>
		
		(1 rows affected)
		1> sp_dropserver "<Server1 hostname>"
		2> go
		1> sp_addserver "primary", local
		2> go
		1> quit
		```
	1. Restart failover group including service1 resourve (SQL Server Instance service) to apply server name changes.

#### Secondary Server at DR site
1. Start SQL Server Installer and select as same as Primary Server but change Data Directories settings as follows:
	- Server Configuration
		- Service Accounts
			- SQL Server Agent:	Manual
			- SQL Server Database Engine:	Auto
			- SQL Server Browser:	As you like
	- Database Engine Configuration
		- Server Coonfiguration
			- Set same authentication mode and same SA password and add same Administrator accoun as Server1/Server2.
		- **Data Directories**
			- Data root directory:	C:\Program Files\Microsoft SQL Server\
			- User database directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Backup
	- **Note**
		- Install SQL Server 2019 CU2 or later because it includes a fix for Log Shipping known issue. ([Microsoft KB 4537869](https://support.microsoft.com/ja-jp/help/4537869/kb4537869-fix-log-shipping-agent-is-not-able-to-log-history-and-error))
			- If you have already installed CU1 or earlier, apply CU2 or later update
1. Start SQL Server Instance service and Agent service.

1. Create a folder for Destination:
	1. Create a folder on Mirror Disk.
		- e.g. E:\LogShipping
	1. Edit access permission of the folder (E:\LogShipping) and give Full Control for "NT Service\SQLSERVERAGENT" account.  
		Because Log Shipping jobs are executed by SQL Server Agent (NT Service\SQLSERVERAGENT).
	1. Share the folder (E:\LogShipping) to Primary Server1 and Server2
		- e.g. Share name: LogShipping

### 2. Before Log Shipping Configuration
#### On Primary Server1 (Active Primary Server)
1. Confirm that failover group is Online on the server.
1. Confirm the server name on SQL Server:
	1. Start Command Prompt.
	1. Connect to Primary instance and confirm the servername has been changed:
		```bat
		sqlcmd -S <Server1> -U <usename> -P <password>
		1> use master
		2> go
		Changed database context to 'master'.
		1> select @@servername
		2> go
		-------------------------------------------------------------------------
		primary
		
		(1 rows affected)
		1> quit
		```
1. Install SQL Server Management Studio (SSMS) and confirm Primary and Secondary Server are accessible:
	1. Install SSMS.
	1. Start SSMS.
	1. Confirm that you can connect Primary Server Instance:
		- Server name: 10.1.1.21 (fip address)
		- Authentication: Administrator account
			- If you cannot connect, confirm:
				- Failover group is Online and SQL Server Instance is running on the server.
	1. Confirm that you can connect Secondary Server Instance:
		- Server name: 10.2.1.11
		- Authentication: Administrator account
			- If you cannot connect, confirm:
				- Secondary Server IP address is accesible from Primary Server.
				- Secondary Server Instance is running on Secondary Server.
1. Confirm that you can access Secondary Server Destination folder (\\10.2.1.11\LogShipping).

#### On Primary Server2 (Standby Primary Server)
1. Install SQL Server Management Studio (SSMS) and confirm Primary and Secondary Server are accessible:
	1. Install SSMS.
	1. Start SSMS.
	1. Confirm that you can connect Primary Server Instance:
		- Server name: 10.1.1.21 (fip address)
		- Authentication: Administrator account
			- If you cannot connect, confirm:
				- Failover group is Online and SQL Server Instance is running on the server.
	1. Confirm that you can connect Secondary Server Instance:
		- Server name: 10.2.1.11
		- Authentication: Administrator account
			- If you cannot connect, confirm:
				- Secondary Server IP address is accesible from Primary Server.
				- Secondary Server Instance is running on Secondary Server.
1. Confirm that you can access Secondary Server Destination folder (\\10.2.1.11\LogShipping).

#### On Secondary Server
1. Install SQL Server Management Studio (SSMS) and confirm Primary and Secondary Server are accessible:
	1. Install SSMS.
	1. Start SSMS.
	1. Confirm that you can connect Primary Server Instance:
		- Server name: 10.1.1.21 (fip address)
		- Authentication: Administrator account
			- If you cannot connect, confirm:
				- Failover group is Online and SQL Server Instance is running on the server.
	1. Confirm that you can connect Secondary Server Instance:
		- Server name: 10.2.1.11
		- Authentication: Administrator account
			- If you cannot connect, confirm:
				- Secondary Server IP address is accesible from Primary Server.
				- Secondary Server Instance is running on Secondary Server.
1. Confirm that you can access Active Primary Server Backup Share folder with fip address (\\10.1.1.21\LogShipping).
	- If you cannot connect, confirm:
		- Fip address is accesible from Secondary Server.
		- cifs resource is Online.
		- cifs resource is set properly.

- **Note** If you can confirm all in this section "2. Before Log Shipping Configuration", go to the next section for Log Shiping configuration.  
	However, if you cannot confirm some points, please review your configuration or ask support before going to the nex section.  
	Because some errors may occur while Log Shiping configuration in the next section.

### 3. Create Database
#### On Primary Server1 (Active Server)
1. Create database (Primary Database)

### 4. Log Shipping Configuration
#### On Primary Server1
1. Start SSMS and connect to Primary Server Instance:
		- Server name: 10.1.1.21 (fip address)
		- Authentication: Administrator account
1. Set Log Shipping for a target databasaes:
	1. In the left tree, Open "Databases".
	1. Right click a target database and select "Properties".
	1. Select "Transaction Log Shipping" page and configure Log Shipping:
		- Enable this as a primary database in a log shipping configuration: Check
		- Backup Settings:
			- Network path to backup folder: \\10.1.1.21\LogShipping
			- If the backup folder is located on the primay server, type a local path to the folder: E:\LogShipping
			- Other: Default or As you like
		- Secondary server instances and databases: Add
			- Secondary server instance: Connect
				- Server name: 10.2.1.11
				- Authentication: Administrator account
			- Initialize Secondary Database tab
				- Default or as you like.
					- To synchronize database between Primary and Secondary Server, we recommend to select "Yes, generate a full backup of the primary database and restore it..."
			- Copy Files tab
				- Destination folder for copied files: E:\LogShipping
				- Other: Default or As you like
			- Restore Transaction Log
				- Default or As you like
					- If you will read Secondary database, select Standby mode.  
		- Other: Default or as you like
		- Click OK
		- Confirm that all process completes successfully.
		- For more details about each parameters, please see [Parameters](★)
	- If you want to configure Log Shipping for multiple databases, do the same for other databases.

### 5. After Log Shipping Configuration
#### On Primary Server1 (Active Primary Server)
1. Confirm that Log Shipping Backup job is created and works properly on Primary Server:
	1. Start SSMS and connect to Primary Server Instance:
		- Server name: 10.1.1.21 (fip address)
		- Authentication: Administrator account
	1. In the left tree, Open "SQL Server Agent" and "Jobs".
	1. Confirm that the following Job exists:
		- LSBackup_<primary database name>
	1. Right click the job and select "View History".
	1. Confirm that Backup job completes successfully.  
		If any errors are recorded, check the message.

1. Confirm that backup files ("<databasename>.bak" and "<databasename>_xxxx.trn") are created in Backup Share folder (E:\LogShipping).

1. Confirm that the database is copied and restored to Secondary Server:
	1. Start SSMS and connect to Secondary Server Instance:
		- Server name: 10.2.1.11
		- Authentication: Administrator account
	1. In the left tree, Open "Databases".
	1. Confirm that the database exists.
		- In the case of NORECOVERY mode, it shows "Restoring" status.
		- In the case of STANDBY mode, it shows "Stanby/Read-only" status.

1. Confirm that Log Shipping Copy and Restore jobs are created and work properly on Secondary Server:
	1. Start SSMS and connect to Secondary Server Instance:
		- Server name: 10.2.1.11
		- Authentication: Administrator account
	1. In the left tree, Open "SQL Server Agent" and "Jobs".
	1. Confirm that the following Jobs exist:
		- LSCopy_<Primary Server fip>_<primary database name>
		- LSRestore_<Primary Server fip>_<primary database name>

#### On Secondary Server
1. Confirm that backup files ("<databasename>.bak" and "<databasename>_xxxx.trn") are copied to Destination folder (E:\LogShipping).

- **Note** If you can confirm all in this section "5. After Log Shipping Configuration", start Log Shiping operation.  
	However, if you cannot confirm some points, please review your configuration or ask support before starting Log Shipping operation.  
	because some errors may occur while Log Shiping operation.

## Reference
### Log Shipping Parameters
- Backup Settings
	- Network path to backup folder: Backup Share folder network path
	- If the backup folder is located on the primary server, type a local path to the folder: Backup Share folder local path
	- Delete files older than: Threshold to delete old transaction log backup files in Backup Share folder (Default: 72 Hours)
	- Alert if no backup occurs whithin: Threshold to alert backup error to monitor server or Windows Application Event (Default: 1 Hour)
	- Schedule
		- Occurs every: Backup job execution interval (Default: 15 Minutes)
- Secondary Database Settings
	- Initialize Secondary Database: Backup and restore options for the first synchronization
	- Copy Files
		- Destination folder for copied files: Destination folder local path
		- Delete copied files after: Thleshould to delete old copied transaction log backup files in Destination folder (Default: 72 Hours)
		- Schedule
			- Occurs every: Copy job execution interval (Default: 15 Minutes)
	- Restore Transaction
		- Database state when restoring backups: Restore morde
			- For more details about each NORECOVERY or STANDBY mode, please see [Microsoft Log Shipping Guide](https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/restore-a-sql-server-database-to-a-point-in-time-full-recovery-model?view=sql-server-ver15
).
			- Mode setting can be changed on Secondary Server after starting operation.
				- In the case of SSMS:
					- Right click the target databse, select "Tasks" - "Restore" - "Database" - "Option" page and select Recovery state, WITH NORECOVERY or WITH STANDBY.
				- In the case of sql command:
					- Sample command: RESTORE DATABASE <database name> WITH [NORECOVERY/STANDBY]
		- Alert if no restore occurs within: Threshold to alert restore error to monitor server or Windows Application Event (Default: 45 Minutes)
		- Schedule
			- Occurs every: Restore job execution interval (Default: 15 Minutes)

- **Note**
  - For more details about Log Shipping parameters, please see [Microsoft Log Shipping Guide](https://docs.microsoft.com/ja-jp/sql/database-engine/log-shipping/configure-log-shipping-sql-server?view=sql-server-ver15).

### Multi Secondary Server configuration
In this Guide, there is one Secondary Server, however, you can add more Secondary Servers.  
About how to add more Secondary Server, please see [Microsoft Log Shipping Guide](https://docs.microsoft.com/en-us/sql/database-engine/log-shipping/add-a-secondary-database-to-a-log-shipping-configuration-sql-server?view=sql-server-ver15)

### Monitor Server
In this Guide, there is no Monitor Server, however, you can add Monitor Server.  
About how to setup, please see [Microsoft Log Shipping Guide](https://docs.microsoft.com/ja-jp/sql/database-engine/log-shipping/configure-log-shipping-sql-server?view=sql-server-ver15).

## Operation
**Note**
- For this solution operation, SQL Server database backup/restore skill is required.
- About SQL Server operation details, please refer Micrsoft SQL Server Guide or ask Microsoft SQL Server support.

### Fail over from Primary Server to Secondary Server
Please see [Microsoft Log Shipping Failover procedure](https://docs.microsoft.com/en-us/sql/database-engine/log-shipping/fail-over-to-a-log-shipping-secondary-sql-server?view=sql-server-ver15).  

If both Primary Server1 and Primary Server2 get down (DC site down) and execute failover to Secondary Server, please recover the servers as follows:
	1. Boot Primary Server1 and Primary Server2.
	1. Start only md resource.
	1. On Active Primary Server, start Windows Service Manager and start SQL Server Instance service manually. (Not start service1 resource.)
	1. Connect to Primary Database and back up the tail of the transaction log of the Primary Database using WITH NORECOVERY as recommended in the Microsoft Failover procedure.
	1. On Windows Service Manager, stop SQL Server Instance service manually.
	1. Start all resources in failover group.

### Fail back from Secondary Server to Primry Server
You can do failback is some ways:
- Option 1) Get Backup on Secondary Server and restore it to Primary Server
- Option 2) Switch Primary and Secondary Server roles
	- Please see [Microsoft Chage roles procedure](https://docs.microsoft.com/en-us/sql/database-engine/log-shipping/change-roles-between-primary-and-secondary-log-shipping-servers-sql-server?view=sql-server-ver15).

### In the case that a network between DC site and DR site is disconnected
Copy job fails and new transaction log backup files are not copied.  
However, when the network recovers, all un-copied backup files will be copied automatically by Copy job.

### In the case that un-restored transacion log backup file is removed
You need to backup Primary Database and restore it to Secondary Server manually.  
When restoring, please specify the same mode, NORECOVER or STANDBY, as Log Shipping configuration.

## Options
### HA for Secondary Server 
You can protect Secondary Server Instance by EXPRESSCLUSTER X SingleServerSafe.
