# SQL Server on Windows cluster Quick Start Guide
This article shows how to setup SQL Server 2019 Cluster with EXPRESSCLUSTER X Shared Disk configuratoin.

## Reference

### EXPRESSCLUSTER
 - [EXPRESSCLUSTER X Manuals](https://www.nec.com/en/global/prod/expresscluster/en/support/manuals.html)
### MSSQL Server 2019 on Windows
 - [SQL Server Installation with Installation Wizard]( https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-installation-wizard-setup?view=sql-server-ver15)

## System configuration
- Servers: 2 node with Shared Disk
- OS: Windows Server 2016/2019
- SW:
	- SQL Server 2019 Standard
	- EXPRESSCLUSTER X 4 (4.0/4.1/4.2/4.3)

```bat
<Public LAN>
 |
 | <Private LAN>
 |  |
 |  |  +--------------------------------+           +-------------+
 +-----| Primary Server                 |           |             |
 |  |  |  OS: Windows Server 2016/2019  +===========+             |
 |  +--|  SW: EXPRESSCLUSTER X 4        |           |             |
 |  |  |      SQL Server 2019           |           |             |
 |  |  +--------------------------------+           |   Shared    |
 |  |                                               |   Disk      |
 |  |  +--------------------------------+           |             |
 +-----| Secondary Server               |           |             |
 |  |  |  OS: Windows Server 2016/2019  +===========+             |
 |  +--|  SW: EXPRESSCLUSTER X 4        |           |             |
 |  |  |      SQL Server 2019           |           |             |
 |  |  +--------------------------------+           +-------------
 |  |
 |  |
 |  |  +--------------------------------+
 +-----| Client machine                 |
 |  |  +--------------------------------+
 |  |
 | [Switch]
 |  :
 |
[Gateway]
 :
```

### Requirements
 - [EXPRESSCLUSTER X Manuals](https://www.nec.com/en/global/prod/expresscluster/en/support/manuals.html)
	- Getting Started Guide
	- Installation and Configuration Guide
 - [SQL Server Installation Requirements](https://docs.microsoft.com/ja-jp/sql/sql-server/install/planning-a-sql-server-installation?view=sql-server-ver15)

### Sample configuration
- Primary/Secondary Servers
	- OS: Windows Server 2016
	- EXPRESSCLUSTER X: 4.3
	- CPU: 2
	- Memory: 8MB
	- Disk (Each server's local disk)
		- C:
			- Size: Depending on system requirements
- Shared Disk
	- Partitions
		- Z:
			- Size: 20MB
			- File system: RAW (do NOT format)
		- E:
			- Size: Depending on data size
			- File system: NTFS
- Required Licenses
	- Core license:
		- In the case of physical servers: 6 CPUs
		- In the case of virtual machines: 2 nodes
	- (Optional) Other Option licenses: 2 nodes

- IP address  

| |Public IP |Private IP |
|-----------------|-----------------|-----------------|
|Primary Server |10.1.1.11 |192.168.1.11 |
|Secondary Server |10.1.1.12 |192.168.1.12 |
|fip |10.1.1.21 |- |
|Client machine |10.1.1.51 |- |
|Gateway |10.1.1.1 |- |


## Cluster configuration
- failover group
	- fip
		- fip address: 10.1.1.21
	- sd
		- Data Partition: E drive
	- service1
		- For SQL Server Instance service
	- service2
		- For SQL Server Agent service
	- **Note**
		- If you need to enable SQL Server Browser service, add one more service resource (service3)

## Setup
This procedure shows how to setup SQL Server cluster by mirroring both SQL Server master database and user database.

### Overview
1. Setup a basic cluster (with fip resource and disk resource).
1. Install SQL Server on Primary Server.
1. Install SQL Server on Secondary Server.
1. Add SQL Serer resources to the basic cluster
1. Failover test

### 1. Setup a basic cluster
Please refer [Basic Cluster Setup](https://github.com/EXPRESSCLUSTER/BasicCluster/blob/master/X41/Win/2nodesShared.md)

### 2. Install SQL Server on Primary Server

#### On Primary Server
1. Confirm that the failover group is active on the server.
1. Create a folder on Shared Disk Switched Partition:
	- e.g.) E:\SQL
1. Start SQL Server Installer and select as follows:
	- Installation:  
		Select "New SQL Server stand-alone installation or add features to an existing installaion"
	- Microsift Update:  
		Default or as you like
	- Product Updates:  
		Default or as you like
	- Product Key:  
		Enter license key
	- License Terms:  
		Accept
	- Feature Selection:
		- Database Engine Service: Check
		- Shared Features: As you like
	- Instance Configuration:  
		Default or as you like
	- Server Configuration:
		- Service Accounts
			- SQL Server Agent:	Manual
			- SQL Server Database Engine:	Manual
			- SQL Server Browser:	As you like
	- Database Engine Configuration:
		- Server Coonfiguration:  
			As you like  
				- **Note** We recommend to set Windows authentication and add domain account as Administrator because the database should be accessible from both Primary and Secondary Servers.
		- Data Directories:
			- Data root directory:	E:\SQL\
			- User database directory:	E:\SQL\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	E:\SQL\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	E:\SQL\MSSQL15.TEST\MSSQL\Backup
	- Ready to install:  
		Install
1. Check Installed SQL Server Instance is started normally:
	1. Start SQL Server Configuration Manager.
	1. Select [SQL Server Services] at the left tree.
	1. Right click [SQL Server (\<Instance name\>)] and select [Start].
	1. Confirm that SQL Server Instance service is normally started.
	1. Right click [SQL Server (\<Instance name\>)] and select [Stop].
1. Move failover group to Secondary Server.

### 3. Install SQL Server on Secondary Server
#### On Secondary Server Server
1. Confirm that the failover group is active on the server.
1. Confirm that files under E:\SQL folder is accessible.
1. Start SQL Server Installer and select as same as Primary Server but change Data Directories settings as follows:
	- Database Engine Configuration
		- Server Coonfiguration
			- Set same authentication mode and same SA password and add same account as Administrator.
		- **Data Directories**
			- Data root directory:	C:\Program Files\Microsoft SQL Server\
			- User database directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- User database log directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Data
			- Backup directory:	C:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\Backup
1. Change SQL Server Startup parameters:
	1. Start SQL Server Configuration Manager.
	1. Select [SQL Server Services] at the left tree.
	1. Right click [SQL Server (\<Instance name\>)] and select [Properties].
	1. Goto [Setup Parameters] tab and edit existing parameters as follow:
		- Before:  
			-dC:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\DATA\master.md  
			-lC:\Program Files\Microsoft SQL Server\MSSQL15.TEST\MSSQL\DATA\mastlog.ld
		- After:  
			-dE:\SQL\MSSQL15.TEST\MSSQL\DATA\master.md  
			-lE:\SQL\MSSQL15.TEST\MSSQL\DATA\mastlog.ld
1. Check Installed SQL Server Instance is started normally:
	1. Start SQL Server Configuration Manager.
	1. Select [SQL Server Services] at the left tree.
	1. Right click [SQL Server (\<Instance name\>)] and select [Start].
	1. Confirm that SQL Server Instance service is normally started.
	1. Right click [SQL Server (\<Instance name\>)] and select [Stop].
1. Move failover group to Primary Server.

### 4. Add SQL Serer resources to the basic cluster
#### On Primary Server
1. Start Cluster WebUI Config Mode.
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
			Click connect and select [SQL Server (\<Instance name\>)]
	- service2
		- Info
			- Type: service resource
			- Name: service_SQLAgent
		- Dependency  
			Uncheck [Follow the default dependency], select [service_SQLServer] and click [Add]
		- Recovery Operation  
			Default or as you like
		- Details  
			Click connect and select [SQL Server Agent (\<Instance name\>)]
1. Apply the configuration.
1. Start the resources on Primary Server.

### 5. Failover test
#### On Primary Server
1. Confirm that the failover group is active on the server.
1. Create a test database:
	1. Connect to SQL Server.
		```bat
		> sqlcmd -S localhost -U <username> -P <password>
		```
	1. Create a test database and table and inser a value to it.
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
	1. Confirm the value is inserted.
		```bat
		1> select * from testtb
		2> go
		id          name
		----------- --------------------
	          0 Kurara
	
		(1 rows affected)
		```
	1. Exit from the database.
		```bat
		1> quit
		```
1. Move the failover group to Secondary Server.

#### On Secondary Server
1. Confirm that the failover group is active normally on the server.
1. Check the test database is failed over.
	1. Connect to SQL Server.
		```bat
		> sqlcmd -S localhost -U SA -P <password>
		```
	1. Confirm that the test database and table which are created on Primary Server exists.
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
	1. Exit from the database.
		```bat
		1> quit
		```
1. Move the failover group to the other server.

## Upgrade SQL Server version
This procedure shows how to upgrade clustered SQL Server version to 2019 from previous version.

### Reference
 - [SQL Server Upgrade path](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/upgrade-sql-server?view=sql-server-ver15).
 - [SQL Server Upgrade Procedure with Installation Wizard](https://docs.microsoft.com/en-us/sql/database-engine/install-windows/upgrade-sql-server-using-the-installation-wizard-setup?view=sql-server-ver15)

### Notification
- This Upgrade procedure does not include Edition upgrade.
- While upgrading, clients cannot connect to database.
- For SQL Server Upgrade requirements, refer SQL Server Upgrade path.

### Overview
1. Preparation
1. Copy SQL Server 2014 Data root directory
1. Upgrade on Primary Server
1. Replace SQL Server 2019 Data root directory with the copied SQL Server 2014 Data root directory
1. Upgrade on Secondary Server
1. Failover test

### 1. Preparation
#### On Primary Server
1. Confirm cluster status:
	1. Start Cluster WebUI Operation Mode and go to [Status] tab.
	1. Confirm that all status are normal.
	1. Confirm that failover group is active on the server.
1. Change cluster setting to avoid unexpected failover while upgrading:
	1. Start Cluster WebUI Config Mode.
	1. Change the following cluster settings to avoid failover by monitor errors while upgrading:
		- Cluster Properties
			- Recovery tab
				- Disable Recovery Action Caused by Monitor Recource Failure: Unheck
	1. Apply the cluster configuration.
1. Backup database.

### 2. Copy SQL Server 2014 Data root directory
#### On Primary Server
1. Stop SQL Server service resurces to avoid databases are updated:
	1. Start Cluster WebUI Operation Mode and go to [Status] tab.
	1. Stop the following resurces:
		- service_SQLAgent resource
		- service_SQLServer resource.
1. Copy SQL Server Data root directory to other folder:
	- e.g.)
		- \<Copy source\>  
			E:\SQL
		- \<Copy target\>  
			E:\SQL_2014

### 3. Upgrade on Primary Server
#### On Primary Server
1. Confirm that failover group is active on the server and the following resources are Offline:
	- service_SQLAgent resource
	- service_SQLServer resource
1. Upgrade SQL Server:
	1. Start SQL Server Installer and select as follows:
		- Installation  
			Select [Upgrade from previous version if SQL Server]
		- Product Key  
			Enter license key
		- License Terms  
			Accept
		- Global Rules  
			No need to select
		- Microsift Update  
			Default or as you like
		- Product Updates  
			Default or as you like
		- Install Setup Files  
			No need to select
		- Select Instance  
			Select an instance to upgrade
		- Select Features  
			Database Engine Service: Check  
			Shared Features: As you like
		- Instance Configuration  
			Select an instance to upgrade
		- Feature Rules  
			No need to select
		- Ready to Upgrade  
			Upgrade
1. Reboot the server.  
	Then failover group will failover to the other server.

#### On Secondary Server
1. Confirm that the other server has been rebooted.
1. Move failover group to the other server.

#### On Primary Server
1. Confirm that failover group is active on the server and the following resources are Offline:
	- service_SQLAgent resource
	- service_SQLServer resource.
1. Confirm that Upgraded SQL Server Instance is started normally:
	1. Start SQL Server Configuration Manager.
	1. Select [SQL Server Services] at the left tree.
	1. Right click [SQL Server (\<Instance name\>)] and select [Start].
	1. Confirm that SQL Server Instance service is normally started.
	1. Right click [SQL Server (\<Instance name\>)] and select [Stop].
1. Move failover group to the other server.

### 4. Replace SQL Server 2019 Data root directory with the copied SQL Server 2014 Data root directory
#### On Secondary Server
1. Confirm that failover group is active on the server and the following resources are Offline:
	- service_SQLAgent resource
	- service_SQLServer resource.
1. Switch SQL Server Data root directory:
	1. Rename current Data root directory:
		- e.g.)
			- \<Before\>  
				E:\SQL
			- \<After\>  
				E:\SQL_2019
	1. Copy SQL Server 2014 Data root directory as current Data root directory:
		- e.g.)
			- \<Copy source\>  
				E:\SQL_2014
			- \<Copy target\>  
				E:\SQL
	1. Add SQL Server Instance service access permission to current Data root directory:
		1. Confirm SQL Server Instance service login account.
			1. Start SQL Server Configuration Manager.
			1. Select [SQL Server Services] at the left tree.
			1. Check [SQL Server (\<Instance name\>)] line [Log On As] Column. (Default: "NT Service\\<Instance name\>")
		1. Add the access permission.
			1. Right click current Data root directory ("E:\SQL") and select [Properties].
			1. Go to [Security] tab.
			1. Click [Edit] -> [Add] and add SQL Server Instance service login account.
			1. Check [Full Control] and click [OK].
1. Confirm that the SQL Server Instance is started normally with replaced Data root directory:
	1. Start SQL Server Configuration Manager.
	1. Select [SQL Server Services] at the left tree.
	1. Right click [SQL Server (\<Instance name\>)] and select [Start].
	1. Confirm that SQL Server Instance service is normally started.
	1. Right click [SQL Server (\<Instance name\>)] and select [Stop].

### 5. Upgrade on Secondary Server
#### On Secondary Server
1. Confirm that failover group is active on the server and the following resources are Offline:
	- service_SQLAgent resource
	- service_SQLServer resource.
1. Upgrade SQL Server:
	1. Start SQL Server Installer and select as follows:
		- Installation  
			Select [Upgrade from previous version if SQL Server]
		- Product Key  
			Enter license key
		- License Terms  
			Accept
		- Global Rules  
			No need to select
		- Microsift Update  
			Default or as you like
		- Product Updates  
			Default or as you like
		- Install Setup Files  
			No need to select
		- Select Instance  
			Select an instance to upgrade
		- Select Features  
			Database Engine Service: Check  
			Shared Features: As you like
		- Instance Configuration  
			Select an instance to upgrade
		- Feature Rules  
			No need to select
		- Ready to Upgrade  
			Upgrade
1. Reboot the server.  
	Then failover group will failover to the other server.

#### On Primary Server
1. Confirm that the other server has been rebooted.
1. Move failover group to the other server.

#### On Secondary Server
1. Confirm that failover group is active on the server and the following resources are Offline:
	- service_SQLAgent resource
	- service_SQLServer resource.
1. Confirm that the Upgraded SQL Server Instance is started normally:
	1. Start SQL Server Configuration Manager.
	1. Select [SQL Server Services] at the left tree.
	1. Right click [SQL Server (\<Instance name\>)] and select [Start].
	1. Confirm that SQL Server Instance service is normally started.
	1. Right click [SQL Server (\<Instance name\>)] and select [Stop].
1. Move failover group to the other server.

### 6. Failover test
#### On Primary Server
1. Confirm that failover group is active on the server and the following resources are Offline:
	- service_SQLAgent resource
	- service_SQLServer resource.
1. Start the following resources:
	- service_SQLAgent resource
	- service_SQLServer resource.
1. Confirm that the resources start normally.
1. Move failover group to the other server.

#### On Secondary Server
1. Confirm that failover group is active on the server.
1. Rollback cluster setting which was changed in Preparaton:
	1. Start Cluster WebUI Config Mode.
	1. Change the following cluster settings to avoid failover by monitor errors while upgrading:
		- Cluster Properties
			- Recovery tab
				- Disable Recovery Action Caused by Monitor Recource Failure: Unheck
	1. Apply the cluster configuration.
1. Remove the following folders:
	- E:\SQL_2014
	- E:\SQL_2019
1. Move failover group to the other server.
