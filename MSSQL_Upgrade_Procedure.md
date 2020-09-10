A) In the case that masterdb is stored on local disk (*)
 * You can confirm the path by:
	- Start SQL Server Configuration Manager
	- Select "SQL Server Services"
	- Right click "SQL Server (<Instance name>)" and select Properties
	- Go to "Startup Parameters" tab    
<Preparatoin>
1. Backup Database on Active Server
2. Confirm that cluster staus is normal and group is active on Primary Server.
3. Change the following cluster setting to disable Recovery Action while SQL Server upgrading.
	- Cluster Properties
	  -> Recovery tab
	  -> Disable Recovery Action Caused by Monitor Recource Failure: Check
	- Apply cluster configuration
<Upgrade>
1. Stop a resource which controls SQL Server Instance Service.
2. Upgrade SQL Server on Primary Server.
3. If reboot is required, reboot Primary Server.
   If not required, move failover group to Secondary Server.
4. Upgrade SQL Server on Secondary Server.
5. If reboot is required, reboot Secondary Server.
   If not required, move failover group to Primary Server.
6. If you use SQL monitor resource (*) and ODBC driver is upgraded, change the following setting:
	- SQL monitor Properties
	  -> Monitor(special) tab
	  -> Change "ODBC Driver Name"
	* SQL monitor is is available with DB Agent Option License:
		https://www.manuals.nec.co.jp/contents/system/files/nec_manuals/node/504/W42_RG_EN/W_RG_04.html#monitor-special-tab-sql-server-monitor-resources
7. Change the following setting:
	- Cluster Properties
	  -> Recovery tab
	  -> Disable Recovery Action Caused by Monitor Recource Failure: Uncheck
8. Apply the configuration.
B) In the case that masterdb is stored on Mirror Disk
<Preparation>
1. Backup Database on Active Server
2. Confirm that cluster staus is normal and group is active on Primary Server.
3. Change the following cluster setting to disable Recovery Action while SQL Server upgrading and auto failover group startup.
	- Cluster Properties
	  -> Recovery tab
	  -> Disable Recovery Action Caused by Monitor Recource Failure: Check
	- Failover group Propertis
	  -> Attribute tab
	  -> Startup Attribute
	  -> Select "Manual Startup"
	- Apply cluster configuration
<Procedure>
1. Stop a resource which controls SQL Server Instance Service.
2. Shutdown Secondary Server to stop mirroring. (*)
3. Upgrade SQL Server on Primary Server.
4. Shutdown Primary Server.
5. Boot Secondary Server.
6. Confirm that cluster service starts and Secondary Server status gets Online.
7. Execute the following command to open Mirror Disk on Secondary Server:
	mdopen <md resource name>
	-------------------
	Sample
	-------------------
	C:\Users\administrator>mdopen md
	Command succeeded.
	-------------------
8. Upgrade SQL Server on Secondary Server.
9. Shutdown Secondary Server
10. Boot both Primary and Secondary Servers.
11. Confirm that Fast Recovery runs and completes from Primary to Secondary Server.
12. Change the following cluster setting to disable Recovery Action while SQL Server upgrading and auto failover group startup.
	- Cluster Properties
	  -> Recovery tab
	  -> Disable Recovery Action Caused by Monitor Recource Failure: Check
	- Failover group Propertis
	  -> Attribute tab
	  -> Startup Attribute
	  -> Select "Manual Startup"
	- Apply cluster configuration
13. If you use SQL monitor resource (*) and ODBC driver is upgraded, change the following setting:
	- SQL monitor Properties
	  -> Monitor(special) tab
	  -> Change "ODBC Driver Name"
	* SQL monitor is is available with DB Agent Option License:
		https://www.manuals.nec.co.jp/contents/system/files/nec_manuals/node/504/W42_RG_EN/W_RG_04.html#monitor-special-tab-sql-server-monitor-resources
14. Change the following setting:
	- Cluster Properties
	  -> Recovery tab
	  -> Disable Recovery Action Caused by Monitor Recource Failure: Uncheck
	- Failover group Propertis
	  -> Attribute tab
	  -> Startup Attribute
	  -> Select "Manual Startup"
	- Apply cluster configuration
    
C) Common Solution
1. Backup Database on Active Server.
2. Confirm that cluster staus is normal and group is active on Primary Server.
3. Stop the Failover Group then start Mirror Disk resource only.
4. Shutdown Secondary Server to stop mirroring.
5. Upgrade SQL Server on Primary Server.
6. Shutdown Primary Server.
7. Boot Secondary Server.
8. Confirm that cluster service started and status online in Secondary Server.
9.  You will find crashed Mirror disk resource then stop the failover group  
10. Marked the latest data on secondary server.
        - Right click on Mirror disk and select Details.
	 > Select Mirror Disk icon of Secondary server in Mirror disk helper.
 	 > Click on Execute. 
	 > Close.
11.  Start the Mirror Disk resource on secondary server.
12.  Update MSSQL server on secondary server.
13.  Restart the secondary server by the help of ECX web manger.
14.  After restarted secondary server wait till get online in ECX web manager.
15.  When you find the failover group is online then check MSSQL databases.
16.  Boot the Primary server.
17.  Check fast recovery of mirror disk completed automatically.
18.  Then move the failover group from secondary server to primary server.
19.  Check the SQL database.