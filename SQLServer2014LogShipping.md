# SQL Server 2014 Log Shipping Cluster

## Evaluation Environment
```
+--------------------------+
| Active Directory         |
| - Windows Server 2012 R2 |
+--------------------------+
 |
 |  +---------------------------+
 +--| Primary Node #1           |
 |  | - Windows Server 2012 R2  |
 |  | - SQL Server 2014         |
 |  | - EXPRESSCLUSTER X 4.0/3.3|
 |  +---------------------------+
 |
 |  +---------------------------+
 +--| Primary Node #2           |
 |  | - Windows Server 2012 R2  |
 |  | - SQL Server 2014         |
 |  | - EXPRESSCLUSTER X 4.0/3.3|
 |  +---------------------------+
 |
 |  +---------------------------+
 +--| Standby Node              |
    | - SQL Server 2014         |
    +---------------------------+
```

### Active Directory
### Primary Nodes
* Windows Server 2012 R2 Datacenter
* SQL Server 2014 Enterprise
* EXPRESSCLUSTER X 4.0/EXPRESSCLUSTER X 3.3
### Standby Node
* Windows Server 2012 R2 Datacenter
* SQL Server 2014 Enterprise
