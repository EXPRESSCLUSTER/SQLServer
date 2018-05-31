# SQL Server 2016 Reporting Service clustere
## About This Guide
This guide provides how to integrate SQL Server 2016 Reporting Service (SSRS) with EXPRESSCLUSTER X and create SSRS cluster.
The guide assumes its readers to have EXPRESSCLUSTER X basic knowledge and setup skills.

## System Overiew
### System Requirement
- 2 servers are required.
- Both servers are required to be communicatable with each other with their IP address.
- 1 shared storage which is connected to and shared by both the servers is requred.
- At least 2 partitions are required on the shared storage.
  - One is for DBs and its volume size depends on DB sizing.
  - Other is for Disk NP and its volume size is 17MB.
- SQL Server 2014 are required for both servers.

### System Configuration
- OS: Windows Server 2016 Standard
- SQL Server: MS SQL Server 2016 Standard
- EXPRESSCLUSTER X: 3.3 or 4.0

```bat
<LAN>
 |
 |  +----------------------------+
 +--| Primary Server             |         +----------------+
 |  | - Windows Server 2016      |  (FC)   |                |
 |  | - SQL Server 2016          +=========+                |
 |  | - EXPRESSCLUSTER X 4.0/3.3 |         |                |
 |  +----------------------------+         |                |
 |                                         | Shared Storage |
 |  +----------------------------+         |                |
 +--| Secondary Server           |         |                |
 |  | - Windows Server 2016      +=========+                |
 |  | - SQL Server 2016          |  (FC)   |                |
 |  | - EXPRESSCLUSTER X 4.0/3.3 |         +----------------+
 |  +----------------------------+
 |
```

## System setup
### Basic cluster setup
#### On Primary and Secondary servers  
1. Install EXPRESSCLUSTER (ECX)  
2. Register ECX licenses  

#### On Primary server  
3. Create a cluster and a failover group
  - NP:  
    Disk NP
  - Group:  
    group
  - Resource:  
    fip  
    sd
4. Start group on Primary server  

### SQL Server and SSRS installation
#### On Primary server
5. Install SQL Server
  - Feature Rules:  
    Select "Database Engine Services" and "Reporting service-Native"
  - Server Configuraiton:  
    Set "Manual" for service startup tyeps which will be clustered.  
      (e.g. SQL Server Database Engine and SQL Server Agent)
  - Database Engine Configuration:  
    Add accounts which will be used from both Primary and Secondary server  
      (e.g. domain user for Windows authentication or sa account for SQL authentication)  
    Set \<folder path which is on sd resource Data Partition\> for Data Root Directory
6. Move group to Secondary server

#### On Secondary server
7. Install MSSQL Server
  - Feature Rules:  
    Select "Database Engine Services" and "Reporting service-Native"
  - Instance Configuration:  
    Set the same name and instance ID for the instance as Primary server
  - Server Configuraiton:  
    Set Manual startup for services which will be clustered.  
      (e.g. SQL Server Database Engine and SQL Server Agent)
  - Database Engine Configuration:  
    Add accounts which will be used from both Primary and Secondary server  
      (e.g. domain user for Windows authentication or sa account for SQL authentication)  
    Set [folder path which is on sd resource Data Partition] for Data Root Directory
8. Move group back to Primary server

### SSRS Setup
#### On Primary server
9. Start SQL Server service and Reporting Services service
10. Start Reporting Service Configuration Manager and connect to the MSSQL Server instance
  - Service Account:  
      Apply the default settings  
  - Web Service URL:  
      Apply the default settings  
  - Database:  
      Select "Create a new report server database"  
      Select local server as a Database Server  
      Set Report Server Database Name.
  - Web Portal URL:  
      Apply the default settings
  - Encryption Key:  
      Backup key file and store it under \<folder path which is on sd resource Data Partition\>
11. Comfirm that you can connect to Report Server from a client
  - http://\<fip\>/Reports  
      http://\<fip\>/ReportServer
12. Stop SQL Server service and Reporting Services service
13. Move group to Secondary server  

#### On Secondary server
14. Start SQL Server service and Reporting Services service  
15. Copy Reporting Service parameter in config file from Primary Server to Secondary server.  
  - Config file path:  
    \<MSSQL Server installation path\>\MSRS13.MSSQLSERVER\Reporting Services\ReportServer
  - Config file name:  
    rsreportserver.config  
  - Target parameter:  
    Installation ID
16. Start Reporting Service Configuration Manager and connect to the MSSQL Server instance  
  - Service Account:  
    Apply the default settings  
  - Web Service URL:  
    Apply the default settings
  - Database:  
    Select "Choose an existing report server database"  
		Select local server as a Database Server  
		Select Report Server Database which was created in step 3.i.b.  
  - Web Portal URL:  
    Apply the default settings
  - Encryption Key:  
    Restore backup key file which was created in step 3.i.b.
17. Comfirm that you can connect to Report Server from a client  
  http://\<fip\>/Reports  
  http://\<fip\>/ReportServer
18. Stop SQL Server service and Reporting Services service  
19. Move group back to Primary server  

### MSSQL cluster setup
#### On Primary server
20. Add resources to group
  - service_sql
    - Target service:  SQL Server  
      Start/Stop:  synchronous
  - service_agent: MSSQL Server
    - Target service:  SQL Server Agent  
      Start/Stop:  synchronous
  - service_report:
    - Target service: SQL Server Reporting Services  
      Start/Stop:  synchronous
  - script:
    - start.bat:  
      Refer the appendix sample script.  
    - stop.bat:
      No need to set.
    - Start/Stop:
      synchronous
21. Change resource dependency as the below:
  - 0  fip  
    1  sd  
    2  service_sql  
    3  service_agent  
    4  service_report  
    5  script
22. Apply the configuration and confirm cluster behaviour.

## Appendix
### Sample scripts
#### start.bat:  
```bat
rskeymgmt -a -f <backup key file path> -p <password>  
  
if %ERRORLEVEL%=0 (  
 exit 0  
) else (  
 exit 1  
)  
```

### Reference
For more details about how to setup EXPRESSCLUSTER, please find [manuals](https://www.nec.com/en/global/prod/expresscluster/en/support/manuals.html).
