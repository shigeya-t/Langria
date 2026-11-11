# App Store での公開手順（iOS / Apple Watch）

Langria の iOSアプリ（Apple Watch アプリを同梱）を App Store に公開するための手順です。各欄に貼り付けるテキストと質問への回答は [listing.md](listing.md) にまとめてあります。

| ファイル | 内容 |
| --- | --- |
| `listing.md` | 名前・説明文（英語・日本語）、キーワード、Appのプライバシー、年齢制限、審査用のメモ |
| `capture.sh` | App Store のスクリーンショット（`images/`）をシミュレーターで撮るスクリプト |
| `../../scripts/archive-ios.sh` | Release ビルドをアーカイブし、App Store Connect にアップロードするスクリプト |
| `../../ios/project.yml` | バージョン（`MARKETING_VERSION`）、バンドルID の接頭辞、広告ユニット ID |
| `../../ios/Langria/PrivacyInfo.xcprivacy` | プライバシーマニフェスト（Apple Watch アプリは `LangriaWatch/` に別にある） |
| `../../docs/privacy/` | プライバシーポリシー（`https://langria.net/privacy/`） |
| `../../docs/app-ads.txt` | AdMob 用（`https://langria.net/app-ads.txt`） |

## 1. 初回だけ必要な準備

1. **Apple Developer Program** に登録する（年額 US$99 / 12,800円）。個人で登録すると、ストアのデベロッパ名・販売元には本名が出ます（App Store Connect では変えられない。屋号や会社名にするには、D-U-N-S 番号を取って組織として登録し直すか、Apple に個人から組織への移行を申し込む）。
2. Xcode の **Settings → Accounts** に同じ Apple アカウントでサインインする。`archive-ios.sh` はこのアカウントで署名・アップロードします。
3. `ios/Local.xcconfig` の `DEVELOPMENT_TEAM` を、登録した Team ID にする（[Membership](https://developer.apple.com/account#MembershipDetailsCard) で確認）。
4. App Store Connect の **ビジネス**（Agreements, Tax, and Banking）で **無料 App 契約** を確認する。無料アプリで広告収入は AdMob から入るので、有料 App 契約・銀行口座は要りません。
5. **EU のトレーダー申告**（Digital Services Act）: App Store Connect の **ビジネス** で、トレーダーか非トレーダーかを申告する。広告で収入を得るので、通常は **トレーダー** になります（住所・電話番号・メールアドレスが EU のストアに表示されます）。Langria は表示しないよう、配信地域から EU を外しているので申告していません（[listing.md](listing.md) の「価格および配信状況」）。アプリの **App 情報** の下の方にある **Digital Services Act → Set Up** からも始められます。

バンドルID は `net.langria.ios`（Apple Watch アプリは `net.langria.ios.watchkitapp`）です。`archive-ios.sh` は `-allowProvisioningUpdates` で App ID とプロファイルを自動で作ります。先に [Identifiers](https://developer.apple.com/account/resources/identifiers/list) で **App IDs → App** を2つ（Explicit、Capabilities は既定のまま）登録しておいてもかまいません。

## 2. App Store Connect にアプリを作る

[App Store Connect](https://appstoreconnect.apple.com/) → **アプリ** → **＋ → 新規 App**:

- プラットフォーム: **iOS**
- 名前: `Langria – AI Translator`（他のアプリと重なると使えないので、そのときは変える）
- プライマリ言語: **英語（米国）**
- バンドルID: `net.langria.ios`（一覧にないときは、先に 3 のアップロードか Identifiers の登録をする）
- SKU: `langria-ios`
- ユーザアクセス: **フルアクセス**

Apple Watch アプリは iPhone アプリのビルドに入っているので、別のアプリとして作る必要はありません。

## 3. ビルドを作ってアップロードする

```sh
scripts/archive-ios.sh            # ios/build/export に .ipa を作るだけ（署名の確認）
scripts/archive-ios.sh --upload   # App Store Connect にアップロード
```

- `extension/lib/version.js` にコミットハッシュを書き込み、`xcodegen generate` してから Release でアーカイブします（設定の「バージョン」に `1.0 (abc1234)` のように出ます）。
- ビルド番号（`CURRENT_PROJECT_VERSION`）はコミット数です。同じコミットからは2回アップロードできないので、直したらコミットしてから作り直します。
- Release の広告は本番のユニット ID です（`project.yml` の `ADMOB_BANNER_UNIT_ID`）。TestFlight でも本番の広告が出るので、自分で広告をタップしないでください。AdMob の **設定 → テストデバイス** に自分の端末を登録しておくと安全です。
- Xcode の Organizer（**Window → Organizer**）で `ios/build/Langria.xcarchive` を開き、**Distribute App → App Store Connect** でアップロードしてもかまいません。

アップロードから十数分で、App Store Connect の **TestFlight** にビルドが出ます（処理中のメールが届きます）。

App Store Connect のアイコンは、バージョンにビルドを選ぶまで格子の仮アイコンです。アイコンは `ios/Langria/Assets.xcassets/AppIcon.appiconset/AppIcon.png`（1024×1024。Apple Watch は `ios/LangriaWatch/` の同じ場所）から取られ、App Store Connect に別の欄はありません。

## 4. TestFlight で確かめる

1. **TestFlight → 内部テスト** にグループを作り、自分を追加する。iPhone の TestFlight アプリから入れる。
2. 次を実機で確かめる。
   - 初回起動で（EU 以外なら）ATT のダイアログが出る。拒否しても翻訳できる
   - 翻訳・カメラ・写真・音声入力・読み上げ・ロック（Face ID）
   - Apple Watch: 設定の「Apple Watch で使う」をオンにして、Watch で翻訳できる
   - ページの最後に広告が出る（出るまで数時間〜1日かかることがある）
   - 設定の「バージョン」がアップロードした版とコミットになっている

## 5. スクリーンショット

App Store Connect で必須なのは次の3種類です（どれも英語・日本語のそれぞれに、1〜10枚）。

| 端末 | サイズ | 撮るシミュレーター |
| --- | --- | --- |
| iPhone（Dynamic Island、中サイズのディスプレイ） | 1206 × 2622（縦） | iPhone 18 Pro |
| iPad 13インチ | 2064 × 2752（縦） | iPad Pro 13-inch (M5) |
| Apple Watch | 422 × 514 | Apple Watch Ultra 4 (49mm) |

iPhone Duo（折りたたみ）の画像も撮ります（シミュレーターは iPhone Duo（iOS 27.1 以降））。閉じた画面（`duo`）は 1398 × 2034（縦）、開いた画面（`duo-open`）は 2853 × 2007（横）です。`capture.sh` からはシミュレーターを開けないので、開いた画面は手で開いてから `--device duo-open` で撮ります（既定では撮りません）。

ほかのサイズは、これらの画像から自動で作られます。iPhone の大きいディスプレイ（Pro Max など、1320 × 2868）の枠は必須ではなく、ここに中サイズの画像を入れるとサイズが違うと言われます。iPhone Duo の画像は、2027年4月から iOS 27.1 SDK 以降でビルドしたアプリに必須になります（[Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)）。

`store/ios/capture.sh` が、シミュレーターで英語・日本語の画面を撮って `store/ios/images/` に保存します。英語の画像は日本語を英語に、日本語の画像は英語を日本語に訳した画面です。

- iPhone・iPhone Duo・iPad: `{en,ja}-{iphone,duo,duo-open,ipad}-{1-translate,2-photo,3-dark,4-settings}.png`（文章の翻訳、写真の文字の翻訳、ダーク、設定）
- Apple Watch: `{en,ja}-watch-1-translate.png`

```sh
store/ios/capture.sh --build   # 片方だけなら --lang en / --lang ja、--device iphone / duo / duo-open / ipad / watch も付ける
```

- Debug ビルドのスクリーンショットモード（`ios/Langria/Screenshots.swift`）を起動引数で使います。広告と同意の確認は出ず、仮のAPIキーが入り、原文と訳文は `capture.sh` に書いた文章が入ります（APIは呼ばないので、APIキーは要りません。サービスは Gemini を表示します）。Release ビルドでは起動引数があっても動きません。
- 写真の画面は、`capture.sh` がその場で作るお知らせの画像を、アプリの文字認識で実際に読みます。訳文だけが固定です。
- Apple Watch は iPhone とペアリングしなくても撮れます（iPhone が送る設定を、`i18n.js` などから作って起動引数で渡します）。
- 例文や訳文を変えるときは `capture.sh` の上の方を直します。
- シミュレーターの名前は `IPHONE` / `DUO` / `IPAD` / `WATCH` で変えられます。なければ Xcode の **Window → Devices and Simulators** で作る。
- シミュレーターの PNG にはアルファチャンネルがあり、App Store Connect が受け付けないので、撮ったあとに取り除きます。
- 時刻は iPhone・iPhone Duo・iPad では 9:41 に揃えます。Apple Watch は `simctl status_bar` が効かない（コマンドが返ってこない）ので、そのときの時刻になります。

### 見出しを付ける

App Store Connect に入れるのは、撮った画像そのものではなく、上に見出しを付けた画像です（最初の2〜3枚で何ができるかが伝わると、インストールされやすくなります）。`store/caption.mjs` が、`store/ios/images/` の画像から `store/ios/images/captioned/` に同じ大きさで作ります。

```sh
node store/caption.mjs ios   # Playwright（Chromium）が要る。見出しは Mac では Hiragino Sans で描かれる
```

- 並べる順は、iPhone が「翻訳 → 写真 → 共有シート → Apple Watch → 設定（登録なし・自分のAPIキー）→ 翻訳モード（ダーク）」、iPad と iPhone Duo は Apple Watch を除いた同じ順です（ファイル名の番号の順に入れる）。
- 共有シートの画像は `capture.sh` では撮れません。シミュレーターの Safari で文章を選んで「共有」→「Langria」を開き、`xcrun simctl io booted screenshot store/ios/images/ja-iphone-5-share.png` のように `{en,ja}-{iphone,duo,ipad}-5-share.png` で保存すると、次から見出し付きで入ります（なければ飛ばします）。
- 見出しの文言は `caption.mjs` の `captions` にあります。他社の商標（ChatGPT・Claude・Gemini）は入れません。
- 元の画像（`store/ios/images/` 直下）は紹介ページ（`scripts/build-pages.sh`）も使うので、消さないでください。
- 比べたいときは、App Store Connect の **プロダクトページの最適化** で、見出しの違う画像を並べて試せます。

## 6. 掲載情報を入力して審査に出す

[listing.md](listing.md) を見ながら入力します。

1. **App 情報**: サブタイトル、カテゴリ、コンテンツ配信権、年齢制限。右上の言語メニューで **日本語** を追加し、名前・サブタイトル・プライバシーポリシーURL を日本語でも入れる。
2. **価格および配信状況**: 価格は「価格表」で **¥0（無料）** を選ぶ（選ばないと審査に追加できません）。配信地域は **EU の27か国と中国本土を外す**。中国本土は生成AIのサービスの提供に許可が要り、OpenAI などの API も使えないため（そのままだと審査で却下されます）。EU はトレーダー申告をしないため。外す国の一覧は [listing.md](listing.md) の「価格および配信状況」。
3. **Appのプライバシー**: プライバシーポリシーの URL と、データの収集の申告を入れ、**公開** する。
4. **バージョン 1.0**（英語・日本語のそれぞれ）: スクリーンショット、プロモーションテキスト、説明、キーワード、サポートURL、マーケティングURL、著作権。
5. **ビルド**: TestFlight で確かめたビルドを選ぶ。
6. **App Review に関する情報**: サインイン不要にし、連絡先（名・姓・メール・`+81` から始まる電話番号）とメモ（審査用の Gemini APIキー入り）を入れる。審査担当者はAPIキーを持っていないので、キーがないと「機能を確認できない」（ガイドライン 2.1）で戻されます。
7. **App Store バージョンのリリース**: 「承認後に手動でリリース」にしておくと、公開の時期を選べます。
8. **審査へ提出**。審査は通常1〜2日です。

## 7. 公開後

1. **AdMob**: **アプリ → アプリの設定 → アプリストアの詳細を追加** で App Store のアプリをリンクする。リンクすると `app-ads.txt`（`https://langria.net/app-ads.txt`）の確認が始まります（ストアのマーケティングURL・サポートURL のドメイン `langria.net` で探します）。
2. 審査用の Gemini APIキーを Google AI Studio で削除する。
3. App Store の URL（`https://apps.apple.com/app/id<数字>`）を、README.md / README.ja.md の iOSアプリの節と、紹介ページ（`docs/index.html` / `docs/ja.html`）に追記する。

## 更新するとき

1. 機能を変えたら `ios/project.yml` の `MARKETING_VERSION` を上げる（`1.0.1`、`1.1` など）。同じバージョンのまま直したビルドを出し直すときは、コミットしてビルド番号を変えるだけでよい。
2. App Store Connect で **＋ バージョン** を作り、**このバージョンの最新情報** を英語・日本語で書く。
3. 送信先・保存するデータ・広告の SDK を変えたら、`listing.md` の「Appのプライバシー」、`PrivacyInfo.xcprivacy`、`docs/privacy/` も合わせて直す。
4. `scripts/archive-ios.sh --upload` → TestFlight で確認 → ビルドを選んで審査に出す。

## 審査で指摘されやすい点

- **機能を試せること（2.1）**: 審査用のAPIキーをメモに入れる。キーの上限に達していないか、提出前に確かめる。
- **ATT とプライバシーの申告の一致（5.1.2）**: ATT を求めるなら、「トラッキングに使用」のデータを申告する。広告をやめるなら ATT も外す。
- **権限の説明文（5.1.1）**: カメラ・マイク・音声認識・Face ID・トラッキングの説明文は `project.yml` の `INFOPLIST_KEY_*`。何に使うかを具体的に書いておく（日本語の説明は `ios/Langria/ja.lproj/InfoPlist.strings`）。
- **他社の商標（4.1・5.2）**: 名前・サブタイトル・アイコン・キーワードに ChatGPT / Claude / Gemini を使わない。説明文で「対応サービス」として触れ、提携していない旨を書く（listing.md に記載済み）。
- **生成AIの国・地域の制限**: 中国本土を配信地域から外す（[listing.md](listing.md) の「価格および配信状況」）。
- **広告の位置（Apple の広告のガイドライン）**: 広告がボタンや入力欄に重ならず、誤ってタップしにくい位置にあること。今はページの最後に置いている。
