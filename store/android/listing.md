# Google Play 掲載情報（貼り付け用）

Play Console の各欄に貼り付けるテキストと、質問への回答です。手順は [README.md](README.md) を参照してください。文字数の上限はかっこ内に書いています。

## アプリの基本情報

| 項目 | 値 |
| --- | --- |
| パッケージ名（applicationId） | `net.langria.app`（公開後は変えられない） |
| アプリ名（30） | 英語: `Langria – AI Translator` / 日本語: `Langria – AI翻訳` |
| デフォルトの言語 | English (United States) – en-US |
| アプリかゲームか | アプリ |
| 無料か有料か | 無料（あとから有料にはできない） |
| デベロッパー名 | `Langria`（Play Console の **デベロッパー アカウント → 自己紹介**。本名でなくてよい。審査のあとで反映） |

## メインのストアの掲載情報

### 簡単な説明（80）

他社の商標（ChatGPT・Claude・Gemini）は、アプリ名と簡単な説明には入れません（詳しい説明で対応サービスとして触れるだけにする）。

```text
Translate text, photos and voice with the AI you choose, using your own API key.
```

```text
入力・写真・音声を、選んだAIとご自身のAPIキーで翻訳。サーバーもアカウントも不要。
```

### 詳しい説明（4000）

```text
Langria translates what you type, say or photograph into the language you want, using the AI service you choose: ChatGPT (OpenAI), Claude (Anthropic) or Gemini (Google).

Langria uses your own API key, and your text goes straight from your phone to that service. A free Gemini API key from Google AI Studio is enough to get started.

TRANSLATE ANYTHING
• Type or paste text — it is translated as soon as you pause.
• Photograph a sign, menu or document, or pick a photo: the text is read on your device and translated. Only the text is sent, never the image.
• Speak to type, and have the translation read aloud in the target language.
• Share text from any app to Langria, or select text and choose "Langria" in the menu.
• Swap the languages with one tap for a back-and-forth conversation.

FEATURES
• Switch between ChatGPT, Claude and Gemini, and set the model for each.
• Translate into English, Japanese, Chinese, Korean, Spanish, French, German and many more — or type any language under "Other".
• Five translation modes: Faithful, Natural, Business, Casual & social, Technical.
• On tablets and wide screens, the original and the translation sit side by side.
• Light and dark appearance; the interface is available in English and Japanese.

PRIVACY
• No Langria server and no account: the developer never sees your text or your keys.
• API keys are encrypted with a key kept in the Android Keystore, only on this device, and never backed up. Turn on the lock to require your fingerprint, face or screen lock.
• Photos are read on your device. Speech is recognized by the system speech service, on the device when the language is available there.
• The app shows a banner ad from Google AdMob at the end of the page. The text you translate is never used for ads.

REQUIREMENTS
An API key for at least one of OpenAI, Anthropic or Google Gemini (Google AI Studio). API usage is billed by each service according to its pricing; Gemini offers a free tier.

Langria is an independent project and is not affiliated with or endorsed by OpenAI, Anthropic or Google.

Source code: https://github.com/shigeya-t/Langria
```

```text
Langria は、入力した文章・話した言葉・写真の文字を、選んだAIサービス — ChatGPT（OpenAI）・Claude（Anthropic）・Gemini（Google）— で好きな言語に翻訳するアプリです。

ご自身のAPIキーを使い、文章はスマホから各サービスへ直接送られます。Google AI Studio で取得できる無料の Gemini APIキーがあれば、すぐに試せます。

なんでも翻訳
・文章を入力・貼り付けると、手を止めたところで翻訳します。
・看板・メニュー・書類を撮影するか写真を選ぶと、文字を端末の中で読み取って翻訳します。送るのは文字だけで、画像は送りません。
・話して入力し、訳文を翻訳先の言語で読み上げられます。
・ほかのアプリから文章を Langria に共有したり、文字を選んだときのメニューの「Langria」で送ったりできます。
・入れ替えボタンで言語をすぐに切り替えられるので、会話にも使えます。

主な機能
・ChatGPT / Claude / Gemini を切り替えられます。モデルもサービスごとに設定できます。
・英語・日本語・中国語・韓国語・スペイン語・フランス語・ドイツ語など多数の言語に翻訳できます。一覧にない言語も「その他」で指定できます。
・翻訳モードは5種類（原文に忠実 / ネイティブらしい自然な訳 / ビジネス文書向け / 会話・SNS向け / 技術文書向け）。
・タブレットや横に広い画面では、原文と訳文を横に並べて表示します。
・ライト / ダーク表示。画面の表示は日本語と英語に対応しています。

プライバシー
・Langria 独自のサーバーもアカウント登録もありません。開発者が翻訳する文章やAPIキーを見ることはありません。
・APIキーは Android Keystore の鍵で暗号化して、この端末にだけ保存します（バックアップされません）。ロックをオンにすると、指紋・顔認証または画面ロックが必要になります。
・写真の文字は端末の中で読み取ります。音声はシステムの音声認識で文字にします（その言語のモデルが端末にあれば端末の中で処理します）。
・ページの最後に Google AdMob のバナー広告を表示します。翻訳する文章を広告に使うことはありません。

必要なもの
OpenAI・Anthropic・Google Gemini（Google AI Studio）のいずれかのAPIキー。APIの利用料金は各サービスの料金体系に従って請求されます（Gemini には無料枠があります）。

Langria は個人による独立したプロジェクトであり、OpenAI・Anthropic・Google とは提携しておらず、これらの企業による承認を受けたものではありません。

ソースコード: https://github.com/shigeya-t/Langria
```

### グラフィック

| 欄 | 規定 | 作り方 |
| --- | --- | --- |
| アプリのアイコン | 512 × 512、32ビット PNG、1MB 以下 | `extension/icons/icon.svg` を 512 × 512 で書き出す（角丸は Play が付けるので、四角いまま・透明なしにする） |
| フィーチャー グラフィック | 1024 × 500、JPEG または 24ビット PNG（透明なし） | アイコンと名前、短いキャッチコピー（英語・日本語）。端に大事な文字を置かない |
| スマートフォンのスクリーンショット | 2〜8枚、縦横とも 320〜3840px、長辺は短辺の2倍まで | エミュレーターで撮る（[README.md](README.md) の「スクリーンショット」） |
| 7インチ・10インチのタブレット | 任意（最大8枚ずつ） | 撮ると大きい画面の端末で見つかりやすくなる。横並びの画面を見せる |

英語と日本語でスクリーンショットを分けます（**翻訳を管理 → 翻訳を追加** で日本語の掲載情報を作り、日本語の画像を入れる）。

## ストアの設定

| 項目 | 値 |
| --- | --- |
| アプリのカテゴリ | ツール（Tools） |
| タグ（最大5） | 翻訳（Translation）、辞書・翻訳、ユーティリティなど、候補から選ぶ |
| メールアドレス | 公開してよいアドレス（例: `support@langria.net`。本名の入った個人のアドレスにしない） |
| ウェブサイト | `https://langria.net/`（AdMob はこのドメインで `app-ads.txt` を探す） |
| 電話番号 | 空欄（個人アカウントでは任意） |
| 外部マーケティング | オン（Google の広告などに出てよい） |

## アプリのコンテンツ（ポリシーの申告）

### プライバシー ポリシー

```text
https://langria.net/privacy/
```

### 広告

**はい、広告を含む**（Google AdMob のバナー）。

### 広告 ID

- 広告 ID を使用しますか: **はい**
- 用途: **広告またはマーケティング**、**アナリティクス**、**不正行為の防止、セキュリティ、コンプライアンス**

Google Mobile Ads SDK が `com.google.android.gms.permission.AD_ID` を manifest に足します（`android/app/src/main/AndroidManifest.xml` には書いていない）。

### アプリのアクセス権

**アプリの一部またはすべての機能が制限されている** を選び、次の手順を入れます（審査用の Gemini APIキーを作って `<API_KEY>` に入れる。審査が終わったら Google AI Studio で削除する）。

- 名前: `API key for review`
- ユーザー名: 空欄 / パスワード: `<API_KEY>`
- 手順:

```text
Langria has no account. It calls the AI service the user chooses (OpenAI, Anthropic or Google Gemini) with the user's own API key; without a key, nothing can be translated.

To test:
1. Tap the gear icon (Settings) → AI service: Gemini.
2. Paste the API key above (in the password field) into "API key" and go back.
3. Type or paste text in the top box; the translation appears below after a moment.
4. Camera / photo buttons: the text in the photo is read on the device (ML Kit) and translated. The microphone button turns speech into text.
5. In another app, select text and choose "Langria" in the menu, or share text to Langria.

The key was created only for this review, on Google's free tier.
```

### コンテンツのレーティング（IARC のアンケート）

- カテゴリ: **ユーティリティ、生産性、コミュニケーション、その他**（Utility, Productivity, Communication, or Other）
- 暴力・性的表現・言葉づかい・規制薬物・ギャンブルなど: すべて **いいえ**
- ユーザーどうしのやり取りやコンテンツの共有: **いいえ**（翻訳結果をほかの利用者に見せる機能はない）
- 位置情報の共有: **いいえ** / デジタル商品の購入: **いいえ**
- 結果は IARC 3+ / 全年齢（日本は IARC 3+）の見込み

### ターゲット ユーザー

- 対象年齢: **18歳以上** だけを選ぶ（13歳未満を含めるとファミリー ポリシーの対象になり、広告の制限や審査が増える）
- 子どもの興味を引く可能性: **いいえ**

### データ セーフティ

Google の案内: [Google Mobile Ads SDK](https://developers.google.com/admob/android/privacy/play-data-disclosure)、[ML Kit](https://developers.google.com/ml-kit/android-data-disclosure)

**全般**

| 質問 | 回答 |
| --- | --- |
| 必要なユーザーデータを収集または共有しますか | はい |
| 収集するデータはすべて転送時に暗号化されますか | はい（HTTPS / TLS） |
| アカウントを作成する方法 | アカウントを作成できない |
| データの削除をリクエストする方法 | なし（アカウントがなく、開発者はデータを受け取らない。キーと設定はアプリの設定画面で消すか、アプリを削除すれば消える） |

**データの種類**（「収集」は端末の外へ送ること、「共有」は第三者へ渡すこと）

| データの種類 | 収集 | 共有 | 用途 | 一時的な処理 | 必須か |
| --- | --- | --- | --- | --- | --- |
| 位置情報 → おおよその位置情報（IP アドレス。AdMob） | はい | はい | 広告またはマーケティング、アナリティクス、不正行為の防止・セキュリティ・コンプライアンス | いいえ | 必須 |
| アプリのアクティビティ → アプリの操作（AdMob） | はい | はい | 同上 | いいえ | 必須 |
| アプリのアクティビティ → その他のユーザー作成コンテンツ（翻訳する文章） | はい | いいえ | アプリの機能 | いいえ | 必須 |
| アプリの情報とパフォーマンス → 診断（AdMob・ML Kit） | はい | はい | アナリティクス、広告またはマーケティング、不正行為の防止・セキュリティ・コンプライアンス | いいえ | 必須 |
| デバイスまたはその他の ID（広告 ID・アプリセット ID・ML Kit のインストールごとの ID） | はい | はい | 広告またはマーケティング、アナリティクス、不正行為の防止・セキュリティ・コンプライアンス | いいえ | 必須 |

申告しない・こう答える理由:

- **翻訳する文章は「収集」だが「共有」ではない**: Play の定義では、端末の外に送るものはすべて「収集」です。一方、利用者が自分で選んだサービスへ、利用者の操作で送るもの（利用者が送られると分かっているもの）は「共有」から除かれます。送り先のAIサービスが保存することがあるので、「一時的な処理」は **いいえ** にします。写真から読んだ文字・音声入力の文字もここに含まれます。
- **写真**: 端末の中（ML Kit）で読み、送りません。
- **音声**: アプリは録音せず、システムの音声認識サービスに渡して文字だけを受け取ります（送るかどうかはそのサービスの処理）。
- **APIキー・設定**: 端末の中にだけ保存し、APIキーは選んだサービスへの認証にだけ使います。
- **ML Kit**: データを第三者に渡さない（Google の案内）ので、ML Kit の分だけなら「共有」ではありません。フォームはデータの種類ごとに1つしか答えられず、同じ種類を AdMob が共有するので「共有: はい」になります。

SDK を更新したら、上の Google の案内を見直して、変わっていないか確かめてください。

### そのほかの申告

| 項目 | 回答 |
| --- | --- |
| 政府機関のアプリ | いいえ |
| 金融機能 | なし |
| 健康 | なし |
| ニュースアプリ | いいえ |
| 新型コロナウイルス感染症の接触確認・ステータス | いいえ |
| 写真と動画へのアクセス権 | 該当なし（写真はシステムの写真ピッカーで受け取り、`READ_MEDIA_IMAGES` などを持たない） |
| フォアグラウンド サービス | 該当なし（WorkManager が `FOREGROUND_SERVICE` を足すが、種類を宣言したサービスはない） |

### 権限（ビルドに含まれるもの）

| 権限 | どこから | 理由 |
| --- | --- | --- |
| `INTERNET` | アプリ | 選んだAIサービスへの翻訳のリクエスト、広告 |
| `RECORD_AUDIO` | アプリ | 音声入力。マイクのボタンを初めて押したときに許可を求める |
| `USE_BIOMETRIC` | アプリ | APIキーのロックを指紋・顔認証で解除する |
| `AD_ID`、`ACCESS_ADSERVICES_*` | Google Mobile Ads SDK | 広告 ID・Privacy Sandbox |
| `ACCESS_NETWORK_STATE`、`WAKE_LOCK`、`FOREGROUND_SERVICE` | Google Mobile Ads SDK / WorkManager | SDK の内部処理 |

カメラ・ストレージの権限は持ちません（撮影はシステムのカメラアプリ、写真はシステムの写真ピッカー）。確認するには、ビルドしてから `app/build/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml` を見ます。

## 配布

| 項目 | 値 |
| --- | --- |
| 国 / 地域 | すべて（Play は中国本土では提供されていない） |
| 端末 | スマートフォン・タブレット（Android 11 以降。`minSdk = 30`）。Wear OS・TV・Chromebook はそのまま（自動で判定される） |

## リリースノート（各版の「このリリースの新機能」、500）

```text
<en-US>
First release.
</en-US>
<ja-JP>
最初のリリースです。
</ja-JP>
```
