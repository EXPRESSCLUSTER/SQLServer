# SQL Server 2022 on Windows cluster Quick Start Guide
This article shows how to setup SQL Server 2022 Cluster with EXPRESSCLUSTER X Mirror Disk configuration.

## Reference

### EXPRESSCLUSTER
- https://www.nec.com/en/global/prod/expresscluster/en/support/manuals.html
### SQL Server 2022 on Windows
- https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-installation-wizard-setup?view=sql-server-ver16
- https://learn.microsoft.com/en-us/sql/database-engine/install-windows/upgrade-sql-server-using-the-installation-wizard-setup?view=sql-server-ver16

## Sample System Configuration
- Servers: 2 nodes with Mirror Disk configuration
- OS: Windows Server 2022
- SW:
	- SQL Server 2022 Standard
	- EXPRESSCLUSTER X 5 (5.3)

```text
<Public LAN>
 |
 | <Private LAN>
 |  |
 |  |  +--------------------------------+
 +-----| Primary Server                 |
 |  |  |  Windows Server 2022           |
 |  |  |  EXPRESSCLUSTER X 5            |
 |  +--|  SQL Server 2022               |
 |  |  +--------------------------------+
 |  |
 |  |  +--------------------------------+
 +-----| Secondary Server               |
 |  |  |  Windows Server 2022           |
 |  |  |  EXPRESSCLUSTER X 5            |
 |  +--|  SQL Server 2022               |
 |  |  +--------------------------------+
 |  |
 |  |
 |  |  +--------------------------------+
 |  +--| Client machine                 |
 |     +--------------------------------+
 |
[Gateway]
 :
```

### Requirements
- All Primary Server, Secondary Server and Client machine should be reachable with IP address.
- To use Floating IP (fip) resource, both servers must belong to the same network.
	- If each server belongs to different networks, you can use ddns resource with [Dynamic DNS Server](https://github.com/EXPRESSCLUSTER/Tips/blob/master/ddnsPreparation.md) instead of fip address.
- The Ports which EXPRESSCLUSTER uses should be opened.
	- The ports are described in [EXPRESSCLUSTER X 5.0 for Windows Getting Started Guide] (https://docs.nec.co.jp/sites/default/files/minisite/static/284b1dba-b9a1-4905-bcbf-e8de2265c9b0/ecx_x50_windows_en/W50_SG_EN/W_SG.html#communication-port-number)
- Mirror Disk resource requires 2 partitions, *Data Partition* and *Cluster Partition*.
	- Data Partition: Depends on mirrored data size (NTFS)
	- Cluster Partition: 1024MB (1GB), RAW (do not format this partition)
	- **Note**
		- It is not supported to mirror C: drive and do NOT specify C: drive for Data Partition.
		- Dynamic disk is not supported for Data Partition and Cluster Partition.
		- Data Partition on Secondary Server will be overwritten on initial Mirror Disk synchronization (Initial Recovery).

### Sample configuration
- Primary/Secondary Server
	- OS: Windows Server 2022
	- EXPRESSCLUSTER X: 5.3
	- CPU: 2
	- Memory: 8 GB
	- Disk
		- Disk0: System Drive
			- C:
		- Disk1: Mirror Disk
			- X:
				- Size: 1 GB
				- File system: RAW (do NOT format)
			- E:
				- Size: Depending on data size
				- File system: NTFS
- Required Licenses
	- Core: 4 CPUs in total (2 CPUs for Primary Server and 2 CPUs for Secondary Server)
	- Replicator Option: 2 nodes
	- (Optional) Database Server Agent: 2 nodes
	- (Optional) Alert Service: 2 nodes

- IP address  

|                 |Public IP   |Private IP    |
|-----------------|------------|--------------|
|Primary Server   | 10.1.1.11  | 192.168.1.11 |
|Secondary Server | 10.1.1.12  | 192.168.1.12 |
|fip              | 10.1.1.10  | -            |
|Client           | 10.1.1.51  | -            |
|Gateway          | 10.1.1.254 | -            |

## Cluster configuration
- failover group
	- fip
	- md
		- Cluster Partition: X drive
		- Data Partition: E drive
	- service1
		- For SQL Server Instance service
	- service2
		- For SQL Server Agent service
	- **Note**
		- If you need to enable SQL Server Browser service, add one more service resource (service3)

## Setup
This procedure shows how to setup SQL Server cluster by mirroring both SQL Server master database and user database.

### Setup a basic cluster
Please refer [Basic Cluster Setup](https://github.com/EXPRESSCLUSTER/BasicCluster/blob/master/X41/Win/2nodesMirror.md)

### Install SQL Server

#### On Primary Server
1. Confirm that the failover group is active on the server
1. Create a folder on Mirror Disk - e.g. `E:\SQL`
1. Start SQL Server Installer and select as follows:
	- Installation  
		Select "New SQL Server stand-alone installation or add features to an existing installation"
	- Microsoft Update  
		Default or as preferred
	- Product Updates  
		Default or as preferred
	- Product Key  
		Enter license key
	- License Terms  
		Accept
	- Feature Selection
		- Database Engine Service: Check
		- Shared Features: as preferred
	- Instance Configuration  
		Default or as preferred
	- Server Configuration
		- Service Accounts
			- SQL Server Agent:	Manual
			- SQL Server Database Engine:	**Manual**
			- SQL Server Browser:	as preferred
	- Database Engine Configuration
		- Server Configuration
			- **Windows authentication mode** would be good for Domain environment. Add a domain account in the **Specify SQL Server administrators** 
			- **Mixed Mode** would be good for Workgroup environment.
		- Data Directories
			- Data root directory:	E:\SQL\
			- User database directory:	E:\SQL\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	E:\SQL\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	E:\SQL\MSSQL15.TEST\MSSQL\Backup
	- Ready to install  
		Install
1. Verify that SQL Server is installed correctly.
	1. Start Windows Service Manager and start SQL Server service.
	1. Confirm that SQL Server service status becomes running.
	1. Stop SQL Server service
1. Move failover group to Secondary Server

#### On Secondary Server
1. Confirm that the failover group is active on the server
1. Confirm that files under E:\SQL folder is accessible
1. Start SQL Server Installer and select as same as Primary Server but change Data Directories settings as follows:
	- Database Engine Configuration
		- Server Configuration
			- Set same authentication mode and same SA password and add same account as SQL Server administrator.
		- **Data Directories**
			- Data root directory:	C:\Program Files\Microsoft SQL Server\
			- User database directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Backup
1. Start SQL Server Configuration Manager
1. Select [SQL Server Services] at the left tree
1. Right click [SQL Server (<instance name>)] and select [Properties]
1. Go to [Setup Parameters] tab and edit existing parameters as follow:
	- Before:
		- -dC:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\DATA\master.md
		- -lC:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\DATA\mastlog.ld
	- After:
		- -dE:\SQL\MSSQL15.TEST\MSSQL\DATA\master.md
		- -lE:\SQL\MSSQL15.TEST\MSSQL\DATA\mastlog.ld
1. Verify that SQL Server is installed correctly.
	1. Start Windows Service Manager and start SQL Server service.
	1. Confirm that SQL Server service status becomes running.
	1. Stop SQL Server service
1. Move failover group to Primary Server

### Add SQL Server to cluster

#### On Primary Server
1. Start Cluster WebUI Config Mode
1. Add resources to existing failover group as follows: 
	- service1
		- Info
			- Type: service resource
			- Name: service_SQLServer
		- Dependency  
			Default
		- Recovery Operation  
			Default or as preferred
		- Details  
			Click connect and select [SQL Server (<instance name>)]
	- service2
		- Info
			- Type: service resource
			- Name: service_SQLAgent
		- Dependency  
			Uncheck [Follow the default dependency], select [service_SQLServer] and click [<Add]
		- Recovery Operation  
			Default or as preferred
		- Details  
			Click connect and select [SQL Server Agent (<instance name>)]
1. Apply the configuration
1. Start the resources on Primary Server.

### Check SQL Server Cluster
#### On Primary Server
1. Confirm that the failover group is active normally on the server
1. Connect to SQL Server
	```bat
	> sqlcmd -S localhost -U <username> -P <password>
	```
1. Create a test database and table and insert a value to it
	```bat
	1> create database testdb
	2> go
	1> use testdb
	2> go
	Changed database context to 'testdb'.
	1> create table testtb(
	2>  id int,
	3>  name varchar(20)
	4> );
	5> go
	1> insert into testtb (id, name) values(0, "Kurara");
	2> go
	```
1. Confirm the value is inserted
	```bat
	1> select * from testtb
	2> go
	id          name
	----------- --------------------
          0 Kurara

	(1 rows affected)
	```
1. Exit from the database
	```bat
	1> quit
1. Move the failover group to Secondary Server
	```

#### On Secondary Server
1. Confirm that the failover group is active normally on the server
1. Connect to SQL Server
	```bat
	> sqlcmd -S localhost -U SA -P <password>
	```
1. Confirm that the database, table and its value is replicated
	```bat
	1> use testdb
	2> go
	Changed database context to 'testdb'.
	1> select * from testtb
	2> go
	id          name
	----------- --------------------
	          0 Kurara
	
	(1 rows affected)
	```
1. Exit from the database
	```bat
	1> quit
	```
1. Move the failover group to the other server

### (Option) Add SQL Server monitor resource
1. Confirm that a database which should be monitored is already created.
1. Register EXPRESSCLUSTER X Database Agent license to each cluster node.
1. Start Cluster WebUI Config Mode
1. Add a SQL Server monitor resource to existing failover group as follows: 
	- monitor_SQLServer
		- Info
			- Type: SQL Server monitor resource
			- Name: sqlserverw
		- Monitor(common)  
			- Target Resource: service_SQLServer
			- Wait Time to Start Monitoring: 10
				- *Note*
					- Monitoring should be delayed to start because the target database takes some seconds to become accessible after the instance service is started. If 10 seconds is not enough in your environment, double this parameter.
			- Other settings: Default or as preferred
		- Monitor(special)
			- Monitor Level: as preferred
			- Database name: Enter the database name to be monitored (e.g `testdb`)
			- Instance: Enter the SQL Server instance name (e.g `MSSQLSERVER`, `SQLEXPRESS`)
			- User Name/Password: Enter a user name and its password which is accessible to the database to be monitored
			- Monitor Table Name: Default or as preferred
			- ODBC Driver Name: Select [ODBC Driver 17 for SQL Server]
		- Recovery Action
			- as preferred
1. Apply the configuration
