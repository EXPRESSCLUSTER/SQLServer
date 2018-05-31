# EXPRESSCLUSTER X Quick Start Guide for MS SQL Server on Linux (FCI Configuration)

1. Overview

	This guide describes a way to build two nodes (active standby) SQL Server Always On FCI (Failover Cluster Instances) configuration by ECX.

2. System Requirements and Planning

	1. Versions used on verification

		- mssql-server-14.0.3006.16-3.x86_64
		- mssql-tools-14.0.6.0-1.x86_64
		- EXPRESSCLUSTER X 3.3.5-1
		- CentOS 7.4 (kernel-3.10.0-693.el7.x86_64)

	2. License Requirements

		| Products	| Qty	|
		| ----		| ----	|
		| SQL Server 2017 on Linux		| 2 |
		| EXPRESSCLSTER X 3.3			| 2 |
		| EXPRESSCLSTER X Database Agent 3.3	| 2 |

	3. Server Requirements

		System Requirements
		- Machine 1: Primary Server
		- Machine 2: Standby Server
		- Machine 3: Client Machine
		- Storage as per user requirement

		|		| Machine 1 Primary Server<br>Machine 2 Standby Server	| Machine 3 Client Machine	|
		| ---		| ---							| ---				|
		| CPU		| Processor cores : 2 cores x64				| Pentium 4 -  3.0 GHz or better|
		| Memory	| 2GB or more						| 512 MB or more		|
		| Disk 		| 1 physical disk<br>OS partition: 20GB or more space available(to include the installation of MSSQL Database Server)| 1 physical disk with 20 GB or more space available |
		| OS		| Linux	| Windows XP or later	|
		| Software	| Java 1.5(or later) enabled web browser	| Java 1.5(or later) enabled web browser	|
		| Network	| 2 100Mbit or faster Ethernet NIC	| 1 100Mbit or faster Ethernet NIC |

	4. System Planning

		Review the requirements from the last section and then fill out the tables of the worksheet below. Use for reference in the following sections of this guide. See Appendix B for an example worksheet.

		- Machine 1 Primary Server
		- Machine 2 Standby Server
		- Machine 3 Client Machine

		Table 1: System Network Configuration

		| Machine | Host name | Network Connection | IP Address | Subnet Mask | Default Gateway | DNS Server |
		| ---	| ---	| ---	| ---	| ---	| ---	| ---	|
		| 1	|	| Public:<br><br>Interconnect:<br><br>	|	|	|	|	|
		| 2	|	| Public:<br><br>Interconnect:<br><br>	|	|	|	|	|
		| 3	|	|                                     	|	|	|	|	|


		- Floating IP (FIP) address:
		- Management IP address:

		Table 2: System OS and Disk Configuration

		| Machine	| OS	| Disk 0 (OS Disk)		| Disk 1 (Data Disk)	|
		| ----		| ----	| ----				| ----			|
		| 1		|	| Boot Partition :<br>Size :	| * Data Partition :<br> Size : |
		| 2		|	| Boot Partition :<br>Size :	| Shared with Machine 1 |
		| 3		|	|				||

		\* The size must be large enough to store all data, and log files for a given MSSQL Database to meet current and expected future needs.

		Table 3: System Logins and Passwords

		| 				| Login	| Password	|
		| ----				| ----	| ----	|
		| Machine 1 administrator	|	|	|
		| Machine 2 administrator	|	|	|
		| Machine 3 administrator	|	|	|

3. Base System Setup

	If necessary, install required hardware components and a supported OS as specified in Chapter 2.

	1. Setup the Primary Server (Machine 1)
		1. Verify basic system boot and root login functionality and availability of required hardware components as specified in Chapter 2.
		2. Configure network interface names
			1. Rename the network interface to be used for network communication with client machine to Public.
			2. Rename the network interface to be used for internal EXPRESSCLUSTER X management and data mirroring network communication between servers to Interconnect.
		3. Configure Network
			1. In the `System` tab go to `Administration` further go to `Network`.
			2. In the Network Connections window, double-click Public.
			3. In the dialog box, click the statically set IP address: option button.
			4. Type the IP address, Subnet mask, and Default gateway values (see Table 1).
			5. Go back to the Network Connections window. Double-click Interconnect.
			6. In the dialog box, click the statically set IP address: option button.
			7. Type the IP address and Subnet mask values (see Table 1).
			8. Click OK.
			9. On the terminal, run the command `service network restart`.

	2. Setup the Standby Server (Machine 2)
		- Perform above steps in *Chapter 3* on the Standby Server.

4. MSSQL Server Installation

	Installing MSSQL on Primary Server and Secondary Server

	1. Install and configure SQL Server 2017 as per requirement of the client/customer.

		1. Download the Microsoft SQL Server repository configuration file

			https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo

		2. Install MSSQL Server , Run the command

				sudo yum install -y mssql-server

		3. Set up password and Version

				sudo /opt/mssql/bin/mssql-conf

		4. To check mssql status

				systemctl status mssql-server

		5. Allow port in running firewall

				sudo firewall-cmd --zone=public --add-port=1433/tcp -permanent
				sudo firewall-cmd -reload

	2. MSSQL server command line tools installation

		1. Run Command

				sudo curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo

			remove if already installed

				sudo yum remove unixODBC-utf16 unixODBC-utf16-devel

		2. now install mssql-tools with unixodbc developer package

				sudo yum install -y mssql-tools unixODBC-devel

		3. enter path in the bash profile and bashrc file

				echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
				echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
				source ~/.bashrc

		4. Run this command to make MSSQL command can be fond more simply

				sudo ln -s /opt/mssql-tools/bin/* /usr/local/bin/

5. ECX Installation

	1. Install EXPRESSCLUSTER on the Primary & Standby Server (Machine 1&2)

		1. Install the EXPRESSCLUSTER Server RPM on all server(s) that constitute the cluster by following the procedures below.

		**Note**: Log in as root user when installing the EXPRESSCLUSTER Server RPM.

		2. Mount the installation CD-ROM.

		3. Run the rpm command to install the package file. The installation RPM varies depending on the products Navigate to the folder, /Linux/3.0/en/server, in the CD-ROM and run the following:

				rpm -i expresscls-[version].[architecture].rpm

		4. When the installation is completed, unmount the installation CD-ROM.

		5. License Registration: Log on to the master server as root user and run the following command.

				clplcnsc -i <filepath> -p <PRODUCT-ID>

			When the command is successfully executed, the message "Command succeeded." is displayed in the console

			**Note**: Here, specify the filepath to the license file by the -i option & the productID by the -p option.

			For Base License: Enter the product ID as BASE33.  Here 33 is the EC version & this number will vary as per the EC deployed. Example for EC2.1 version, command param would become BASE21. The Base license needs to be applied on only one server

			**Note**: For registering the license from the command line refer to EXPRESSCLUSTER, Installation and Configuration Guide.

	2. Restart the Primary and Standby Servers (Machines 1 & 2)

	First restart the Primary Server and then restart the Standby Server

6. ISCSI Target and Initiator configuration 

	1. ISCSI Target Configuration

		Configure the storage to be used as the Target Server.

	2. ISCSI Target Configuration

		Use the Primary Server and Secondary server as the Initiator 1 and 2 respectively

7. Base Cluster Setup

	This chapter describes the steps to create a cluster using EXPRESSCLUSTER Manager running on the Management Console/ Client (Machine 3).

	Verify JRE v.1.5.0.6 or newer is installed on the Management Console/Test Client (Machine 3). If necessary, install JRE by performing the following steps:

	1. Install Java Runtime Environment (JRE)

		1. Run jre-1_5_0 <build and platform version>.exe (a compatible JRE distribution can be found in the jre folder on the EXPRESSCLUSTER CD).
		2. On the License Agreement screen, verify the default Typical setup option button is selected. Click Accept.
		3. On the Installation Completed screen, click Finish.

	2. Start the cluster manager

		The cluster manager is started by accessing port 29003 from the web browser of any of the nodes (Machine1 or Machine 2). Example: http://localhost:29003

	3. Create a cluster

		For all of the steps below, refer to Table 1 for the IP addresses and server names.

		1. When the cluster manager is opened for the first time, a pop up will appear which has three options. Click on "Start cluster generation wizard".
		2. A new window opens where the name of the cluster can be specified and cluster generation begins.
		3. Type a cluster name. Example: cluster
		4. Type the Management IP address and click Next.
		5. In the next window, the server on which the cluster creation has started is already added. Click Add to add another server to this cluster.
		6. Provide the hostname or the IP address of the second server and click OK.
		7. Now both servers will appear on the list. Click Next.
		8. EXPRESSCLUSTER X 3.3 automatically detects the IP addresses of the servers, which can be seen on this screen. Select the network to be used for the Heartbeat path as type Kernel Mode. If Mirroring is also occurring through the same network cards, then specify the Mirror connect settings in the respective network fields. Click the dropdown button on the "Mirror Disk Connect" and select the connect number (e.g.: mdc1). Click Next.
		9. For this guide, the NP resolutions resources are not configured. Click Next.

	4. Create a failover group

		For all of the steps below, refer to Table 1 for the IP addresses and server names. 

		1. Now the cluster generation wizard is in the groups section.
		2. Click Add to add a group.
		3. In the newly opened window, select the type of the group as Failover and give this group a name (e.g.:Failover_MSSQL ) and click Next and then click next.
		4. Leave the default options for the group attribute settings and click Next

	5. Create floating IP and disk resource

		1. Now in the group resources section of the Cluster generation wizard.
		2. Click on Add to add a resource.
		3. In the next window, to add a Floating IP Resource (FIP) select "floating ip resource" from the drop down list. Click Next.
		4. By default, the FIP resource is not dependent on any other resources. Follow the default dependency and click Next.
		5. Use the default options and click Next.
		6. Provide a floating IP address that is not used by any other network element. Click Finish.
		7. Again click Add to add a Disk Resource.
		8. In the next window, to add a Disk Resource. Select "Disk resource" from the drop down list. Click Next.
		9. Again, follow the default dependency. Click Next.
		10. Use the default options and click Next.
		11. Now in Common Tab Select Disk type as disk , In file system select file system type, in Device Name Select the UUID of Target disk which will be used as data partition, in Mount Point give the name of mount point that will be used to access target disk.
		12. Click Finish.
		13. To add FIP monitor, Right click on "Monitors" in web manager.
		14. Select "Add monitor resource"
		15.  Select FIP monitor from type drop down and give name to the monitor resource (eg. fipw_monitor) and click Next.
		16. In the Target resource field. Click on Browse. Select the FIP resource and click OK. Click Next.
		17. In the Recovery target field, click Browse. Now click on Failover group and click OK.
		18. Click Finish to add the FIP monitor resource.

	6. Upload the cluster configuration and initialize the cluster

		1. In the Cluster Manager window, to apply the configuration, click the File menu and then apply the Configuration File.
		2. After the upload is completed, change the mode of the Cluster Manager to Operation Mode.
		3. Restart Cluster Manager and start the cluster. Click on the Service menu and then click on Start Cluster.
		4. In the Cluster Manager window, all icons in the tree view should now be green


[Figure 1](fig1.jpg) Live cluster


8. MSSQL Cluster Setup

	1. Change the group and user permissions of the disk resource mount point

		1. Change the owner and group of the mount point for the disk resource.

				sudo chown mssql:mssql /mssql/data/

			/mssql/data is mount point of the shared storage.

		2. Use mssql-conf to change the default data directory with the set command

				sudo /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /mssql/data

		3. Restart the SQL Server service

				sudo systemctl restart mssql-server

	To configure MSSQL Database server cluster we will configure its service with EXPRESSCLUSTER. Change the default path of the database to a path on the data partition.

	2. Change the default master database file directory location

		Use mssql-conf to change the default master database directory

			sudo /opt/mssql/bin/mssql-conf set filelocation.masterdatafile /mssql/data/master.mdf
			sudo /opt/mssql/bin/mssql-conf set filelocation.masterlogfile /mssql/data/mastlog.ldf

	3. Move the master.mdf and master.ldf

		1. Stop the MSSQL Server Service

				sudo systemctl stop mssql-server
				sudo mv /var/opt/mssql/data/master.mdf /mssql/data/master.mdf
				sudo mv /var/opt/mssql/data/mastlog.ldf /mssql/data/mastlog.ldf

		2. Start the MSSQL Service

				sudo systemctl start mssql-server

	4. Cluster Configuration Setup

		Adding a Service resource

		1. On Cluster Builder (Config Mode), in the tree view, under Groups, right-click failover and then click Add Resource.
		2. In the "Group Resource Definitions" window, for Type, select execute resource from the pull-down box. For Name, use the default (exec). Click Next.
		3. On next window, make sure "Follow the default dependency" check box is checked and click NEXT.
		4. On next window "Recovery Operation at Deactivation Failure Detection", make the final action as "No Operation (deactivate next resource)" and click NEXT.
		5. In the next window edit the start.sh file and replace the source with source code shown below.
		6. In the same window select the stop.sh file and edit the stop.sh file and replace the source with scripts shown as below and click FINISH.

			Start Script

				#/bin/bash
				sudo systemctl start mssql-server

			Stop Script

				#/bin/bash
				sudo systemctl stop mssql-server

		Adding a Service resource

		1. On Cluster Builder (Config Mode), in the tree view, under Groups, right-click failover and then click Add Resource.
		2. In the "Group Resource Definitions" window, for Type, select execute resource from the pull-down box. For Name, use the default (exec). Click Next.
		3. On next window, make sure "Follow the default dependency" check box is checked and click NEXT.
		4. On next window "Recovery Operation at Deactivation Failure Detection", make the final action as "No Operation (deactivate next resource)" and click NEXT.
		5. In the next window edit the start.sh file and replace the source with source code shown below.
		6. In the same window select the stop.sh file and edit the stop.sh file and replace the source with scripts shown below and click FINISH.
		7. The below scripts will login and logout from the primary and secondary servers.

			Start Script

				#/bin/bash
				iscsiadm --mode node --targetname iqn.2003-01.org.linux-iscsi.target.x8664:sn.6dee7f95da33 --portal 10.0.7.118 --login

			Stop Script
		
				#/bin/bash
				iscsiadm --mode node --targetname iqn.2003-01.org.linux-iscsi.target.x8664:sn.6dee7f95da33 --portal 10.0.7.118 --logout

		`10.0.7.118` is IP address of iSCSI target server in the above scripts.

9. Final Deployment in a LAN Environment

	This chapter describes the steps to verify a LAN infrastructure and to deploy the cluster configuration on the Primary and the Secondary servers

	1. Configure and verify the connection between the Primary and Standby servers to meet the following requirements
		- Two logically separate IP protocol networks: one for the Public Network and one for the Cluster Interconnect.
		- The Public Network must be a single IP subnet that spans the Primary and Standby servers to enable transparent redirection of the client connection to a single floating server IP address. 
		- The Cluster Interconnect should be a single IP subnet that spans the Primary and Standby servers to simplify system setup.
		- A proper IP network between client and server machines on the Public Network on both the Primary and Standby servers.
	2. Make sure that the Primary server is in active mode with a fully functional target application and the Standby Server is running in passive mode.
	3. Ping both the Primary and Secondary servers from the test system and make sure the Secondary server has all the target services in manual and stopped mode.
	4. Start the cluster and try accessing the application from the Primary server. Then move the cluster to the Secondary server. Check the availability of the application on the Secondary server after failover.
	5. Deployment is completed.

10. Common Maintenance Tasks

	This chapter describes how to perform common EXPRESSCLUSTER maintenance tasks using the EXPRESSCLUSTER Manager.

	1. Start Cluster Manager

		There are two methods to start/access Cluster Manager through a supported Java enabled web browser. The first method is through the IP address of the physical server running the cluster management server application. The second method is through the floating IP address for a cluster management server within a cluster.

		1. The first method is typically used during initial cluster setup before the cluster management server floating IP address becomes effective

			1. Start Internet Explorer or another supported Java enabled Web browser.
			2. Type the URL with the IP address of the active physical server followed by a colon and the cluster management server port number.

			Example:
			Assuming that the cluster management server is running on an active physical server with an IP address (e.g.: 10.1.1.1) on port number 29003, enter http://10.1.1.1:29003/

		2. The second method is more convenient and is typically used after initial cluster setup

			1. Start Internet Explorer or another supported Java enabled Web browser.
			2. Type the URL with the cluster management server floating IP address followed by a colon and the cluster management server port number.

			Example:
			Assuming that the cluster management server is running with a floating IP address (10.1.1.3) on port 29003, enter http://10.1.1.3:29003/.

	2. Reboot/shutdown one or all servers

		1. Reboot all servers

			1. Start Cluster Manager. (Chapter 10, Section 1)
			2. On the left hand side, right click on Cluster name and choose "Reboot".

		2. Shutdown all servers

			- Same as "Reboot all servers", except in step 2 click Shutdown.

		3. Shutdown one server

			1. Start Cluster Manager.( Chapter 10, Section 1)
			2. Right-click the %machine name% and click Shutdown.
			3. In the Confirmation window, click OK.
			4. Right-click the %cluster name% and click Reboot.
			5. In the Confirmation window, click OK.

	3. Startup/stop/move failover groups

		1. Start Cluster Manager.( Chapter 10, Section 1)
		2. Under Groups, right-click the Failover group and then click Start/Stop/Move.
		3. In the Confirmation window, click OK.

	4. Isolate a server for maintenance

		1. Start Cluster Manager. (Chapter 10, Section 1)
		2. In the Cluster Manager window, change to Config Mode.
		3. Click the %cluster name% and then right-click Properties.
		4. Click the Auto Recovery tab. To manually return the server to the cluster, select Off for the Auto Return option. Otherwise, leave it set to On for automatic recovery when the server is turned back on. Click OK.
		5. If a change was made, upload the configuration file.
		6. Shut down the server to be isolated for maintenance.
		7. The server is now isolated and ready for maintenance tasks.

	5. Return an isolated server to the cluster

		Start with the server that was isolated in the steps listed above ("Isolate a server for maintenance").

		1. Automatic Recovery

			1. Turn the machine back on.
			2. Recovery starts automatically to return the server to the cluster.

		2. Manual Recovery

			1. Turn the machine back on and wait until the boot process has completed.
			2. Start Cluster Manager.
			3. In the Cluster Manager window, right click the name of the server which was isolated and select Recover. The server which was isolated will return to the cluster.

11. Appendix A: EXPRESSCLUSTER X Server Un-installation

	Follow the steps below to uninstall EXPRESSCLUSTER from each of the server systems.
	
	1. On the Management Console/Client, in Cluster Manger (Operation Mode), under Groups, right-click Failover and then click STOP.
	2. Close Cluster Manger window.
	3. On the server system that you are starting the uninstall process for EXPRESSCLUSTER, stop all EXPRESSCLUSTER services. To stop all services, follow the steps below

		1. On the terminal stop the following services by running the below commands

				service clusterpro stop
				service clusterpro_md stop
				service clusterpro_evt stop
				service clusterpro_trn stop
				service clusterpro_alertsync stop
				service clusterpro_webmgr stop

		2. On the terminal run the below specified command:

				rpm -e expresscls-[version].[architecture].rpm

		3. Restart the machine.

	This completes the uninstall process for an individual server system.

	**Note**: You must be logged on as a root or an account with administrator privileges to uninstall Express Cluster Server.

	If a shared disk is used, unplug all disk cables connected to the server after un-installation is completed.

12. Appendix B: Example System Planning Worksheet

	- Machine 1 Primary Server
	- Machine 2 Standby Server
	- Machine 3 Client Machine

	Table 1: System Network Interfaces

	| Machine | Host name | Network Connection | IP Address | Subnet Mask | Default Gateway | DNS Server |
	|--- |--- |--- |--- |--- |--- |--- |
	| 1  | Primary | Public<br>Interconnect | 10.1.1.1<br>192.168.1.1 | 255.255.255.0<br>255.255.255.0 | 10.1.1.3<br>__________ | 10.1.1.3<br>__________ |
	| 2  | Standby | Public<br>Interconnect | 10.1.1.2<br>192.168.1.2 | 255.255.255.0<br>255.255.255.0 | 10.1.1.3<br>__________ | 10.1.1.3<br>__________ |


	Table 2: System OS and Disks

	| Machine | OS | Disk 0 (OS Disk) | Disk 1 (Data Disk) |
	|--- |--- |--- |--- |
	| 1  | Linux | Boot Partition: /dev/sda1<br>Size: 75GB | * Cluster Partition: /dev/sdb1<br>Size: 24MB<br>Data Partition: /dev/sdc1<br>Size: 50GB |
	| 2  | Linux | Boot Partition: /dev/sda1<br>Size: 75GB | Same as Machine 1 |
	| 3  | Win XP SP1 or later | C: 20 GB ||

	\* Must be a raw partition and larger than 17MB.

	Floating IP (FIP) address:

	Web Management Console FIP:      (1) 10.0.7.125

	Table 3: System Logins and Passwords

	|       | Login | Password |
	|---    | ---   |---       |
	| Machine 1 Administrator | root | admin1234 |
	| Machine 2 Administrator | root | admin1234 |
	| MSSQL DB Administrator  | root | admin1234 |
