# 第12章　--翻訳作業中-- 集団レベルの推定 {#PopulationLevelEstimation}

*チャプターリード: Martijn Schuemie, David Madigan, Marc Suchard & Patrick Ryan*

\index{population-level estimation}

保険請求データや電子健康記録などの観察的な医療データは、治療の効果に関する現実世界のエビデンスを生成する機会を提供し、患者の生活を有意に改善することができます。本章では、特定の健康アウトカムに対する曝露（例えば、薬剤曝露や処置などの医療介入）の平均的な因果効果の推定を指す集団レベルの効果推定に焦点を当てます。以下では、2つの異なる推定タスクを検討します：

-   **直接効果推定**: アウトカムのリスクに対する曝露の効果を、曝露なしと比較して推定する。 \index{direct effect estimation}
-   **比較効果推定**: アウトカムのリスクに対する曝露（ターゲット曝露）の効果を、別の曝露（比較曝露）と比較して推定する。 \index{comparative effect estimation}

いずれの場合でも、患者レベルの因果効果は事実のアウトカム、すなわち曝露を受けた患者に何が起こったかと、反事実のアウトカム、すなわち曝露がなかった場合（直接）や異なる曝露があった場合（比較）に何が起こったかを対比させます。各患者は事実のアウトカムのみを明らかにするため（因果推論の基本問題）、さまざまな効果推定デザインは異なるデバイスを使用して反事実のアウトカムを明らかにします。 \index{counterfactual}

集団レベルの効果推定のユースケースには、治療選択、安全性監視、および比較効果が含まれます。方法論は、特定の仮説を一度に1つずつテストすること（例：「シグナル評価」）や、複数の仮説を一度に探索すること（例：「シグナル検出」）ができます。いずれの場合も、目的は同じです：因果効果の高品質な推定を生成することです。 \index{safety surveillance} \index{comparative effectiveness|see {comparative effect estimation}}

本章ではまず、[OHDSI Methods Library](https://ohdsi.github.io/MethodsLibrary/)としてRパッケージで実装されているさまざまな集団レベルの推定研究デザインについて説明します。次に、具体的な推定研究の設計を詳細に説明し、ATLASおよびRを使用して設計を実装する手順ガイドを提供します。最後に、研究から生成されるさまざまな出力、包括的な研究診断および効果サイズの推定についてレビューします。

## コホートメソッド設計 {#CohortMethod}

\index{コホートメソッド}

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{images/PopulationLevelEstimation/cohortMethod} 

}

\caption{新規ユーザーコホートデザイン。ターゲット治療を開始した被験者は比較対照治療を開始した被験者と比較されます。2つの治療グループ間の違いを調整するために、傾向スコアによる層化、マッチング、または重み付け、あるいはベースライン特性をアウトカムモデルに追加するなど、いくつかの調整戦略が使用されます。傾向スコアモデルまたはアウトカムモデルに含まれる特性は治療開始前に取得されます。}(\#fig:cohortMethod)
\end{figure}

コホートメソッドはランダム化臨床試験を模倣することを試みます　[@hernan_2016]。 ある治療（ターゲット）を開始した被験者は別の治療（比較対照）を開始した被験者と比較され、治療開始後の特定の期間、例えば治療を継続する期間にわたって追跡されます。コホート研究において我々が答えたい質問は、表\@ref(tab:cmChoices)にハイライトされた5つの選択を行うことで具体化されます。 \index{ターゲットコホート!コホートメソッド} \index{比較対照コホート} \index{アウトカムコホート!コホートメソッド}

表: (#tab:cmChoices) 比較コホートデザインの主要な設計選択。

| 選択 | 説明 |
|:---|:---|
| ターゲットコホート | ターゲット治療を代表するコホート |
| 比較対照コホート | 比較対照治療を代表するコホート |
| アウトカムコホート | 関心のあるアウトカムを代表するコホート |
| リスク期間 | どの時点で（通常はターゲットおよび比較対照コホートの開始および終了日）アウトカムのリスクを考慮するか |
| モデル | ターゲットと比較対照の間の違いを調整しながら効果を推定するために使用されるモデル |

モデルの選択には、他の要素の中でも、アウトカムモデルの種類が含まれます。例えば、ロジスティック回帰を使用することができ、これはアウトカムが発生したかどうかを評価し、オッズ比を生成します。ロジスティック回帰はリスク期間がターゲットと比較対照で同じ長さであるか、または関係がないと仮定します。代替的に、定常発生率を仮定するポアソン回帰を選ぶこともできます。よく使用されるのは、リスク比を推定するための初回アウトカムまでの時間を考慮するコックス回帰であり、ターゲットと比較対照間で比例ハザードを仮定します。 \index{ロジスティック回帰} \index{ポアソン回帰} \index{コックス回帰} \index{コックス比例ハザードモデル|see {コックス回帰}}

\BeginKnitrBlock{rmdimportant}
新規ユーザーコホートメソッドは本質的に比較効果推定の方法であり、治療を比較対照と比較します。この方法を使用して治療対未治療を比較するのは難しいです。なぜなら、未曝露群と曝露群が比較可能な群を定義するのが難しいからです。この設計を直接的な効果推定に使用したい場合は、関心のある曝露に対する比較対照として、同じ適応症に対する治療を選択するのが望ましいです。ただし、必ずしもそのような比較対照が利用可能であるとは限りません。

\EndKnitrBlock{rmdimportant}

重要な懸念は、ターゲット治療を受ける患者が比較対照治療を受ける患者と系統的に異なる可能性があることです。例えば、ターゲットコホートが平均60歳であり、比較対照コホートが平均40歳であるとします。年齢に関連する健康アウトカム（例：脳卒中）に関してターゲットと比較対照を比較する場合、コホート間で顕著な違いが見られるかもしれません。無知な研究者は、ターゲット治療と比較対照に比べて脳卒中の間に因果関係があると結論づけるかもしれません。もっと平凡な、あるいはありふれた結論として、ターゲット患者が脳卒中を経験したことが、比較対照を受けていたらそうならなかったであろうと結論づけるかもしれません。この結論は完全に間違っている可能性があります！おそらくこれらのターゲット患者は、ただ年を取っているだけで脳卒中が発生したかもしれません。治療を受けていたとしても同様であった可能性があります。この文脈では、年齢は「交絡因子（コンファウンダー）」です。観察研究で交絡因子に対処する一つのメカニズムは傾向スコアを介することです。 \index{交絡因子}

### 傾向スコア

\index{傾向スコア}

ランダム化試験では、（仮想的な）コイントスが患者を各グループに割り当てます。したがって、設計によって、患者がターゲット治療を受ける確率は患者の特性（例：年齢）とは無関係です。コインは患者を知りませんし、何よりも、ターゲット曝露を受ける患者の確率を正確にはっきりと知っています。そのアウトカム、試験の患者数が増えるにつれて、両方のグループの患者はどのような患者特性においても体系的に異なることは基本的にできません。このバランスの保証は、試験が測定した特性（例：年齢）および試験が測定しなかった特性（例：患者の遺伝的要因）にも適用されます。 \index{ランダム化試験}

ある患者に対する*傾向スコア（PS）*は、その患者がターゲット治療を受ける確率です　[@rosenbaum_1983]。 バランスの取れた二群ランダム化試験では、傾向スコアはすべての患者に対して0.5です。傾向スコアで補正された観察研究では、治療開始時およびその前のデータに基づいて患者がターゲット治療を受ける確率を推定します（実際に受けた治療に関係なく）。これは単純な予測モデリングの応用です。ロジスティック回帰などのモデルを適合させ、患者がターゲット治療を受けるかどうかを予測し、各被験者の予測確率（PS）を生成するためにこのモデルを使用します。標準的なランダム化試験とは異なり、異なる患者は異なるターゲット治療を受ける確率を持ちます。PSは、PSが似たターゲット被験者と比較対照被験者をマッチングする、PSに基づいて研究集団を層化する、PSから導き出された治療重み付けの逆確率（IPTW）を使うなど、いくつかの方法で使用できます。マッチングの場合、各ターゲット被験者に対して一人の比較対照被験者だけを選択することも、一人以上の比較対照被験者を許容することもできます。これを可変比マッチングと言います　[@rassen_2012]。 \index{傾向スコアモデル} \index{傾向スコア!マッチング} \index{傾向スコア!層化} \index{傾向スコア!重み付け} \index{治療重み付けの逆確率 (IPTW)|see {傾向スコア!重み付け}} \index{可変比マッチング}

例えば、一対一のPSマッチングを用いるとします。Janのターゲット治療を受ける事前確率が0.4であり、実際にターゲット治療を受けたとします。もし、事前確率0.4でターゲット治療を受けるはずだったが実際には比較対照を受けた患者（Junという名前）が見つかれば、JanとJunのアウトカムを比較することは、測定された交絡因子に関しては、小規模なランダム化試験のようなものです。この比較は、ランダム化によって生成されるJan-Jun因果コントラストの推定をもたらします。次に、推定手順は次のようになります：ターゲットを受けた各患者に対して、事前確率が同じで比較対照を受けた一人以上の患者を見つけ、これらのマッチング群内でターゲット患者のアウトカムを比較対照患者のアウトカムと比較します。

傾向スコアは測定された交絡因子を制御します。実際、測定された特性がない場合、採用された推定方法に基づいて誤差のない因果効果の推定値が得られます。測定された特性は「強い無視可能性」を仮定します。 “強い無視可能性”は実際にはテストできない前提です。この問題についての詳細はChapter \@ref(MethodValidity)で説明します。 \index{強い無視可能性}

### 変数選択 {#VariableSelection}

以前は、PSは手動で選択された特性に基づいて計算されていましたが、OHDSIツールはそのような実践をサポートする一方で、特定の曝露およびアウトカムに基づいて選択されていない、より多くの汎用特性を使用することを好みます　[@tian_2018] 。これらの特性には、人口統計情報、治療開始前および当日に観察された診断、薬剤曝露、測定値、および医療処置が含まれます。通常、モデルには10,000から100,000の特有の特性が含まれ、これらを大規模な正則化回帰[@suchard_2013]を使用して適合させ、[Cyclops](https://ohdsi.github.io/Cyclops/)パッケージで実装します。本質的には、どの特性が治療割り当ての予測に関連するかをデータに決定させ、モデルに含めます。

\BeginKnitrBlock{rmdimportant}
典型的には、治療開始日の特性は治療の原因となる診断などの多くの関連データがその日に記録されているため、共変量収集ウィンドウに含まれるべきです。この日には、ターゲットおよび比較対照の治療自体も記録されているが、これらは傾向スコアモデルに含まれるべきではありません。なぜなら、私たちはまさにこれらを予測しようとしているからです。したがって、ターゲットおよび比較対照治療は共変量セットから明示的に除外する必要があります。

\EndKnitrBlock{rmdimportant}

一部の人々は、因果構造を特定するために臨床専門知識に依存しない共変量選択のデータ駆動型アプローチは、誤っていわゆる道具変数や交絡因子を含め、分散を増加させ、潜在的にバイアスを導入するリスクがあると主張します。しかし、これらの懸念は現実的なシナリオでは大きな影響を与える可能性は低いです。さらに、医学においては真の因果構造が判明することはほとんどなく、異なる研究者が特定の研究問題に対して「正しい」共変量を特定するように求められると、それぞれの研究者は必ず異なるリストを作成し、そのプロセスを再現不能にします。最も重要なのは、傾向スコアモデルの確認、すべての共変量のバランス評価、および否定的対照の含有などの診断によって、交絡因子や道具変数に関連するほとんどの問題を特定できることです。 \index{道具変数} \index{交絡因子}

### カリパー

\index{カリパー}

傾向スコアは0から1の連続体上にあるため、厳密なマッチングはほとんど不可能です。代わりに、マッチングプロセスはターゲット患者の傾向スコアと一致する患者を「カリパー」として知られる許容範囲内で見つけます。@austin_2011 に従い、ロジットスケールで標準偏差の0.2を使用します。

### オーバーラップ：偏好スコア

\index{偏好スコア}

傾向スコア方法は一致する患者が存在することを必要とします。このため、主要な診断は二つのグループの傾向スコアの分布を示します。解釈を容易にするために、OHDSIツールは「偏好スコア」と呼ばれる傾向スコアの変換をプロットします。偏好スコアは二つの治療の「市場占有率」を調整します。例えば、10%の患者がターゲット治療を受ける場合（比較対照治療を受ける患者が90%の場合）、偏好スコアが0.5の患者はターゲット治療を受ける確率が10%です。数学的に、偏好スコアは

$$\ln\left(\frac{F}{1-F}\right)=\ln\left(\frac{S}{1-S}\right)-\ln\left(\frac{P}{1-P}\right)$$

ここで $F$ は偏好スコア、$S$ は傾向スコア、$P$ はターゲット治療を受ける患者の割合です。

@walker_2013 は「経験的均衡」のコンセプトを述べています。彼らは、少なくとも半数の曝露が偏好スコアの0.3から0.7の間にある場合、これらの曝露ペアを経験的均衡にあると見なします。 \index{臨床均衡}

### バランス

\index{共変量バランス} \index{バランス|see {共変量バランス}}

良い実践は常にPS調整がバランスの取れた患者群を生成するかどうかをチェックします。図\@ref(fig:balance)はバランスをチェックするための標準的なOHDSI出力を示しています。各患者特性について、露出グループ間の平均の標準化差をPS調整前後でプロットします。いくつかのガイドラインは、PS調整後の標準化差の上限を0.1とすることを推奨しています　[@rubin_2001]。

## 自己対照コホートデザイン

\index{自己対照コホートデザイン}

\begin{figure}[h]

{\centering \includegraphics[width=0.9\linewidth]{images/PopulationLevelEstimation/selfControlledCohort} 

}

\caption{自己対照コホートデザイン。ターゲットへの曝露中のアウトカムの発生率を曝露前の時間中の発生率と比較します。}(\#fig:scc)
\end{figure}

自己対照コホート（SCC）デザイン [@ryan_2013] は曝露中のアウトカムの発生率を、曝露直前の時間におけるアウトカムの発生率と比較します。表 \@ref(tab:sccChoices) に示す4つの選択肢が、自己対照コホートの質問を定義します。\index{ターゲットコホート!自己対照コホートデザイン} \index{アウトカムコホート!自己対照コホートデザイン}

\begin{table}
\centering
\caption{(\#tab:sccChoices)自己対照コホートデザインの主要な設計選択肢。}
\centering
\begin{tabular}[t]{l>{\raggedright\arraybackslash}p{9cm}}
\toprule
Choice & Description\\
\midrule
Target cohort & 治療を表すコホート\\
Outcome cohort & 興味のあるアウトカムを表すコホート\\
Time-at-risk & アウトカムのリスクをどのタイミング（通常ターゲットコホートの開始および終了日が基準）で考慮するか？\\
Control time & コントロールタイムとして使用される期間\\
\bottomrule
\end{tabular}
\end{table}

曝露群を構成する同じ被験者が対照群としても使用されるため、被験者間の差異について調整する必要はありません。ただし、この方法は、異なる期間間のアウトカムの基礎リスクの差異など、他の違いには脆弱です。

## 症例対照デザイン

\index{症例対照デザイン}

\begin{figure}[h]

{\centering \includegraphics[width=0.9\linewidth]{images/PopulationLevelEstimation/caseControl} 

}

\caption{症例対照デザイン。アウトカムを持つ被験者（「症例」）は、アウトカムを持たない被験者（「対照」）との曝露ステータスの面で比較されます。通常、症例と対照は年齢や性別などの様々な特性で一致させられます。}(\#fig:caseControl)
\end{figure}

症例対照研究 [@vandenbroucke_2012] は、「特定の疾患のアウトカムを持つ人が、その疾患を持たない人よりも特定のエージェントにより頻繁に曝露されているかどうか」を問います。このため、中心的なアイディアは、興味のあるアウトカムを経験する被験者（「症例」）を、興味のあるアウトカムを経験しない被験者（「対照」）と比較することです。表 \@ref(tab:ccChoices) の選択肢が、症例対照の質問を定義します。\index{アウトカムコホート!症例対照デザイン} \index{ターゲットコホート!症例対照デザイン} \index{ネスティングコホート!症例対照デザイン}

\begin{table}
\centering
\caption{(\#tab:ccChoices)症例対照デザインの主要な設計選択肢。}
\centering
\begin{tabular}[t]{l>{\raggedright\arraybackslash}p{9cm}}
\toprule
Choice & Description\\
\midrule
Outcome cohort & 症例（興味のあるアウトカム）を表すコホート\\
Control cohort & 対照を表すコホート。通常、選択ロジックを使用してアウトカムコホートから自動的に導出される\\
Target cohort & 治療を表すコホート\\
Nesting cohort & 任意で症例および対照が抽出されるサブポピュレーションを定義するコホートを指定\\
Time-at-risk & 曝露ステータスをどのタイミング（通常インデックス日が基準）で考慮するか？\\
\bottomrule
\end{tabular}
\end{table}

通常、症例を年齢や性別などの特性で一致させて対照を選択し、症例と対照を比較しやすくします。もう1つの広く行われている方法は、興味のある曝露のいずれかの適応症と診断されたすべての人々など、特定のサブグループに分けて分析を行うことです。

## 症例交叉デザイン

\index{症例交叉デザイン}

\begin{figure}[h]

{\centering \includegraphics[width=0.9\linewidth]{images/PopulationLevelEstimation/caseCrossover} 

}

\caption{症例交叉デザイン。アウトカムの周りの時間を、アウトカムの日付より前の事前に決められた間隔のコントロール日と比較します。}(\#fig:caseCrossover)
\end{figure}

症例交叉 [@maclure_1991] デザインは、アウトカムのタイミングでの曝露率が、アウトカムよりも前の事前に決められた日数での曝露率よりも異なるかどうかを評価します。これは、アウトカムが発生した日の特別な理由があるかどうかを判断しようとしています。表 \@ref(tab:ccrChoices) は、症例交叉の質問を定義する選択肢を示します。\index{アウトカムコホート!症例交叉デザイン} \index{ターゲットコホート!症例交叉デザイン}

\begin{table}
\centering
\caption{(\#tab:ccrChoices)症例交叉デザインの主要な設計選択肢。}
\centering
\begin{tabular}[t]{l>{\raggedright\arraybackslash}p{9cm}}
\toprule
Choice & Description\\
\midrule
Outcome cohort & 症例（興味のあるアウトカム）を表すコホート\\
Target cohort & 治療を表すコホート\\
Time-at-risk & 曝露ステータスをどのタイミング（通常インデックス日が基準）で考慮するか\\
Control time & コントロールタイムとして使用される期間\\
\bottomrule
\end{tabular}
\end{table}

症例は自分自身の対照として機能します。自己対照デザインとして、これらは人間間の差異による交絡に対して頑健であるべきです。ただし、アウトカムの日付が常にコントロール日付よりも後であるため、曝露の全体的な頻度が時間とともに増加する（または減少する）場合、方法は陽性バイアスを受ける可能性があります。これに対処するために、症例-時間-コントロールデザイン [@suissa_1995] が開発され、例えば年齢や性別で一致させた対照を症例交叉デザインに追加して、曝露のトレンドを調整します。\index{症例-時間-コントロールデザイン}

## 自己対照症例シリーズデザイン

\index{自己対照症例シリーズ (SCCS) デザイン}

\begin{figure}[h]

{\centering \includegraphics[width=0.9\linewidth]{images/PopulationLevelEstimation/selfControlledCaseSeries} 

}

\caption{自己対照症例シリーズデザイン。曝露中のアウトカム発生率と非曝露中のアウトカム発生率を比較する。}(\#fig:selfControlledCaseSeries)
\end{figure}

自己対照症例シリーズ（SCCS）デザイン[@farrington_1995; @whitaker_2006]は、曝露中のアウトカム発生率を、すべての非曝露期間中の発生率、これには曝露前、曝露間、曝露後の時間も含まれます、と比較します。これは、個人に依存したポアソン回帰であり、「患者がアウトカムを有する場合、曝露期間中の方が非曝露期間中よりもアウトカムが発生しやすいか？」という質問に答えようとします。表\@ref(tab:sccsChoices)の選択肢が SCCS の質問を定義します。 \index{アウトカムコホート!SCCS デザイン} \index{ターゲットコホート!SCCS デザイン}

\begin{table}
\centering
\caption{(\#tab:sccsChoices)自己対照症例シリーズデザインの主な設計選択肢。}
\centering
\begin{tabular}[t]{l>{\raggedright\arraybackslash}p{9cm}}
\toprule
選択肢 & 説明\\
\midrule
ターゲットコホート & 治療を代表するコホート\\
アウトカムコホート & 関心のあるアウトカムを代表するコホート\\
リスク期間 & どの時点（多くの場合、ターゲットコホートの開始日または終了日と関連のある時点）でアウトカムのリスクを考慮するか？\\
モデル & 時間変動する交絡因子の調整を含む効果の推定モデル\\
\bottomrule
\end{tabular}
\end{table}

他の自己対照デザイン同様、SCCS は個人間の違いによる交絡に対して頑健ですが、時間変動する影響による交絡には脆弱です。これらを考慮するためのいくつかの調整が可能であり、たとえば年齢や季節を含めることができます。SCCSの特別なバリアントでは、関心のある曝露だけでなく、データベースに記録された他の薬剤すべての曝露を含めます　[@simpson_2013]。これにより、モデルに数千の追加変数が追加されます。この場合、関心のある曝露以外のすべての曝露の係数に、正則化ハイパーパラメータをクロスバリデーションで選択するL1正則化が適用されます。

SCCSの重要な前提条件の一つは、観察期間の終了がアウトカムの日付と独立していることです。一部のアウトカム、特に心筋梗塞などの致命的なアウトカムにおいては、この前提が破られることがあります。SCCSの拡張版では、このような依存関係を修正するものがあります　[@farrington_2011]。

## 高血圧研究のデザイン

### 問題の定義

ACE 阻害薬（ACEi）は、高血圧や虚血性心疾患を持つ患者、特にうっ血性心不全、糖尿病、慢性腎臓病などの併存疾患を持つ患者によく使用されます　[@zaman_2002]。アンジオエデマは、唇、舌、口、喉頭、咽頭、または眼窩周囲の腫れとして現れる、深刻で時には命に関わる有害事象であり、これらの薬の使用と関連付けられています　[@sabroe_1997]。しかし、これらの薬剤使用に関連するアンジオエデマの絶対および相対リスクについての情報は限られています。既存の証拠は、主に特定のコホート（例えば、主に男性の退役軍人やメディケイド受給者）に基づいたものであり、他の集団に一般化できない可能性があります。また、イベント数が少ない研究に基づくものであり、不安定なリスク推定を提供します　[@powers_2012]。いくつかの観察研究は、ACEiをβ遮断薬と比較してアンジオエデマのリスクを評価しています[@magid_2010; @toh_2012]が、β遮断薬はもはや高血圧の一線級治療として推奨されていません　[@whelton_2018]。有力な代替治療法として、チアジド類およびチアジド様利尿薬（THZ）が考えられます。これらは高血圧や急性心筋梗塞（AMI）などの関連リスクを管理する上で同様に有効であり、アンジオエデマのリスクを増加させない可能性があります。

以下では、観察医療データに我々の集団レベル推定フレームワークを適用して、次の比較推定質問に対処する方法を示します：

> ACE阻害薬の新規使用者とチアジドおよびチアジド様利尿薬の新規使用者を比較した場合のアンジオエデマのリスクはどれくらいですか？

> ACE阻害薬の新規使用者とチアジドおよびチアジド様利尿薬の新規使用者を比較した場合の急性心筋梗塞のリスクはどれくらいですか？

これらは比較効果推定の質問であるため、\@ref (CohortMethod)節で述べたコホート方法を適用します。

### ターゲットおよび比較対象

高血圧の治療を初めて観察された患者をACEiまたはTHZクラスのどちらかの単剤療法として利用する患者と見なします。治療開始後7日以内に他の抗高血圧薬を開始しない患者を単剤療法と定義します。患者は最初の曝露前に少なくとも1年間の継続的な観察期間および治療開始の前年または前年に記録された高血圧診断を有することを要求します。

### アウトカム

アンジオエデマは、入院または救急部（ER）訪問中の血管浮腫のコンディションコンセプトの発生として定義し、7日前には血管浮腫診断が記録されていないことを要求します。AMIは、入院またはER訪問中のAMIコンディションコンセプトの発生として定義し、180日前にはAMI診断が記録されていないことを要求します。

### リスク期間

リスク期間を治療開始の翌日から開始し、曝露が終了するまでと定義し、後続の薬剤曝露の間に30日のギャップを許容します。

### モデル

デフォルトの共変量セットを使用してPSモデルを適合させます。このセットには、人口統計、条件、薬剤、処置、測定値、観察、およびいくつかの併存疾患スコアが含まれます。ACEiとTHZを共変量から除外します。可変比マッチングを行い、マッチングセットに条件付けてコックス回帰を行います。

### 研究要約

表 (#tab:aceChoices)は、我々の比較コホート研究の主な設計選択肢を示します。

| 選択肢 | 値 |
|:---|:---|
| ターゲットコホート | 高血圧の第一選択単剤療法としてのACE阻害薬の新規使用者。 |
| 比較コホート | 高血圧の第一選択単剤療法としてのチアジドまたはチアジド様利尿薬の新規使用者。 |
| アウトカムコホート | アンジオエデマまたは急性心筋梗塞。 |
| リスク期間 | 治療開始の翌日から開始し、曝露が終了するまで。 |
| モデル | 可変比マッチングを用いたコックス比例ハザードモデル。 |

### コントロール質問

我々の研究デザインが真実と一致する推定を生成するかどうかを評価するために、真の効果サイズが既知の一連のコントロール質問を追加で含めます。コントロール質問は、ハザード比が1の負のコントロールと、既知のハザード比が1を超える陽性対照に分けることができます。さまざまな理由から、実際の陰性対照を使用し、これらの陰性対照に基づいて陽性対照を合成します。コントロール質問の定義と使用方法の詳細は、チャプター \@ref（MethodValidity）で説明しています。

## ATLASを使用した研究の実施 {#PleAtlas}

ここでは、ATLASの推定機能を使用してこの研究を実施する方法を示します。ATLASの左バーで ![](images/PopulationLevelEstimation/estimation.png) をクリックし、新しい推定研究を作成します。研究に簡単に認識できる名前を付けてください。研究設計はいつでも ![](images/PopulationLevelEstimation/save.png) ボタンをクリックして保存できます。

推定設計機能には、比較、分析設定、評価設定の3つのセクションがあります。複数の比較と複数の分析設定を指定でき、それらの組み合わせを個別の分析として実行します。ここでは、それぞれのセクションについて説明します。

### 比較コホート設定 {#ComparisonSettings}

研究には1つ以上の比較を含めることができます。「比較を追加」をクリックすると、新しいダイアログが開きます。 ![](images/PopulationLevelEstimation/open.png) をクリックしてターゲットおよび比較コホートを選択します。「アウトカムを追加」をクリックして2つのアウトカムコホートを追加できます。コホートがすでにATLASで作成されていると仮定しています（Chapter \@ref(Cohorts)を参照）。ターゲット（Appendix \@ref(AceInhibitorsMono)）、比較（Appendix \@ref(ThiazidesMono））、およびアウトカム（Appendix \@ref(Angioedema）およびAppendix \@ref(Ami））コホートの完全な定義は付録にあります。完了すると、ダイアログはFigure \@ref(fig:comparisons)のようになります。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/comparisons} 

}

\caption{比較ダイアログ}(\#fig:comparisons)
\end{figure}

ターゲットと比較コホートのペアに対して複数のアウトカムを選択できることに注意してください。各アウトカムは独立したものとして扱われ、別々の分析アウトカムが得られます。

#### 陰性対照アウトカム {.unnumbered}

陰性対照アウトカムは、ターゲットまたはコンパレータによって引き起こされないと信じられているアウトカムであり、真のハザード比が1であると仮定されます。理想的には各アウトカムコホートの適切なコホート定義が必要ですが、通常は各陰性対照アウトカムごとに1つのコンセプトセットと、それらをアウトカムコホートに変換するための標準的なロジックしか持ちません。ここではコンセプトセットがChapter \@ref(MethodValidity)で説明されているとおりすでに作成されていると仮定し、それを選択するだけです。陰性対照コンセプトセットには、陰性対照ごとに1つのコンセプトが含まれ、その子孫は含まれないはずです。Figure \@ref(fig:ncConceptSet)は、この研究に使用された陰性対照コンセプトセットを示しています。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/ncConceptSet} 

}

\caption{陰性対照コンセプトセット。}(\#fig:ncConceptSet)
\end{figure}

#### 含めるコンセプト {.unnumbered}

コンセプトを選択するときに、生成したい共変量を指定できます。たとえば、傾向スコアモデルで使用するためです。ここで共変量を指定すると、それ以外の共変量（指定したもの以外）は除外されます。通常、ベースラインのすべての共変量を含め、正則化回帰モデルがすべての共変量をバランスさせるモデルを構築します。特定の共変量を指定する唯一の理由は、手動で共変量を選択した既存の研究を再現する場合です。これらの除外は、この比較セクションまたは分析セクションで指定できます。なぜなら、時には特定の比較に関連する場合（たとえば、比較における既知の交絡因子）、または特定の分析に関連する場合があります（たとえば、特定の共変量選択戦略を評価するとき）。

#### 除外するコンセプト {.unnumbered}

含めるコンセプトを指定する代わりに、*除外*するコンセプトを指定することもできます。このフィールドにコンセプトセットを送信すると、送信したコンセプトを除くすべての共変量を使用します。デフォルトの共変量セット（治療開始日のすべての薬剤および処置を含む）を使用する場合、ターゲットおよび比較治療、およびそれらに直接関連するコンセプトを除外する必要があります。たとえば、ターゲット曝露が注射可能なものである場合、薬剤だけでなく、プロペンシティモデルからその投与手技も除外する必要があります。この例では、除外したい共変量はACEiとTHZです。Figure \@ref(fig:covsToExclude)は、これらのコンセプトを含むコンセプトセットを示しています（その子孫も含まれます）。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/covsToExclude} 

}

\caption{除外するコンセプトを定義するコンセプトセット。}(\#fig:covsToExclude)
\end{figure}

ネガティブコントロールと除外する共変量を選択した後、比較ダイアログの下半分はFigure \@ref(fig:comparisons2)のようになります。

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/comparisons2} 

}

\caption{ネガティブコントロールおよび除外するコンセプトセットを示す比較ウィンドウ。}(\#fig:comparisons2)
\end{figure}

### 効果推定の分析設定

比較ダイアログを閉じた後、「分析設定を追加」をクリックできます。「分析名」とラベル付けされたボックスには、将来簡単に思い出せて見つけやすい一意の名前を付けることができます。たとえば、「傾向スコアマッチング」に設定することもできます。

#### 研究集団 {.unnumbered}

分析に入る被験者のセットである研究集団を指定するさまざまなオプションがあります。多くのオプションは、コホート定義ツールでターゲットおよび比較コホートを設計する際に利用可能なオプションと重複しています。Estimationのオプションを使用する理由の1つは再利用性です。ターゲット、比較、およびアウトカムコホートを完全に独立して定義し、後でそれらの間に依存関係を追加できます。たとえば、治療開始前にアウトカムを持っていた人を削除したい場合、ターゲットおよび比較コホートの定義でこれを行うことができますが、すべてのアウトカムごとに別のコホートを作成する必要があります。代わりに、分析設定で事前のアウトカムを持つ人々を削除することができ、これで興味のある2つのアウトカム（および陰性対照アウトカム）のターゲットおよび比較コホートを再利用できます。

**研究開始および終了日**を使用して、特定の期間に分析を制限できます。研究終了日はリスクウィンドウも切り詰め、研究終了日以降のアウトカムは考慮されません。研究開始日を選択する理由の1つは、研究している薬剤の1つが新しく、以前の期間には存在しなかったことです。自動で調整するには、「両方の曝露がデータ内に存在する期間に分析を制限しますか？」の質問に「はい」と回答します。医療行為が時間の経過とともに変わった場合（例：薬剤 警告のため）であり、特定の方法で 実践された時間にのみ興味がある場合、研究開始および終了日を調整する別の理由があります。

The option "**Should only the first exposure per subject be included?**" can be used to restrict to the first exposure per patient. Often this is already done in the cohort definition, as is the case in this example. Similarly, the option "**The minimum required continuous observation time prior to index date for a person to be included in the cohort**" is often already set in the cohort definition, and can therefore be left at 0 here. Having observed time (as defined in the OBSERVATION_PERIOD table) before the index date ensures that there is sufficient information about the patient to calculate a propensity score, and is also often used to ensure the patient is truly a new user, and therefore was not exposed before.

"**Remove subjects that are in both the target and comparator cohort?**" defines, together with the option "**If a subject is in multiple cohorts, should time-at-risk be censored when the new time-at-risk starts to prevent overlap?**" what happens when a subject is in both target and comparator cohorts. The first setting has three choices:

-   "**Keep All**" indicating to keep the subjects in both cohorts. With this option it might be possible to double-count subjects and outcomes.
-   "**Keep First**" indicating to keep the subject in the first cohort that occurred.
-   "**Remove All**" indicating to remove the subject from both cohorts.

If the options "keep all" or "keep first" are selected, we may wish to censor the time when a person is in both cohorts. This is illustrated in Figure \@ref(fig:tar). By default, the time-at-risk is defined relative to the cohort start and end date. In this example, the time-at-risk starts one day after cohort entry, and stops at cohort end. Without censoring the time-at-risk for the two cohorts might overlap. This is especially problematic if we choose to keep all, because any outcome that occurs during this overlap (as shown) will be counted twice. If we choose to censor, the first cohort's time-at-risk ends when the second cohort's time-at-risk starts.

\begin{figure}

{\centering \includegraphics[width=0.9\linewidth]{images/PopulationLevelEstimation/tar} 

}

\caption{Time-at-risk (TAR) for subjects who are in both cohorts, assuming time-at-risk starts the day after treatment initiation, and stops at exposure end.}(\#fig:tar)
\end{figure}

We can choose to **remove subjects that have the outcome prior to the risk window start**, because often a second outcome occurrence is the continuation of the first one. For instance, when someone develops heart failure, a second occurrence is likely, which means the heart failure probably never fully resolved in between. On the other hand, some outcomes are episodic, and it would be expected for patients to have more than one independent occurrence, like an upper respiratory infection. If we choose to remove people that had the outcome before, we can select **how many days we should look back when identifying prior outcomes**.

Our choices for our example study are shown in Figure \@ref(fig:studyPopulation). Because our target and comparator cohort definitions already restrict to the first exposure and require observation time prior to treatment initiation, we do not apply these criteria here.

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/studyPopulation} 

}

\caption{Study population settings.}(\#fig:studyPopulation)
\end{figure}

#### Covariate Settings {.unnumbered}

Here we specify the covariates to construct. These covariates are typically used in the propensity model, but can also be included in the outcome model (the Cox proportional hazards model in this case). If we **click to view details** of our covariate settings, we can select which sets of covariates to construct. However, the recommendation is to use the default set, which constructs covariates for demographics, all conditions, drugs, procedures, measurements, etc.

We can modify the set of covariates by specifying concepts to **include** and/or **exclude**. These settings are the same as the ones found in Section \@ref(ComparisonSettings) on comparison settings. The reason why they can be found in two places is because sometimes these settings are related to a specific comparison, as is the case here because we wish to exclude the drugs we are comparing, and sometimes the settings are related to a specific analysis. When executing an analysis for a specific comparison using specific analysis settings, the OHDSI tools will take the union of these sets.

Figure \@ref(fig:covariateSettings) shows our choices for this study. Note that we have selected to add descendants to the concept to exclude, which we defined in the comparison settings in Figure \@ref(fig:comparisons2).

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/covariateSettings} 

}

\caption{Covariate settings.}(\#fig:covariateSettings)
\end{figure}

#### Time At Risk {.unnumbered}

Time-at-risk is defined relative to the start and end dates of our target and comparator cohorts. In our example, we had set the cohort start date to start on treatment initiation, and cohort end date when exposure stops (for at least 30 days). We set the start of time-at-risk to one day after cohort start, so one day after treatment initiation. A reason to set the time-at-risk start to be later than the cohort start is because we may want to exclude outcome events that occur on the day of treatment initiation if we do not believe it biologically plausible they can be caused by the drug.

We set the end of the time-at-risk to the cohort end, so when exposure stops. We could choose to set the end date later if for example we believe events closely following treatment end may still be attributable to the exposure. In the extreme we could set the time-at-risk end to a large number of days (e.g. 99999) after the cohort end date, meaning we will effectively follow up subjects until observation end. Such a design is sometimes referred to as an *intent-to-treat* design.

A patient with zero days at risk adds no information, so the **minimum days at risk** is normally set at one day. If there is a known latency for the side effect, then this may be increased to get a more informative proportion. It can also be used to create a cohort more similar to that of a randomized trial it is being compared to (e.g., all the patients in the randomized trial were observed for at least N days).

\BeginKnitrBlock{rmdimportant}
A golden rule in designing a cohort study is to never use information that falls after the cohort start date to define the study population, as this may introduce bias. For example, if we require everyone to have at least a year of time-at-risk, we will likely have limited our analyses to those who tolerate the treatment well. This setting should therefore be used with extreme care.
\EndKnitrBlock{rmdimportant}

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/timeAtRisk} 

}

\caption{Time-at-risk settings.}(\#fig:timeAtRisk)
\end{figure}

#### Propensity Score Adjustment {.unnumbered}

We can opt to **trim** the study population, removing people with extreme PS values. We can choose to remove the top and bottom percentage, or we can remove subjects whose preference score falls outside the range we specify. Trimming the cohorts is generally not recommended because it requires discarding observations, which reduces statistical power. It may be desirable to trim in some cases, for example when using IPTW. \index{propensity score!trimming}

In addition to, or instead of trimming, we can choose to **stratify** or **match** on the propensity score. When stratifying we need to specify the **number of strata** and whether to select the strata based on the target, comparator, or entire study population. When matching we need to specify the **maximum number of people from the comparator group to match to each person in the target group**. Typical values are 1 for one-on-one matching, or a large number (e.g. 100) for variable-ratio matching. We also need to specify the **caliper**: the maximum allowed difference between propensity scores to allow a match. The caliper can be defined on difference **caliper scales**: \index{caliper!scale}

-   **The propensity score scale**: the PS itself
-   **The standardized scale**: in standard deviations of the PS distributions
-   **The standardized logit scale**: in standard deviations of the PS distributions after the logit transformation to make the PS more normally distributed.

In case of doubt, we suggest using the default values, or consult the work on this topic by @austin_2011.

Fitting large-scale propensity models can be computationally expensive, so we may want to restrict the data used to fit the model to just a sample of the data. By default the maximum size of the target and comparator cohort is set to 250,000. In most studies this limit will not be reached. It is also unlikely that more data will lead to a better model. Note that although a sample of the data may be used to fit the model, the model will be used to compute PS for the entire population.

**Test each covariate for correlation with the target assignment?** If any covariate has an unusually high correlation (either positive or negative), this will throw an error. This avoids lengthy calculation of a propensity model only to discover complete separation. Finding very high univariate correlation allows you to review the covariate to determine why it has high correlation and whether it should be dropped.

**Use regularization when fitting the model?** The standard procedure is to include many covariates (typically more than 10,000) in the propensity model. In order to fit such models some regularization is required. If only a few hand-picked covariates are included, it is also possible to fit the model without regularization.

Figure \@ref(fig:psSettings) shows our choices for this study. Note that we select variable-ratio matching by setting the maximum number of people to match to 100.

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/psSettings} 

}

\caption{Propensity score adjustment settings.}(\#fig:psSettings)
\end{figure}

#### Outcome Model Settings {.unnumbered}

First, we need to **specify the statistical model we will use to estimate the relative risk of the outcome between target and comparator cohorts**. We can choose between Cox, Poisson, and logistic regression, as discussed briefly in Section \@ref(CohortMethod). For our example we choose a Cox proportional hazards model, which considers time to first event with possible censoring. Next, we need to specify **whether the regression should be conditioned on the strata**. One way to understand conditioning is to imagine a separate estimate is produced in each stratum, and then combined across strata. For one-to-one matching this is likely unnecessary and would just lose power. For stratification or variable-ratio matching it is required. \index{conditioned model} \index{stratified model|see {conditioned model}}

We can also choose to **add the covariates to the outcome model** to adjust the analysis. This can be done in addition or instead of using a propensity model. However, whereas there usually is ample data to fit a propensity model, with many people in both treatment groups, there is typically very little data to fit the outcome model, with only few people having the outcome. We therefore recommend keeping the outcome model as simple as possible and not include additional covariates.

Instead of stratifying or matching on the propensity score we can also choose to **use inverse probability of treatment weighting** (IPTW).

If we choose to include all covariates in the outcome model, it may make sense to use regularization when fitting the model if there are many covariates. Note that no regularization will be applied to the treatment variable to allow for unbiased estimation.

Figure \@ref(fig:outcomeModelSettings) shows our choices for this study. Because we use variable-ratio matching, we must condition the regression on the strata (i.e. the matched sets).

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/outcomeModelSettings} 

}

\caption{Outcome model settings.}(\#fig:outcomeModelSettings)
\end{figure}

### Evaluation Settings {#evaluationSettings}

As described in Chapter \@ref(MethodValidity), negative and positive controls should be included in our study to evaluate the operating characteristics, and perform empirical calibration.

#### Negative Control Outcome Cohort Definition {.unnumbered}

In Section \@ref(ComparisonSettings) we selected a concept set representing the negative control outcomes. However, we need logic to convert concepts to cohorts to be used as outcomes in our analysis. ATLAS provides standard logic with three choices. The first choice is whether to **use all occurrences** or just the **first occurrence** of the concept. The second choice determines **whether occurrences of descendant concepts should be considered**. For example, occurrences of the descendant "ingrown nail of foot" can also be counted as an occurrence of the ancestor "ingrown nail." The third choice specifies which domains should be considered when looking for the concepts.

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/ncSettings} 

}

\caption{Negative control outcome cohort definition settings.}(\#fig:ncSettings)
\end{figure}

#### Positive Control Synthesis {.unnumbered}

In addition to negative controls we can also include positive controls, which are exposure-outcome pairs where a causal effect is believed to exist with known effect size. For various reasons real positive controls are problematic, so instead we rely on synthetic positive controls, derived from negative controls as described in Chapter \@ref(MethodValidity). We can choose to **perform positive control synthesis**. If "yes", we must choose the **model type**, currently being "Poisson" and "survival". Since we use a survival (Cox) model in our estimation study, we should choose "survival". We define the time-at-risk model for the positive control synthesis to be the same as in our estimation settings, and similarly mimic the choices for the **minimum required continuous observation prior to exposure**, **should only the first exposure be included**, **should only the first outcome be included**, as well as **remove people with prior outcomes**. Figure \@ref(fig:outcomeModelSettings) shows the settings for the positive control synthesis.

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/pcSynthesis} 

}

\caption{Negative control outcome cohort definition settings.}(\#fig:pcSynthesis)
\end{figure}

### Running the Study Package

Now that we have fully defined our study, we can export it as an executable R package. This package contains everything that is needed to execute the study at a site that has data in CDM. This includes the cohort definitions that can be used to instantiate the target, comparator and outcome cohorts, the negative control concept set and logic to create the negative control outcome cohorts, as well as the R code to execute the analysis. Before generating the package make sure to save your study, then click on the **Utilities** tab. Here we can review the set of analyses that will be performed. As mentioned before, every combination of a comparison and an analysis setting will result in a separate analysis. In our example we have specified two analyses: ACEi versus THZ for AMI, and ACEi versus THZ for angioedema, both using propensity score matching.

We must provide a name for our package, after which we can click on "Download" to download the zip file. The zip file contains an R package, with the usual required folder structure for R packages. [@Wickham_2015] To use this package we recommend using R Studio. If you are running R Studio locally, unzip the file, and double click the .Rproj file to open it in R Studio. If you are running R Studio on an R studio server, click ![](images/PopulationLevelEstimation/upload.png) to upload and unzip the file, then click on the .Rproj file to open the project.

Once you have opened the project in R Studio, you can open the README file, and follow the instructions. Make sure to change all file paths to existing paths on your system.

A common error message that may appear when running the study is "High correlation between covariate(s) and treatment detected." This indicates that when fitting the propensity model, some covariates were observed to be highly correlated with the exposure. Please review the covariates mentioned in the error message, and exclude them from the set of covariates if appropriate (see Section \@ref(VariableSelection)). \index{high correlation}

## Rを使用した研究の実施 {#pleR}

研究を実行するためのRコードを記述するためにATLASを使用する代わりに、Rコードを自分で書くこともできます。これを行いたい理由の一つは、RがATLASで公開されているものよりもはるかに柔軟性を提供するからです。例えば、カスタム共変量や線形アウトカムモデルを使用したい場合は、カスタムRコードを作成し、OHDSI Rパッケージが提供する機能と組み合わせる必要があります。

例として、[CohortMethod](https://ohdsi.github.io/CohortMethod/)パッケージを使用して研究を実行します。CohortMethodは、CDMに含まれるデータベースから必要なデータを抽出し、プロペンシティモデルのための多数の共変量を利用できます。次の例では、最初にアウトカムとして血管浮腫のみを考慮します。セクション \@ref(MultipleAnalyses)において、これを拡張してAMIと陰性対照アウトカムを含める方法について説明します。

### コホートのインスタンス化

最初にターゲットコホートおよびアウトカムコホートをインスタンス化する必要があります。コホートのインスタンス化は、セクション (\@ref(Cohorts))で説明しています。付録にはターゲット（付録 (\@ref(AceInhibitorsMono))）、比較（付録 (\@ref(ThiazidesMono))）、およびアウトカム（付録 (\@ref(Angioedema))）コホートの完全な定義が示されています。ACEi、THZ、および血管浮腫コホートが、それぞれコホート定義ID 1、2、3である `scratch.my_cohorts` という表にインスタンス化されていると仮定します。

### データ抽出

最初に、Rにサーバーへの接続方法を教える必要があります。 [CohortMethod](https://ohdsi.github.io/CohortMethod/)は[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)パッケージを使用しており、`createConnectionDetails`という関数を提供しています。さまざまなデータベース管理システム（DBMS）に必要な特定の設定については、`?createConnectionDetails`と入力してください。たとえば、以下のコードを使用してPostgreSQLデータベースに接続できます：


``` r
library(CohortMethod)
connDetails <- createConnectionDetails(dbms = "postgresql",
                                       server = "localhost/ohdsi",
                                       user = "joe",
                                       password = "supersecret")

cdmDbSchema <- "my_cdm_data"
cohortDbSchema <- "scratch"
cohortTable <- "my_cohorts"
cdmVersion <- "5"
```

最後の4行は`cdmDbSchema`、`cohortDbSchema`、および`cohortTable`変数と、CDMバージョンを定義しています。これらは後ほどRにCDM形式のデータがどこにあるか、関心のあるコホートがどこに作成されたか、そして使用されているCDMのバージョンを伝えるために使用します。Microsoft SQL Serverの場合、データベーススキーマはデータベースとスキーマの両方を指定する必要があるため、たとえば`cdmDbSchema <- "my_cdm_data.dbo"`のようになります。

次に、CohortMethodにコホートを抽出し、共変量を構築し、分析に必要なすべてのデータを抽出するよう指示できます：


``` r
# ターゲットおよびコンパレータの成分コンセプト
aceI <- c(1335471,1340128,1341927,1363749,1308216,1310756,1373225,
          1331235,1334456,1342439)
thz <- c(1395058,974166,978555,907013)

# 構築すべき共変量のタイプを定義
cs <- createDefaultCovariateSettings(excludedCovariateConceptIds = c(aceI,
                                                                     thz),
                                     addDescendantsToExclude = TRUE)

# データをロード
cmData <- getDbCohortMethodData(connectionDetails = connectionDetails,
                                cdmDatabaseSchema = cdmDatabaseSchema,
                                oracleTempSchema = NULL,
                                targetId = 1,
                                comparatorId = 2,
                                outcomeIds = 3,
                                studyStartDate = "",
                                studyEndDate = "",
                                exposureDatabaseSchema = cohortDbSchema,
                                exposureTable = cohortTable,
                                outcomeDatabaseSchema = cohortDbSchema,
                                outcomeTable = cohortTable,
                                cdmVersion = cdmVersion,
                                firstExposureOnly = FALSE,
                                removeDuplicateSubjects = FALSE,
                                restrictToCommonPeriod = FALSE,
                                washoutPeriod = 0,
                                covariateSettings = cs)
cmData
```


```
## CohortMethodDataオブジェクト
## 
## 治療コンセプトID：1
## コンパレータコンセプトID：2
## アウトカムコンセプトID(s)：3
```

多くのパラメーターがありますが、すべて[CohortMethodマニュアル](https://ohdsi.github.io/CohortMethod/reference/)に文書化されています。`createDefaultCovariateSettings`関数は[FeatureExtraction](https://ohdsi.github.io/FeatureExtraction/)パッケージで説明されています。簡単に言えば、私たちのコホートを含むテーブルを指し、そのテーブル内でターゲット、コンパレータ、およびアウトカムを識別するコホート定義IDを指定しています。デフォルトの共変量セットが構築される指示を行い、インデックス日前日までに見つかったすべての状態、薬剤曝露、および手順に対する共変量を含むようにします。セクション (\@ref(CohortMethod))で述べたように、共変量のセットからターゲットとコンパレータ処置を除外する必要があり、ここでは、2クラスすべての成分を一覧表示し、FeatureExtractionにこれらの成分を含むすべての薬剤を除外するように指示します。

コホート、アウトカム、および共変量に関するすべてのデータはサーバーから抽出され、`cohortMethodData`オブジェクトに保存されます。このオブジェクトは`ff`パッケージを使用して情報を保存するため、データが大きくてもRがメモリ不足にならないようにします（セクション (\@ref(BigDataSupport))で述べたように）。

抽出したデータの詳細を確認するために、汎用`summary()`関数を使用できます：


``` r
summary(cmData)
```


```
## CohortMethodDataオブジェクトの要約
## 
## 治療コンセプトID：1
## コンパレータコンセプトID：2
## アウトカムコンセプトID(s)：3
## 
## 治療を受けた人数：67166
## コンパレータ人数：35333
## 
## アウトカウント：
##          イベント数 人数
## 3               980          891
## 
## 共変量：
## 共変量の数：58349
## ゼロでない共変量値の数：24484665
```

`cohortMethodData`ファイルの作成にはかなりの計算時間がかかる可能性がありますので、将来のセッションのために保存しておくのが良いでしょう。`cohortMethodData`は`ff`を使用するため、Rの通常の保存関数は使用できません。代わりに、`saveCohortMethodData()`関数を使用します：


``` r
saveCohortMethodData(cmData, "AceiVsThzForAngioedema")
```

将来のセッションでデータをロードするには、`loadCohortMethodData()`関数を使用できます。

#### 新しいユーザーの定義 {.unnumbered}

通常、新しいユーザーは薬剤（ターゲットかコンパレータのいずれか）の初回使用として定義され、初回使用として真実である確率を高めるためにウォッシュアウト期間（初回使用前の最小日数）が使用されます。CohortMethodパッケージを使用する場合、新しい使用のための必要要件を3つの方法で適用できます：

1.  コホートの定義時。
2.  コホートを`getDbCohortMethodData`関数を使用してロードする際、`firstExposureOnly`、`removeDuplicateSubjects`、`restrictToCommonPeriod`、および`washoutPeriod`引数を使用。
3.  `createStudyPopulation`関数を使用して研究集団を定義する際（下記参照）。

オプション1の利点は、入力コホートがすでにCohortMethodパッケージの外部で完全に定義されているため、外部コホート特性化ツールがこの分析で使用される同じコホートで使用できることです。オプション2および3の利点は、DRUG_ERAテーブルを直接使用できるなど、自分で初回使用に制限する手間を省くことです。オプション2は3よりも効率的であるため、最初の使用に必要なデータを取得するだけで済みますが、オプション3は効率は低いものの、元のコホートを研究集団と比較できます。

### 研究集団の定義

通常、曝露コホートとアウトカムコホートは独立して定義されます。効果サイズの推定値を算出するには、これらのコホートをさらに制限し、例えば曝露前にアウトカムが生じた被験者を除外し、定義されたリスクウィンドウ内でのみ発生したアウトカムを保持するなどの方法で、これらを一緒にする必要があります。これには`createStudyPopulation`関数を使用できます：


``` r
studyPop <- createStudyPopulation(cohortMethodData = cmData,
                                  outcomeId = 3,
                                  firstExposureOnly = FALSE,
                                  restrictToCommonPeriod = FALSE,
                                  washoutPeriod = 0,
                                  removeDuplicateSubjects = "remove all",
                                  removeSubjectsWithPriorOutcome = TRUE,
                                  minDaysAtRisk = 1,
                                  riskWindowStart = 1,
                                  startAnchor = "cohort start",
                                  riskWindowEnd = 0,
                                  endAnchor = "cohort end")
```

`firstExposureOnly`と`removeDuplicateSubjects`をFALSEに設定し、`washoutPeriod`を0に設定しているのは、コホート定義内でこれらの基準をすでに適用しているためです。使用するアウトカムIDを指定し、リスクウィンドウの開始日より前にアウトカムがある被験者を削除するように指示します。リスクウィンドウはコホート開始日の翌日から始まり（`riskWindowStart = 1`および`startAnchor = "cohort start"`）、リスクウィンドウはコホート定義で定義された曝露終了時に終了します（`riskWindowEnd = 0`および`endAnchor = "cohort end"`）。リスクウィンドウは自動的に観察終了時または研究終了日に切り捨てられます。リスクの時間がない被験者も削除します。研究集団に残っている人数を確認するには、`getAttritionTable`関数を使用できます：


``` r
getAttritionTable(studyPop)
```


```
##                    説明 ターゲット人数 コンパレータ人数 ...
## 1             元のコホート         67212             35379 ...
## 2 両コホートの重複削除         67166             35333 ...
## 3             前のアウトカムなし          67061             35238 ...
## 4 リスク期間が1日以上有り         66780             35086 ...
```

### 傾向スコア

`getDbcohortMethodData()`で構築された共変量を使用してプロペンシティモデルを適合し、各個人に傾向スコア（PS）を計算できます：


``` r
ps <- createPs(cohortMethodData = cmData, population = studyPop)
```

`createPs`関数は[Cyclops](https://ohdsi.github.io/Cyclops/)パッケージを使用して大規模な正則化ロジスティック回帰を適合します。プロペンシティモデルを適合するために、Cyclopsは事前分布の分散を指定するハイパーパラメータ値を知る必要があります。デフォルトでは、Cyclopsは交差検証を使用して最適なハイパーパラメータを推定します。ただし、これには非常に長い時間がかかる場合があります。`createPs`関数の`prior`および`control`パラメータを使用して、Cyclopsの動作を指定し、交差検証を高速化するために複数のCPUを使用するようにできます。

ここでは、変数比のマッチングを使用してPSを使用します：


``` r
matchedPop <- matchOnPs(population = ps, caliper = 0.2,
                        caliperScale = "standardized logit", maxRatio = 100)
```

あるいは、PSを`trimByPs`、`trimByPsToEquipoise`、または`stratifyByPs`関数で使用することもできます。

### アウトカムモデル

アウトカムモデルは、どの変数がアウトカムと関連しているかを説明するモデルです。厳密な仮定の下では、治療変数の係数は因果効果として解釈できます。ここではマッチドセットに基づいたCox比例ハザードモデルを適合します：


``` r
outcomeModel <- fitOutcomeModel(population = matchedPop,
                                modelType = "cox",
                                stratified = TRUE)
outcomeModel
```


```
## モデルタイプ：cox
## 階層化：TRUE
## 共変量の使用：FALSE
## 治療重量の逆確率：FALSE
## ステータス：OK
## 
##           推定値 下限95% 上限95% logRr seLogRr
## 治療     4.3203   2.4531   8.0771 1.4633  0.304
```

### 複数の分析の実行 {#MultipleAnalyses}

一般的に、ネガティブコントロールを含む多くのアウトカムに対して複数の分析を実行することを希望します。[CohortMethod](https://ohdsi.github.io/CohortMethod/)は、そのような研究を効率的に実行するための関数を提供します。これは[複数の分析の実行に関するパッケージのビネット](https://ohdsi.github.io/CohortMethod/articles/MultipleAnalyses.html)で詳細に説明されています。要約すると、関心のあるアウトカムおよびネガティブコントロールコホートが既に作成されていることを前提とし、分析したいすべてのターゲット・コンパレータ・アウトカムの組み合わせを指定できます：


``` r
# Outcomes of interest:
ois <- c(3, 4) # Angioedema, AMI

# Negative controls:
ncs <- c(434165,436409,199192,4088290,4092879,44783954,75911,137951,77965,
         376707,4103640,73241,133655,73560,434327,4213540,140842,81378,
         432303,4201390,46269889,134438,78619,201606,76786,4115402,
         45757370,433111,433527,4170770,4092896,259995,40481632,4166231,
         433577,4231770,440329,4012570,4012934,441788,4201717,374375,
         4344500,139099,444132,196168,432593,434203,438329,195873,4083487,
         4103703,4209423,377572,40480893,136368,140648,438130,4091513,
         4202045,373478,46286594,439790,81634,380706,141932,36713918,
         443172,81151,72748,378427,437264,194083,140641,440193,4115367)

tcos <- createTargetComparatorOutcomes(targetId = 1,
                                       comparatorId = 2,
                                       outcomeIds = c(ois, ncs))

tcosList <- list(tcos)
```

Next, we specify what arguments should be used when calling the various functions described previously in our example with one outcome:


``` r
aceI <- c(1335471,1340128,1341927,1363749,1308216,1310756,1373225,
          1331235,1334456,1342439)
thz <- c(1395058,974166,978555,907013)

cs <- createDefaultCovariateSettings(excludedCovariateConceptIds = c(aceI,
                                                                     thz),
                                     addDescendantsToExclude = TRUE)

cmdArgs <- createGetDbCohortMethodDataArgs(
  studyStartDate = "",
  studyEndDate = "",
  firstExposureOnly = FALSE,
  removeDuplicateSubjects = FALSE,
  restrictToCommonPeriod = FALSE,
  washoutPeriod = 0,
  covariateSettings = cs)

spArgs <- createCreateStudyPopulationArgs(
  firstExposureOnly = FALSE,
  restrictToCommonPeriod = FALSE,
  washoutPeriod = 0,
  removeDuplicateSubjects = "remove all",
  removeSubjectsWithPriorOutcome = TRUE,
  minDaysAtRisk = 1,
  startAnchor = "cohort start",
  addExposureDaysToStart = FALSE,
  endAnchor = "cohort end",
  addExposureDaysToEnd = TRUE)

psArgs <- createCreatePsArgs()

matchArgs <- createMatchOnPsArgs(
  caliper = 0.2,
  caliperScale = "standardized logit",
  maxRatio = 100)

fomArgs <- createFitOutcomeModelArgs(
  modelType = "cox",
  stratified = TRUE)
```

We then combine these into a single analysis settings object, which we provide a unique analysis ID and some description. We can combine one or more analysis settings objects into a list:


``` r
cmAnalysis <- createCmAnalysis(
  analysisId = 1,
  description = "Propensity score matching",
  getDbCohortMethodDataArgs = cmdArgs,
  createStudyPopArgs = spArgs,
  createPs = TRUE,
  createPsArgs = psArgs,
  matchOnPs = TRUE,
  matchOnPsArgs = matchArgs
  fitOutcomeModel = TRUE,
  fitOutcomeModelArgs = fomArgs)

cmAnalysisList <- list(cmAnalysis)
```

We can now run the study including all comparisons and analysis settings:


``` r
result <- runCmAnalyses(connectionDetails = connectionDetails,
                        cdmDatabaseSchema = cdmDatabaseSchema,
                        exposureDatabaseSchema = cohortDbSchema,
                        exposureTable = cohortTable,
                        outcomeDatabaseSchema = cohortDbSchema,
                        outcomeTable = cohortTable,
                        cdmVersion = cdmVersion,
                        outputFolder = outputFolder,
                        cmAnalysisList = cmAnalysisList,
                        targetComparatorOutcomesList = tcosList)
```

The `result` object contains references to all the artifacts that were created. For example, we can retrieve the outcome model for AMI:


``` r
omFile <- result$outcomeModelFile[result$targetId == 1 &
                                    result$comparatorId == 2 &
                                    result$outcomeId == 4 &
                                    result$analysisId == 1]
outcomeModel <- readRDS(file.path(outputFolder, omFile))
outcomeModel
```


```
## Model type: cox
## Stratified: TRUE
## Use covariates: FALSE
## Use inverse probability of treatment weighting: FALSE
## Status: OK
## 
##           Estimate lower .95 upper .95   logRr seLogRr
## treatment   1.1338    0.5921    2.1765 0.1256   0.332
```

We can also retrieve the effect size estimates for all outcomes with one command:


``` r
summ <- summarizeAnalyses(result, outputFolder = outputFolder)
head(summ)
```


```
##     analysisId targetId comparatorId outcomeId        rr ...
## 1            1        1            2     72748 0.9734698 ...
## 2            1        1            2     73241 0.7067981 ...
## 3            1        1            2     73560 1.0623951 ...
## 4            1        1            2     75911 0.9952184 ...
## 5            1        1            2     76786 1.0861746 ...
## 6            1        1            2     77965 1.1439772 ...
```

## 研究の結果 {#studyOutputs}

私たちの推定値は、いくつかの仮定が満たされている場合にのみ有効です。これが満たされているかどうかを評価するために、広範な診断を使用します。これらはATLASによって生成されたRパッケージが生成したアウトカムで利用可能であり、または特定のR関数を使用して随時生成することもできます。

### 傾向スコアとモデル

まず、ターゲットコホートと比較対象コホートがある程度比較可能かどうかを評価する必要があります。そのためには、傾向モデルの受信者動作特性曲線(ROC)の下の面積（AUC）統計を計算できます。AUCが1である場合、治療の割り当てはベースライン共変量に基づいて完全に予測可能であり、したがって、2つのグループは比較不可能であることを示します。`computePsAuc`関数を使用してAUCを計算できます。私たちの例では0.79です。`plotPs`関数を使用して、図 \@ref(fig:ps)に示すような傾向スコア分布も生成できます。この図から、多くの人々にとって受けた治療が予測可能だったことがわかりますが、大量の重複があり、調整を使用して比較可能なグループを選択できることを示しています。 \index{preference score!example}

\begin{figure}

{\centering \includegraphics[width=0.8\linewidth]{images/PopulationLevelEstimation/ps} 

}

\caption{Preference score distribution.}(\#fig:ps)
\end{figure}

一般的に、特にモデルが非常に予測的である場合には、傾向モデル自体も検査することが良い考えです。その方法で、最も予測的な変数を発見できるかもしれません。表 \@ref(tab:psModel)は、私たちの傾向モデルにおける主要な予測因子を示しています。変数があまりにも予測的である場合、CohortMethodパッケージは情報的なエラーを投げますが、すでに完全に予測可能であることがわかっているモデルを適合させようとはしません。 \index{propensity model!example}

| ベータ | 共変量                                                            |
|-------:|:------------------------------------------------------------------|
|  -1.42 | 基準日から-30日から0日までの期間の疾患エラ: 浮腫                  |
|  -1.11 | 基準日から0日から0日までの期間の薬剤エラ: 塩化カリウム            |
|   0.68 | 年齢グループ: 05-09                                               |
|   0.64 | 基準日から-365日から0日までの期間の測定: レニン                   |
|   0.63 | 基準日から-30日から0日までの期間の疾患エラ: 蕁麻疹                |
|   0.57 | 基準日から-30日から0日までの期間の疾患エラ: タンパク尿            |
|   0.55 | 基準日から-365日から0日までの期間の薬剤エラ: インスリン及び類似体 |
|  -0.54 | 人種: 黒人またはアフリカ系アメリカ人                              |
|   0.52 | (切片)                                                            |
|   0.50 | 性別: 男性                                                        |

: (#tab:psModel) Top 10 predictors in the propensity model for ACEi and THZ. Positive values mean subjects with the covariate are more likely to receive the target treatment. "(Intercept)" indicates the intercept of this logistic regression model.

\BeginKnitrBlock{rmdimportant}
変数が非常に予測的であると判明した場合、2つの可能な結論があります。変数が明らかに曝露の一部であると判明し、モデルを適合させる前に削除する必要があるか、または2つの集団が本当に比較不可能であり、解析を中止しなければならないという結論に達します。

\EndKnitrBlock{rmdimportant}

### 共変量のバランス

PSを使用する目的は、2つのグループを比較可能にすることです（少なくとも比較可能なグループを選択すること）。これが達成されたかどうかを確認する必要があります。たとえば、調整後のベースライン共変量が確かにバランスされているかどうかを確認することです。`computeCovariateBalance`および`plotCovariateBalanceScatterPlot`関数を使用して図 \@ref(fig:balance)を生成できます。指標の1つの目安は、傾向スコア調整後の絶対標準化差が0.1を超える共変量がないことです。ここでは、マッチング前には大きな不均衡がありましたが、マッチング後にはこの基準を満たしていることがわかります。 \index{covariate balance!example}

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{images/PopulationLevelEstimation/balance} 

}

\caption{共変量バランスの図。傾向スコア マッチング前およびマッチング後の平均の絶対標準化差を示す。各ドットは共変量を表します。}(\#fig:balance)
\end{figure}

### フォローアップとパワー

アウトカムモデルを適合させる前に、特定の効果サイズを検出するための十分なパワーがあるかどうかを知りたい場合があります。図 \@ref(fig:attrition)に示すように、`drawAttritionDiagram`関数を使用して私たちの研究での対象者の脱落を表示できます。 \index{attrition diagram}

\begin{figure}

{\centering \includegraphics[width=0.7\linewidth]{images/PopulationLevelEstimation/attrition} 

}

\caption{脱落図。上部に示されているカウントは目標および比較対象コホートの定義を満たしているものです。下部に示されているカウントは、アウトカムモデルに入るものです。この場合、Cox回帰です。}(\#fig:attrition)
\end{figure}

レトロスペクティブ研究ではサンプルサイズは固定されており（データはすでに収集されている）、真の効果サイズは不明であるため、期待される効果サイズに基づいて電力を計算することに意味は少ないです。代わりに、CohortMethodパッケージは、最小検出可能相対リスク（MDRR）を計算するための`computeMdrr`関数を提供します。私たちの研究例におけるMDRRは1.69です。 \index{minimum detectable relative risk (MDRR)} \index{power}

追跡可能なフォローアップの量をよりよく理解するために、フォローアップ時間の分布を検査することもできます。追跡時間をリスクにさらされる時間と定義し、アウトカムが発生するまでの期間として検討できます。`getFollowUpDistribution`関数は簡単な概要を提供でき、図 \@ref(fig:followUp)に示されるように、両コホートのフォローアップ時間が比較可能であることがわかります。

\begin{figure}

{\centering \includegraphics[width=0.8\linewidth]{images/PopulationLevelEstimation/followUp} 

}

\caption{ターゲットおよび比較対象コホートのフォローアップ時間の分布。}(\#fig:followUp)
\end{figure}

### カプランマイヤー

最後に、カプラン−マイヤープロットをレビューし、両コホートの時間経過による生存率を示します。`plotKaplanMeier`関数を使用して \@ref(fig:kmPlot)を作成し、ハザードの比例性の仮定が保持されているかどうかなどを確認できます。カプラン−マイヤープロットはPSによる層別化や重み付けを自動的に調整します。この場合、可変比マッチングが使用されるため、比較対象グループの生存曲線は、ターゲットグループが比較対象に曝露されていた場合に曲線がどのように見えたであろうかを模倣するように調整されます。 \index{Kaplan-Meier plot} \index{survival plot|see {Kaplan-Meier plot}}

\begin{figure}

{\centering \includegraphics[width=1\linewidth]{images/PopulationLevelEstimation/kmPlot} 

}

\caption{カプラン−マイヤープロット。}(\#fig:kmPlot)
\end{figure}

### 効果サイズ推定

私たちは血管浮腫に対するハザード比は4.32（95％信頼区間：2.45 - 8.08）を観察しました。これは、ACEiがTHZと比較して血管浮腫のリスクを増加させることを示しています。同様に、AMIに対するハザード比は1.13（95％信頼区間：0.59 - 2.18）を観察し、AMIに対してはほとんどまたは全く効果がないことを示唆しています。前述の診断アウトカムは疑う理由がありません。しかし、最終的には、この証拠の質とそれを信頼するかどうかは、Chapter \@ref(EvidenceQuality)で説明されている研究診断ではカバーされていない多くの要因に依存します。

## まとめ

\BeginKnitrBlock{rmdsummary}
- 集団レベルの推定は、観察データから因果効果を推測することを目的としています。

- **反事実**とは、被験者が別の曝露または何も曝露を受けなかった場合に何が起こったかということですが、それは観察できません。

- 異なる設計は、異なる方法で反事実を構築しようとします。

- OHDSIメソッドライブラリに実装されているさまざまな設計は、適切な反事実を作成するための仮定が満たされているかどうかを評価するための診断を提供します。

\EndKnitrBlock{rmdsummary}

## 演習

#### 前提条件 {.unnumbered}

これらの演習を行うためには、R、R-Studio、およびJavaがセクション \@ref(installR) で説明されているようにインストールされていることを前提とします。また、[SqlRender](https://ohdsi.github.io/SqlRender/)、[DatabaseConnector](https://ohdsi.github.io/DatabaseConnector/)、[Eunomia](https://ohdsi.github.io/Eunomia/)、および[CohortMethod](https://ohdsi.github.io/CohortMethod/)パッケージも必要です。これらは次のコマンドでインストールできます：


``` r
install.packages(c("SqlRender", "DatabaseConnector", "remotes"))
remotes::install_github("ohdsi/Eunomia", ref = "v1.0.0")
remotes::install_github("ohdsi/CohortMethod")
```

Eunomiaパッケージは、ローカルのRセッション内で実行されるCDM内のシミュレートされたデータセットを提供します。接続の詳細は次のコマンドで取得できます：


``` r
connectionDetails <- Eunomia::getEunomiaConnectionDetails()
```

CDMデータベースのスキーマは「main」です。また、これらの演習ではいくつかのコホートも使用します。Eunomiaパッケージの`createCohorts`関数を使用して、これらをCOHORTテーブル内に作成できます：


``` r
Eunomia::createCohorts(connectionDetails)
```

#### 問題定義 {.unnumbered}

> セレコキシブの新規使用者とジクロフェナクの新規使用者における消化管（GI）出血のリスクは？

セレコキシブ新規使用者コホートのCOHORT_DEFINITION_IDは1です。ジクロフェナク新規使用者コホートのCOHORT_DEFINITION_IDは2です。GI出血コホートのCOHORT_DEFINITION_IDは3です。セレコキシブとジクロフェナクの成分コンセプトIDは、それぞれ1118084と1124300です。リスク期間は治療開始の日から始まり、観察終了時に終了します（いわゆる治療意図分析）。

::: {.exercise #exercisePle1}
CohortMethod Rパッケージを使用して、デフォルトの共変量セットを使用し、CDMからCohortMethodDataを抽出します。CohortMethodDataのサマリーを作成します。
:::

::: {.exercise #exercisePle2}
`createStudyPopulation`関数を使用して、180日のウォッシュアウト期間を要求し、事前にアウトカムを持つ人々を除外し、両方のコホートに出現する人々を除去して研究集団を作成します。人は失われましたか？
:::

::: {.exercise #exercisePle3}
調整を行わずにコックス比例ハザードモデルを適合させます。これを行う際に何が問題になる可能性がありますか？
:::

::: {.exercise #exercisePle4}
傾向スコアモデルを適合させます。2つの群は比較可能ですか？
:::

::: {.exercise #exercisePle5}
5つの層を使用してPS階層化を行います。共変量バランスは達成されましたか？
:::

::: {.exercise #exercisePle6}
PS階層を使用してコックス比例ハザードモデルを適合させます。そのアウトカムが無調整モデルと異なる理由は何ですか？
:::

推奨される解答は付録 \@ref(Pleanswers) で見つけることができます。
