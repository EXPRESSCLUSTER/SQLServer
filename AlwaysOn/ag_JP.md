



# 可用性グループクラスタ　クイック構築ガイド
## はじめに
本ガイドでは、CLUSTERPRO X による SQL Server 2017 on Linux 可用性グループクラスタを構築する手順を記載します。  
CLUSTERPRO X の詳細については、[こちら](https://jpn.nec.com/clusterpro/clpx/index.html)を参照ください。  

## 構成
### システム構成
- ハードウェア
	- サーバ: 3台（仮想/物理）
		- メモリ: 4GB
		- CPU: 2コア/1ソケット
		- ディスク: 20GB
		- OS: Cent 7.4 (3.10.0-693.21.1.el7.x86_64)
	- PingNP ターゲットノード: 1台
- ソフトウェア
	- SQL Server 2017 on Linux
	- CLUSTERPRO X 3.3.5-1/4.0.0-1

### クラスタ構成
- クラスタのプロパティ
	- NP解決:
		- Ping NP:  
			ネットワークパーティション回避のために追加する。
- フェイルオーバグループ
	- リソース
		- fip:  
			クライアントからプライマリ可用性レプリカ（プライマリレプリカ）への接続に使用する。
		- exec:  
			プライマリレプリカとセカンダリ可用性レプリカ（セカンダリレプリカ）の管理に使用する。
	- 監視リソース
		- genw-ActiveNode:  
			フェイルオーバグループが起動しているサーバ（アクティブサーバ）の可用性レプリカの役割を監視する。
		- genw-StandbyNode:  
			フェイルオーバグループが起動していないサーバ（スタンバイサーバ）の可用性レプリカの役割を監視する。
		- psw:  
			全サーバの SQL Server サービスを監視する。

### システム要件
- 全てのサーバと PingNP ターゲットは、お互いに IP アドレスで通信可能である。
- SQL Server on Linux と EXPRESSCLUSTER X は全てのサーバにインストールされる。
- クライアントからプライマリレプリカへの接続には、必ず fip を使用し、サーバの実 IP アドレスは使用しない。
- 可用性レプリカの操作は、必ず CLUSTERPRO X から行う。

### 動作
- アクティブサーバでは、可用性レプリカの役割がプライマリになる。  
- スタンバイサーバでは、可用性レプリカの役割がセカンダリになる。  
- フェイルオーバグループがフェイルオーバすると、フェイルオーバ元サーバの可用性レプリカの役割はプライマリからセカンダリに変わり、フェイルオーバ先サーバの可用性レプリカの役割はセカンダリからプライマリに変わる。  

### 監視
- アクティブサーバ可用性レプリカの役割監視:  
	アクティブサーバの可用性レプリカの役割が、CLUSTERPRO X からの操作以外でセカンダリに変わった場合、エラーとして検知され、フェイルオーバが実行される。  
- スタンバイサーバ可用性レプリカの役割監視:  
	スタンバイサーバの可用性レプリカの役割が、CLUSTERPRO X からの操作以外でプライマリに変わった場合、エラーとして検知され、セカンダリに役割変更される。  
- アクティブサーバのサービス監視:  
	アクティブサーバの SQL Server サービス（mssql-server）が停止した場合、エラーとして検知され、フェイルオーバが実行される。  
- スタンバイサーバのサービス監視:  
	スタンバイサーバの SQL Server サービス（mssql-server）が停止した場合、エラーとして検知される。  

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
https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-red-hat

### 可用性グループの構築
#### 全サーバで行う
1. 全サーバの名前解決ができるよう、"/etc/hostname" を編集する。  
	```bat
	# sudo vi /etc/hostname
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
https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-availability-group-configure-ha

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
  クラスタの構成については[クラスタ設定](https://github.com/EXPRESSCLUSTER/SQLServer/blob/master/AlwaysOn/ag_JP.md#%E3%82%AF%E3%83%A9%E3%82%B9%E3%82%BF%E8%A8%AD%E5%AE%9A)を参照する。  
5. フェイルオーバグループを PRIMARY サーバで起動する。  

参考：  
https://jpn.nec.com/clusterpro/clpx/manual_x40.html#anc-lin  
Linux インストール&設定ガイド  
Linux リファレンスガイド

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
		- genw-StandbyNode:
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
			- プロセス名(※): /opt/mssql/bin/sqlservr  
				※ps コマンドで事前にプロセス名を確認してください。  
					```bat
					# ps -eaf
					```
			- 回復動作: 回復対象に対してフェイルオーバ実行
			- 回復対象: フェイルオーバグループ


参考:  
https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/monitor-availability-groups-transact-sql#AvGroups  
https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-availability-group-transact-sql?view=sql-server-2017  
