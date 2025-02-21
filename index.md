---
title: " --翻訳作業中--　OHDSIの書"
author: "観察ヘルスデータ科学および情報学"
date: "2025-02-21"
output: word_document
geometry:
- paperheight=10in
- paperwidth=7in
- margin=1in
- inner=1in
- outer=0.65in
- top=0.8in
- bottom=0.8in
mainfont: Times New Roman
bibliography:
- book.bib
- packages.bib
description: 観察ヘルスデータ科学および情報学 (OHDSI) についての本。OHDSIのコミュニティ、オープンスタンダードとオープンソースソフトウェアについて詳述しています。
documentclass: book
favicon: images/favicon.ico
github-repo: OHDSI/TheBookOfOhdsi
link-citations: true
cover-image: images/Cover/Cover.png
site: bookdown::bookdown_site
biblio-style: apalike
url: https://ohdsi.github.io/TheBookOfOhdsi/
classoption: 11pt
---



# 序章 {.unnumbered}

<img src="images/Cover/Cover.png" alt="カバー画像" width="250" height="375" align="right" style="margin: 0 1em 0 1em"/> これは、観察ヘルスデータ科学および情報学 (OHDSI) コラボレーティブについての本です。OHDSIコミュニティは、この本をすべてのOHDSIに関する知識の中心的なリポジトリとして役立てることを目的として書きました。本はオープンソース開発ツールを通じてコミュニティによって維持される生きた文書であり、絶えず進化しています。 <http://book.ohdsi.org> で無料で利用できるオンライン版は常に最新バージョンを表しています。物理的なコピーは[Amazon](https://www.amazon.com/OHDSI-Observational-Health-Sciences-Informatics/dp/1088855199) で原価価格で入手可能です。

## この本の目標 {.unnumbered}

この本は、OHDSIの中心知識リポジトリとなることを目的としており、OHDSIコミュニティ、OHDSI データスタンダード、およびOHDSIツールについて説明します。本書は、OHDSIの初心者とベテランの両方を対象としており、必要な理論とそれに続く手順を提供する実用的な内容を目指しています。本書を読んだ後、OHDSIが何であり、どのようにしてその旅に参加できるかを理解できます。共通データモデルおよび標準語彙とは何か、それらを観察医療データベースを標準化するためにどのように使用するかを学びます。これらのデータの主な使用例である、特性評価、集団レベルの推定、および患者レベルの予測について学びます。これらの活動をサポートするOHDSIのオープンソースツールとその使用方法についても読みます。データ品質、臨床的妥当性、ソフトウェアの適切性、および方法の適切性に関する章は、生成された証拠の品質をどのように確立するかを説明します。最後に、分散研究ネットワークでこれらの研究を実行するためのOHDSIツールの使用方法を学びます。

## 本書の構成 {.unnumbered}

この本は5つの主要なセクションに分かれています：

I)  OHDSIコミュニティ
II) 統一データ表現
III) データ解析
IV) 証拠の品質
V)  OHDSI研究

各セクションには複数の章があり、各章は次の順序に従います：導入、理論、実践、まとめ、演習。

## 貢献者 {.unnumbered}

各章には1つ以上の章リーダーがリストされています。これらは章の執筆を主導した人々です。しかし、本書に貢献した他の多くの人々もおり、ここで感謝の意を表したいと思います：


\begin{tabular}{l|l|l}
\hline
Hamed Abedtash & Mustafa Ascha & Mark Beno\\
\hline
Clair Blacketer & David Blatt & Brian Christian\\
\hline
Gino Cloft & Frank DeFalco & Sara Dempster\\
\hline
Jon Duke & Sergio Eslava & Clark Evans\\
\hline
Thomas Falconer & George Hripcsak & Vojtech Huser\\
\hline
Mark Khayter & Greg Klebanov & Kristin Kostka\\
\hline
Bob Lanese & Wanda Lattimore & Chun Li\\
\hline
David Madigan & Sindhoosha Malay & Harry Menegay\\
\hline
Akihiko Nishimura & Ellen Palmer & Nirav Patil\\
\hline
Jose Posada & Nicole Pratt & Dani Prieto-Alhambra\\
\hline
Christian Reich & Jenna Reps & Peter Rijnbeek\\
\hline
Patrick Ryan & Craig Sachson & Izzy Saridakis\\
\hline
Paola Saroufim & Martijn Schuemie & Sarah Seager\\
\hline
Anthony Sena & Sunah Song & Matt Spotnitz\\
\hline
Marc Suchard & Joel Swerdel & Devin Tian\\
\hline
Don Torok & Kees van Bochove & Mui Van Zandt\\
\hline
Erica Voss & Kristin Waite & Mike Warfe\\
\hline
Jamie Weaver & James Wiggins & Andrew Williams\\
\hline
Seng Chan You &  & \\
\hline
\end{tabular}

## ソフトウェアのバージョン {.unnumbered}

この本の大部分はOHDSIのオープンソースソフトウェアについてであり、このソフトウェアは時間とともに進化します。開発者はユーザーに一貫して安定した体験を提供するよう最善を尽くしていますが、時間の経過とともにソフトウェアの改善により、本書の一部の指示が時代遅れになるのは避けられません。コミュニティはそれらの変更を反映するためにオンライン版の本を更新し、時間の経過とともにハードコピーの新しい版がリリースされます。参考までに、このバージョンの本で使用されているソフトウェアのバージョン番号は以下の通りです：

-   ACHILLES: バージョン 1.6.6
-   ATLAS: バージョン 2.7.3
-   EUNOMIA: バージョン 1.0.0
-   方法ライブラリパッケージ: 表 \@ref(tab:packageVersions)を参照

\begin{table}

\caption{(\#tab:packageVersions)本書で使用されている方法ライブラリのパッケージのバージョン。}
\centering
\begin{tabular}[t]{ll}
\toprule
パッケージ & バージョン\\
\midrule
CaseControl & 1.6.0\\
CaseCrossover & 1.1.0\\
CohortMethod & 3.1.0\\
Cyclops & 2.0.2\\
DatabaseConnector & 2.4.1\\
\addlinespace
EmpiricalCalibration & 2.0.0\\
EvidenceSynthesis & 0.0.4\\
FeatureExtraction & 2.2.4\\
MethodEvaluation & 1.1.0\\
ParallelLogger & 1.1.0\\
\addlinespace
PatientLevelPrediction & 3.0.6\\
SelfControlledCaseSeries & 1.4.0\\
SelfControlledCohort & 1.5.0\\
SqlRender & 1.6.2\\
\bottomrule
\end{tabular}
\end{table}

## ライセンス {.unnumbered}

この本は [Creative Commons Zero v1.0 Universal license](http://creativecommons.org/publicdomain/zero/1.0/) に基づいてライセンスされています。

![](images/Preface/cc0.png)

## 本書の開発方法 {.unnumbered}

この本は [RMarkdown](https://rmarkdown.rstudio.com) を使用して [bookdown](https://bookdown.org) パッケージで書かれています。オンライン版はソースリポジトリ <https://github.com/OHDSI/TheBookOfOhdsi> から自動的に再構築され、継続的統合システム ["travis"](http://travis-ci.org/) によって管理されます。定期的に本の状態のスナップショットが取得され、「版」としてマークされます。これらの版はAmazonから物理コピーとして入手できます。
