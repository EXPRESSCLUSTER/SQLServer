# SQL Server on Windows cluster Quick Start Guide
This article shows how to setup SQL Server 2019 Cluster with EXPRESSCLUSTER X Mirror Disk configuratoin.

## Reference

### EXPRESSCLUSTER
- https://www.nec.com/en/global/prod/expresscluster/en/support/manuals.html
### MSSQL Server 2019 on Windows
- https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-installation-wizard-setup?view=sql-server-ver15
- https://docs.microsoft.com/en-us/sql/database-engine/install-windows/upgrade-sql-server-using-the-installation-wizard-setup?view=sql-server-ver15

## System configuration
- Servers: 2 node with Mirror Disk
- OS: Windows Server 2019
- SW:
	- SQL Server 2019 Standard
	- EXPRESSCLUSTER X 4.0/4.1/4.2

```bat
<LAN>
 |
 |  +----------------------------+
 +--| Primary Server             |
 |  | - Windows Server 2019      |
 |  | - SQL Server 2019          |
 |  | - EXPRESSCLUSTER X 4       |
 |  +----------------------------+
 |                                
 |  +----------------------------+
 +--| Secondary Server           |
 |  | - Windows Server 2019      |
 |  | - SQL Server 2019          |
 |  | - EXPRESSCLUSTER X 4       |
 |  +----------------------------+
 |
```

## Cluster configuration
- failover group
	- fip
	- md
		- Cluster Partition: X drive
		- Data Partition: E drive
	- service1
	- service2

## Setup
This procedure shows how to setup SQL Server cluster by mirroring both SQL Server master database and user database.

### Setup a basic cluster
Please refer [Basic Cluster Setup](https://github.com/EXPRESSCLUSTER/BasicCluster/blob/master/X41/Win/2nodesMirror.md)

### Install SQL Server

#### On Primary Server
1. Confirm that the failover group is active on the server
1. Create a folder on Mirror Disk  
	```bat
	e.g.) E:\SQL
	```
1. Start SQL Server Installer and select as follows:
	- Installation  
		Select "New SQL Server stand-alone installation or add features to an existing installaion"
	- Microsift Update  
		Default or as you like
	- Product Updates  
		Default or as you like
	- Product Key  
		Enter license key
	- License Terms  
		Accept
	- Feature Selection
		- Database Engine Service: Check
		- Shared Features: As you like
			- **Note** We recommend to install SQL Client Connectivity SDK to enable sql command for maintenance.
	- Instance Configuration  
		Default or as you like
	- Server Configuration
		- Service Accounts
			- SQL Server Agent:	Manual
			- SQL Server Database Engine:	Manual
			- SQL Server Browser:	As you like
	- Database Engine Configuration
		- Server Coonfiguration
			- As you like
				- **Note** We recommend to set SA Acount with Mixed Mode or add Domain Account for Windows authentication because the database should be accessible from both Primary and Secondary Servers.
		- Data Directories
			- Data root directory:	E:\SQL\
			- User database directory:	E:\SQL\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	E:\SQL\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	E:\SQL\MSSQL15.TEST\MSSQL\Backup
	- Ready to install  
		Install
1. Check SQL Server is installed normally.
	1. Start Windows Service Manager and start SQL Server service.
	1. Confirm that SQL Server service status becomes running.
	1. Stop SQL Server service
1. Move failover group to Secondary Server

#### On Secondary Server Server
1. Confirm that the failover group is active on the server
1. Confirm that files under E:\SQL folder is accessible
1. Start SQL Server Installer and select as same as Primary Server but change Data Directories settings as follows:
	- Database Engine Configuration
		- **Data Directories**
			- Data root directory:	C:\Program Files\Microsoft SQL Server\
			- User database directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Backup
1. Start SQL Server Configuration Manager
1. Select [SQL Server Services] at the left tree
1. Right click [SQL Server (<instance name>)] and select [Properties]
1. Goto [Setup Parameters] tab and edit existing parameters as follow:
	- Before:
		- -dC:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\DATA\master.md
		- -lC:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\DATA\mastlog.ld
	- After:
		- -dE:\SQL\MSSQL15.TEST\MSSQL\DATA\master.md
		- -lE:\SQL\MSSQL15.TEST\MSSQL\DATA\mastlog.ld
1. Check SQL Server is installed normally.
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
			Default or as you like
		- Details  
			Click connect and select [SQL Server (<instance name>)]
	- service2
		- Info
			- Type: service resource
			- Name: service_SQLAgent
		- Dependency  
			Uncheck [Follow the default dependency], select [service_SQLServer] and click [<Add]
		- Recovery Operation  
			Default or as you like
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
1. Create a test database and table and inser a value to it
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

## Upgrade SQL Server version
This procedure shows how to upgrade clustered SQL Server to 2019 from previous version (e.g. 2017).  
Please note that it does not include Edition upgrade.  
Please refer SQL Server document for Upgrade path.  

### Suspend monitoring and stop mirroring
#### On Primary Server
1. (If you need) Backup database
1. Start Cluster WebUI Operation Mode and go to [Status] tab
1. Confirm that all status are normal
1. Suspend all monitor resources on both the servers
1. Goto [Mirror disks] tab
1. Execute [Mirror break] for md resource
1. Execute [Turn off access restriction] for md resource

### Upgrade SQL Server
#### On both servers
1. Start SQL Server Installer and select as follows:
	- Installation  
		Select "Upgrade from a previous version of SQL Server"
	- Microsoft Update  
		Default or as you like
	- Product Updates  
		Default or as you like
	- Product Key  
		Enter license key
	- License Terms  
		Accept
	- Select Instance  
		Select instance to be upgraded
	- Select Features
		- Database Engine Service: Check
		- Shared Features: As you like
	- Instance Configuration  
		Confirm the instance name is correct
	- Ready to Upgrade  
		Upgrade

- **Note** Please do NOT reboot the servers at this time

#### On Primary Server
1. Start Cluster WebUI Operation Mode and go to [Mirror disks] tab
1. Execute [Turn on access restriction] for md resource
1. Goto [Status] tab and resume all monitor resources on both the servers
1. Confirm that Fast Recovery runs and completes
1. (If you need) Reboot both servers
