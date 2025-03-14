# OHDSI 分析ツール {#OhdsiAnalyticsTools}

*著者: Martijn Schuemie & Frank DeFalco*

OHDSIは、患者レベルの観察データに対するさまざまなデータ分析のユースケースをサポートするための幅広いオープンソースツールを提供しています。これらのツールの共通点は、すべて共通データモデル（CDM）を使用して1つ以上のデータベースと相互にやりとりできることです。さらに、これらのツールはさまざまなユースケースに対して分析を標準化します。ゼロから始める必要はなく、標準テンプレートに入力することで分析を実装できます。これにより、分析が容易になり、再現性と透明性が向上します。例として、発生率を計算する方法は無数にあるように思われますが、OHDSIツールではいくつかの選択肢で指定でき、同じ選択肢を選んだ人は同じ方法で発生率を計算します。

本章では、最初に分析を実装するさまざまな方法を説明し、分析で採用できる戦略について説明します。次に、さまざまなOHDSIツールとそれらがどのようにさまざまなユースケースにどのように適合するかを検討します。

## 分析の実装 {#analysisImplementation}

図 \@ref(fig:implementations) は、CDMを使用してデータベースに対して研究を実装するために選択できるさまざまな方法を示しています。 \index{分析の実装}

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{images/OhdsiAnalyticsTools/implementations} 

}

\caption{CDMのデータに対する分析を実装するさまざまな方法}(\#fig:implementations)
\end{figure}

研究を実装するための主なアプローチは3つあります。最初の方法は、OHDSIが提供するツールを一切使用しないカスタムコードを作成することです。R、SAS、またはその他の言語で新規の分析を作成することができます。これにより最大の柔軟性が得られ、特定の分析がツールでサポートされていない場合は唯一の選択肢となるかもしれません。しかし、この方法は高度な技術、時間、労力を必要とし、分析が複雑になるほどコードのエラーを避けることが難しくなります。

2番目の方法は、Rで分析を開発し、[OHDSI Methods Library](https://ohdsi.github.io/MethodsLibrary/)のパッケージを利用する方法です。少なくとも、[SqlRender](https://ohdsi.github.io/SqlRender/)と[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)のパッケージを使用できます。これらのパッケージについては、第 \@ref(SqlAndR) 章で詳しく説明していますが、PostgreSQL、SQL Server、Oracleなどのさまざまなデータベースプラットフォーム上で同じコードを実行することができます。また、[CohortMethod](https://ohdsi.github.io/CohortMethod/)や[PatientLevelPrediction](https://ohdsi.github.io/PatientLevelPrediction/)などのパッケージでは、CDMに対する高度な分析のためのR関数が提供されており、コードから呼び出すことができます。これには依然として高度な専門知識が必要ですが、検証済のMethods Libraryのコンポーネントを再利用することで、完全にカスタムコードを使用する場合よりも効率的に作業を進めることができ、エラーが発生する可能性も低くなります。

3番目の方法は、プログラマーでなくても幅広く分析を効率的に実行できるウェブベースのツール、[ATLAS](https://github.com/OHDSI/Atlas/wiki)を使用することです。ATLASはMethods Librariesを使用しますが、分析をデザインするための単純なグラフィカルインターフェイスを提供し、多くの場合、分析を実行するために必要なRコードを生成します。ただし、Methods Libraryで利用可能なすべてのオプションをサポートしているわけではありません。大半の研究はATLASを通じて行うことができると予想されますが、2番目の方法が提供する柔軟性を必要とする研究もあります。

ATLASとMethods Libraryは独立したものではありません。ATLASで呼び出される複雑な分析の一部は、Methods Libraryのパッケージへの呼び出しを通じて実行されます。同様に、Methods Libraryで使用されるコホートは、多くの場合、ATLASでデザインされています。

## 分析戦略

CDMに対する分析を実装するための戦略に加え、例えばカスタムコーディングやMethods Libraryで提供される標準分析コードの利用など、エビデンスを生成するための分析技術を使用する複数の戦略もあります。図 \@ref(fig:strategies) は、OHDSIで採用されている3つの戦略を示しています。

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{images/OhdsiAnalyticsTools/strategies} 

}

\caption{(臨床の)問いに対するエビデンスを生成するための戦略}(\#fig:strategies)
\end{figure}

最初の戦略では、各分析を個別の研究として扱います。分析はプロトコルで事前に規定し、コードとして実装し、データに対して実行し、その後、結果をまとめ解釈します。各課題（リサーチクエスチョン）ごとに、すべてのステップを繰り返す必要があります。このような分析の一例は、レベチラセタムとフェニトインを比較した際の血管性浮腫のリスクに関するOHDSI研究です[@duke_2017]。 ここでは、まずプロトコルが作成され、OHDSI Methods Libraryを使用した分析コードが開発され、OHDSIネットワーク全体で実行され、結果がまとめられて学術誌に公表されました。

第二の戦略では、リアルタイムまたはほぼリアルタイムで特定のクラスの問いに答えられるアプリケーションを開発します。アプリケーションが開発されると、ユーザーはクエリをインタラクティブに定義し、それを送信して結果を表示できます。この戦略の一例は、ATLASのコホート定義および生成ツールです。このツールは、ユーザーが複雑さの異なるコホート定義を指定し、データベースに対してその定義を実行して、さまざまな適格基準と除外基準を満たす人数を確認することができます。

第三の戦略では、同様に問いに焦点を当てますが、その問いのクラス内のすべてのエビデンスを網羅的に生成しようとします。ユーザーは、さまざまなインターフェースを通じて必要に応じてエビデンスを探索できます。一例は、うつ病治療の効果に関するOHDSI研究です[@schuemie_2018b]。 この研究では、すべてのうつ病治療が、4つの大規模な観察研究データベースで関心のあるアウトカムの大規模なセットに対して比較されました。17,718の実証的にキャリブレーションされたハザード比と広範な研究診断を含む結果の全セットは、インタラクティブなウェブアプリ [^ohdsianalyticstools-1] で利用できます。

[^ohdsianalyticstools-1]: <http://data.ohdsi.org/SystematicEvidence/>

## ATLAS

ATLAS は、OHDSI コミュニティが開発した、標準化された患者レベルの観察データを CDM 形式で分析する設計と実行を支援する、無料で公開されているウェブベースのツールです。ATLAS は、OHDSI WebAPI と組み合わせてウェブアプリケーションとして展開され、通常は Apache Tomcat 上でホストされます。リアルタイム分析を行うには、CDM 内の患者レベルデータへのアクセスが必要であるため、通常は組織のファイアウォールのバックにインストールされます。ただし、パブリックなATLAS^[40](https://ohdsi.github.io/TheBookOfOhdsi/OhdsiAnalyticsTools.html#fn40)^も存在し、このATLASインスタンスは少数の小規模なシミュレーションデータセットにしかアクセスできませんが、テストやトレーニングなど、多くの目的に使用できます。パブリックなATLASインスタンスを使用して効果の推定や予測研究を完全に定義し、研究を実行するためのRコードを自動的に生成することも可能です。そのコードは、ATLASとWebAPIをインストールすることなく、利用可能なCDMがインストールされている環境であればどこでも実行できます。\index{ATLAS}

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/atlas} 

}

\caption{ATLASユーザインタフェース}(\#fig:atlas)
\end{figure}

図 \@ref(fig:atlas) にATLASのスクリーンショットを示します。左側にはATLASの様々な機能を示すナビゲーションバーがあります。

データソース \index{ATLAS!データソース} \index{ACHILLES|see {ATLAS!データソース}}

:   データソースは、ATLASプラットフォームに構成された各データソースの記述的で標準化されたレポートをレビューする機能を提供します。この機能は大規模分析戦略を用いており、すべての記述は事前に計算されています。データソースについては、第\@ref(Characterization)章で説明します。

ボキャブラリ検索 \index{ATLAS!ボキャブラリ検索}

:   ATLASはOMOP標準化ボキャブラリを検索し、これらのボキャブラリにどのようなコンセプトが存在するのか、そしてそのコンセプトをどう適用するかを理解するための機能を提供します。この機能については、第\@ref(StandardizedVocabularies)章で議論されています。

コンセプトセット \index{ATLAS!コンセプトセット}

:   コンセプトセットは、標準化された分析全体で使用するコンセプトのセットを識別するために使用できる論理式のコレクションを作成する機能を提供します。コンセプトセットは単純なコードや値のリストよりも高度な機能を提供します。コンセプトセットは、標準化ボキャブラリからの複数のコンセプトと、関連するコンセプトの適格や除外を指定するための論理インジケータを組み合わせて構成されます。ボキャブラリの検索、コンセプトセットの特定、そしてコンセプトセットを決定するために使用する論理の指定は、分析プランで使用されることが多い難解な医療用語を定義するための強力なメカニズムとなります。これらのコンセプトセットはATLAS内に保存され、その後の分析の一部としてコホート定義や分析仕様に使用できます。

コホート定義 \index{ATLAS!コホート定義}

:   コホート定義は、一定期間内に1つまたは複数の基準を満たす人のセットを構築する機能であり、これらのコホートはその後のすべての分析の入力の基礎として使用されます。この機能については、第\@ref(Cohorts)章で説明します。

特性評価\index{ATLAS!特性評価}

:   特性評価は、定義された１つまたは複数のコホートを調査し、これらの患者集団の特性を要約するための分析機能です。この機能はリアルタイムクエリ戦略を用いており、第\@ref(Characterization)章で説明しています。

コホート経路 \index{ATLAS!コホート経路}

:   コホート経路は、1つまたは複数の集団内で発生する臨床イベントのシーケンスを観察できる分析ツールです。この機能については、第\@ref(Characterization)章で説明されています。

発生率 \index{ATLAS!発生率}

:   発生率は、対象集団内のアウトカムの発生率を推定するためのツールです。この機能については、第\@ref(Characterization)章で説明されています。

プロファイル \index{ATLAS!プロファイル}

:   プロファイルは、個々の患者の縦断的観察データを調査し、特定の個人に起こっている状況を要約するためのツールです。この機能はリアルタイムクエリ戦略を使用します。

集団レベルの推定 \index{ATLAS!集団レベルの推定}

:   推定は、比較コホートデザインを使用して集団レベルの効果推定研究を定義し、1つまたは複数の対象コホートと比較コホート間の比較の一連の結果を調査することができます。この機能はコーディングが不要で、リアルタイムクエリ戦略を実装していると言えます。この機能については第\@ref(PopulationLevelEstimation)章で説明されています。

患者レベルの予測 \index{ATLAS!患者レベルの予測}

:   予測機能は機械学習アルゴリズムを適用して、患者レベルの予測分析を行い、特定のターゲット曝露内でアウトカムを予測することができます。この機能もリアルタイムクエリ戦略を実装しており、コーディングが不要です。第\@ref(PatientLevelPrediction)章で説明されています。

ジョブ \index{ATLAS!ジョブ}

:   ジョブメニュー項目を選択して、WebAPIを通じて実行されているプロセスの状態を確認できます。ジョブは、コホートの生成やコホートの特性評価のレポートの計算など、長時間実行されるプロセスであることが多いです。

構成 \index{ATLAS!構成}

:   構成メニュー項目を選択して、ソース構成セクションに構成されたデータソースを確認できます。

フィードバック \index{ATLAS!フィードバック}

:   フィードバックリンクをクリックすると、ATLASの課題ログにアクセスし、新しいイシューのログの記録や既存のイシューの検索ができます。新しい機能や拡張機能のアイデアがある場合は、開発コミュニティに伝える場所としても利用できます。

### セキュリティ

ATLASとWebAPIは、プラットフォーム全体で機能やデータソースへのアクセスを制御するための細かいセキュリティモデルを提供します。セキュリティシステムはApache Shiroライブラリを活用して構築されています。セキュリティシステムの詳細は、オンラインのWebAPIセキュリティWikiで確認できます [^ohdsianalyticstools-2]。 \index{ATLAS!セキュリティ}

[^ohdsianalyticstools-2]: <https://github.com/OHDSI/WebAPI/wiki/Security-Configuration>

### ドキュメント

ATLASのドキュメントは、ATLAS GitHubリポジトリのWikiでオンラインで確認できます [^ohdsianalyticstools-3]。 このWikiには、さまざまなアプリケーション機能に関する情報や、オンラインビデオチュートリアルへのリンクが含まれています。 \index{ATLAS!ドキュメント}

[^ohdsianalyticstools-3]: <https://github.com/OHDSI/ATLAS/wiki>

### インストール方法

ATLASのインストールは、OHDSI WebAPIと組み合わせて行います。各コンポーネントのインストールガイドは、ATLAS GitHubリポジトリのセットアップガイド[^ohdsianalyticstools-4]とWebAPI GitHubリポジトリのインストールガイド[^ohdsianalyticstools-5]をオンラインで参照できます。 \index{ATLAS!インストール}

[^ohdsianalyticstools-4]: <https://github.com/OHDSI/Atlas/wiki/Atlas-Setup-Guide>

[^ohdsianalyticstools-5]: <https://github.com/OHDSI/WebAPI/wiki/WebAPI-Installation-Guide>

## Methods Library

[OHDSI Methods library](https://ohdsi.github.io/MethodsLibrary/)は、図 \@ref(fig:methodsLibrary) に示されているオープンソースのRパッケージのコレクションです。 \index{Methods Library}

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/methodsLibrary} 

}

\caption{OHDSI Methods Libraryのパッケージ}(\#fig:methodsLibrary)
\end{figure}

これらのパッケージは、CDM内のデータから始まり、推定値やそれを裏付ける統計、図表を生成する完全な観察研究を実施するためのR関数を提供しています。これらのパッケージはCDM内の観察データと直接やりとりし、第\@ref(SqlAndR)章で説明されているような完全にカスタマイズされた分析にクロスプラットフォームの互換性を提供するために用いることも、集団特性の評価（第\@ref(Characterization)章）、集団レベルの効果推定（第\@ref(PopulationLevelEstimation)章）、患者レベルの予測（第\@ref(PatientLevelPrediction)章 ）のための高度な標準化分析を提供することもできます。Methods libraryは、透明性、再現性、異なるコンテキストでのメソッドの操作特性の測定値、そのメソッドによって生成される推定値やその後の実証的キャリブレーションなど、過去や現在の研究から学んだベストプラクティスをサポートしています。

Methods libraryはすでに多くの公表された臨床研究 [@boland_2017; @duke_2017; @ramcharran_2017; @weinstein_2017; @wang_2017; @ryan_2017; @ryan_2018; @vashisht_2018; @yuan_2018; @johnston_2019] で使用されており、方法論の研究にも利用されています [@schuemie_2014; @schuemie_2016; @reps2018; @tian_2018; @schuemie_2018; @schuemie_2018b; @reps_2019]。Methods library内のメソッドの実装の妥当性については第 \@ref(SoftwareValidity) 章で説明されています。

### 大規模分析サポート

すべてのパッケージで組み込まれている重要な機能の一つは、多くの分析を効率的に実行できることです。例えば、集団レベルの推定を行う場合、CohortMethodパッケージは多数の曝露とアウトカムに対して効果量の推定を行うことを可能にし、さまざまな分析設定を使用して、必要な中間データセットや最終データセットを計算するための最適な方法を自動的に選択します。共変量の抽出や、一つのターゲット・比較対照ペアに対して複数のアウトカムで使用される傾向スコアモデルの適合など、再利用可能なステップは一度だけ実行されます。可能な場合は、計算リソースを最大限に活用するために計算は並列処理されます。

この計算効率により、大規模な分析が可能になり、多くの課題に一度に回答することができます。また、コントロール仮説（ネガティブコントロールなど）を含めることで、当社の手法の運用特性を測定し、第\@ref(MethodValidity)章 で説明されているように、実証的なキャリブレーションを行うことも不可欠です。 \index{コントロール仮説}

### ビッグデータ対応 {#BigDataSupport}

Methods Libraryは、非常に大規模なデータベースに対しても大量のデータを含む計算を実行できるようにデザインされています。これは次の三つの方法で実現されます：

1.  大部分のデータ操作はデータベースサーバー上で実行されます。分析は通常、データベース内の全データのごく一部しか必要としないため、Methods LibraryはSqlRenderやDatabaseConnectorパッケージを介して関連データの前処理や抽出をする高度な操作をサーバー上で実行できるようにします。
2.  大量のローカルデータオブジェクトはメモリ効率の良い方法で保存されます。ローカルマシンにダウンロードされるデータについては、Methods Libraryは[ff](https://cran.r-project.org/web/packages/ff)パッケージを使用して大規模データオブジェクトを保存、処理します。これにより、メモリに収まらないほど大きなデータでも処理することが可能です。
3.  必要に応じて高性能コンピューティングが適用されます。例えば、[Cyclops](https://ohdsi.github.io/Cyclops/)パッケージは、Methods Library全体で使用される非常に効率的な回帰エンジンを実装しており、これにより通常は適合できない大規模な回帰（多くの変数、大量の観測値）を実行することができます。

### ドキュメント

Rはパッケージを文書化するための標準的な方法を提供しています。各パッケージには、パッケージに含まれるすべての関数とデータセットを文書化した*パッケージマニュアル*があります。すべてのパッケージマニュアルは、Methods Libraryのウェブサイト[^ohdsianalyticstools-6]、パッケージのGitHubリポジトリ、CRANで利用できます。さらに、Rの内部からパッケージマニュアルを参照するにはクエスチョンマークを使用します。例えばDatabaseConnectorパッケージを読み込んだ後、コマンド`?connect`を入力すると「connect」関数に関するドキュメントが表示されます。

[^ohdsianalyticstools-6]: <https://ohdsi.github.io/MethodsLibrary>

パッケージマニュアルに加えて、多くのパッケージは*ビネット*が提供されています。ビネットは、特定のタスクを実行するためにパッケージをどのように使用するかを説明した詳細なドキュメントです。例えば、一つのビネット[^ohdsianalyticstools-7]では、CohortMethodパッケージを使用して複数の分析を効率的に実行する方法が説明されています。ビネットはMethods Libraryのウェブサイト、パッケージのGitHubリポジトリ、CRANで入手可能なパッケージはCRANでも見つけることができます。 \index{ビネット}

[^ohdsianalyticstools-7]: <https://ohdsi.github.io/CohortMethod/articles/MultipleAnalyses.html>

### システム要件

システム要件を検討する際には、二つのコンピューティング環境が関連してきます：データベースサーバーと分析ワークステーションです。 \index{システム要件}

データベースサーバーはCDM形式の観察医療データを保持する必要があります。Methods Libraryは、従来のデータベースシステム（PostgreSQL、Microsoft SQL Server、Oracle）、パラレルデータウェアハウス（Microsoft APS、IBM Netezza、Amazon Redshift）、に加えビッグデータプラットフォーム（Impala経由でのHadoop、Google BigQuery）など、幅広いデータベース管理システムをサポートしています。

分析ワークステーションは、Methods Libraryがインストールされ実行される場所です。これがローカルマシン（例えば、ノートパソコン）か、RStudio Serverが実行されるリモートサーバーかに関わらず、Rがインストールされている必要があります。可能であればRStudioも一緒にインストールすることをお勧めします。また、Methods LibraryではJavaがインストールされている必要があります。分析ワークステーションはデータベースサーバーに接続できる必要があり、具体的には、両者の間にファイアウォールがある場合は、ワークステーションでデータベースサーバーのアクセスポートが開いている必要があります。一部の分析は計算集中的であるため、複数のプロセッサコアと十分なメモリを持つことが分析の高速化につながります。少なくとも4コアと16ギガバイトのメモリを推奨します。

### インストール方法 {#installR}

OHDSI Rパッケージを実行するために必要な環境をインストールするための手順は次の通りです。インストールする必要があるものは4つあります： \index{R!インストール}

1.  **R**は統計的コンピューティング環境です。基本的なユーザインターフェースとして主にコマンドラインインターフェースを提供します。
2.  **Rtools**は、WindowsでRパッケージをソースからビルドする際に必要なプログラム一式です。
3.  **RStudio**は、Rを使いやすくするIDE（統合開発環境）です。コードエディタ、デバッグ、およびビジュアルツールが含まれています。素晴らしいR体験を得るために、これを使用ください。
4.  **Java**は、OHDSI Rパッケージの一部のコンポーネント、例えばデータベースへの接続に必要なコンポーネントを実行するために必要なコンピューティング環境です。

以下では、Windows環境でのそれぞれのインストール方法を説明します。

\BeginKnitrBlock{rmdimportant}
Windowsでは、RとJavaはどちらも32ビットと64ビットのアーキテクチャがあります。Rを両方のアーキテクチャにインストールする場合、Javaも両方のアーキテクチャにインストールしなければなりません。Rの64ビットのみをインストールすることをお勧めします。
\EndKnitrBlock{rmdimportant}

#### Rのインストール {.unnumbered}

1.  <https://cran.r-project.org/> で、図 \@ref(fig:downloadR) に示されるように「Download R for Windows 」、「base」 の順にクリックし、ダウンロードしてください。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/downloadR} 

}

\caption{CRANからのRのダウンロード}(\#fig:downloadR)
\end{figure}

2.  ダウンロードが完了したら、インストーラを実行します。2つの例外を除いて、すべてデフォルトのオプションを使用してください： まず、プログラムファイルにはインストールしない方が良いでしょう。代わりに、図 \@ref(fig:rDestination) のように、CドライブのサブフォルダとしてＲを作成します。次に、RとJavaのアーキテクチャの違いによる問題を回避するため、図 \@ref(fig:no32Bits) のように32ビットアーキテクチャを無効にします。

\begin{figure}

{\centering \includegraphics[width=0.8\linewidth]{images/OhdsiAnalyticsTools/rDestination} 

}

\caption{Rフォルダの設定}(\#fig:rDestination)
\end{figure}

\begin{figure}

{\centering \includegraphics[width=0.8\linewidth]{images/OhdsiAnalyticsTools/no32Bits} 

}

\caption{32ビットバージョンのRを無効化}(\#fig:no32Bits)
\end{figure}

完了すると、スタートメニューからRを選択できるようになります。

#### Rtoolsのインストール {.unnumbered}

1.  <https://cran.r-project.org/> にアクセスし、「Download R for Windows」をクリックし、次に「Rtools」をクリックして、最新版のRtoolsをダウンロードします。

2.  ダウンロードが完了後、インストーラを実行します。すべてデフォルトのオプションを選択します。

#### RStudioのインストール {.unnumbered}

1.  <https://www.rstudio.com/> にアクセスし、「Download RStudio」またはRStudioの下の「ダウンロード」ボタンをクリックし、無料版を選択し、図 \@ref(fig:downloadRStudio) に示されるようにWindows用のインストーラをダウンロードします。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/downloadRStudio} 

}

\caption{RStudioのダウンロード}(\#fig:downloadRStudio)
\end{figure}

2.  ダウンロードが完了後、インストーラを実行します。すべてデフォルトのオプションを選択してください。

#### Javaのインストール {.unnumbered}

1.  <https://java.com/en/download/manual.jsp> にアクセスし、図 \@ref(fig:downloadJava) に示されるように、Wiindows64ビット版のインストーラを選択します。32ビット版のRもインストールしている場合には、Javaも32ビット版をインストールしなければなりません。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/downloadJava} 

}

\caption{Javaのダウンロード}(\#fig:downloadJava)
\end{figure}

2.  ダウンロード後、インストーラを実行してます。

#### インストールの確認 {.unnumbered}

これで準備は整ったはずですが、念のため確認しておきましょう。Rを起動し、下記のようにタイプしてください。


``` r
install.packages("SqlRender")
library(SqlRender)
translate("SELECT TOP 10 * FROM person;", "postgresql")
```


```
## [1] "SELECT  * FROM person LIMIT 10;"
## attr(,"sqlDialect")
## [1] "postgresql"
```

この関数はJavaを使用するので、すべてがうまくいけば、RとJavaの両方が正しくインストールされていることがわかります！

もう一つのテストは、ソースパッケージがビルドできるかどうかを確認することです。以下のRコードを実行して、OHDSI GitHubリポジトリから`CohortMethod`パッケージをインストールします：


``` r
install.packages("drat")
drat::addRepo("OHDSI")
install.packages("CohortMethod")
```

## 展開戦略

ATLASやMethods Libraryを含むOHDSIツールスタック全体を組織内で展開することは、非常に困難な作業です。依存関係がある多くのコンポーネントを考慮し、設定を行う必要があります。このため、二つの取り組みが、スタック全体を一つのパッケージとしてインストールできる統合展開戦略を開発しました。一部の仮想化技術を使用して、これを実現します。それは、BroadseaおよびAmazon Web Services (AWS)です。 \index{ツール開発}

### Broadsea

Broadsea[^ohdsianalyticstools-8]はDockerコンテナ技術[^ohdsianalyticstools-9]を使用しています。OHDSIツールは依存関係とともに、Dockerイメージと呼ばれる単一のポータブルなバイナリファイルにパッケージ化されています。このイメージはDockerエンジンサービス上で実行でき、すべてのソフトウェアがインストールされるとすぐに実行可能な仮想マシンが作成されます。DockerエンジンはMicrosoft Windows、MacOS、Linuxなどのほとんどのオペレーティングシステムで利用可能です。Broadsea Dockerイメージには、Methods LibraryやATLASを含む主なOHDSIツールが含まれています。 \index{ツール開発!Broadsea}

[^ohdsianalyticstools-8]: <https://github.com/OHDSI/Broadsea>

[^ohdsianalyticstools-9]: <https://www.docker.com/>

### Amazon AWS

Amazonは、AWSクラウドコンピューティング環境でボタンをクリックするだけでインスタンス化できる二つの環境を用意しています：OHDSI-in-a-Box[^ohdsianalyticstools-10]とOHDSIonAWS[^ohdsianalyticstools-11]です。 \index{ツール開発!Amazon AWS}

[^ohdsianalyticstools-10]: <https://github.com/OHDSI/OHDSI-in-a-Box>

[^ohdsianalyticstools-11]: <https://github.com/OHDSI/OHDSIonAWS>

OHDSI-in-a-Boxは特に学習環境として作成さたものであり、OHDSIコミュニティが提供するほとんどのチュートリアルで使用されています。これには多くのOHDSIツール、サンプルデータセット、RStudio、その他のサポートソフトウェアが低コストの単一のWindows仮想マシンに含まれています。PostgreSQLデータベースは、CDMの保存と、ATLASからの中間結果の保存の両方に使用されます。OMOP CDMデータマッピングとETLツールも、OHDSI-in-a-Boxに含まれています。OHDSI-in-a-Boxのアーキテクチャは、図 \@ref(fig:ohdsiinaboxDiagram) に示されています。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/OHDSI-in-a-BoxDiagram} 

}

\caption{OHDSI-in-a-BoxのAmazon Web Servicesアーキテクチャ}(\#fig:ohdsiinaboxDiagram)
\end{figure}

OHDSIonAWSは、企業向け、マルチユーザー対応、拡張性や耐障害性に優れたOHDSI環境のためのリファレンスアーキテクチャであり、組織がデータ分析を行う際に使用することができます。 複数のサンプルデータセットが含まれており、組織の実際のヘルスケアデータを自動的にロードすることも可能です。 データはAmazon Redshiftデータベースプラットフォームに配置され、OHDSIツールによってサポートされます。 ATLASの中間結果はPostgreSQLデータベースに保存されます。ユーザーはフロントエンドで、ウェブインターフェース（RStudio Serverを活用）を通じてATLASやRStudioにアクセスできます。RStudioにはOHDSI Methods Libraryがすでにインストールされており、データベースへの接続に使用できます。OHDSIonAWSの自動展開はオープンソースであり、組織の管理ツールやベストプラクティスを含めるようにカスタマイズできます。OHDSIonAWSのアーキテクチャは図\@ref(fig:ohdsionawsDiagram)に示されています。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/OhdsiAnalyticsTools/OHDSIonAWSDiagram} 

}

\caption{OHDSIonAWSのAmazon Web Servicesアーキテクチャ}(\#fig:ohdsionawsDiagram)
\end{figure}

## まとめ

\BeginKnitrBlock{rmdsummary}
- CDM内のデータに対して分析を行うには
    - カスタムコードを作成する
    - OHDSI Methods LibraryのRパッケージを使用したコードを作成する
    - インタラクティブな分析プラットフォームATLASを使用する

- OHDSIツールはさまざまな分析戦略を用いています
    - 単一研究
    - リアルタイムクエリ
    - 大規模アナリティクス

- OHDSIアナリティクスツールのほとんどは、以下に組み込まれています
    - インタラクティブな分析プラットフォームATLAS
    - OHDSI Methods LibraryのRパッケージ

- OHDSIツールの展開を容易にするいくつかの戦略があります。

\EndKnitrBlock{rmdsummary}
