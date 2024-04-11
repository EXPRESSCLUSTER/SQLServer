# Microsoft SQL Server 2017 on Windows HowTo

## はじめに

- 本ガイドは、CLUSTERPRO X (以降、CLUSTERPRO) で Microsoft SQL Server 2017 (以降 SQL Server) をクラスタ化する手順を記載しています。
- CLUSTERPRO X の詳細については、[こちら](https://jpn.nec.com/clusterpro/clpx/index.html)をご参照ください。

## 構成

- 本構成では2-node構成のミラーディスク型クラスタを構築します。CLUSTERPRO 環境下での SQL Server の運用は片方向クラスタと双方向クラスタがあります。本ガイドでは片方向クラスタについて紹介します。 


### 使用ソフトウェア
- Microsoft SQL Server 2017
- SQL Server Management Studio 
- CLUSTERPRO X 4.2 for Windows (内部バージョン：12.22)
  - ミラーディスク型クラスタを構築するためには、CLUSTERPRO X Replicator 4.2 for Windows のライセンスが必要となります。 

### クラスタ構成
- グループリソース
  - フローティング IP リソース
  - ミラーディスクリソース
  - サービスリソース
  - スクリプトリソース
- モニタリソース
  - フローティング IP 監視リソース
  - ミラーコネクト監視リソース
  - ミラーディスク監視リソース
  - サービス監視リソース
  - ユーザ空間監視リソース


## システム構成例  
初めに CLUSTERPRO と SQL Server とOS の互換性を確認する必要があります。

```bat
<LAN>
 |
 | 
 |     
 |     +--------------------------------+
 |     | server1                        |
 |-----+ - Windows Server 2019          |
 |     | - CLUSTERPRO X 4.2             |
 |     | - SQL Server 2017              |
 |     +--------------+-----------------+
 |                    |
 |                    |
 |                    |
 |                    |
 |     +--------------+-----------------+
 |     | server2                        |
 |-----+ - Windows Server 2019          |
 |     | - CLUSTERPRO X 4.2             |
 |     | - SQL Server 2017              |
 |     +--------------------------------+
 |
[Gateway]
 :
```

### IPアドレス
|server1|server2|fip|
|---|---|---|
|192.168.1.100|192.168.1.101|      -      |
|192.168.2.100|192.168.2.101|192.168.2.253|  
<br>

### パーティション
||server1|server2|サイズ|
|---|---|---|---|
|クラスタパーティション|Eドライブ|Eドライブ|1024MB|
|データパーティション|Fドライブ|Fドライブ|2048MB|
- クラスタパーティションには最低 1024MB が必要です。
- データパーティションはユーザデータベースを格納するのに十分な領域を確保してください。
 - またコマンド [clpvolsz](https://www.manuals.nec.co.jp/contents/system/files/nec_manuals/node/496/W42_RG_JP/W_RG_08.html#tuning-partition-size-clpvolsz-command)  でデータパーティションのサイズ確認をおこないます。サイズに差異がある場合はサイズの大きいほうを縮小させ、同一にする必要があります。
<br>


## 構築手順
### CLUSTERPRO のインストール 
1. [インストール & 設定ガイド](https://www.manuals.nec.co.jp/contents/system/files/nec_manuals/node/496/W42_IG_JP/index.html)に従い、CLUSTERPRO をインストールしてください。
1. フェイルオーバグループを作成し、以下のリソースを追加してください。
   - フローティング IP アドレス 
     - IPアドレス: 192.168.2.253
   - ミラーディスクリソース 
     - 上述のクラスタパーティション及びデータパーティションのドライブ文字を設定してください。 


### SQL Server のインストール
- 各サーバーに SQL Server を[インストール](https://www.microsoft.com/ja-jp/download/details.aspx?id=55994)します。
   - SQL Server およびシステムデータベースファイルはシステムドライブ (C:\\) にインストールしてください。
- 以下の設定画面にてパラメータを設定する必要があります。そのほかは既定値で問題ありません。本ガイドでは既定のインスタンスを使用します。
  - 「SQL Server の新規スタンドアローン インストールを実行するか、既存のインストールに機能を追加」を選択します。
  -  機能の選択：「データベースエンジンサービス」にチェックします。
  - データベース エンジンの構成：本ガイドでは混合認証モードにチェックします。SQL server のシステム管理者(sa)アカウントのパスワードを指定します。


### SQL Server Management Studio のインストール
1. 以下のガイドを参考に、任意のサーバに SQL Server Management Studio (以降、SSMS) を[インストール](https://docs.microsoft.com/ja-jp/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver15)してください。
1. インストール後、SSMS を起動し、server1 に接続してください。
1. server1 に対し、以下のクエリをから実行し、ユーザーデータベースの作成を行います。
   ```sql
   /* TESTDB_Data、TESTDB_Log の 2つのファイルから TESTDB という DB を作成 */ 
   create database TESTDB on PRIMARY (   
   name = 'TESTDB_Data',   
   filename = 'F:\sql\data\TESTDB_Data.mdf',   size = 10 
   ) 
   LOG ON (   name = 'TESTDB_Log',   
   filename = 'F:\sql\data\TESTDB_Log.ldf',   size = 10 ) 
   go 
   CHECKPOINT 
   go 
   ``` 
   - server2 にユーザーデータベースの作成は必要ありません。


### データベースをアタッチ/デタッチするスクリプトの作成
- CLUSTERPRO によるフェイルオーバ、およびフェイルバックが行われる際には、ユーザデータベースのアタッチ/デタッチが必要となります。 以下はアタッチを行うスクリプト（attach.sql）とデタッチを行うスクリプト（detach.sql）の記述例となります。
  - attach.sql
    ```sql
    create database [TESTDB] on 
    (filename = 'F:\sql\data\TESTDB_Data.mdf'),  
    (filename = 'F:\sql\data\TESTDB_Log.ldf') 
    for attach     
    ```
  - detach.sql
    ```sql 
    alter database [TESTDB] set offline with ROLLBACK IMMEDIATE 
    exec sp_detach_db 'TESTDB',TRUE 
    ```
- 作成した各スクリプトを、各ノードの下記フォルダに格納します。server1 とserver2 で同じディレクトリを指定する必要があります。
  ```
  C:\Program Files\CLUSTERPRO\scripts\SQLscripts
  ```


### CLUSTERPRO への SQL Server サービスの組み込み 
1. システム環境変数のPATHに以下を追加してください。
   - C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn
1. SQL Server サービスの起動、停止を管理するためにサービスリソースを追加します。 
    - 依存関係タブにて、依存するリソースにミラーディスクリソースが含まれていることを確認してください。
    - 詳細タブにて、サービス名に「SQL Server (MSSQLSERVER)」を設定します。
1. データベースのアタッチとデタッチを実行するためのスクリプトリソースを追加します。 
    - 依存関係タブにて、依存するリソースにサービスリソースを追加します。
    - 詳細タブにて、開始スクリプト(start.bat)、終了スクリプト(stop.bat)を編集します。start.bat ではデータベースのアタッチを行い、stop.bat ではデータベースのデタッチを行います。以下に一例を紹介します。

      -  start.bat
          ```bat
         rem *************
          rem 業務通常処理
          rem *************
          sqlcmd –U sa –P <パスワード> –i "C:\Program Files\CLUSTERPRO\scripts\SQLscripts/attach.sql"
          .
          .
          .
          rem *************
          rem フェイルオーバ後の業務起動ならびに復旧処理
          rem *************
          sqlcmd –U sa –P <パスワード> –i "C:\Program Files\CLUSTERPRO\scripts\SQLscripts/attach.sql"
          ```
        - stop.bat
          ```bat
          rem *************
          rem 業務通常処理
          rem *************
          sqlcmd –U sa –P <パスワード> –i "C:\Program Files\CLUSTERPRO\scripts\SQLscripts/detach.sql"
          .
          .
          .
          rem *************
          rem フェイルオーバ後の業務起動ならびに復旧処理
          rem *************
          sqlcmd –U sa –P <パスワード> –i "C:\Program Files\CLUSTERPRO\scripts\SQLscripts/detach.sql"
          ```
## 動作確認

1. server1 にてフェイルオーバグループが起動していることを確認してください。
1. server1 にログインしてください。
1. 以下の通り実行してください。

   ```sql
    C:\> sqlcmd
    1> use testdb
    2> go
    データベース コンテキストが'testdb'に変更されました
    1> create table userinfo(
      id int,
      usename varchar(20)
      email varchar(25),
      password char(20)
      )
    2> insert into userinfo values (1,'foo','mail@foo.com',password)
    3> go
    1> quit
   ```
1. Cluster WebUI を用いてグループを server2 に移動します。
1. server2 にログインし、sqlcmd コマンドで server1 で追加したデータが表示されることを確認してください。

   ```sql
    C:\> sqlcmd
    1> use testdb
    2> go
    データベース コンテキストが'testdb'に変更されました
    1> select * from userinfo
    2> go
    id      username      email             password      
    --------------------------------------------------------
          1 foo           mail@foo.com      password
    (1行処理されました)
    1> quit
   ```  

1. 同様にserver2 で書き込んで server1 にグループを移動させて追加されたデータが得られたか確認してください。
