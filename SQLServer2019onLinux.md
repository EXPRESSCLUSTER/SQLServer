# SQL Server on Linux cluster Quick Start Guide

## System configuration
- Servers: 2 node with Mirror Disk
- OS: Cent OS 7.6 (3.10.0-957.el7.x86_64)
- EXPRESSCLUSTER: X4.1

## Cluster configuration
- failover group
	- fip
	- md
		- Mount Point: /mnt/md-sql
		- Data Partition: /dev/sdb2
		- Cluster Partition: /dev/sdb1
	- exec
		- start.sh
		- stop.sh

## Setup
### Setup a basic cluster
#### On both servers
1. Install EXPRESSCLUSTER X and register licenses
1. Reboot the server
#### On Primary Server
1. Create a cluster
1. Add one failover group with fip and md resources
	- failover group
		- fip
		- md
			- Mount Point: /mnt/md-sql
			- Data Partition: /dev/sdb2
			- Cluster Partition: /dev/sdb1
1. Apply the configuration
1. Start the failover group on Primary Server

### Install SQL Server
#### On both servers
1. Confirm that the failover group is active on the server  
	```bat
	# clpstat
	```
1. Register SQL Server repository  
	```bat
	# curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2019.repo
	```
1. Install SQL Server  
	```bat
	# curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2019.repo
	```
1. Register SQL Server license and set SA password  
	\* For evaluation, you can select 2) Developer license
	```bat
	# /opt/mssql/bin/mssql-conf setup

	usermod: no changes
	Choose an edition of SQL Server:
	  1) Evaluation (free, no production use rights, 180-day limit)
	  2) Developer (free, no production use rights)
	  3) Express (free)
	  4) Web (PAID)
	  5) Standard (PAID)
	  6) Enterprise (PAID) - CPU Core utilization restricted to 20 physical/40 hyperthreaded
	  7) Enterprise Core (PAID) - CPU Core utilization up to Operating System Maximum
	  8) I bought a license through a retail sales channel and have a product key to enter.

	Details about editions can be found at
	https://go.microsoft.com/fwlink/?LinkId=852748&clcid=0x409

	Use of PAID editions of this software requires separate licensing through a
	Microsoft Volume Licensing program.
	By choosing a PAID edition, you are verifying that you have the appropriate
	number of licenses in place to install and run this software.

	Enter your edition(1-8): 2
	The license terms for this product can be found in
	/usr/share/doc/mssql-server or downloaded from:
	https://go.microsoft.com/fwlink/?LinkId=855862&clcid=0x409

	The privacy statement can be viewed at:
	https://go.microsoft.com/fwlink/?LinkId=853010&clcid=0x409

	Do you accept the license terms? [Yes/No]:yes

	Enter the SQL Server system administrator password:
	Confirm the SQL Server system administrator password:
	Configuring SQL Server...

	ForceFlush is enabled for this instance.
	ForceFlush feature is enabled for log durability.
	Created symlink from /etc/systemd/system/multi-user.target.wants/mssql-server.service to /usr/lib/systemd/system/mssql-server.service.
	Setup has completed successfully. SQL Server is now starting.
	```
1. Confirm SQL Server service is started  
	```bat
	# systemctl status mssql-server
	```
1. Register sqlcmd tool repository  
	```bat
	# curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
	```
1. Install sqlcmd tool  
	```bat
	# yum install -y mssql-tools unixODBC-devel
	```
1. Add environment valiables  
	```bat
	# echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
	# echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
	# source ~/.bashrc
	```
1. Stop SQL Server service  
	```bat
	# systemctl stop mssql-server
	```
1. Move the falover group to the other server  
	```bat
	# clpgrp -m
	```

### Move SQL Server database to Mirror Disk
#### On Primary Server
1. Confirm that the failover group is active on the server  
	```bat
	# clpstat
	```
1. Confirm that SQL Server service is stopped  
	```bat
	# systemctl status mssql-server
	```
1. Create directories for SQL Server database on Mirror Disk and change their owner  
	```bat
	# mkdir /mnt/md-sql/data
	# chown mssql /mnt/md-sql/data
	# chgrp mssql /mnt/md-sql/data
	# mkdir /mnt/md-sql/log
	# chown mssql /mnt/md-sql/log
	# chgrp mssql /mnt/md-sql/log
	# mkdir /mnt/md-sql/masterdatabasedir
	# chown mssql /mnt/md-sql/masterdatabasedir
	# chgrp mssql /mnt/md-sql/masterdatabasedir
	```
1. Edit SQL Server database locations from the default to the new directories  
	```bat
	# /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /mnt/md-sql/data
	# /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /mnt/md-sql/log
	# /opt/mssql/bin/mssql-conf set filelocation.masterdatafile /mnt/md-sql/masterdatabasedir/master.mdf
	# /opt/mssql/bin/mssql-conf set filelocation.masterlogfile /mnt/md-sql/masterdatabasedir/mastlog.ldf
	```
1. Move master database and log files from the default to the new directories  
	```bat
	# mv /var/opt/mssql/data/master.mdf /mnt/md-sql/masterdatabasedir/master.mdf
	# mv /var/opt/mssql/data/mastlog.ldf /mnt/md-sql/masterdatabasedir/mastlog.ldf
	```
1. Start SQL Server service and confirm it starts normally  
	```bat
	# systemctl start mssql-server
	# systemctl status mssql-server
	```
1. Stop SQL Server service  
	```bat
	# systemctl stop mssql-server
	```
1. Move the failover group to the other server  
	```bat
	# clpgrp -m
	```
#### On Secondary Server
1. Confirm that the failover group is active on the server  
	```bat
	# clpstat
	```
1. Confirm that SQL Server service is stopped  
	```bat
	# systemctl status mssql-server
	```
1. Change permission of directories for SQL Server database on Mirror Disk  
	```bat
	# chown mssql /mnt/md-sql/data
	# chgrp mssql /mnt/md-sql/data
	# chown mssql /mnt/md-sql/log
	# chgrp mssql /mnt/md-sql/log
	# chown mssql /mnt/md-sql/masterdatabasedir
	# chgrp mssql /mnt/md-sql/masterdatabasedir
	```
1. Edit database locations  
	```bat
	# /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /mnt/md-sql/data
	# /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /mnt/md-sql/log
	# /opt/mssql/bin/mssql-conf set filelocation.masterdatafile /mnt/md-sql/masterdatabasedir/master.mdf
	# /opt/mssql/bin/mssql-conf set filelocation.masterlogfile /mnt/md-sql/masterdatabasedir/mastlog.ldf
	```
1. Start SQL Server service and confirm it starts normally  
	```bat
	# systemctl start mssql-server
	# systemctl status mssql-server
	```
1. Stop SQL Server service  
	```bat
	# systemctl stop mssql-server
	```
1. Move the failover group to the other server  
	```bat
	# clpgrp -m
	```

### Setup SQL Server cluster
#### On Primary Server
1. Add one exec resource to the failover group
	- failover group
		- exec
			- start.sh: Refer a sample script
			- stop.sh: Refer a sample script
1. Apply the configuration
1. Start the exec resource
### Replication Test
#### On Primary Server
1. Confirm that the failover group is active normally on the server  
	```bat
	# clpstat
	```
1. Connect to SQL Server  
	```bat
	# sqlcmd -S localhost -U SA -P <password>
	```
1. Create a test database and table and inser a value to it  
	```
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
	1> exit
	```
1. Move the failover group to the other server  
	```bat
	# clpgrp -m
	```
#### On Secondary Server
1. Confirm that the failover group is active normally on the server  
	```bat
	# clpstat
	```
1. Connect to SQL Server  
	```bat
	# sqlcmd -S localhost -U SA -P <password>
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
	1> exit
	```
1. Move the failover group to the other server  
	```bat
	# clpgrp -m
	```

## Sample scripts
### start.sh
```bat
#! /bin/sh
#***************************************
#*              start.sh               *
#***************************************

#ulimit -s unlimited

systemctl start mssql-server

exit $?
```
### stop.sh
```bat
#! /bin/sh
#***************************************
#*              start.sh               *
#***************************************

#ulimit -s unlimited

systemctl stop mssql-server

exit $?
```
