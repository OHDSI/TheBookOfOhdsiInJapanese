# 第9章　--翻訳作業中--　SQLとR {#SqlAndR}

*チャプタリーダー: Martijn Schuemie & Peter Rijnbeek*



共通データモデル（CDM）はリレーショナルデータベースモデルです（すべてのデータはフィールドを持つテーブルのレコードとして表されます）。そのため、データは通常、PostgreSQL、Oracle、またはMicrosoft SQL Serverなどのソフトウェアプラットフォームを使用してリレーショナルデータベースに保存されます。ATLASやMethods LibraryなどのさまざまなOHDSIツールは、バックグラウンドでデータベースをクエリすることによって機能しますが、適切なアクセス権を持っていれば、私たちも直接データベースにクエリを実行することができます。これを行う主な理由は、現在のツールではサポートされていない分析を実行するためです。しかし、直接のクエリはミスを犯すリスクが高まり、OHDSIツールはしばしば適切なデータ分析へのガイドとして設計されているため、直接クエリにはそのようなガイドが提供されません。

リレーショナルデータベースをクエリする標準的な言語はSQL（Structured Query Language）で、クエリやデータ変更に使用できます。SQLの基本コマンドは確かに標準化されており、すべてのソフトウェアプラットフォームで同じですが、各プラットフォームには独自の表現があり、微妙な変更があります。例えば、SQL ServerでPERSONテーブルの上位10行を取得するには、次のように入力します： \index{SQL} \index{structured query language|see {SQL}}


``` sql
SELECT TOP 10 * FROM person;
```

一方、PostgreSQLでは同じクエリは次のようになります：


``` sql
SELECT * FROM person LIMIT 10;
```

OHDSIでは、プラットフォーム固有の表現に依存しないことを望んでいます。すなわち、すべてのOHDSIデータベースで同じSQL言語を使用したいと考えています。このため、OHDSIは[SqlRender](https://ohdsi.github.io/SqlRender/)パッケージを開発しました。これは、ある標準表現から後述するサポートされる表現のいずれかに翻訳できるRパッケージです。この標準表現 - **OHDSI SQL** - は主にSQL Server SQL表現のサブセットです。今章の例示するSQL文はすべてOHDSI SQLを使用します。 \index{SqlRender} \index{agnostic SQL|see {SqlRender}} \index{Standard SQL Dialect|see {SqlRender}} \index{OHDSI SQL|see {SqlRender}}

各データベースプラットフォームには、SQLを使用したデータベースのクエリのための独自のソフトウェアツールも付属しています。OHDSIでは、多くのデータベースプラットフォームに接続できる1つのRパッケージである[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)パッケージを開発しました。DatabaseConnectorも今章後半で説明します。 \index{DatabaseConnector}

したがって、CDMに準拠したデータベースに対してOHDSIツールを使用せずにクエリを実行できますが、推奨されるパスはDatabaseConnectorとSqlRenderパッケージを使用することです。これにより、1つのサイトで開発されたクエリが他のサイトでも修正なしで使用できるようになります。さらに、R自体がデータベースから抽出されたデータをさらに分析するための機能（統計分析の実行や（インタラクティブな）プロットの生成）を即座に提供します。 \index{R}

この章では、読者がSQLの基本的な理解を持っていることを前提としています。まず、SqlRenderとDatabaseConnectorの使用方法をレビューします。これらのパッケージを使用しない場合は、これらのセクションをスキップできます。セクション\@ref(QueryTheCdm)では、CDMをクエリするためのSQL（この場合OHDSI SQL）使用方法を説明します。次のセクションでは、CDMをクエリする際にOHDSI標準化ボキャブラリを使用する方法を強調します。CDMに対する一般的なクエリのコレクションであるQueryLibraryを紹介し、公開されています。最後に、発現率を推定する例の研究を示し、この研究をSqlRenderとDatabaseConnectorを使用して実装します。 \index{Query Library} \index{SQL Query Library|see {Query Library}}

## SqlRender {#SqlRender}

[SqlRender](https://ohdsi.github.io/SqlRender/) パッケージは CRAN（Comprehensive R Archive Network）で利用可能であり、以下の方法でインストールできます：


``` r
install.packages("SqlRender")
```

SqlRenderは、従来のデータベースシステム（PostgreSQL、Microsoft SQL Server、SQLite、Oracle）を含む幅広い技術プラットフォーム、並列データウェアハウス（Microsoft APS、IBM Netezza、Amazon Redshift）、およびビッグデータプラットフォーム（Impala経由のHadoop、Google BigQuery）をサポートしています。このRパッケージには、パッケージマニュアルと機能の全体を探るためのビネットが付属しています。ここでは、主な機能のいくつかを説明します。

### SQLのパラメータ設定

パッケージの機能の一つは、SQLのパラメータ設定をサポートすることです。しばしば、いくつかのパラメータに基づいて小さなバリエーションのSQLを生成する必要があります。SqlRenderは、SQLコード内にパラメータ設定を可能にするシンプルなマークアップ文法を提供します。パラメータ値に基づいてSQLをレンダリングするには、`render()`関数を使用します。 \index{SqlRender!parameterization}

#### パラメータ値の置換 {-}

`@` 文字を使用して、レンダリング時に実際のパラメータ値と交換する必要があるパラメータ名を示します。以下の例では、SQL内で `a` という変数が言及されています。`render` 関数の呼び出しでは、このパラメータの値が定義されています：


``` r
sql <- "SELECT * FROM concept WHERE concept_id = @a;"
render(sql, a = 123)
```

```
## [1] "SELECT * FROM concept WHERE concept_id = 123;"
```

ほとんどのデータベース管理システムが提供するパラメータ設定とは異なり、値だけでなくテーブルやフィールド名も簡単にパラメータ化できます：


``` r
sql <- "SELECT * FROM @x WHERE person_id = @a;"
render(sql, x = "observation", a = 123)
```

```
## [1] "SELECT * FROM observation WHERE person_id = 123;"
```

パラメータ値は、数値、文字列、ブール値、ベクターであり、コンマ区切りリストに変換されます：


``` r
sql <- "SELECT * FROM concept WHERE concept_id IN (@a);"
render(sql, a = c(123, 234, 345))
```

```
## [1] "SELECT * FROM concept WHERE concept_id IN (123,234,345);"
```

#### If-Then-Else {-}

時々、あるパラメータの値に基づいてコードのブロックをオンまたはオフにする必要があります。これは `{Condition} ? {if true} : {if false}` 構文を使用して行われます。*condition* が true または 1 の場合、*if true* ブロックが使用され、それ以外の場合は *if false* ブロックが表示されます（存在する場合）。


``` r
sql <- "SELECT * FROM cohort {@x} ? {WHERE subject_id = 1}"
render(sql, x = FALSE)
```

```
## [1] "SELECT * FROM cohort "
```

``` r
render(sql, x = TRUE)
```

```
## [1] "SELECT * FROM cohort WHERE subject_id = 1"
```

簡単な比較もサポートされています：


``` r
sql <- "SELECT * FROM cohort {@x == 1} ? {WHERE subject_id = 1};"
render(sql, x = 1)
```

```
## [1] "SELECT * FROM cohort WHERE subject_id = 1;"
```

``` r
render(sql, x = 2)
```

```
## [1] "SELECT * FROM cohort ;"
```

`IN` 演算子もサポートされています：


``` r
sql <- "SELECT * FROM cohort {@x IN (1,2,3)} ? {WHERE subject_id = 1};"
render(sql, x = 2)
```

```
## [1] "SELECT * FROM cohort WHERE subject_id = 1;"
```

### 他のSQL表現への置換

[SqlRender](https://ohdsi.github.io/SqlRender/) パッケージのもう一つの機能は、OHDSI SQLから他のSQL表現へ翻訳することです。例えば：


``` r
sql <- "SELECT TOP 10 * FROM person;"
translate(sql, targetDialect = "postgresql")
```

```
## [1] "SELECT  * FROM person LIMIT 10;"
## attr(,"sqlDialect")
## [1] "postgresql"
```

`targetDialect` パラメータには次の値が設定可能です："oracle", "postgresql", "pdw", "redshift", "impala", "netezza", "bigquery", "sqlite", "sql server"。 \index{SqlRender!translation}

\BeginKnitrBlock{rmdimportant}
すべてのSQL関数や構造を正確に翻訳するには限界があります。パッケージに実装されている翻訳ルールが限られているためでもあり、一部のSQL機能がすべての表現に同等のものを持たないためです。これは、OHDSI SQLが独自の新しいSQL表現として開発された主な理由です。それでも、可能な限り、車輪の再発明を避けるためにSQL Serverの構文を維持しました。

\EndKnitrBlock{rmdimportant}

最善を尽くしても、すべてのサポートプラットフォームでエラーなしに実行できるOHDSI SQLを書くにはかなりの注意が必要です。以下にその検討事項を詳述します。

#### Translateがサポートする関数と構造 {-}

これらのSQL Server関数はテストされ、各表現への正確な翻訳が確認されています：\index{SqlRender!supported functions}

表: (\#tab:sqlFunctions) supported by translate

|関数                 |関数               |関数               |
|:------------------- |:----------------- |:----------------- |
|ABS                 |EXP                |RAND               |
|ACOS                |FLOOR              |RANK               |
|ASIN                |GETDATE            |RIGHT              |
|ATAN                |HASHBYTES*         |ROUND              |
|AVG                 |ISNULL             |ROW_NUMBER         |
|CAST                |ISNUMERIC          |RTRIM              |
|CEILING             |LEFT               |SIN                |
|CHARINDEX           |LEN                |SQRT               |
|CONCAT              |LOG                |SQUARE             |
|COS                 |LOG10              |STDEV              |
|COUNT               |LOWER              |SUM                |
|COUNT_BIG           |LTRIM              |TAN                |
|DATEADD             |MAX                |UPPER              |
|DATEDIFF            |MIN                |VAR                |
|DATEFROMPARTS       |MONTH              |YEAR               |
|DATETIMEFROMPARTS   |NEWID              |                   |
|DAY                 |PI                 |                   |
|EOMONTH             |POWER              |                   |

\* Oracleでは特別な権限が必要です。SQLiteでは同等のものがありません。

同様に、多くのSQL構文構造がサポートされています。ここには、正確に翻訳されることが確認されている非網羅的なリストを示します：

```sql
-- Simple selects:
SELECT * FROM table;

-- Selects with joins:
SELECT * FROM table_1 INNER JOIN table_2 ON a = b;

-- Nested queries:
SELECT * FROM (SELECT * FROM table_1) tmp WHERE a = b;

-- Limiting to top rows:
SELECT TOP 10 * FROM table;

-- Selecting into a new table:
SELECT * INTO new_table FROM table;

-- Creating tables:
CREATE TABLE table (field INT);

-- Inserting verbatim values:
INSERT INTO other_table (field_1) VALUES (1);

-- Inserting from SELECT:
INSERT INTO other_table (field_1) SELECT value FROM table;

-- Simple drop commands:
DROP TABLE table;

-- Drop table if it exists:
IF OBJECT_ID('ACHILLES_analysis', 'U') IS NOT NULL
  DROP TABLE ACHILLES_analysis;

-- Drop temp table if it exists:
IF OBJECT_ID('tempdb..#cohorts', 'U') IS NOT NULL
  DROP TABLE #cohorts;

-- Common table expressions:
WITH cte AS (SELECT * FROM table) SELECT * FROM cte;

-- OVER clauses:
SELECT ROW_NUMBER() OVER (PARTITION BY a ORDER BY b)
  AS "Row Number" FROM table;

-- CASE WHEN clauses:
SELECT CASE WHEN a=1 THEN a ELSE 0 END AS value FROM table;

-- UNIONs:
SELECT * FROM a UNION SELECT * FROM b;

-- INTERSECTIONs:
SELECT * FROM a INTERSECT SELECT * FROM b;

-- EXCEPT:
SELECT * FROM a EXCEPT SELECT * FROM b;
```

#### 文字列の連結 {-}

文字列連結は、SQL Serverが他の表現よりも特異ではない領域の1つです。SQL Serverでは、`SELECT first_name + ' ' + last_name AS full_name FROM table` と書きますが、これは PostgreSQL と Oracle では `SELECT first_name || ' ' || last_name AS full_name FROM table` でなければなりません。SqlRenderは、連結される値が文字列であることを推測しようとします。上記の例では、明示的な文字列（シングルクォートで囲まれたスペース）があるため、翻訳は正しく行われます。しかし、クエリが `SELECT first_name + last_name AS full_name FROM table` であった場合、SqlRenderは2つのフィールドが文字列であることを知らず、プラス記号を正しく残しません。値が文字列であることのもう一つの手がかりは、明示的なVARCHARへのキャストです。したがって、`SELECT last_name + CAST(age AS VARCHAR(3)) AS full_name FROM table` も正しく翻訳されます。曖昧さを避けるために、2つ以上の文字列を連結する場合は、```CONCAT()``` 関数を使用するのがベストです。

#### テーブルエイリアスとASキーワード {-}

多くのSQL表現ではテーブルエイリアスを定義する際に `AS` キーワードを使用できますが、キーワードなしでも問題ありません。例えば、これらのSQL文はSQL Server、PostgreSQL、Redshiftなどのプラットフォームで問題ありません：

```sql
-- Using AS keyword
SELECT *
FROM my_table AS table_1
INNER JOIN (
  SELECT * FROM other_table
) AS table_2
ON table_1.person_id = table_2.person_id;

-- Not using AS keyword
SELECT *
FROM my_table table_1
INNER JOIN (
  SELECT * FROM other_table
) table_2
ON table_1.person_id = table_2.person_id;
```

しかし、Oracleでは `AS` キーワードを使用するとエラーが発生します。上記の例では、最初のクエリが失敗します。そのため、テーブルのエイリアスを付ける際には `AS` キーワードを使用しないことを推奨します。（注：SqlRenderがこれを処理することはできません。Oracleが許可していない `AS` を使用しているかどうかを区別するのが難しいためです。）

#### 一時テーブル {-}

一時テーブルは中間結果を保存するのに非常に便利で、正しく使用するとクエリのパフォーマンスを大幅に向上させることができます。ほとんどのデータベースプラットフォームでは、一時テーブルは非常に良い特性を持っています：現在のユーザーのみに表示され、セッションが終了すると自動的に削除され、書き込みアクセス権がなくても作成できます。残念ながら、Oracleでは一時テーブルは基本的に恒久的なテーブルであり、唯一の違いはテーブル内のデータが現在のユーザーのみに表示されることです。このため、OracleではSqlRenderが以下の方法で一時テーブルをエミュレートしようとします。

1. 異なるユーザーからのテーブルが競合しないように、テーブル名にランダムな文字列を追加します。
2. 一時テーブルが作成されるスキーマをユーザーが指定できるようにします。

例えば：

``` r
sql <- "SELECT * FROM #children;"
translate(sql, targetDialect = "oracle", oracleTempSchema = "temp_schema")
```

```
## Warning: The 'oracleTempSchema' argument is deprecated. Use 'tempEmulationSchema' instead.
## This warning is displayed once every 8 hours.
```

```
## [1] "SELECT * FROM temp_schema.cihkqx5nchildren ;"
## attr(,"sqlDialect")
## [1] "oracle"
```

ユーザーは `temp_schema` に書き込み権限を持っている必要があります。

また、Oracleではテーブル名の長さが30文字に制限されているため、**一時テーブル名は最大22文字以内である必要があります**。セッションIDを追加すると名前が長くなりすぎるためです。

さらに、Oracleでは一時テーブルは自動的に削除されないため、使用が終わったときにはすべての一時テーブルを明示的に ```TRUNCATE``` および ```DROP``` して、孤立したテーブルがOracleの一時スキーマに蓄積しないようにする必要があります。

#### 暗黙的なキャスト {-}

SQL Serverが他の表現よりも特異である数少ない点の1つは、暗黙のキャストを許可することです。例えば、このコードはSQL Serverで動作します：

```sql
CREATE TABLE #temp (txt VARCHAR);

INSERT INTO #temp
SELECT '1';

SELECT * FROM #temp WHERE txt = 1;
```

`txt` はVARCHARフィールドであり、私たちはそれを整数と比較していますが、SQL Serverは自動的に適切なタイプにキャストして比較を許可します。これに対して、PostgreSQLなどの他の表現は、VARCHARとINTを比較しようとするとエラーをスローします。

したがって、常にキャストを明示的に行う必要があります。上記の例では、最後の文は次のいずれかに置き換える必要があります：

```sql
SELECT * FROM #temp WHERE txt = CAST(1 AS VARCHAR);
```

または

```sql
SELECT * FROM #temp WHERE CAST(txt AS INT) = 1;
```

#### 文字列比較における大文字小文字の区別 {-}

SQL Serverなどの一部のDBMSプラットフォームは常に大文字と小文字を区別せずに文字列比較を行いますが、PostgreSQLなどの他のプラットフォームは常に大文字と小文字を区別します。したがって、比較条件がケースを区別しないときに明示的に指定することをお勧めします。例えば、次のように：

```sql
SELECT * FROM concept WHERE concept_class_id = 'Clinical Finding'
```
代わりに次のように記述することが推奨されます：

```sql
SELECT * FROM concept WHERE LOWER(concept_class_id) = 'clinical finding'
```

#### スキーマとデータベース {-}

SQL Serverでは、テーブルはスキーマにあり、スキーマはデータベースに存在します。例えば、`cdm_data.dbo.person` は `cdm_data` データベース内の `dbo` スキーマ内の `person` テーブルを指します。他の表現でも同様の階層が存在しますが、使用方法が非常に異なります。SQL Serverでは、データベースごとに通常1つのスキーマ（しばしば `dbo` と呼ばれる）が存在し、ユーザーは異なるデータベースのデータを簡単に使用できます。他のプラットフォーム、例えばPostgreSQLでは、単一のセッション内で異なるデータベースのデータを使用することはできませんが、通常他のデータベースム範多くのスキーマがあります。 PostgreSQLでは、SQL Serverのデータベースに相当するのはスキーマであると言えます。

したがって、SQL Serverのデータベースとスキーマを単一のパラメータに連結することをお勧めします。このパラメータを `@databaseSchema` と呼ぶことが一般的です。例えば、パラメータ化されたSQLでは次のようになります：
```sql
SELECT * FROM @databaseSchema.person
```
SQL Serverでは、値にデータベースとスキーマの両方を含めることができます：`databaseSchema = "cdm_data.dbo"`。他のプラットフォームでは、同じコードを使用し、パラメータ値としてスキーマのみを指定します：`databaseSchema = "cdm_data"`。

この方法が失敗する唯一の状況は `USE` コマンドです。`USE cdm_data.dbo;` はエラーをスローします。したがって、常にデータベース/スキーマを指定してテーブルの場所を示すようにし、`USE` コマンドの使用を避けることをお勧めします。

#### パラメータ化されたSQLのデバッグ {-}

パラメータ化されたSQLのデバッグは少し複雑になることがあります。レンダリングされたSQLのみがデータベースサーバーでテストできますが、コードの変更はパラメータ化された（レンダリング前の）SQLで行う必要があります。 \index{SqlRender!debugging}

ソースSQLをインタラクティブに編集し、レンダリングおよび翻訳されたSQLを生成するためのShinyアプリが SqlRender パッケージに含まれています。このアプリは次の方法で起動できます：


``` r
launchSqlRenderDeveloper()
```

これにより、図\@ref(fig:sqlDeveloper)に示すように、アプリがデフォルトのブラウザで開きます。アプリはウェブ上でも公開されています。[^sqlDeveloperUrl]

```{r sqlDeveloper, fig.cap='The SqlDeveloper'

## DatabaseConnector {#DatabaseConnector}

[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)は、JavaのJDBCドライバを使用してさまざまなデータベースプラットフォームに接続するためのRパッケージです。DatabaseConnectorパッケージはCRAN（Comprehensive R Archive Network）で入手可能で、次のようにインストールできます：


``` r
install.packages("DatabaseConnector")
```

DatabaseConnectorは、従来のデータベースシステム（PostgreSQL、Microsoft SQL Server、SQLite、およびOracle）、並列データウェアハウス（Microsoft APS、IBM Netezza、およびAmazon）、ならびにビッグデータプラットフォーム（Hadoopを介したImpala、およびGoogle BigQuery）など、広範な技術プラットフォームをサポートしています。このパッケージにはすでにほとんどのドライバが含まれていますが、ライセンス上の理由からBigQuery、Netezza、およびImpalaのドライバは含まれておらず、ユーザーが入手する必要があります。これらのドライバのダウンロード方法については、`?jdbcDrivers`を参照してください。ダウンロード後、`connect`、`dbConnect`、`createConnectionDetails`関数の`pathToDriver`引数を使用できます。

### 接続の作成

データベースに接続するには、データベースプラットフォーム、サーバーの位置、ユーザー名、およびパスワードなど、多くの詳細を指定する必要があります。`connect`関数を呼び出し、これらの詳細を直接指定することができます: \index{DatabaseConnector!creating a connection}


``` r
conn <- connect(dbms = "postgresql",
                server = "localhost/postgres",
                user = "joe",
                password = "secret",
                schema = "cdm")
```

```
## Connecting using PostgreSQL driver
```

各プラットフォームに必要な詳細については、`?connect`を参照してください。接続後は忘れずに接続を閉じてください：


``` r
disconnect(conn)
```

サーバー名を提供する代わりに、JDBC接続文字列を提供することも可能です：


``` r
connString <- "jdbc:postgresql://localhost:5432/postgres"
conn <- connect(dbms = "postgresql",
                connectionString = connString,
                user = "joe",
                password = "secret",
                schema = "cdm")
```

```
## Connecting using PostgreSQL driver
```

場合によっては、接続の詳細を先に指定し、接続を後回しにすることが便利なこともあります。例えば、接続が関数内で確立される場合、その詳細を引数として渡す必要があります。この目的のために、`createConnectionDetails`関数を使用できます：


``` r
details <- createConnectionDetails(dbms = "postgresql",
                                   server = "localhost/postgres",
                                   user = "joe",
                                   password = "secret",
                                   schema = "cdm")
conn <- connect(details)
```

```
## Connecting using PostgreSQL driver
```

### クエリの実行

データベースにクエリを実行するための主な関数は、`querySql`と`executeSql`です。`querySql`はデータがデータベースから返されることを期待しており、一度に1つのSQLステートメントのみを処理できます。対照的に、`executeSql`はデータが返されることを期待せず、複数のSQLステートメントを1つのSQL文字列で受け付けます。 \index{DatabaseConnector!querying}

いくつかの例：


``` r
querySql(conn, "SELECT TOP 3 * FROM person")
```

```
##   person_id gender_concept_id year_of_birth
## 1         1              8507          1975
## 2         2              8507          1976
## 3         3              8507          1977
```


``` r
executeSql(conn, "TRUNCATE TABLE foo; DROP TABLE foo;")
```

これらの関数は広範なエラーレポートを提供します：サーバーによってエラーが発生した場合、エラーメッセージと問題のあるSQL部分がテキストファイルに書き込まれてデバッグがしやすくなります。また、`executeSql`関数はデフォルトで進行状況バーを表示し、実行されたSQLステートメントの割合を示します。もしそれらの属性が不要な場合は、`lowLevelQuerySql`および`lowLevelExecuteSql`関数を使用できます。

### ffdfオブジェクトを使用したクエリの実行

データベースからフェッチされるデータが大きすぎてメモリに収まらない場合があります。セクション\@ref(BigDataSupport)で述べたように、そのような場合は`ff`パッケージを使用してRデータオブジェクトをファイルに保存し、メモリ上にあるかのように使用することができます。`DatabaseConnector`はデータを直接ffdfオブジェクトにダウンロードすることができます：


``` r
x <- querySql.ffdf(conn, "SELECT * FROM person")
```

xは現在ffdfオブジェクトです。

### 同じSQLを使用して異なるプラットフォームにクエリを実行する

SqlRenderパッケージの`render`および`translate`関数を最初に呼び出す便利な関数があります：`renderTranslateExecuteSql`、`renderTranslateQuerySql`、`renderTranslateQuerySql.ffdf`。例えば：


``` r
x <- renderTranslateQuerySql(conn,
                             sql = "SELECT TOP 10 * FROM @schema.person",
                             schema = "cdm_synpuf")
```
SQL Server専用の「TOP 10」構文は、PostgreSQLでは「LIMIT 10」などに変換され、SQLパラメーター`@schema`は提供された値「cdm_synpuf」に置き換えられます。

### テーブルの挿入

データをデータベースに挿入するには`executeSql`関数を使用してSQLステートメントを送信することも可能ですが、最適化により`insertTable`関数を使用する方がより便利で迅速です：


``` r
data(mtcars)
insertTable(conn, "mtcars", mtcars, createTable = TRUE)
```

この例では、mtcarsデータフレームをサーバー上の「mtcars」というテーブルにアップロードします。このテーブルは自動的に作成されます。

## CDMへのクエリ {#QueryTheCdm}

以下の例では、OHDSI SQLを使用してCDMに準拠したデータベースにクエリを実行します。これらのクエリでは、CDMのデータベーススキーマを示すために`@cdm`を使用します。

まず最初に、データベースに何人の人がいるかをクエリしてみましょう：

```sql
SELECT COUNT(*) AS person_count FROM @cdm.person;
```
| PERSON_COUNT |
| ------------:|
| 26299001     |

あるいは、観察期間の平均に関心があるかもしれません：

```sql
SELECT AVG(DATEDIFF(DAY,
                    observation_period_start_date,
                    observation_period_end_date) / 365.25) AS num_years
FROM @cdm.observation_period;
```
| NUM_YEARS |
| ---------:|
| 1.980803  |

テーブルを結合して追加の統計を生成することができます。結合は通常、テーブル内の特定のフィールドに同じ値があることを要求することによって、複数のテーブルからフィールドを組み合わせます。例えば、ここでは、PERSONテーブルを、両方のテーブルのPERSON_IDフィールドでOBSERVATION_PERIODテーブルに結合します。つまり、この結合の結果は、新しいテーブル状のセットであり、両テーブルのすべてのフィールドを持ちますが、すべての行において両テーブルのPERSON_IDフィールドは同じ値でなければなりません。このようにして、OBSERVATION_PERIODテーブルのOBSERVATION_PERIOD_END_DATEフィールドとPERSONテーブルのyear_of_birthフィールドを使用して、観察終了時の最大年齢を計算することができます：

```sql
SELECT MAX(YEAR(observation_period_end_date) -
           year_of_birth) AS max_age
FROM @cdm.person
INNER JOIN @cdm.observation_period
  ON person.person_id = observation_period.person_id;
```
| MAX_AGE |
| -------:|
|      90 |

観察開始時の年齢分布を決定するためには、はるかに複雑なクエリが必要です。このクエリでは、まずPERSONをOBSERVATION_PERIODテーブルに結合して観察開始時の年齢を計算します。また、この結合されたセットの順序を年齢に基づいて計算し、それをorder_nrとして保存します。この結合の結果を複数回使用したい場合には、一般的なテーブル式（CTE）として定義し（`WITH ... AS`を使用）、"ages"と呼びます。これにより、agesを既存のテーブルのように参照することができます。agesの行数を数えて"n"を生成し、各四分位数に対して、order_nrがnの小数より小さい最小年齢を見つけます。例えば、中央値を見つけるためには$`order_nr < .50 * n`の最小年齢を使用します。最小年齢と最大年齢は別々に計算されます：

```sql
WITH ages
AS (
	SELECT age,
		ROW_NUMBER() OVER (
			ORDER BY age
			) order_nr
	FROM (
		SELECT YEAR(observation_period_start_date) - year_of_birth AS age
		FROM @cdm.person
		INNER JOIN @cdm.observation_period
			ON person.person_id = observation_period.person_id
		) age_computed
	)
SELECT MIN(age) AS min_age,
	MIN(CASE
			WHEN order_nr < .25 * n
				THEN 9999
			ELSE age
			END) AS q25_age,
	MIN(CASE
			WHEN order_nr < .50 * n
				THEN 9999
			ELSE age
			END) AS median_age,
	MIN(CASE
			WHEN order_nr < .75 * n
				THEN 9999
			ELSE age
			END) AS q75_age,
	MAX(age) AS max_age
FROM ages
CROSS JOIN (
	SELECT COUNT(*) AS n
	FROM ages
	) population_size;
```
| MIN_AGE | Q25_AGE | MEDIAN_AGE | Q75_AGE | MAX_AGE |
| -------:| -------:| ----------:| -------:| -------:|
|       0 |       6 |         17 |      34 |      90 |

より複雑な計算は、SQLの代わりにRを使用して行うこともできます。例えば、同じ結果を得るためにこのRコードを使用することができます：


``` r
sql <- "SELECT YEAR(observation_period_start_date) -
               year_of_birth AS age
FROM @cdm.person
INNER JOIN @cdm.observation_period
  ON person.person_id = observation_period.person_id;"
age <- renderTranslateQuerySql(conn, sql, cdm = "cdm")
quantile(age[, 1], c(0, 0.25, 0.5, 0.75, 1))
```

```
##   0%  25%  50%  75% 100%
##    0    6   17   34   90
```

ここでは、サーバー上で年齢を計算し、すべての年齢をダウンロードし、その後年齢分布を計算します。しかし、これはデータベースサーバーから数百万行のデータをダウンロードする必要があるため、非常に効率的ではありません。計算がSQLで行われるべきかRで行われるべきかは、ケースバイケースで判断する必要があります。

クエリは、CDM内のソース値を使用することができます。例えば、最も頻繁に使用されるコンディションのソースコードのトップ10を取得するには、次のようにします：

```sql
SELECT TOP 10 condition_source_value,
  COUNT(*) AS code_count
FROM @cdm.condition_occurrence
GROUP BY condition_source_value
ORDER BY -COUNT(*);
```
| CONDITION_SOURCE_VALUE | CODE_COUNT |
| ----------------------:| ----------:|
|                   4019 |   49094668 |
|                  25000 |   36149139 |
|                  78099 |   28908399 |
|                    319 |   25798284 |
|                  31401 |   22547122 |
|                    317 |   22453999 |
|                    311 |   19626574 |
|                    496 |   19570098 |
|                    I10 |   19453451 |
|                   3180 |   18973883 |

ここでは、CONDITION_OCCURRENCEテーブル内のCONDITION_SOURCE_VALUEフィールドの値でレコードをグループ化し、各グループのレコード数をカウントしました。CONDITION_SOURCE_VALUEとそのカウントを取得し、カウントの逆順で並べ替えています。

## クエリ時にボキャブラリを使用する

多くの操作は、ボキャブラリを使用することで有用になります。ボキャブラリテーブルはCDMの一部であり、SQLクエリを使用して利用できます。ここでは、ボキャブラリに対するクエリをCDMに対するクエリと組み合わせる方法を示します。CDMの多くのフィールドにはコンセプトIDが含まれていますが、これらはCONCEPTテーブルを使用して解決できます。例えば、データベース内の人数を性別で階層化してカウントしたい場合、GENDER_CONCEPT_IDフィールドをコンセプト名に解決することが便利です：

```sql
SELECT COUNT(*) AS subject_count,
  concept_name
FROM @cdm.person
INNER JOIN @cdm.concept
  ON person.gender_concept_id = concept.concept_id
GROUP BY concept_name;
```
| SUBJECT_COUNT | CONCEPT_NAME |
| -------------:| ------------:|
|      14927548 |       FEMALE |
|      11371453 |         MALE |

ボキャブラリの非常に強力な機能の一つは、その階層構造です。非常に一般的なクエリは、特定のコンセプトとそのすべての子孫を探すものです。例えば、イププロフェンを含む処方件数を数えるとします：

```sql
SELECT COUNT(*) AS prescription_count
FROM @cdm.drug_exposure
INNER JOIN @cdm.concept_ancestor
  ON drug_concept_id = descendant_concept_id
INNER JOIN @cdm.concept ingredient
  ON ancestor_concept_id = ingredient.concept_id
WHERE LOWER(ingredient.concept_name) = 'ibuprofen'
  AND ingredient.concept_class_id = 'Ingredient'
  AND ingredient.standard_concept = 'S';
```
| PRESCRIPTION_COUNT |
| ------------------:|
|           26871214 |

## QueryLibrary

\index{QueryLibrary}

QueryLibraryは、CDM用の一般的なSQLクエリのライブラリです。これはオンラインアプリケーション[^queryLibraryUrl]として提供されており、図\@ref(fig:queryLibrary)に示すように、Rパッケージとしても利用できます[^queryLibraryPackageUrl]。

[^queryLibraryUrl]: http://data.ohdsi.org/QueryLibrary
[^queryLibraryPackageUrl]: https://github.com/OHDSI/QueryLibrary

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/SqlAndR/queryLibrary} 

}

\caption{クエリライブラリ：CDMに対するSQLクエリのライブラリ。}(\#fig:queryLibrary)
\end{figure}

このライブラリの目的は、新しいユーザーがCDMのクエリ方法を学ぶ手助けをすることです。ライブラリ内のクエリは、OHDSIコミュニティによってレビューされ、承認されています。クエリライブラリは主にトレーニング目的で使用されますが、経験豊富なユーザーにとっても貴重なリソースです。

QueryLibraryは、SqlRenderを使用して、選択したSQLダイアレクトでクエリを出力します。ユーザーはCDMのデータベーススキーマ、語彙のデータベーススキーマ（別々のものがある場合）、およびOracleの一時スキーマ（必要な場合）を指定することもでき、これらの設定でクエリが自動的にレンダリングされます。

## 簡単な研究のデザイン

### 問題の定義

血管浮腫は、ACE阻害剤（ACEi）のよく知られた副作用です。@slater_1988 によると、ACEi治療開始後1週間で血管浮腫の発生率は週あたり3,000人中1例と推定されています。ここでは、この発見を再現し、年齢と性別によって層別化します。簡単のため、1つのACEi（リシノプリル）に焦点を当てます。したがって、次の質問に答えます：

> リシノプリル治療開始後の最初の1週間での血管浮腫の発生率は、年齢と性別で層別化されていますか？

### 曝露

曝露をリシノプリルへの最初の曝露として定義します。最初とは、以前にリシノプリルに曝露されたことがないことを意味します。最初の曝露の前に365日間の連続した観察期間が必要です。

### アウトカム

血管浮腫の診断コードが入院または救急（ER）訪問時に出現した場合を血管浮腫の発生と定義します。

### リスク期間

治療開始後の最初の1週間の発生率を計算します。患者が1週間全部にわたって曝露されているかどうかは問いません。

## SQLとRを使用した研究の実施

OHDSIツールの規約に縛られることはありませんが、同じ原則に従うと便利です。この場合、OHDSIツールが動作するのと同様に、コホートテーブルを作成するためにSQLを使用します。COHORTテーブルはCDMに定義されており、我々も使用する事前定義されたフィールドセットがあります。まず、書き込み権限のあるデータベーススキーマにCOHORTテーブルを作成する必要がありますが、これはCDM形式でデータを保持しているスキーマとは異なるスキーマである可能性が高いです。


``` r
library(DatabaseConnector)
conn <- connect(dbms = "postgresql",
                server = "localhost/postgres",
                user = "joe",
                password = "secret")
cdmDbSchema <- "cdm"
cohortDbSchema <- "scratch"
cohortTable <- "my_cohorts"

sql <- "
CREATE TABLE @cohort_db_schema.@cohort_table (
  cohort_definition_id INT,
  cohort_start_date DATE,
  cohort_end_date DATE,
  subject_id BIGINT
);
"
renderTranslateExecuteSql(conn, sql,
                          cohort_db_schema = cohortDbSchema,
                          cohort_table = cohortTable)
```

ここでは、データベーススキーマおよびテーブル名をパラメータ化しているため、異なる環境に簡単に適応できます。結果として、データベースサーバー上に空のテーブルが作成されます。

### 曝露コホート

次に、曝露コホートを作成し、COHORTテーブルに挿入します：


``` r
sql <- "
INSERT INTO @cohort_db_schema.@cohort_table (
  cohort_definition_id,
  cohort_start_date,
  cohort_end_date,
  subject_id
)
SELECT 1 AS cohort_definition_id,
  cohort_start_date,
  cohort_end_date,
  subject_id
FROM (
  SELECT drug_era_start_date AS cohort_start_date,
    drug_era_end_date AS cohort_end_date,
    person_id AS subject_id
  FROM (
    SELECT drug_era_start_date,
      drug_era_end_date,
      person_id,
      ROW_NUMBER() OVER (
        PARTITION BY person_id
  			ORDER BY drug_era_start_date
      ) order_nr
    FROM @cdm_db_schema.drug_era
    WHERE drug_concept_id = 1308216 -- リシノプリル
  ) ordered_exposures
  WHERE order_nr = 1
) first_era
INNER JOIN @cdm_db_schema.observation_period
  ON subject_id = person_id
    AND observation_period_start_date < cohort_start_date
    AND observation_period_end_date > cohort_start_date
WHERE DATEDIFF(DAY,
               observation_period_start_date,
               cohort_start_date) >= 365;
"

renderTranslateExecuteSql(conn, sql,
                          cohort_db_schema = cohortDbSchema,
                          cohort_table = cohortTable,
                          cdm_db_schema = cdmDbSchema)
```

ここでは、CDMの標準テーブルであるDRUG_ERAテーブルを使用します。このテーブルはDRUG_EXPOSUREテーブルから自動的に派生されます。DRUG_ERAテーブルには連続する成分レベルの曝露期間が含まれるため、リシノプリルを検索すると、自動的にリシノプリルを含む薬物のすべての曝露を特定します。各人の最初の薬剤曝露を選択し、OBSERVATION_PERIODテーブルと結合します。各人が複数の観察期間を持つことができるため、薬剤曝露を含む期間にのみ結合されるよう注意が必要です。一方で、OBSERVATION_PERIOD_START_DATEとCOHORT_START_DATEの間に少なくとも365日の間隔を要求します。

### アウトカムコホート

最後に、アウトカムコホートを作成する必要があります：


``` r
sql <- "
INSERT INTO @cohort_db_schema.@cohort_table (
 cohort_definition_id,
 cohort_start_date,
 cohort_end_date,
subject_id
)
SELECT 2 AS cohort_definition_id,
  cohort_start_date,
  cohort_end_date,
  subject_id
FROM (
  SELECT DISTINCT person_id AS subject_id,
    condition_start_date AS cohort_start_date,
    condition_end_date AS cohort_end_date
  FROM @cdm_db_schema.condition_occurrence
  INNER JOIN @cdm_db_schema.concept_ancestor
    ON condition_concept_id = descendant_concept_id
  WHERE ancestor_concept_id = 432791 -- 血管浮腫
) distinct_occurrence
INNER JOIN @cdm_db_schema.visit_occurrence
  ON subject_id = person_id
  AND visit_start_date <= cohort_start_date
  AND visit_end_date >= cohort_start_date
WHERE visit_concept_id IN (262, 9203,
    9201) -- 入院またはER;
"

renderTranslateExecuteSql(conn, sql,
                          cohort_db_schema = cohortDbSchema,
                          cohort_table = cohortTable,
                          cdm_db_schema = cdmDbSchema)
```

ここでは、CONDITION_OCCURRENCEテーブルをCONCEPT_ANCESTORテーブルと結合して、血管浮腫またはその子孫のすべての発生を見つけます。同じ日に複数の診断がある場合、それは同じ現象である可能性が高いため、各日1件のレコードのみを取得するようにDISTINCTを使用します。次に、診断が入院またはERで行われたことを確認するために、これらの発生をVISIT_OCCURRENCEテーブルと結合します。

### 発症率の計算

コホートが整ったので、年齢と性別に分けて発症率を計算できます：


``` r
sql <- "
WITH tar AS (
  SELECT concept_name AS gender,
    FLOOR((YEAR(cohort_start_date) -
          year_of_birth) / 10) AS age,
    subject_id,
    cohort_start_date,
    CASE WHEN DATEADD(DAY, 7, cohort_start_date) >
      observation_period_end_date
    THEN observation_period_end_date
    ELSE DATEADD(DAY, 7, cohort_start_date)
    END AS cohort_end_date
  FROM @cohort_db_schema.@cohort_table
  INNER JOIN @cdm_db_schema.observation_period
    ON subject_id = observation_period.person_id
      AND observation_period_start_date < cohort_start_date
      AND observation_period_end_date > cohort_start_date
  INNER JOIN @cdm_db_schema.person
    ON subject_id = person.person_id
  INNER JOIN @cdm_db_schema.concept
    ON gender_concept_id = concept_id
  WHERE cohort_definition_id = 1 -- 曝露
)
SELECT days.gender,
    days.age,
    days,
    CASE WHEN events IS NULL THEN 0 ELSE events END AS events
FROM (
  SELECT gender,
    age,
    SUM(DATEDIFF(DAY, cohort_start_date,
      cohort_end_date)) AS days
  FROM tar
  GROUP BY gender,
    age
) days
LEFT JOIN (
  SELECT gender,
      age,
      COUNT(*) AS events
  FROM tar
  INNER JOIN @cohort_db_schema.@cohort_table angioedema
    ON tar.subject_id = angioedema.subject_id
      AND tar.cohort_start_date <= angioedema.cohort_start_date
      AND tar.cohort_end_date >= angioedema.cohort_start_date
  WHERE cohort_definition_id = 2 -- 結果
  GROUP BY gender,
    age
) events
ON days.gender = events.gender
  AND days.age = events.age;
"

results <- renderTranslateQuerySql(conn, sql,
                                   cohort_db_schema = cohortDbSchema,
                                   cohort_table = cohortTable,
                                   cdm_db_schema = cdmDbSchema,
                                   snakeCaseToCamelCase = TRUE)
```

まず、CTE「tar」を作成し、適切なリスク時間を伴うすべての曝露を含めます。OBSERVATION_PERIOD_END_DATEでリスク時間を切り詰めることに注意してください。また、10年ごとの年齢階層を計算し、性別を特定します。CTEを使用する利点は、クエリ中に同じ中間結果セットを複数回使用できることです。この場合、リスク時間の合計およびリスク期間中に発生する血管浮腫の数を数えるために使用します。

SQLではフィールド名にスネークケースを使用するため（SQLは大文字小文字を区別しないため）、Rではキャメルケースを使用します（Rは大文字小文字を区別するため）。`results`データフレームの列名はキャメルケースになります。

ggplot2パッケージを使用すると、結果を簡単にプロットできます：


``` r
# 発症率（IR）を計算
results$ir <- 1000 * results$events / results$days / 7

# 年齢スケールを修正
results$age <- results$age * 10

library(ggplot2)
ggplot(results, aes(x = age, y = ir, group = gender, color = gender)) +
  geom_line() +
  xlab("年齢") +
  ylab("発症率（1,000患者週間当たり）")
```

\begin{center}\includegraphics[width=0.8\linewidth]{images/SqlAndR/ir} \end{center}

### クリーンアップ

作成したテーブルをクリーンアップし、接続を閉じることを忘れないでください：


``` r
sql <- "
TRUNCATE TABLE @cohort_db_schema.@cohort_table;
DROP TABLE @cohort_db_schema.@cohort_table;
"
renderTranslateExecuteSql(conn, sql,
                          cohort_db_schema = cohortDbSchema,
                          cohort_table = cohortTable)

disconnect(conn)
```

### 互換性

OHDSI SQLとDatabaseConnectorおよびSqlRenderを組み合わせて使用するため、ここで紹介したコードはOHDSIがサポートする任意のデータベースプラットフォームで実行できます。

デモンストレーションの目的で、手作業で作成したSQLを使用してコホートを作成することを選びましたが、ATLASでコホート定義を構築し、ATLASが生成したSQLを使用してコホートを実インスタンス化する方が便利です。ATLASもOHDSI SQLを生成し、SqlRenderおよびDatabaseConnectorと一緒に簡単に使用できます。

## まとめ

\BeginKnitrBlock{rmdsummary}
- **SQL**（Structured Query Language）は、共通データモデル（CDM）に準拠したデータベースを含む、データベースを照会するための標準言語です。

- 異なるデータベースプラットフォームは異なるSQL表現を持っており、照会するためには異なるツールが必要です。

- **SqlRender**および**DatabaseConnector**Rパッケージは、CDM内のデータを照会するための統一された方法を提供し、同じ分析コードを異なる環境で変更なしで実行できるようにします。

- RとSQLを組み合わせて使用することで、OHDSIツールではサポートされていないカスタム分析を実装できます。

- **QueryLibrary**は、CDM用の再利用可能なSQLクエリのコレクションを提供します。

\EndKnitrBlock{rmdsummary}
## 練習問題

#### 前提条件 {-}

これらの練習問題では、セクション \@ref(installR) に記載されているように、R、R-Studio、Java がインストールされていることを前提とします。また、[SqlRender](https://ohdsi.github.io/SqlRender/)、[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)、および [Eunomia](https://ohdsi.github.io/Eunomia/) パッケージも必要です。以下の手順でインストールできます。


``` r
install.packages(c("SqlRender", "DatabaseConnector", "remotes"))
remotes::install_github("ohdsi/Eunomia", ref = "v1.0.0")
```

Eunomia パッケージは、CDM 内でローカル R セッション内で動作するシミュレートされたデータセットを提供します。接続の詳細は以下の方法で取得できます。


``` r
connectionDetails <- Eunomia::getEunomiaConnectionDetails()
```

CDM データベースのスキーマは「main」です。

::: {.exercise #exercisePeopleCount}
SQL および R を使用して、データベース内に何人いるかを計算しなさい。

:::

::: {.exercise #exerciseCelecoxibUsers}
SQL および R を使用して、少なくとも 1 回のセレコキシブの処方を受けたことがある人の数を計算しなさい。

:::
::: {.exercise #exerciseGiBleedsDuringCelecoxib}
SQL および R を使用して、セレコキシブの服用中に胃腸出血の診断が出たケースの数を計算しなさい。(ヒント: 胃腸出血のコンセプト ID は [192671](http://athena.ohdsi.org/search-terms/terms/192671) です)

:::

提案された解答は付録 \@ref(SqlAndRanswers) にあります。
