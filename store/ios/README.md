# App Store での公開手順（iOS / Apple Watch）

Langria の iOSアプリ（Apple Watch アプリを同梱）を App Store に公開するための手順です。各欄に貼り付けるテキストと質問への回答は [listing.md](listing.md) にまとめてあります。

| ファイル | 内容 |
| --- | --- |
| `listing.md` | 名前・説明文（英語・日本語）、キーワード、Appのプライバシー、年齢制限、審査用のメモ |
| `../../scripts/archive-ios.sh` | Release ビルドをアーカイブし、App Store Connect にアップロードするスクリプト |
| `../../ios/project.yml` | バージョン（`MARKETING_VERSION`）、バンドルID の接頭辞、広告ユニット ID |
| `../../ios/Langria/PrivacyInfo.xcprivacy` | プライバシーマニフェスト（Apple Watch アプリは `LangriaWatch/` に別にある） |
| `../../docs/privacy/` | プライバシーポリシー（`https://langria.net/privacy/`） |
| `../../docs/app-ads.txt` | AdMob 用（`https://langria.net/app-ads.txt`） |

## 1. 初回だけ必要な準備

1. **Apple Developer Program** に登録する（年額 US$99 / 12,800円）。個人で登録すると、ストアの販売元には本名が出ます。
2. Xcode の **Settings → Accounts** に同じ Apple アカウントでサインインする。`archive-ios.sh` はこのアカウントで署名・アップロードします。
3. `ios/Local.xcconfig` の `DEVELOPMENT_TEAM` を、登録した Team ID にする（[Membership](https://developer.apple.com/account#MembershipDetailsCard) で確認）。
4. App Store Connect の **ビジネス**（Agreements, Tax, and Banking）で **無料 App 契約** を確認する。無料アプリで広告収入は AdMob から入るので、有料 App 契約・銀行口座は要りません。
5. **EU のトレーダー申告**（Digital Services Act）: App Store Connect の **ビジネス** で、トレーダーか非トレーダーかを申告する。広告で収入を得るので、通常は **トレーダー** になります（住所・電話番号・メールアドレスが EU のストアに表示されます）。表示したくなければ、配信地域から EU を外します。

バンドルID は `net.langria.app`（Apple Watch アプリは `net.langria.app.watchkitapp`）です。`archive-ios.sh` は `-allowProvisioningUpdates` で App ID とプロファイルを自動で作ります。先に [Identifiers](https://developer.apple.com/account/resources/identifiers/list) で **App IDs → App** を2つ（Explicit、Capabilities は既定のまま）登録しておいてもかまいません。

## 2. App Store Connect にアプリを作る

[App Store Connect](https://appstoreconnect.apple.com/) → **アプリ** → **＋ → 新規 App**:

- プラットフォーム: **iOS**
- 名前: `Langria – AI Translator`（他のアプリと重なると使えないので、そのときは変える）
- プライマリ言語: **英語（米国）**
- バンドルID: `net.langria.app`（一覧にないときは、先に 3 のアップロードか Identifiers の登録をする）
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

| 端末 | サイズの例 | 撮るシミュレーター |
| --- | --- | --- |
| iPhone 6.9インチ | 1320 × 2868（縦） | iPhone 18 Pro Max |
| iPad 13インチ | 2064 × 2752（縦） | iPad Pro 13-inch (M5) |
| Apple Watch | 422 × 514 など | Apple Watch Ultra、Series の大きい方 |

小さい画面のサイズは、大きい画面の画像から自動で作られます。Apple Watch は App Store Connect が受け付けるサイズの一覧に合うものを1種類だけ上げれば足ります。

```sh
cd ios
xcodebuild -project Langria.xcodeproj -scheme Langria -destination 'platform=iOS Simulator,name=iPhone 18 Pro Max' -derivedDataPath build/shots build
xcrun simctl boot 'iPhone 18 Pro Max'
xcrun simctl status_bar 'iPhone 18 Pro Max' override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl install 'iPhone 18 Pro Max' build/shots/Build/Products/Debug-iphonesimulator/Langria.app
xcrun simctl launch 'iPhone 18 Pro Max' net.langria.app -langria-ui-language en -langria-theme light
# 自分の APIキーで翻訳した画面にしてから
xcrun simctl io 'iPhone 18 Pro Max' screenshot en-1.png
```

- シミュレーターがなければ、Xcode の **Window → Devices and Simulators** で作る（`xcrun simctl create 'iPhone 18 Pro Max' com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max`）。
- Debug ビルドなので、広告は Google のテスト広告です。スクリーンショットには広告が入らないところ（ページの上の方）を使うか、テスト広告の表示が入らないように撮ります。
- 日本語は `-langria-ui-language ja` で起動し直し、日本語の文章を翻訳した画面を撮ります。
- 撮るとよい画面: 文章の翻訳、写真の文字の翻訳（文字の多い写真をシミュレーターの写真に入れておく: `xcrun simctl addmedia`）、iPad の横並び、設定（サービスの切り替え・ロック）、Apple Watch。
- カメラはシミュレーターにないので、カメラのボタンは写りません。写真のボタンから選んだ画面で代わりにします。

## 6. 掲載情報を入力して審査に出す

[listing.md](listing.md) を見ながら入力します。

1. **App 情報**: サブタイトル、カテゴリ、コンテンツ配信権、年齢制限。右上の言語メニューで **日本語** を追加し、名前・サブタイトル・プライバシーポリシーURL を日本語でも入れる。
2. **価格および配信状況**: **無料**。配信地域は、生成AIのサービスの提供に許可が要り、OpenAI などの API も使えない **中国本土を外す**（そのままだと審査で却下されます）。トレーダー申告をしない場合は EU も外す。
3. **Appのプライバシー**: プライバシーポリシーの URL と、データの収集の申告を入れ、**公開** する。
4. **バージョン 1.0**（英語・日本語のそれぞれ）: スクリーンショット、プロモーションテキスト、説明、キーワード、サポートURL、マーケティングURL、著作権。
5. **ビルド**: TestFlight で確かめたビルドを選ぶ。
6. **App Review に関する情報**: サインイン不要にし、連絡先とメモ（審査用の Gemini APIキー入り）を入れる。審査担当者はAPIキーを持っていないので、キーがないと「機能を確認できない」（ガイドライン 2.1）で戻されます。
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
- **生成AIの国・地域の制限**: 中国本土を配信地域から外す。
- **広告の位置（Apple の広告のガイドライン）**: 広告がボタンや入力欄に重ならず、誤ってタップしにくい位置にあること。今はページの最後に置いている。
