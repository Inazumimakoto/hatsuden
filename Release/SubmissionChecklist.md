# 発電どうぶつの公開準備

対象はバージョン `1.0`、ビルド `4`、Bundle ID `jp.hatsuden.works`。iOS 17以降のiPhone専用、縦画面です。販売価格は無料で、バナー、起動時、任意視聴のリワード広告を使います。アプリ内課金とアカウント登録は現在ありません。連絡先は `inazumimakoto@gmail.com` です。

このファイルのチェック欄は、App Store Connectへの実際の入力や公開確認を済ませた時点で更新します。

**ビルドと実機確認**

- [x] アーカイブのバージョン `1.0`、ビルド `4`、Bundle ID `jp.hatsuden.works`、署名チーム `V7XG8HDQL4` を確認した。
- [x] [署名付きアーカイブ](</Users/inazumimakoto/Library/Developer/Xcode/Archives/2026-11-07/Hatsuden 1.0 (4).xcarchive>) を作成した。現在はApple Development署名で、App Store向け配布処理は次の段階。
- [ ] 実機で起動し、連打、複数指、ピンチ、売店の購入、追加個体の即時表示、BGMを確認する。
- [ ] バックグラウンドから復帰し、所持金が加算されることを確認する。
- [ ] Release構成で広告の同意画面と広告を確認する。通常の開発ビルドはテスト広告IDを使うため、Debugの表示だけで本番広告の準備完了と判断しない。
- [ ] 広告を最後まで見た場合だけ5分のブーストが付くことを確認する。途中で閉じた場合と通信できない場合も確認する。
- [ ] 作成済みアーカイブをXcodeのOrganizerで開き、Validate App → Distribute App → App Store Connectへ進む。配布署名とプロビジョニングも確認する。
- [ ] App Store Connectで処理が完了した `1.0 (4)` を確認する。

2026年11月7日時点では、アップロードにXcode 26以降とiOS 26以降のSDKが必要です。現在のXcode 26.1はこの最低条件を満たします。[Appleの提出要件](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)

**公開サイトと掲載URL**

以下のURLをNetlifyで公開済みです。ログイン不要で正常に表示されることをHTTPで確認しています。

| App Store Connectの項目 | 入力するURL |
| --- | --- |
| マーケティングURL | `https://hatsuden-animals.netlify.app/` |
| サポートURL | `https://hatsuden-animals.netlify.app/support.html` |
| プライバシーポリシーURL | `https://hatsuden-animals.netlify.app/privacy.html` |

- [x] Netlifyで上記3ページを公開し、ログイン不要で表示されることを確認した。
- [ ] サポートページから `inazumimakoto@gmail.com` へ連絡できることを確認する。
- [ ] アプリ内の売店からプライバシーポリシーとサポートを開く。
- [ ] プライバシーポリシーの保存・削除、広告SDK、同意設定の説明を実際のアプリと照合する。

Appleは、App Store Connectの掲載情報とアプリ内の両方からプライバシーポリシーへ到達できることを求めています。[審査ガイドライン5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)

**App Store Connectの基本情報**

- [ ] Account Holder本人が更新契約を確認・同意する。現在のApp Store Connectには「ビジネス」でPaid Applications Scheduleを更新するよう通知が表示されている。代理での承諾はしていない。
- [x] チーム `V7XG8HDQL4` のDeveloper Identifiersで `Hatsuden / jp.hatsuden.works` を登録し、一覧で確認した。
- [x] [App Store Connectの新規アプリ](https://appstoreconnect.apple.com/apps/6831870090/distribution)をiOS、日本語、Bundle ID `jp.hatsuden.works` で作成した。Apple IDは `6831870090`、SKUは `hatsuden-ios`。ユーザアクセス保存の警告は表示されたが、現在は選択どおり全ユーザがアクセス可能でアプリ作成は完了している。
- [ ] 名前、サブタイトル、説明、キーワード、プロモーション文を [AppStore-ja.md](AppStore-ja.md) から入力する。
- [ ] 主カテゴリをゲームにし、カジュアル／シミュレーションなど、実際の遊び方に合うサブカテゴリを選ぶ。
- [ ] 価格を無料にする。配信地域と公開日を本人の意向に合わせて確定する。
- [ ] 著作権欄を `2026` と本人が使用する権利者名で入力する。
- [ ] コンテンツの配信権を確認する。背景と動物は本アプリ用の描画、BGMはCC0、同梱フォントはOFLで、元の権利情報はREADMEと同梱ライセンスを参照する。
- [ ] EUにも配信する場合、DSAのトレーダー区分を本人が判断して入力し、必要な連絡先の検証を終える。[AppleのDSA手順](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)

**スクリーンショット**

- [x] 室内の発電、売店、街、火山、宇宙の原寸5枚を `screenshots/raw/` に保存した。
- [x] 見出し付きの掲載用画像を `screenshots/marketing/1206x2622/` と `screenshots/marketing/1320x2868/` に各5枚生成した。
- [x] 原寸は1206 × 2622、掲載用は各フォルダー名どおりの寸法で、全15枚がRGB形式であることを確認した。
- [ ] `Release/screenshots` の原寸画像を確認し、実際のビルド4と内容が一致する画像をアップロードする。
- [x] iPhone Dynamic Island中型の対応サイズ `1206 × 2622` の原寸画像を用意した。
- [x] 画像はPNG形式で、アルファチャンネルを含まない。
- [ ] 開発用の縮小プレビューや、別の版の古い画面をアップロードしない。
- [ ] 室内から始まる画面、動物が増えた画面、売店、広い景色など、遊び方が伝わる順に並べる。

iPhone専用のためiPad画像は今回の対象外です。Appleは画面サイズごとに最大10枚を受け付けています。[Appleの画像仕様](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

**Appのプライバシー**

最初の質問は、広告SDKを含めてデータを収集するため「はい」を選びます。ゲームの進行は端末のUserDefaultsに保存しており、本アプリ専用のサーバーへの送信処理はありません。広告と同意管理についてはGoogle Mobile Ads SDK `13.12.0` とUMP `3.1.0` を含めて回答します。[Appleのデータ開示](https://developer.apple.com/app-store/app-privacy-details/)、[Google SDKの開示案内](https://developers.google.com/admob/ios/privacy/data-disclosure)

次の表は、このリポジトリで固定したSDKに同梱される `PrivacyInfo.xcprivacy` の宣言を確認した一覧です。「関連付け」は個人名を知っているかどうかではなく、端末やユーザーへ関連付くかの分類です。用途はSDKの宣言であり、最終入力時には実際のAdMob設定とAppleの定義を照合します。

| App Store Connectのデータ項目 | Google Mobile Adsの関連付け | 同梱マニフェストに記載される用途 | トラッキング宣言 |
| --- | --- | --- | --- |
| 位置情報 → おおよその位置情報 | 関連付けあり | サードパーティ広告、デベロッパの広告またはマーケティング、アナリティクス | なし |
| 識別子 → デバイスID | 関連付けあり | サードパーティ広告、デベロッパの広告またはマーケティング、アナリティクス | あり |
| 使用状況データ → 製品の操作 | 関連付けあり | サードパーティ広告、デベロッパの広告またはマーケティング、アナリティクス | なし |
| 使用状況データ → 広告データ | 関連付けあり | サードパーティ広告、デベロッパの広告またはマーケティング、アナリティクス | なし |
| 診断 → パフォーマンスデータ | 関連付けなし | サードパーティ広告、デベロッパの広告またはマーケティング、アナリティクス | なし |
| 診断 → クラッシュデータ | 関連付けなし | アナリティクス | なし |
| 診断 → その他の診断データ | 関連付けなし | サードパーティ広告、デベロッパの広告またはマーケティング、アナリティクス | なし |

UMPは、おおよその位置情報、製品の操作、パフォーマンスデータについて、関連付けなし・トラッキングなしで「アプリの機能」の用途も宣言しています。該当する項目にこの用途を合わせます。これらはSDK同梱宣言の記録であり、SDKを更新した際は再確認します。

- [ ] 上記7種類の収集項目を回答対象に含める。
- [ ] 用途を実際の広告運用と照合する。「デベロッパの広告またはマーケティング」は、Appleの定義に当てはまる利用がある場合に選ぶ。単に他社広告が表示されるという理由だけで選択しない。
- [ ] 「トラッキングに使用」を、実際のATT・AdMob設定と照合して確定する。デバイスIDのSDK宣言だけを見て機械的に回答しない。
- [ ] XcodeのOrganizerからプライバシーレポートを確認し、アプリと組み込まれたSDK全体を照合する。
- [ ] ポリシー本文、App Store Connectの回答、実際の広告設定を一致させる。

この版にはATT許可画面を表示する処理がありません。IDFAを取得して他社のアプリ・サイトのデータと結び付ける運用を追加する場合は、許可処理と説明文を実装し、回答も変更します。トラッキングはIDFAだけで判断する分類ではありません。[Appleのトラッキング定義](https://developer.apple.com/app-store/app-privacy-details/)、[GoogleのATT実装案内](https://developers.google.com/admob/ios/privacy/strategies)

氏名、メール、写真、連絡先、金融情報、ヘルスケア情報をアプリの機能として集める処理は現在ありません。サポート用メールアドレスを掲載したことだけを理由に、ユーザーの連絡先を自動収集しているとは回答しません。サポート運用で受け取る情報はポリシーに記載します。

**年齢制限と広告の内容**

- [ ] 年齢制限の質問で「広告あり」を申告する。
- [ ] アプリ内課金、チャット、ユーザー生成コンテンツ、無制限のWeb閲覧、実際のお金を使う賭博機能は、現在の実装に基づいて回答する。ゲーム内の `¥` は架空の通貨。
- [ ] 暴力、性的表現などの各質問は本編と表示し得る広告を確認して回答する。年齢の数値は質問の回答からAppleが計算するため、ここでは4+などに確定しない。
- [ ] 一般向けゲームとして提出する場合、Kids Categoryの指定と「子ども向け」の訴求は別途判断する。
- [ ] AdMobの広告コンテンツの上限をApp Storeの対象年齢に合わせる。幅広い層への公開準備では `G` を候補にし、現在のSDK設定とAdMob画面の設定を両方確認する。

AdMobではSDKの指定が管理画面の上限に優先します。`G`、`PG`、`T`、`MA` は広告内容の成熟度の分類で、アプリの対象年齢やKids Categoryと同じ質問ではありません。[Appleの年齢制限設定](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)、[Googleの広告内容分類](https://support.google.com/admob/answer/10478094?hl=en)、[上限設定](https://support.google.com/admob/answer/10477886?hl=en)

**AdMobの公開準備**

- [ ] AdMobの「プライバシーとメッセージ」で、配信地域に必要なメッセージを公開する。アプリは毎回の起動でUMPに状態を確認する。
- [ ] 広告の同意が必要な地域と、不要な地域で実機確認する。同意の再設定が必要な場合、売店に「広告のプライバシー設定」が表示されることを確認する。
- [ ] App Storeの公開情報が作成された後、AdMobのアプリにApp Store掲載先をリンクする。
- [ ] `app-ads.txt` の公開先を検証し、AdMobでアプリ所有権と広告配信の審査状態を確認する。

Googleは新規アプリについて `app-ads.txt` による検証を求めています。このアカウントの掲載行は次の形式です。AdMobの管理画面で発行される行とも照合します。[Googleの検証案内](https://support.google.com/admob/answer/14538460?hl=en)

```text
google.com, pub-9336495538487468, DIRECT, f08c47fec0942fa0
```

マーケティングURLは `https://hatsuden-animals.netlify.app/`、広告認証ファイルはサイト直下の `https://hatsuden-animals.netlify.app/app-ads.txt` です。公開済みのファイルに上記の1行が含まれることを確認しています。App Store ConnectにこのマーケティングURLを掲載した後、AdMobで再検査します。公開や掲載先の変更の検出には時間がかかる場合があります。[Googleの配置手順](https://support.google.com/admob/answer/9363762?hl=en)

**輸出コンプライアンス**

- [ ] アプリ独自の暗号機能を含まず、広告SDKなどの標準HTTPS通信が対象であることをアーカイブでも確認する。
- [ ] `ITSAppUsesNonExemptEncryption = false` を確認する。これは「非免除の暗号化を使わない」という設定。
- [ ] App Store Connectに追加質問が出る場合は、実際の暗号の利用に合わせて回答する。暗号方式やSDKを変更した際は再確認する。

Appleは、アプリと組み込んだライブラリが暗号を使わないか、免除される暗号のみを使う場合に、このキーを `NO` にするよう案内しています。[Appleのキー説明](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption)

**審査への提出**

- [ ] 審査連絡先の氏名、電話番号、メールを本人の情報で入力する。メールは `inazumimakoto@gmail.com`。
- [ ] ログインが必要かの質問は、現在のアプリではログイン不要として回答する。
- [ ] 審査メモに、連打でゲージを溜め、点灯中に発電する遊び方と、売店の場所を記載する。任意のリワード広告が5分のブーストを付与することも説明する。
- [ ] 説明文、スクリーンショット、プライバシー、年齢制限、価格、ビルド `1.0 (4)` の選択を確認する。
- [ ] 公開方式を確認してから審査に提出する。公開前にもう一度本人が確認する運用なら、審査後の手動リリースを選ぶ。

審査メモの下書きは以下です。

```text
本アプリはアカウント登録なしで利用できる、動物の発電クリッカーゲームです。
ゲーム画面を続けてタップすると左のゲージが上がり、点灯している間のタップでゲーム内通貨が増えます。
左下のかごボタンから売店を開き、ゲーム内通貨で動物を購入できます。
二本指のピンチで、画面右下を基準に背景と動物を拡大できます。

広告はゲーム画面と売店の下部バナー、3回目以降のコールド起動時、売店内の任意リワード広告です。
2種類のリワード広告は、それぞれ連打発電または留守中発電を5分間2倍にします。
ログイン、現金の入出金、アプリ内課金はありません。表示される¥はゲーム内の架空の通貨です。
売店からプライバシーポリシーとサポートページを開けます。
```
