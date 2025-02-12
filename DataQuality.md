# --翻訳作業中--　データ品質 {#DataQuality}

*章リーダー: Martijn Schuemie, Vojtech Huser & Clair Blacketer*

観察的医療研究に使用されるデータのほとんどは研究目的で収集されたものではありません。例えば、電子カルテ（EHR）は患者ケアをサポートするために必要な情報をキャプチャすることを目的としており、行政請求は支払者への費用配分の根拠を提供するために収集されます。多くの人々が、このようなデータを臨床研究に使用することの適切性について疑問を投げかけています。@vanDerLei_1991 は、「データは収集された目的のみに使用されるべきだ」とさえ述べています。この懸念は、私たちが行いたい研究のためにデータが収集されていなかったため、データの品質が十分であることが保証されていないというものです。データの品質が低い場合（入力がゴミなら）、そのデータを使用した研究の結果の品質も低いに違いありません（出力もゴミ）。したがって、観察的医療研究の重要な側面はデータ品質の評価であり、次の質問に答えることを目指しています。

> 私たちの研究目的に対して、データの品質は十分か？

データ品質（DQ）を次のように定義できます [@roebuck_2012]: \index{data quality}

> 特定の使用目的に対してデータを適切にする完全性、有効性、一貫性、タイムリーさ、および正確性の状態。

データが完璧であることはまずありませんが、私たちの目的にとって十分である可能性はあります。

DQは直接観察することができませんが、それを評価する方法論が開発されています。2種類のDQ評価が区別されます [@weiskopf_2013]: 一般的なDQを評価するための評価と、特定の研究の文脈でDQを評価するための評価です。

この章では、まずDQ問題の可能な原因をレビューし、その後、一般的なおよび研究特有のDQ評価の理論について議論し、OHDSIツールを使用してこれらの評価を実行する方法をステップバイステップで説明します。


## データ品質問題の原因

Chapter \@ref(EvidenceQuality) で述べたように、医師が自分の考えを記録する段階からデータの品質に対する脅威は数多く存在します。@dasu_2003 は、データのライフサイクルにおいて次のステップを区別し、各ステップにDQを統合することを推奨しています。これをDQ連続体と呼んでいます。

1. **データ収集と統合**。考えられる問題には、手動入力の誤り、バイアス（例: 請求におけるアップコーディング）、EHRでのテーブルの誤った結合、および欠測値のデフォルト値での置き換えが含まれます。
2. **データの保存と知識共有**。潜在的な問題としては、データモデルの文書化の欠如やメタデータの欠如が挙げられます。
3. **データ分析**。問題には、データ変換の誤り、データの誤った解釈、不適切な方法論の使用が含まれます。
4. **データの公開**。下流での使用のためにデータを公開する際の問題。

私たちが使用するデータはすでに収集され統合されていることが多いため、ステップ1を改善するためにできることはあまりありません。この章の後半で詳しく述べるように、このステップによって生成されるDQをチェックする方法があります。

同様に、私たちは特定の形式でデータを受け取ることが多いため、ステップ2の一部にはほとんど影響を与えることができません。しかし、OHDSIでは、すべての観察データを共通データモデル（CDM）に変換しており、このプロセスに対する所有権を持っています。一部の人々は、この特定のステップがDQを低下させる可能性があると懸念しています。しかし、このプロセスを制御しているため、セクション \@ref(etlUnitTests) で後述するように、DQを保護するための厳格な安全対策を構築することができます。いくつかの調査 [@defalco_2013;@makadia_2014;@matcho_2014;@voss_2015;@voss_2015b;@hripcsak_2018] によれば、正しく実行されれば、CDMへの変換時にほとんどエラーは導入されません。実際、広範なコミュニティと共有される十分に文書化されたデータモデルを持つことは、明確かつ明確な方法でデータを保存するのに役立ちます。

ステップ3（データ分析）も私たちの制御下にあります。OHDSIでは、このステップの品質問題についてはDQという用語をあまり使用せず、代わりに*臨床的妥当性*、*ソフトウェアの妥当性*および*方法の妥当性*という用語を使用します。これらについては、Chapter \@ref(ClinicalValidity)、Chapter \@ref(SoftwareValidity)、Chapter \@ref(MethodValidity) で詳しく議論しています。
## 一般的なデータ品質

観察研究の一般的な目的に対してデータが適しているかどうかを問うことができます。@kahn_harmonized_2016 は、このような一般的なデータ品質（DQ）を次の3つの要素から構成されると定義しています。

1. **準拠性**: データ値が指定された基準や形式に従っているか？3つのサブタイプが識別されます：
   - **値**: 記録されたデータ要素が指定された形式に合致しているか？例えば、すべての提供者の医療専門分野が有効なものであるか？
   - **関係**: 記録されたデータが指定された関係制約に合致しているか？例えば、DRUG_EXPOSURE データの PROVIDER_ID が PROVIDER テーブルに対応する記録を持っているか？
   - **計算**: データに対する計算が意図した結果をもたらすか？例えば、身長と体重から計算されたBMIがデータに記録されているものと等しいか？
2. **完全性**: 特定の変数が存在するか（例：診察室で測定された体重が記録されているか？）および変数がすべての記録された値を含んでいるか（例：すべての人々が既知の性別を持っているか？）
3. **妥当性**: データ値が信じられるものであるか？3つのサブタイプが定義されています：
    - **一意性**: 例えば、PERSON テーブルで各 PERSON_ID が一度しか出現しないか？
    - **非一時的**: 値、分布、または密度が予期される値と一致するか？例えば、データが示す糖尿病の有病率が既知の有病率と一致するか？
    - **一時的**: 値の変化が予期されるものと一致するか？例えば、予防接種の順序が推奨に一致するか？

    \index{データ品質!準拠} \index{データ品質!完全性} \index{データ品質!妥当性}

各コンポーネントは2つの方法で評価できます：

* **検証** はモデルとメタデータのデータ制約、システムの仮定、およびローカルな知識に焦点を当てます。外部参照には依存しません。検証の主要な特徴は、ローカル環境内のリソースを使用して予期される値や分布を決定する能力です。
* **検証（バリデーション）** は、関連する外部ベンチマークに対するデータ値の整合性に焦点を当てます。外部ベンチマークの一つの可能なソースは、複数のデータサイトからの結果を組み合わせることです。

\index{データ品質!検証} \index{データ品質!バリデーション}

### データ品質チェック

\index{ACHILLES} \index{データ品質!チェック}

カーンは、指定された要件にデータが準拠しているかどうかをテストする *データ品質チェック* （データ品質ルールとも呼ばれる）という用語を紹介しています（例：誤った生年や死亡イベントの欠落により患者の年齢が141であるというありえない値をフラグすること）。このようなチェックは、ソフトウェアで自動化されたデータ品質ツールを作成することで実装できます。一つのツールとして [ACHILLES](https://github.com/OHDSI/Achilles) （大規模な長期縦断エビデンスシステムにおける医療情報の自動特性評価）があります。 [@huser_methods_2018] ACHILLES は、CDM に準拠したデータベースの特性評価と可視化を提供するソフトウェアツールであり、そのため、データベースネットワーク内のデータ品質を評価するために使用できます。 [@huser_multisite_2016] ACHILLES はスタンドアロンツールとして利用可能であり、「データソース」機能として ATLAS に統合されています。 \index{データ品質!データ品質チェック} \index{ACHILLES}

ACHILLES は 170 以上のデータ特性評価分析を事前計算しており、各分析には分析 ID と分析の簡単な説明があります。例えば「715: DRUG_CONCEPT_ID 別の DAYS_SUPPLY の分布」や「506: 性別別の死亡時の年齢の分布」などです。これらの分析の結果はデータベースに保存され、ウェブビューアや ATLAS からアクセスできます。

\index{データ品質ダッシュボード}

データ品質を評価するためにコミュニティによって作成されたもう一つのツールは [データ品質ダッシュボード (DQD)](https://github.com/OHDSI/DataQualityDashboard) です。ACHILLES が CDM インスタンスの全体的な視覚的理解を提供するために特性評価分析を実行するのに対し、DQD はテーブルごとおよびフィールドごとに進み、特定の仕様に準拠していない CDM での記録の数を定量化します。合計で 1,500 以上のチェックが実行され、各チェックはカーンフレームワークに組織されています。各チェックの結果は閾値と比較され、閾値を上回る違反行がある場合に FAIL とみなされます。表 \@ref(tab:dqdExamples) にはいくつかの例チェックが示されています。

表: (\#tab:dqdExamples) データ品質ダッシュボードの例データ品質ルール。

| 違反行の割合 | チェックの説明 | 閾値 | 状態 |
|:-------- |:------------------------------------ |:------ |:---- |
| 0.34|VISIT_OCCURRENCE の provider_id が仕様に基づく期待されるデータ型であるかどうかを示す yes または no の値。 | 0.05 | FAIL|
| 0.99| MEASUREMENT テーブルの measurement_source_value フィールドにある異なるソース値の数およびパーセントが 0 にマッピングされている。| 0.30 | FAIL|
| 0.09| DRUG_ERA テーブルの drug_concept_id フィールドにある値が成分クラスに適合しない記録の数およびパーセント。 | 0.10 | PASS|
| 0.02| DRUG_EXPOSURE テーブルの DRUG_EXPOSURE_END_DATE フィールドの値が DRUG_EXPOSURE_START_DATE フィールドの日付より前に発生する記録の数およびパーセント。 |0.05|PASS|
| 0.00| PROCEDURE_OCCURRENCE テーブルの procedure_occurrence_id フィールドに重複する値がある記録の数およびパーセント。 | 0.00 | PASS|

ツール内では、チェックは複数の方法で組織化されており、その一つがテーブル、フィールド、概念レベルのチェックです。テーブルチェックは CDM 内の高レベルで行われるもので、すべての必須テーブルが存在するかどうかを判断する例などです。フィールドレベルのチェックは、すべてのテーブル内のすべてのフィールドが CDM 仕様に準拠しているかを評価する方式で実行されます。これには、すべての主キーが真に一意であることや、標準概念フィールドが適切なドメイン内の概念 ID を含むことを確認するなど多くの確認が含まれます。概念レベルのチェックはさらに深入りし、個々の概念 ID を調査します。これらの多くは、例として、性別の概念が誤った性別の人に帰属されていないか（例：女性患者に前立腺癌があること）を確認するなど、カーンフレームワークの妥当性カテゴリに該当します。

\BeginKnitrBlock{rmdimportant}
ACHILLES と DQD は CDM のデータに対して実行されます。この方法で特定されたデータ品質問題は CDM への変換によるものである場合もありますが、元のデータに既に存在するデータ品質問題を反映している場合もあります。変換が原因である場合、通常、問題を修正することが私たちのコントロール下にありますが、元のデータが原因である場合、唯一の対処法は当該記録を削除することかもしれません。


\EndKnitrBlock{rmdimportant}

### ETL 単体テスト {#etlUnitTests}

\index{ETL!単体テスト}

高レベルのデータ品質チェックに加えて、個々のレベルのデータチェックも実行する必要があります。データが CDM に変換される ETL (Extract-Transform-Load) プロセスはしばしば非常に複雑であり、その複雑さには未検出のミスを犯す危険性があります。さらに、時間の経過とともに元のデータモデルが変更されたり、CDM がアップデートされたりするため、ETL プロ세スの修正が必要になる場合があります。複雑なプロセスであるETLを変更することには意図しない影響が伴うことが多く、ETLのすべての側面を再検討し、レビューする必要があります。

ETL が予定通りの動作をすることを確実にするために、単体テストのセットを構築することが強く推奨されます。単体テストは、単一の側面を自動的にチェックする小さなコード断片です。第 \@ref(ExtractTransformLoad) 章で説明した Rabbit-in-a-Hat ツールは、このような単体テストのフレームワークを作成することで、単体テストの記述を容易にします。このフレームワークは、ETL のソースデータベースおよびターゲット CDM バージョンに特有の R 関数の集合です。これらの関数のいくつかはソースデータスキーマに準拠するダミーデータエントリを作成するためのものであり、他の関数は CDM 形式でのデータに対する期待を指定するためのものです。以下に単体テストの例を示します：


``` r
source("Framework.R")
declareTest(101, "Person gender mappings")
add_enrollment(member_id = "M000000102", gender_of_member = "male")
add_enrollment(member_id = "M000000103", gender_of_member = "female")
expect_person(PERSON_ID = 102, GENDER_CONCEPT_ID = 8507
expect_person(PERSON_ID = 103, GENDER_CONCEPT_ID = 8532)
```

この例では、Rabbit-in-a-Hat によって生成されたフレームワークがソースされ、その後のコードで使用される関数がロードされます。次に、person gender mappings のテストを開始することを宣言します。ソーススキーマには ENROLLMENT テーブルがあり、Rabbit-in-a-Hat によって作成された add_enrollment 関数を使用して、MEMBER_ID および GENDER_OF_MEMBER フィールドに異なる値を持つ2つのエントリを作成します。最後に、ETL の後、さまざまな期待される値を持つ PERSON テーブルに2つのエントリが存在することを指定します。

ENROLLMENT テーブルには他にも多くのフィールドがありますが、このテストの文脈ではこれらの他のフィールドが持つ値についてはあまり気にしません。ただし、これらの値（例：生年月日）が空のままだとETLが記録を破棄したりエラーを引き起こしたりする可能性があります。この問題を克服しながらテストコードを読みやすく保つために、`add_enrollment` 関数は、指定されていないフィールド値に対してデフォルト値（White Rabbit スキャンレポートで観察された最も一般的な値）を割り当てます。

ETL の他のロジック全体に対しても同様の単体テストを作成することができ、通常は何百ものテストが作成されます。テストの定義が終了したら、フレームワークを使用して、ダミーのソースデータを作成するための SQL ステートメントのセットと、ETL 後のデータに対するテストを作成するための SQL ステートメントのセットを生成できます：


``` r
insertSql <- generateInsertSql(databaseSchema = "source_schema")
testSql <- generateTestSql(databaseSchema = "cdm_test_schema")
```

全体のプロセスは図 \@ref(fig:testFramework) に示されています。

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{images/DataQuality/testFramework} 

}

\caption{Rabbit-in-a-Hat テストフレームワークを使用した ETL (Extract-Transform-Load) プロセスの単体テスト。}(\#fig:testFramework)
\end{figure}

テスト SQL は表 \@ref(tab:exampleTestResults) のようなテーブルを返します。このテーブルでは、以前に定義した2つのテストに合格したことがわかります。

表: (\#tab:exampleTestResults) ETL 単体テスト結果の例。

| ID    | 説明                  | 状態   |
|:-----:|:--------------------- |:------:|
| 101   | Person gender mappings | PASS   |
| 101   | Person gender mappings | PASS   |

これらの単体テストの力は、ETL プロセスが変更されたときに簡単に再実行できることです。

## 研究特有のチェック

\index{データ品質! 研究特有のチェック}

これまでの章では、一般的なデータ品質（DQ）チェックに焦点を当ててきました。このようなチェックは、データを研究で使用する前に実行すべきです。これらのチェックは研究質問に関わらず行われるため、研究特有のDQ評価を実施することをお勧めします。

これらの評価の一部は、研究に特に関連するDQルールの形を取ることができます。たとえば、関心のある曝露の記録の少なくとも90％が曝露の長さを指定しているというルールを課すことが望ましいかもしれません。

標準的な評価として、ACHILLESで研究に最も関連する概念、たとえばコホート定義で指定された概念を見直すことが挙げられます。コードが観察される率が時間とともに急激に変化する場合、DQの問題が示唆されるかもしれません。いくつかの例については、この章の後半で説明します。

別の評価として、研究のために開発されたコホート定義を使用して生成された結果コホートの有病率と時間とともに変化を見直し、外部クリニカルナレッジに基づいて期待されるものと一致するかどうかを確認します。たとえば、新薬の曝露は市場導入前には存在せず、導入後に時間とともに増加する可能性があります。同様に、アウトカムの有病率は、人口内でその症状の有病率として知られているものと一致する必要があります。ネットワーク全体で研究が実行される場合、データベース間でコホートの有病率を比較することができます。あるデータベースで非常に有病なコホートが別のデータベースで欠けている場合、DQの問題があるかもしれません。このような評価は、*臨床的妥当性*の概念と重なることに注意してください（Chapter \@ref(ClinicalValidity) で議論されています）。いくつかのデータベースで予期しない有病率を見つけるのは、DQの問題ではなく、コホート定義が関心のある健康状態を真に捉えていないため、または異なる患者集団を捉えたデータベースで健康状態が正当に異なるためである可能性があります。

### マッピングのチェック

しっかりと管理下にある可能なエラーの一つは、ソースコードから標準概念へのマッピングです。Vocabulary 内のマッピングは慎重に作成されており、コミュニティメンバーによって指摘されたマッピングのエラーは Vocabulary の問題トラッカー[^vocabIssueTrackerUrl] で報告され、今後のリリースで修正されます。それでも、すべてのマッピングを手で完全にチェックすることは不可能であり、エラーが依然として存在する可能性があります。そのため、研究を実行する際には、研究に最も関連する概念のマッピングを確認することをお勧めします。幸いなことに、CDMでは標準概念だけでなく、ソースコードも保存するため、これを比較的簡単に行うことができます。研究で使用される概念にマッピングされたソースコードと、マッピングされていないソースコードの両方を確認できます。

[^vocabIssueTrackerUrl]: https://github.com/OHDSI/Vocabulary-v5.0/issues

マッピングされたソースコードを確認する方法の一つは、MethodEvaluation R パッケージの `checkCohortSourceCodes` 関数を使用することです。この関数は、ATLAS によって作成されたコホート定義を入力として使用し、コホート定義で使用される各コンセプトセットに対して、どのソースコードがセットの概念にマッピングされているかをチェックします。これにより、特定のソースコードに関連する時間的な問題を特定するためのコードの有病率も計算されます。図 \@ref(fig:sourceCodes) のサンプル出力は、「抑うつ障害」と呼ばれるコンセプトセットの（部分的な）内訳を示しています。関心のあるデータベースでこのコンセプトセットで最も有病な概念は、概念 [440383](http://athena.ohdsi.org/search-terms/terms/440383) ("抑うつ障害") です。この概念には、データベース内の3つのソースコードがマッピングされています：ICD-9コード3.11およびICD-10コードF32.8とF32.89です。左側には概念全体の有病率が、最初は徐々に増加し、その後急激に減少していることが示されています。個々のコードを見ると、この減少はICD-9コードの使用が停止する時点と一致していることがわかります。これはICD-10コードの使用開始時点とも一致していますが、ICD-10コードの合計有病率はICD-9コードよりもはるかに小さくなっています。この例は、ICD-10コードF32.9（「大うつ病エピソード、特定不能」）もこの概念にマッピングされるべきものだったために発生しました。この問題はその後、Vocabularyで解決されました。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/DataQuality/sourceCodes} 

}

\caption{checkCohortSourceCodes関数のサンプル出力。}(\#fig:sourceCodes)
\end{figure}

前の例は、マッピングされていないソースコードの発見の機会を示していますが、一般的にマッピングが存在するかどうかを確認するよりも、マッピングされていないものを特定する方が困難です。これは、マッピングされるべきソースコードを知っている必要があります。半自動的に評価を行う方法の一つは、MethodEvaluation R パッケージの `findOrphanSourceCodes` 関数を使用することです。この関数は、単純なテキスト検索を使用してソースコードをボキャブラリー内で検索し、これらのソースコードが特定の概念またはその概念の子孫にマッピングされているかどうかを確認します。結果のソースコードセットは、その後、当該CDMデータベースに表示されるものに制限されます。たとえば、研究では、概念「壊疽障害」（[439928](http://athena.ohdsi.org/search-terms/terms/439928)）およびそのすべての子孫を使用して、壊疽の発生をすべて見つけようとしました。これが本当にすべての壊疽を示すソースコードを含んでいるかどうかを評価するために、「壊疽」などの用語を使用して、CONCEPTおよびSOURCE_TO_CONCEPT_MAPテーブル内の説明を検索し、ソースコードを特定しました。その後、自動検索を使用して、データに表示される各壊疽ソースコードが、データに直接または間接的に（祖先を介して）「壊疽障害」概念にマッピングされているかどうかを評価しました。この評価の結果が図 \@ref(fig:missingMapping) に示されており、ICD-10コードJ85.0（「肺の壊疽および壊死」）が概念 [4324261](http://athena.ohdsi.org/search-terms/terms/4324261)（「肺壊死」）にのみマッピングされており、これは「壊疽障害」の子孫ではありませんでした。

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{images/DataQuality/missingMapping} 

}

\caption{孤立したソースコードのサンプル。}(\#fig:missingMapping)
\end{figure}

## 実践におけるACHILLES {#achillesInPractice}

ここでは、CDM形式のデータベースに対してACHILLESを実行する方法を示します。

まず、Rにサーバーへの接続方法を教える必要があります。ACHILLESは [DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/) パッケージを使用し、このパッケージは `createConnectionDetails` と呼ばれる関数を提供します。特定のデータベース管理システム（DBMS）に必要な設定については、`?createConnectionDetails`を参照してください。たとえば、PostgreSQLデータベースに接続するには、次のコードを使用します：


``` r
library(Achilles)
connDetails <- createConnectionDetails(dbms = "postgresql",
                                       server = "localhost/ohdsi",
                                       user = "joe",
                                       password = "supersecret")

cdmDbSchema <- "my_cdm_data"
cdmVersion <- "5.3.0"
```

最後の2行で `cdmDbSchema` 変数とCDMバージョンを定義しています。これは後で、CDM形式のデータがどこにあるか、どのバージョンのCDMが使用されているかをRに教えます。Microsoft SQL Serverの場合、データベーススキーマにはデータベースとスキーマの両方を指定する必要があることに注意してください。例えば、`cdmDbSchema <- "my_cdm_data.dbo"` です。

次に、ACHILLESを実行します：


``` r
result <- achilles(connectionDetails,
                   c
## Data Quality Dashboardの実践 {#dqdInPractice}

ここでは、CDM形式のデータベースに対してData Quality Dashboardを実行する方法を示します。この作業は、セクション\@ref(achillesInPractice)で説明したCDM接続に対して大規模なチェックセットを実行することによって行います。現時点でDQDはCDM v5.3.1のみをサポートしているため、接続する前にデータベースが正しいバージョンであることを確認してください。ACHILLESと同様に、Rがデータを検索する場所を指定するために`cdmDbSchema`変数を作成する必要があります。
```

``` r
cdmDbSchema <- "my_cdm_data.dbo"
```

次に、Dashboardを実行します...


``` r
DataQualityDashboard::executeDqChecks(connectionDetails = connectionDetails,
                                      cdmDatabaseSchema = cdmDbSchema,
                                      resultsDatabaseSchema = cdmDbSchema,
                                      cdmSourceName = "My database",
                                      outputFolder = "My output")
```

上記の関数は、指定されたスキーマに対して利用可能なすべてのデータ品質チェックを実行します。その後、チェックの実行結果を含むテーブルを`resultsDatabaseSchema`に書き込みます。ここでは、CDMと同じスキーマに設定しています。このテーブルには、各チェックランに関するすべての情報が含まれます。例えば、CDMテーブル、CDMフィールド、チェック名、チェック説明、Kahnカテゴリおよびサブカテゴリ、違反行数、しきい値レベル、およびチェックの合否などです。また、この関数は指定された`outputFolder`にJSONファイルも書き込みます。このJSONファイルを使用して、結果を確認するためのウェブビューアを起動することができます。


``` r
viewDqDashboard(jsonPath)
```

変数`jsonPath`は、Dashboardの結果を含むJSONファイルのパスを指定する必要があります。このファイルは、上記の`executeDqChecks`関数を呼び出す際に指定した`outputFolder`内にあります。

Dashboardを初めて開くと、図\@ref(fig:dqdOverview)に示されるように概観テーブルが表示されます。これには、各Kahnカテゴリごとに実行された総チェック数、コンテキストごとの内訳、各カテゴリの合否数およびパーセンテージ、全体の合格率が示されます。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/DataQuality/dqdOverview} 

}

\caption{Data Quality Dashboardにおけるデータ品質チェックの概要。}(\#fig:dqdOverview)
\end{figure}

左側のメニューで*Results*をクリックすると、実行された各チェックの詳細結果を見ることができます（図\@ref(fig:dqdResults)）。この例では、指定されたテーブルに少なくとも1件の記録を持つCDMの個人の数とパーセンテージを判断するためのチェックランが表示されています。この場合、リストされた5つのテーブルはすべて空であり、Dashboardはこれを失敗としてカウントします。![](images/DataQuality/plusIcon.png) アイコンをクリックすると、実行された正確なクエリがデータについて表示され、その結果がリストされています。これにより、Dashboardが失敗と判定した行の特定が容易になります。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/DataQuality/dqdResults} 

}

\caption{Data Quality Dashboardにおけるデータ品質チェックの詳細。}(\#fig:dqdResults)
\end{figure}


## 特定の研究チェックの実践

次に、付録\@ref(Angioedema)で提供されているアンギオオデーマコホート定義に対して特定のチェックを実行します。ここでは、セクション\@ref(achillesInPractice)で説明したように接続詳細が設定されていることを前提とし、コホート定義のJSONとSQLが"cohort.json"および"cohort.sql"ファイルに保存されていることを前提とします。JSONとSQLは、ATLASのコホート定義機能のエクスポートタブから入手できます。


``` r
library(MethodEvaluation)
json <- readChar("cohort.json", file.info("cohort.json")$size)
sql <- readChar("cohort.sql", file.info("cohort.sql")$size)
checkCohortSourceCodes(connectionDetails,
                       cdmDatabaseSchema = cdmDbSchema,
                       cohortJson = json,
                       cohortSql = sql,
                       outputFile = "output.html")
```

出力ファイルをウェブブラウザで開くことができます（図\@ref(fig:sourceCodesAngioedema)）。ここでは、アンギオオデーマコホート定義には"入院またはER訪問"と"アンギオオデーマ"という二つの概念セットがあります。この例のデータベースでは、訪問は"ER"および"IP"というデータベース固有のソースコードによって見つかり、ETL中に標準概念にマッピングされました。また、アンギオオデーマは一つのICD-9コードと二つのICD-10コードによって見つかります。それぞれのコードのスパークラインを見ると、二つのコーディングシステムのどの時点で切り替わったかが明らかになりますが、概念セット全体としてはその時点での不連続性はありません。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/DataQuality/sourceCodesAngioedema} 

}

\caption{アンギオオデーマコホート定義で使用されるソースコード。}(\#fig:sourceCodesAngioedema)
\end{figure}

次に、標準概念コードにマッピングされていない孤立したソースコードを検索できます。ここでは、標準概念「Angioedema」を検索し、名前の一部として"Angioedema"または提供する同義語を含むコードや概念を探します。


``` r
orphans <- findOrphanSourceCodes(connectionDetails,
                                 cdmDatabaseSchema = cdmDbSchema,
                                 conceptName = "Angioedema",
                                 conceptSynonyms = c("Angioneurotic edema",
                                                     "Giant hives",
                                                     "Giant urticaria",
                                                     "Periodic edema"))
View(orphans)
```
|コード              |説明                                                            |語彙ID       | 全体のカウント|
|:-----------------|:----------------------------------------------------------------------|:------------|------------:|
|T78.3XXS          |Angioneurotic edema, sequela                                           |ICD10CM      |          508|
|10002425          |Angioedemas                                                            |MedDRA       |            0|
|148774            |Angioneurotic Edema of Larynx                                          |CIEL         |            0|
|402383003         |Idiopathic urticaria and/or angioedema                                 |SNOMED       |            0|
|232437009         |Angioneurotic edema of larynx                                          |SNOMED       |            0|
|10002472          |Angioneurotic edema, not elsewhere classified                          |MedDRA       |            0|

唯一データで使用されている可能性がある孤立したコードは"Angioneurotic edema, sequela"であり、これはアンギオオデーマにマッピングされるべきではありません。この分析は、欠落したコードを明らかにしませんでした。


## まとめ

\BeginKnitrBlock{rmdsummary}
- ほとんどの観察医療データは研究のために収集されたものではありません。

- データ品質チェックは研究の重要な部分です。データが研究目的に十分な品質かどうかを判断するためにデータ品質を評価する必要があります。

- 一般的な研究目的のために、そして特定の研究の文脈でデータ品質を評価する必要があります。

- データ品質の一部の側面は、Data Quality Dashboardのような大規模な事前定義されたルールセットを通じて自動的に評価できます。

- 特定の研究に関連するコードのマッピングを評価するための他のツールも存在します。


\EndKnitrBlock{rmdsummary}


## 実習

#### 前提条件 {-}

これらの演習では、セクション\@ref(installR)で説明した通りにR、R-Studio、およびJavaがインストールされていることを前提とします。必要なパッケージは[SqlRender](https://ohdsi.github.io/SqlRender/)、[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)、[ACHILLES](https://github.com/OHDSI/Achilles)、および[Eunomia](https://ohdsi.github.io/Eunomia/)であり、以下のコマンドでインストールできます：


``` r
install.packages(c("SqlRender", "DatabaseConnector", "remotes"))
remotes::install_github("ohdsi/Achilles")
remotes::install_github("ohdsi/DataQualityDashboard")
remotes::install_github("ohdsi/Eunomia", ref = "v1.0.0")
```

Eunomiaパッケージは、ローカルのRセッション内で実行されるCDMのシミュレーションデータセットを提供します。接続情報は以下のコマンドで取得できます：


``` r
connectionDetails <- Eunomia::getEunomiaConnectionDetails()
```

CDMデータベーススキーマは「main」です。

::: {.exercise #exerciseRunAchilles}
Eunomiaデータベースに対してACHILLESを実行してください。

:::

::: {.exercise #exerciseRunDQD}
Eunomiaデータベースに対してData Quality Dashboardを実行してください。

:::

::: {.exercise #exerciseViewDQD}
DQDのチェックリストを抽出してください。

:::

提案された回答は付録\@ref(DataQualityanswers)にあります。
