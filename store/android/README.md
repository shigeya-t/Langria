# Google Play での公開手順（Android）

Langria の Androidアプリを Google Play に公開するための手順です。各欄に貼り付けるテキストと質問への回答は [listing.md](listing.md) にまとめてあります。

| ファイル | 内容 |
| --- | --- |
| `listing.md` | アプリ名・説明文（英語・日本語）、ストアの設定、データ セーフティ、コンテンツのレーティング、審査用の手順 |
| `../../android/app/build.gradle.kts` | パッケージ名（`net.langria.app`）、バージョン（`versionCode` / `versionName`）、リリース版の署名・広告の ID の読み込み |
| `../../android/local.properties` | リリース版の AdMob の ID と署名の鍵（git管理外。`local.properties.example` を参照） |
| `../../docs/privacy/` | プライバシーポリシー（`https://langria.net/privacy/`） |
| `../../docs/app-ads.txt` | AdMob 用（`https://langria.net/app-ads.txt`。iOS と共通） |

## 1. 初回だけ必要な準備

1. **Play Console のデベロッパー登録**: [Play Console](https://play.google.com/console/signup) で **個人** のアカウントを作る（登録料 US$25、一度だけ）。
   - 本人確認: 氏名・住所（Google お支払いプロファイル）、身分証、連絡先の電話番号・メールアドレス。これらは Google だけが使い、Google Play には出ません。
   - 本物の Android 端末を持っていることの確認: 端末に **Play Console アプリ** を入れてサインインする（エミュレーターでは通らない）。
2. **デベロッパー名**: **デベロッパー アカウント → 自己紹介** で `Langria` など、ストアに出す名前を決める（本名でなくてよい。Google の審査のあとで反映）。**ストアの設定** の連絡先のメールアドレスは公開されるので、`support@langria.net` のような公開用のアドレスにする。
   - 登録したら **デベロッパー プロフィール** のページで、ストアに出る情報を確かめる。氏名と住所が出るのは、有料アプリかアプリ内課金がある場合だけです（Langria は無料で広告だけなので出ない）。
3. **EU のトレーダー申告**（Digital Services Act）: Play Console の案内に従い、トレーダーか非トレーダーかを申告する。トレーダーにすると、EU の利用者に住所・電話番号などが表示されます。広告で収入を得るので、iOS と同じく通常は **トレーダー** になります。表示したくなければ、配信する国から EU を外します（判断に迷ったら専門家に確認する）。
4. **AdMob に Android アプリを登録**: [AdMob](https://admob.google.com/) → **アプリ → アプリを追加 → Android**。まだストアに出ていないので「いいえ」で作り、あとでリンクする。作った **App ID**（`ca-app-pub-…~…`）と、**広告ユニット → バナー** の ID（`ca-app-pub-…/…`）を控える。
5. **アップロード鍵を作る**（リポジトリの外に置き、バックアップする。なくすと Play のサポートに再設定を頼むことになる）。`keytool` と `gradlew` は JDK を使います。Homebrew の JDK は macOS に登録されないので、`Unable to locate a Java Runtime` と出たら先に `JAVA_HOME` を設定します（`~/.zshrc` に書いておくとよい）:
   ```sh
   export JAVA_HOME=/opt/homebrew/opt/openjdk@21
   export PATH="$JAVA_HOME/bin:$PATH"
   mkdir -p ~/keys
   keytool -genkeypair -v -keystore ~/keys/langria-upload.jks -keyalg RSA -keysize 4096 -validity 10000 -alias langria
   ```
6. `android/local.properties` に、4 と 5 で作ったものを書く:
   ```properties
   admob.appId=ca-app-pub-0000000000000000~0000000000
   admob.bannerUnitId=ca-app-pub-0000000000000000/0000000000
   signing.storeFile=/Users/<you>/keys/langria-upload.jks
   signing.storePassword=...
   signing.keyAlias=langria
   signing.keyPassword=...
   ```
   `admob.*` を書かないと、リリース版も Google のテスト広告になります。

## 2. リリース版を作る

```sh
.githooks/write-version                 # 設定の「バージョン」にコミットを出す（extension/lib/version.js）
cd android
./gradlew testDebugUnitTest bundleRelease
# → app/build/outputs/bundle/release/app-release.aab
# → app/build/outputs/mapping/release/mapping.txt（R8 の対応表）
```

- Play に出すのは APK ではなく **AAB**（Android App Bundle）です。
- `versionCode` は、アップロードのたびに前より大きくする必要があります（同じ番号は受け付けられません）。`android/app/build.gradle.kts` の `versionCode` / `versionName` を上げてコミットしてから作ります。最初は `1` / `1.0` のままでかまいません。
- リリース版は R8 でコードを縮小・難読化します。デバッグ版では起きない不具合が出ることがあるので、出す前に実機で確かめます:
  ```sh
  ./gradlew assembleRelease
  adb install -r app/build/outputs/apk/release/app-release.apk
  ```
  翻訳・カメラ・写真・音声入力・読み上げ・ロック・共有・文字選択メニュー・広告を一通り試します。本番の広告が出るので、自分で広告をタップしないでください（AdMob の **設定 → テストデバイス** に自分の端末を登録しておくと安全です）。

## 3. Play Console にアプリを作る

**すべてのアプリ → アプリを作成**:

- アプリ名: `Langria – AI Translator`
- パッケージ名: `net.langria.app`（あとから変えられない）
- デフォルトの言語: **英語（米国）– en-US**
- アプリかゲームか: **アプリ** / 無料か有料か: **無料**
- 連絡先のメールアドレス: `support@langria.net`（ストアに公開される）
- 申告（デベロッパー プログラム ポリシー、米国の輸出法）と Play アプリ署名の利用規約に同意する

## 4. 掲載情報とポリシーの申告を入れる

[listing.md](listing.md) を見ながら、ダッシュボードの「アプリのセットアップ」の項目を順に埋めます。

1. **アプリのコンテンツ**（**モニタリングと改善 → ポリシーとプログラム → アプリのコンテンツ**）: プライバシー ポリシー、広告、ログイン情報（審査用の Gemini APIキー）、コンテンツのレーティング、ターゲット ユーザー、データ セーフティ、広告 ID、政府機関・金融・健康・ニュースのアプリかどうか。
2. **ストアの設定**: カテゴリ（ツール）、タグ、連絡先（メールアドレス・ウェブサイト `https://langria.net/`）。
3. **メインのストアの掲載情報**: アプリ名・簡単な説明・詳しい説明（英語）、アイコン、フィーチャー グラフィック、スクリーンショット。**翻訳を管理 → 翻訳を追加 → 日本語** で、日本語の説明と画像も入れる。

ログイン情報の審査用キーは、審査が終わったら Google AI Studio で削除します（審査のたびに作り直す）。

## 5. スクリーンショット

`store/android/capture.sh` が、エミュレーターで翻訳画面と設定画面を、英語・日本語 × ライト・ダークの8枚撮ります（`store/android/images/{en,ja}-{light,dark}-{1-translate,2-settings}.png`）。英語の画像は日本語の例文を英語に、日本語の画像は英語の例文を日本語に訳した画面です。

```sh
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools   # Android Studio の SDK なら $HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH   # adb と emulator（~/.zshrc に書いておくとよい）
emulator -avd langria &   # なければ Android Studio の Device Manager で Pixel を作る
store/android/capture.sh --build   # 動画は --video、片方の言語だけなら --lang en / --lang ja も付ける。Gemini の APIキーを聞かれるので貼り付ける（GEMINI_API_KEY でも渡せる）
```

- 翻訳は本物の Gemini API で行います。キーはエミュレーターの Langria にだけ保存され、ファイルには残りません。
- エミュレーターの Langria のデータは消えます（`pm clear`）。設定はデバッグ版の `run-as` で書き換え、例文はほかのアプリからの共有として渡します。
- 撮る間だけ、画面を 1080 × 1920（9:16。Play の上限は 2:1 で、おすすめ枠に使われるのは 9:16）にし、ステータスバーをデモモード（9:41・電池満タン・通知なし）にします。通知は1時間スヌーズします。終わると画面の大きさとデモモードは元に戻ります。
- デバッグ版は、設定に `langria-screenshots` があるとテスト広告を出しません（`Ads.kt`。リリース版には影響しない）。
- `--video` を付けると、スクリーンショットの代わりに、初めて使うときの流れ（設定画面でキーを入力して保存 → 文章を入力して翻訳）を録画します（`store/android/images/{en,ja}-demo.mp4`、1080 × 1920）。英語の動画は日本語の文章を英語に、日本語の動画は英語の文章を日本語に訳します。`adb` は英数字しか入力できないので、英語の動画の日本語の文章は、貼り付けたように一度に入ります（共有で今の画面に渡す）。録画の間は、パスワードの最後の文字を表示する設定と、キーボードの手書き入力の案内を止めます（終わると戻る）。アニメーションは止めません。
- Play の「プレビュー動画」は YouTube の URL で登録します。録画した動画を YouTube に（限定公開などで）アップロードし、**メインのストアの掲載情報** の動画欄にその URL を入れます。
- 写真の文字の翻訳、文字選択メニューの「Langria」、タブレットの横並び（Pixel Tablet などの AVD）は手で撮ります。文字の多い画像は `adb push` で `/sdcard/Pictures` に置き、写真ピッカーから選びます。

## 6. テストして本番に出す

個人アカウントは、**本番に出す前にクローズド テストが必須**です（新しく作った個人アカウントの場合）。

1. **内部テスト**: **テスト → 内部テスト → 新しいリリースを作成** で AAB をアップロードする。
   - 初回は **Play アプリ署名** を使う（既定のまま。Google が配信用の鍵を持ち、手元の鍵はアップロード専用になる）。
   - R8 の対応表（`mapping.txt`）は AAB に入っていて、Play が自動で使います。クラッシュレポートは元のクラス名・メソッド名で表示されます。
   - テスターのリストに自分を入れ、案内のリンクから Play 経由でインストールして動作を確かめる。
2. **クローズド テスト**: **12人以上** のテスター（Google アカウントのメールアドレス、または Google グループ）を登録し、**14日間続けて** オプトインしてもらう。途中で抜けた人は数えられないので、多めに集めます。
3. **製品版へのアクセスを申請**: ダッシュボードの **製品版へのアクセスを申請** から、テストの内容（何人で何を試し、何を直したか）と、アプリの対象者・価値についての質問に答える。審査は通常1週間ほど。
4. **製品版**: **製品版 → 新しいリリースを作成** で、テストした AAB を選び、リリースノート（listing.md）を入れて **審査に送信**。
   - **公開の概要 → 管理された公開** をオンにしておくと、承認後に自分で公開のタイミングを選べます。
   - 段階的な公開（例: 最初は 20%）にもできます。

## 7. 公開後

1. **AdMob**: **アプリ → アプリの設定 → アプリストアの詳細を追加** で Play のアプリをリンクする。リンクすると `app-ads.txt` の確認が始まります（ストアのウェブサイト `langria.net` で探します）。
2. 審査用の Gemini APIキーを Google AI Studio で削除する。
3. Play の URL（`https://play.google.com/store/apps/details?id=net.langria.app`）を、README.md / README.ja.md の Androidアプリの節と、紹介ページ（`docs/index.html` / `docs/ja.html`）に追記する。

## 更新するとき

1. `android/app/build.gradle.kts` の `versionCode` を上げる（必須）。機能を変えたら `versionName` も上げる（`1.0.1`、`1.1` など）。
2. 送信先・保存するデータ・権限・広告の SDK を変えたら、`listing.md` のデータ セーフティと権限、`docs/privacy/` も合わせて直す。
3. `bundleRelease` で AAB を作り、内部テストで確かめてから、製品版の新しいリリースとして審査に出す。

## 審査で指摘されやすい点

- **機能を試せること（ログイン情報）**: 審査担当者は APIキーを持っていないので、審査用のキーと手順を入れる。キーの上限に達していないか、提出前に確かめる。
- **データ セーフティとアプリの動作の一致**: SDK が集めるデータ（AdMob・ML Kit）も申告する。ずれていると、アプリの更新が止められることがあります。
- **他社の商標（なりすまし・メタデータのポリシー）**: アプリ名・簡単な説明・アイコンに ChatGPT / Claude / Gemini を使わない。詳しい説明で「対応サービス」として触れ、提携していない旨を書く（listing.md に記載済み）。
- **AI が作るコンテンツのポリシー**: チャットボットや画像の生成アプリは、不快な出力を報告する手段をアプリ内に置く必要があります。Langria は利用者の文章を訳すだけの翻訳ツールなので対象外と考えていますが、審査で求められたら、設定に「問題を報告」（GitHub の Issues やメールへのリンク）を足して対応します。
- **広告の位置（広告のポリシー）**: 広告がボタンや入力欄に重ならず、誤ってタップしにくい位置にあること。今はページの最後に置いている。
- **ターゲット API レベル**: 新しいアプリと更新は、毎年8月末までに、その前年に出た Android のバージョンを対象にする必要があります（今は `targetSdk = 37`）。
