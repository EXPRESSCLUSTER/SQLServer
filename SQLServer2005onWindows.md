# SQL Server on Windows cluster Quick Start Guide
This article describes how to setup SQL Server 2005 Cluster with EXPRESSCLUSTER X Mirror Disk configuratoin.

## Reference

### EXPRESSCLUSTER
- https://www.nec.com/en/global/prod/expresscluster/en/support/manuals/previous.html#ecx33
### MSSQL Server 2005 on Windows
- https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2005/ms130214(v=sql.90)

## Limitation
- **Microsoft's support for Windows Server 2003 and SQL Server 2005 has already ended.**
- System database (such as master, msdb) is saved on the local disk (C:\\).
	- System database is not replicated to another node.
- We tested the default instance (MSSQLSERVER) only.

## System configuration
- Servers: 2 nodes with Mirror Disk
- OS: Windows Server 2003 Enterprise Edition SP1
- SW:
	- SQL Server 2005 Enterprise Edition
	- EXPRESSCLUSTER X 3.3 (Internal version 11.35)

```bat
<Public LAN>
 |
 | <Private LAN>
 |  |
 |  |  +--------------------------------+
 +-----| Primary Server                 |
 |  |  |  Windows Server 2003 SP1       |
 |  |  |  EXPRESSCLUSTER X 3.3          |
 |  +--|  SQL Server 2005               |
 |  |  +--------------------------------+
 |  |
 |  |  +--------------------------------+
 +-----| Secondary Server               |
 |  |  |  Windows Server 2003 SP1       |
 |  |  |  EXPRESSCLUSTER X 3.3          |
 |  +--|  SQL Server 2005               |
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

## Sample cluster configuration
- failover group
	- fip
	- md
		- Cluster Partition: E drive (17MB, RAW)
		- Data Partition: F drive (The database is saved here)
	- service_sql
		- For SQL Server (MSSQLSERVER) service
	- script_sql
		- For database attachment/detachment
	- service_sqlagent
		- For SQL Server Agent (MSSQLSERVER) service
- monitor
	- fipw
	- mdw
	- mdnw
	- servicew1
	- servicew2
	- userw
	- sqlserverw **(if you have EXPRESSCLUSTER X Database Agent Lincense)**

## Setup

### Install ECX and create a basic cluster
- Create a failover group including the following resources.
	- Floating IP resource
	- Mirror Disk resource
		- The database will be created later on this partition.

### Install SQL Server 2005 on both nodes
- Components to Install
	- **SQL Server Database Services** is mandatory.
	- It is recommended that the entire feature of **Client Components** in **Advance** is installed as client's database connection method.
- Instance Name
	- **Default instance**
- Service Account
	- **Use the built-in System account: Local system**
- Authentication Mode
	- **Mixed Mode**
- After the installation, change the startup type of SQL Server services to **Manual**.
	- You can change the startup type on Windows Service Manager.

### Create the database on the md **(On Primary server)**
1. Add an environmental variable of sqlcmd.exe.
	- System variables Path: *C:\Program Files\Microsoft SQL Server\90\Tools\Binn*
1. Create folders for a database on the md.
	- e.g.: *F:\\sql\\data*
1. Login to SQL Server on Command Prompt.
	
	e.g.
	```
	> sqlcmd /S localhost /U sa /P password
	```
1. Create a database on the md.

	After the following commands, the database **testdb** is created on *F:\\sql\\data*, that is composed of 10MB data file **(testdb_Data.MDF)** and 10MB log file **(testdb_Log.LDF)**.
	```
	1> create database testdb
	2> on PRIMARY
	3> (
	4> NAME= 'testdb_Data',
	5> FILENAME='Y:¥sql¥data¥testdb_Data.MDF',
	6> SIZE=10
	7> )
	8> LOG ON
	9> (
	10> NAME='testdb_Log'
	11> FILENAME='Y:¥sql¥data¥testdb_Log.LDF',
	12> SIZE=10
	13> )
	14> GO
	1> checkpoint
	2> GO
	```

### Create SQL scripts with a text editor **(On Both servers)**

Cluster nodes need to attach or detach the database at the timing of failover.
You need to create the scripts for attach/detach of database.

1. Create ACT.SQL

	e.g.
	```
	exec sp_attach_db 'testdb',
	  @filename1='F:\sql\data\testdb_Data.MDF',
	  @filename2='F:\sql\data\testdb_Log.LDF'
	```
1. Create DEACT.SQL

	e.g.
	```
	Alter database [testdb] set offline with ROLLBACK IMMEDIATE
	exec sp_detach_db 'testdb',TRUE
	```
1. Copy both files to *C:\mssql*.

### Create EXPRESSCLUSTER resources
1. Stop all SQL Server services on Service Manager on both nodes.
1. Add the service resource for SQL Server service.
	- Service Name: SQL Server (MSSQLSERVER)
1. Add the script resource for database attachment/detachment.
	- Dependent Resources: The service resouce for SQL Server service.
	- start.bat

		e.g.
		```
		.
		.
		rem *************
		rem Routine procedure
		rem *************
		"c:\Program Files\Microsoft SQL Server\90\Tools\Binn\OSQL.EXE" /Usa /Ppassword /i c:\mssql\ACT.SQL /o c:\mssql\ACT.LOG
		.
		.
		rem *************
		rem Starting applications/services and recovering process after failover
		rem *************
		"c:\Program Files\Microsoft SQL Server\90\Tools\Binn\OSQL.EXE" /Usa /Ppassword /i c:\mssql\ACT.SQL /o c:\mssql\ACT.LOG
		.
		.
		```
	- stop.bat
		
		e.g.
		```
		.
		.
		rem *************
		rem Routine procedure
		rem *************
		"c:\Program Files\Microsoft SQL Server\90\Tools\Binn\OSQL.EXE" /Usa /Ppassword /i c:\mssql\DEACT.SQL /o c:\mssql\DEACT.LOG
		.
		.
		rem *************
		rem Starting applications/services and recovering process after failover
		rem *************
		"c:\Program Files\Microsoft SQL Server\90\Tools\Binn\OSQL.EXE" /Usa /Ppassword /i c:\mssql\DEACT.SQL /o c:\mssql\DEACT.LOG
		.
		.
		```
1. Add the service resource for SQL Server Agent service.
	- Dependency Resources: The script resource for database attachment/detachment
	- Service Name: SQL Server Agent (MSSQLSERVER)
1. Add the SQL Server monitor resource. **(if you have EXPRESSCLUSTER X Database Agent Lincense)**
	- Monitor Timing: Active
		- Target Resource: The script resource for database attachment/detachment
	- Database Name: testdb
	- Instance Name: MSSQLSERVER
	- User Name: SA
	- Password: The password of SA
	- Monitor Table Name: SQLWATCH
	- ODBC Driver Name: SQL Native Client

### Check SQL Server Cluster
#### On Primary Server
1. Confirm that the failover group is active normally on the server
1. Connect to SQL Server
	```bat
	> sqlcmd -S localhost -U sa -P password
	```
1. Create a test database and table and inser a value to it
	```bat
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

#### On Secondary Server
1. Confirm that the failover group is active normally on the server
1. Connect to SQL Server
	```bat
	> sqlcmd -S localhost -U sa -P password
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
1. Move the failover group to Primary Server
