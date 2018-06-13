# 可用性グループクラスタ　構築ガイド
## 概要
本ガイドでは、CLUSTERPRO X による SQL Server 2017 on Linux 可用性グループクラスタを構築する手順を記載します。
CLUSTERPRO X の詳細については、[こちら](https://jpn.nec.com/clusterpro/clpx/index.html)を参照ください。
SQL Server 2017 on Linux の詳細については、Microsoft 社へお問い合わせください。

## System Overiew
### System Requirement
- 3 servers are required for AG cluster.
- 1 Ping NP target is required for AG cluster.
- All the servers and Ping NP target are required to be communicatable with each other with IP address.
- MSSQL Server for Linux and EXPRESSCLUSTER X are required to be installed on all servers.

### System Environment
- Server spec  
	- Mem: 4GB
	- CPU Core: 2 for 1 Socket
	- Disk: 20GB
	- OS: Cent 7.4 (3.10.0-693.21.1.el7.x86_64)
	```
- Software versions  
	- MS SQL Server 2017 on Linux
	- EXPRESSCLUSTER X 3.3.5-1
	```

## Cluster Overview
### Cluster Configuration
- Cluster Properties
	- NP Resolution:
		- Ping NP:  
			Used to avoid NP.
- Failover Group
	- Resurces
		- fip:  
			Used to connect AG database from Client.
		- exec:  
			Used to manage AG.
	- Monitor Resources
		- genw-ActiveNode:  
			Used to monitor Active Server AG role.
		- genw-SatndbyNode:  
			Used to monitor Standby Server AG role.
		- psw:  
			Used to moitor SQL Server service status.

### Assumptions
- For an access from client to PRIMARY replica, fip is used.
- AG replica on all servers should be operated by EXPRESSCLUSTER.

### Behavior
- When failover group is activated on a server, AG role of the server replica becomes PRIMARY.  
- When failover group is de-activated on a server, AG role of the server replica becomes SECONDARY.  
- When failover group is failed over, AG role of the source server replica becomes SECONDARY and role of the target server replica becomes PRIMARY.  

### Monitoring
- Active node role monitoring:  
	If replica role on Active server is demoted from PRIMARY to SECONDARY by other than EXPRESSCLUSTER operations, it is detected as an error and failover will occur.
- Standby node monitorng:  
	If replica role on Standby server role is promoted from SECONDARY to PRIMARY by other than EXPRESSCLUSTER operations, it is detected as an error and EXPRESSCLUSTER will demote it to SECONDARY.
- Active node service monitoring:  
	If mssql-server service on Active server is stopped by other than EXPRESSCLUSTER operations, it is detected as an error and failover will occur.
- Standby node service monitoring:  
	If mssql-server service on Standby server is stopped by other than EXPRESSCLUSTER operations, it is detected as an error but no action will occur.

## 構築
### SQL Server のダウンロードとインストール
#### 全サーバで行う
1. SQL Server 用のリポジトリをダウンロードする。  
	```bat
	# sudo curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo
	```
2. SQL Server をインストールする。  
	```bat
	# yum install -y mssql-server
	```
3. SQL Server のエディションを選択し、SA アカウントのパスワードを設定する。（評価用には2を選択する。）  
	```bat
	# /opt/mssql/bin/mssql-conf setup
	```
4. SQL Server サービスが起動していることを確認する。  
	```bat
	# systemctl status mssql-server
	```
5. SQL Server で使用するポートを解放する。（デフォルトはポート番号1433）  
	```bat
	# sudo firewall-cmd --zone=public --add-port=1433/tcp --permanent
	# sudo firewall-cmd --reload
	```
6. SQL Server cmmand-line tools 用のリポジトリをダウンロードする。  
	```bat
	# curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
	```
7. もし古いバージョンのものがインストールされている場合は、アンインストールしてから最新版をインストールする。  
	```bat
	# yum remove unixODBC-utf16 unixODBC-utf16-devel
	# yum install -y mssql-tools unixODBC-devel
	```
8. 環境変数を設定する。  
	```bat
	# echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
	# echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
	# source ~/.bashrc
	```
9. SQL Server インスタンスに接続できるかを確認する。  
	```bat
	# sqlcmd -S localhost -U SA -P '<YourPassword>'
	```

参考：
[https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-red-hat]

### 可用性グループの構築
#### 全サーバで行う
1. 全サーバの名前解決ができるよう、"/etc/hostname" を編集する。  
	```bat
	# sudo vi /etc/hstname
	```
2. 可用性グループ機能を有効化し、mssql-server サービスを再起動する。  
	```bat
	# /opt/mssql/bin/mssql-conf set hadr.hadrenabled  1
	# systemctl restart mssql-server
	```
3. データベースのミラーリングエンドポイント接続用ユーザアカウントを作成する。  
	```bat
	# sqlcmd -U SA -P <SA password>
	> CREATE LOGIN dbm_login WITH PASSWORD = '<dbm_login password>';
	> CREATE USER dbm_user FOR LOGIN dbm_login;
	> go
	> exit
	```
#### 1号機でのみ行う
4. 証明書を作成し、2号機/3号機へコピーする。  
	```bat
	# sqlcmd -U SA -P <SA password>
	> CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<Master_Key_Password>';
	> CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'dbm';
	> BACKUP CERTIFICATE dbm_certificate
	>   TO FILE = '/var/opt/mssql/data/dbm_certificate.cer'
	>   WITH PRIVATE KEY (
	>           FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
	>           ENCRYPTION BY PASSWORD = '<Private_Key_Password>'
	>       );
	> go
	> exit
	# scp /var/opt/mssql/data/dbm_certificate.* root@<server2 IP address>:/var/opt/mssql/data/
	# scp /var/opt/mssql/data/dbm_certificate.* root@<server3 IP address>:/var/opt/mssql/data/
	```
#### 2号機/3号機で行う  
5. 証明書の権限を変更する。  
	```bat
	# chown mssql:mssql /var/opt/mssql/data/dbm_certificate.*
	```
6. 証明書を取り込む。  
	```bat
	# sqlcms -U SA -P <SA password>
	> CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<Master_Key_Password>';
	> CREATE CERTIFICATE dbm_certificate   
	>    AUTHORIZATION dbm_user
	>    FROM FILE = '/var/opt/mssql/data/dbm_certificate.cer'
	>    WITH PRIVATE KEY (
	>    FILE = '/var/opt/mssql/data/dbm_certificate.pvk',
	>    DECRYPTION BY PASSWORD = '<Private_Key_Password>'
	>            );
	> go
	> exit
	```
#### 全サーバで行う
7. データベースのミラーリングエンドポイントを作成する。  
	```bat
	# sqlcms -U SA -P <SA password>
	>CREATE ENDPOINT [Hadr_endpoint]
	>    AS TCP (LISTENER_PORT = <listener port number(default: 5022)>)
	>    FOR DATA_MIRRORING (
	>        ROLE = ALL,
	>        AUTHENTICATION = CERTIFICATE dbm_certificate,
	>        ENCRYPTION = REQUIRED ALGORITHM AES
	>        );
	>ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
	>GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [dbm_login];
	> go
	>exit
	```
#### 1号機でのみ行う
8. 可用性グループを作成する。なお、 **FAILOVER_MODE は MANUAL とする**。  
	```bat
	# sqlcms -U SA -P <SA password>
	> CREATE AVAILABILITY GROUP <ag name>
	>    WITH (DB_FAILOVER = ON, CLUSTER_TYPE = NONE)
	>    FOR REPLICA ON
	>        N'<server1 name>' 
	>         WITH (
	>            ENDPOINT_URL = N'tcp://<server1 hostname>:<listener port number>',
	>            AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
	>            FAILOVER_MODE = MANUAL,
	>            SEEDING_MODE = AUTOMATIC
	>            ),
	>        N'<server2 name>' 
	>         WITH ( 
	>            ENDPOINT_URL = N'tcp://<server2 hostname>:<listener port number>', 
	>            AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
	>            FAILOVER_MODE = MANUAL,
	>            SEEDING_MODE = AUTOMATIC
	>            ),
	>        N'<server3 name>'
	>        WITH( 
	>           ENDPOINT_URL = N'tcp://<server3 hostname>:<listener port number>', 
	>           AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
	>           FAILOVER_MODE = MANUAL,
	>           SEEDING_MODE = AUTOMATIC
	>           );
	> go
	> exit
	```
#### 2号機/3号機で行う
9. 可用性グループにサーバを追加する。  
	```bat
	# sqlcms -U SA -P <SA password>
	> ALTER AVAILABILITY GROUP <ag name> JOIN WITH (CLUSTER_TYPE = NONE);
	> ALTER AVAILABILITY GROUP <ag name> GRANT CREATE ANY DATABASE;
	> go
	> exit
	```
10. データベースのバックアップを作成し、可用性グループに追加する。  
	```bat
	# sqlcms -U SA -P <SA password>
	> CREATE DATABASE <db name>;
	> ALTER DATABASE <db name> SET RECOVERY FULL;
	> BACKUP DATABASE <db name>
	>    TO DISK = N'/var/opt/mssql/data/<db name>.bak';
	> ALTER AVAILABILITY GROUP <ag name> ADD DATABASE <db name>;
	> go
	> exit
	```
#### 全サーバで行う
11. PRIMARY サーバでのみデータベースに接続できることを確認する。 
	```bat
	# sqlcms -U SA -P <SA password>
	> USE <db name>;
	> go
	> exit
	```
参考:
[https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-availability-group-configure-ha]

### CLUSTERPRO のインストールと構築
#### 全サーバで行う
1. CLUSTERPRO をインストールし、ライセンスを登録する。  
2. sqlcommand スクリプトを作成し、保存する。  
	例） "/opt/nec/clusterpro/scripts/failover/sqlcommand/" フォルダを作成し、以下のスクリプトを保存する。 
  	- [agFailover.sql](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/agFailover.sql)  
	- [is_failover_ready.sql](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/is_failover_ready.sql)  
	- [role.sql](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/role.sql)  
	- [setSecondary.sql](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/setSecondary.sql)  
3. 保存したスクリプトに実行権限を付与する。  
	```bat
	# chown 777 /opt/nec/clusterpro/scripts/failover/sqlcommand/*
	```

#### 1号機でのみ行う
4. WebManager を起動し、クラスタを構築して適用する。  
  クラスタの構成については[クラスタ設定](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/AG%20cluster%20Quick%20Start%20Guide.md#cluster-settings)を参照する。  
5. フェイルオーバグループを PRIMARY サーバで起動する。  

参考:
[https://www.nec.com/en/global/prod/expresscluster/en/support/manuals.html]
- EXPRESSCLUSTER X 3.3 for Linux Installation and Configuration Guide
- EXPRESSCLUSTER X 3.3 for Linux Reference Guide

## クラスタ設定
- クラスタのプロパティ
	- NP解決:
		- Ping NP:
			- NP発生時動作: クラスタサービスの停止と OS シャットダウン
- フェイルオーバグループ
	- リソース
		- fip:
		- exec:
			- 依存関係: 依存するリソースに fip を指定する。
			- [start.sh](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/start.sh)
			- [stop.sh](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/stop.sh)
	- モニタリソース
		- genw-ActiveNode:
			- 監視タイミング: 活性時 (対象リソース: exec)
			- 監視を行うサーバを選択する: 全てのサーバ
			- [genw.sh](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/Active%20Node%20monitor%20genw.sh)
			- 監視タイプ: 同期
			- 正常な戻り値: 0
			- 回復動作: 回復対象に対してフェイルオーバ実行
			- 回復対象: フェイルオーバグループ
		- genw-SatndbyNode:
			- 監視タイミング: 常時
			- 監視を行うサーバを選択する: 全サーバ
			- [genw.sh](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/Standby%20Node%20monitor%20genw.sh)
			- 監視タイプ: 同期
			- 正常な戻り値: 0
			- 回復動作: カスタム設定
			- 回復対象: ローカルサーバ
			- 回復スクリプト実行回数:  1
			- 最終動作: クラスタサービスの停止と OS シャットダウン
			- スクリプト設定: [preaction.sh](https://github.com/Igaigasuru/EXPRESSCLUSTER/blob/master/scripts/AG%20cluster/Standby%20Node%20monitor%20preaction.sh)
		- psw:
			- 監視タイミング: 常時
			- 監視を行うサーバを選択する: 全てのサーバ
			- プロセス名(*): /opt/mssql/bin/sqlservr  
        * ps コマンドで事前にプロセス名を確認してください。
          # ps -eaf
			- 回復動作: 回復対象に対してフェイルオーバ実行
			- 回復対象: フェイルオーバグループ


参考:
[https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/monitor-availability-groups-transact-sql#AvGroups]
[https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-availability-group-transact-sql?view=sql-server-2017]
