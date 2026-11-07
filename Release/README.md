# 発電どうぶつ 1.0（4）の公開素材

今回の背景修正を含む初回公開用の素材です。価格は無料、広告あり。連絡先は `inazumimakoto@gmail.com` です。43件のテストとiOS Releaseビルドを確認し、`1.0 (4)` の署名付きアーカイブを作成しました。[App Store Connectのアプリ](https://appstoreconnect.apple.com/apps/6831870090/distribution)も登録済みです。掲載情報の入力、ビルドのアップロード、審査提出は残りの作業です。

[Xcodeアーカイブ](</Users/inazumimakoto/Library/Developer/Xcode/Archives/2026-11-07/Hatsuden 1.0 (4).xcarchive>) はチーム `V7XG8HDQL4` の開発署名です。App Store Connect向けの配布時にXcodeで検証し、適切な配布署名でアップロードします。

| 素材 | 内容 |
| --- | --- |
| [日本語掲載文](AppStore-ja.md) | 名前、サブタイトル、プロモーション文、概要、キーワード、審査メモ |
| [提出チェックリスト](SubmissionChecklist.md) | ビルド、プライバシー、年齢制限、広告、輸出コンプライアンス、提出手順 |
| [原寸キャプチャ](screenshots/raw/) | ゲーム画面を撮影した1206 × 2622の5枚 |
| [掲載用 1206 × 2622](screenshots/marketing/1206x2622/) | iPhone Dynamic Island中型枠向けの5枚 |
| [掲載用 1320 × 2868](screenshots/marketing/1320x2868/) | 大型枠向けの5枚 |
| [撮影と生成の手順](screenshots/plan.md) | 掲載順、撮影条件、画像の再生成方法 |
| [5枚の一覧プレビュー](screenshots/preview.jpg) | 確認用の一覧画像。提出時は各PNGを使います |

画像は室内の発電、売店、街、火山、宇宙の順です。原寸5枚と、2サイズ各5枚の見出し付きPNGを生成し、全15枚の寸法とRGB形式を確認しています。App Storeで使う画像を選べます。

撮影には別Bundle IDの一時ビルドを使い、ゲームの進行状態を撮影用に設定しています。広告読み込みを止め、実際のゲーム画面をSimulatorから取得しました。掲載用の見出し以外にゲームUIの描き足しはありません。撮影用の設定は本番ソースには含めていません。

公開サイトは [アプリ紹介](https://hatsuden-animals.netlify.app/)、[サポート](https://hatsuden-animals.netlify.app/support.html)、[プライバシーポリシー](https://hatsuden-animals.netlify.app/privacy.html) です。広告認証用の [app-ads.txt](https://hatsuden-animals.netlify.app/app-ads.txt) もサイト直下にあります。

公開に向けた残りの操作は次の順です。

1. App Store Connectの「ビジネス」にある更新契約をAccount Holder本人が確認・同意する。現在はPaid Applications Scheduleの更新通知が表示されています。契約を代理で承諾してはいません。
2. 登録済みの「発電どうぶつ」（Apple ID `6831870090`、日本語、iOS、SKU `hatsuden-ios`、Bundle ID `jp.hatsuden.works`）を開く。
3. 作成済みアーカイブをXcodeで検証し、App Store Connectへアップロードする。処理後に `1.0 (4)` を選ぶ。
4. 掲載文と画像、無料の価格、配信地域、著作権名義、審査連絡先を入力する。
5. 広告SDKを含むプライバシー回答と広告ありの年齢制限回答を確定する。SDKのデバイスID宣言を含め、実際のAdMob・ATT設定と一致させる。輸出コンプライアンスも確認する。
6. AdMobで必要な同意メッセージを公開し、広告内容の上限を対象年齢と合わせる。App Store掲載先をリンクした後、アプリ所有権と広告配信の審査状態を確認する。
7. 実機で本番構成の起動・購入・広告・復帰を確認し、公開方式を選んで審査へ提出する。

入力内容と残りの判断事項は [提出チェックリスト](SubmissionChecklist.md) にまとめています。
