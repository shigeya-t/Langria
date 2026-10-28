# App Store 掲載情報（貼り付け用）

App Store Connect の各欄に貼り付けるテキストと、質問への回答です。手順は [README.md](README.md) を参照してください。文字数の上限はかっこ内に書いています。

## アプリ情報（App Information）

| 項目 | 値 |
| --- | --- |
| 名前（30） | 英語: `Langria – AI Translator` / 日本語: `Langria – AI翻訳` |
| サブタイトル（30） | 英語: `Translate text, photos & voice` / 日本語: `文章・写真・音声をAIで翻訳` |
| バンドルID | `net.langria.app`（Apple Watch: `net.langria.app.watchkitapp`） |
| SKU | `langria-ios` |
| プライマリ言語 | English (U.S.) |
| カテゴリ | プライマリ: ユーティリティ（Utilities）、セカンダリ: 仕事効率化（Productivity） |
| コンテンツ配信権 | 第三者のコンテンツを含まない（No） |
| 年齢制限 | すべて「なし」/「いいえ」→ 4+（下の「年齢制限」） |
| プライバシーポリシーURL | 英語: `https://langria.net/privacy/` / 日本語: `https://langria.net/privacy/ja.html` |

## バージョン情報（各言語）

| 項目 | 英語 | 日本語 |
| --- | --- | --- |
| サポートURL | `https://langria.net/` | `https://langria.net/ja.html` |
| マーケティングURL | `https://langria.net/` | `https://langria.net/ja.html` |
| 著作権 | `© 2026 Shigeya Tanabe` | 同じ |

マーケティングURL・サポートURLは `langria.net` にしておきます。AdMob はストアに載っているデベロッパーのWebサイトのドメインで `app-ads.txt` を探します。

### キーワード（100、カンマ区切り・空白なし）

名前とサブタイトルの語は重ねて入れなくても検索されます。他社の商標（ChatGPT・Claude・Gemini など）は入れません（審査で却下されます）。

```text
translate,translation,ocr,camera,photo,voice,speech,language,english,japanese,chinese,korean,watch
```

```text
翻訳,通訳,翻訳機,カメラ,写真,OCR,音声,読み上げ,英語,中国語,韓国語,外国語,Apple Watch
```

### プロモーションテキスト（170、審査なしでいつでも変えられる）

```text
Type, speak or snap a photo, and get a translation from the AI you choose. Your own API key, no account, no Langria server. Works on Apple Watch too.
```

```text
入力・音声・写真の文字を、選んだAIで翻訳。ご自身のAPIキーを使い、アカウント登録もLangriaのサーバーもありません。Apple Watch でも使えます。
```

### 説明（4000）

```text
Langria translates what you type, say or photograph into the language you want, using the AI service you choose: ChatGPT (OpenAI), Claude (Anthropic) or Gemini (Google).

Langria uses your own API key, and your text goes straight from your iPhone to that service. A free Gemini API key from Google AI Studio is enough to get started.

TRANSLATE ANYTHING
• Type or paste text — it is translated as soon as you pause.
• Photograph a sign, menu or document, or pick a photo: the text is read on your device and translated. Only the text is sent, never the image.
• Speak to type, and have the translation read aloud in the target language.
• Swap the languages with one tap for a back-and-forth conversation.
• On Apple Watch, dictate or scribble a sentence and see — or hear — the translation on your wrist.

FEATURES
• Switch between ChatGPT, Claude and Gemini, and set the model for each.
• Translate into English, Japanese, Chinese, Korean, Spanish, French, German and many more — or type any language under "Other".
• Five translation modes: Faithful, Natural, Business, Casual & social, Technical.
• On iPad and wide screens, the original and the translation sit side by side.
• Light and dark appearance; the interface is available in English and Japanese.

PRIVACY
• No Langria server and no account: the developer never sees your text or your keys.
• API keys are kept in this device's keychain. Turn on the lock to require Face ID, Touch ID or your passcode.
• Photos are read on your device. Speech is recognized on your device when the language supports it.
• The app shows a banner ad from Google AdMob at the end of the page. The text you translate is never used for ads.

REQUIREMENTS
An API key for at least one of OpenAI, Anthropic or Google Gemini (Google AI Studio). API usage is billed by each service according to its pricing; Gemini offers a free tier.

Langria is an independent project and is not affiliated with or endorsed by OpenAI, Anthropic or Google.
```

```text
Langria は、入力した文章・話した言葉・写真の文字を、選んだAIサービス — ChatGPT（OpenAI）・Claude（Anthropic）・Gemini（Google）— で好きな言語に翻訳するアプリです。

ご自身のAPIキーを使い、文章は iPhone から各サービスへ直接送られます。Google AI Studio で取得できる無料の Gemini APIキーがあれば、すぐに試せます。

なんでも翻訳
・文章を入力・貼り付けると、手を止めたところで翻訳します。
・看板・メニュー・書類を撮影するか写真を選ぶと、文字を端末の中で読み取って翻訳します。送るのは文字だけで、画像は送りません。
・話して入力し、訳文を翻訳先の言語で読み上げられます。
・入れ替えボタンで言語をすぐに切り替えられるので、会話にも使えます。
・Apple Watch では、音声入力や手書きで文章を入れ、訳文を手元で読んだり聞いたりできます。

主な機能
・ChatGPT / Claude / Gemini を切り替えられます。モデルもサービスごとに設定できます。
・英語・日本語・中国語・韓国語・スペイン語・フランス語・ドイツ語など多数の言語に翻訳できます。一覧にない言語も「その他」で指定できます。
・翻訳モードは5種類（原文に忠実 / ネイティブらしい自然な訳 / ビジネス文書向け / 会話・SNS向け / 技術文書向け）。
・iPad や横に広い画面では、原文と訳文を横に並べて表示します。
・ライト / ダーク表示。画面の表示は日本語と英語に対応しています。

プライバシー
・Langria 独自のサーバーもアカウント登録もありません。開発者が翻訳する文章やAPIキーを見ることはありません。
・APIキーは端末のキーチェーンに保存します。ロックをオンにすると Face ID・Touch ID・パスコードが必要になります。
・写真の文字は端末の中で読み取ります。音声は、言語が対応していれば端末の中で認識します。
・ページの最後に Google AdMob のバナー広告を表示します。翻訳する文章を広告に使うことはありません。

必要なもの
OpenAI・Anthropic・Google Gemini（Google AI Studio）のいずれかのAPIキー。APIの利用料金は各サービスの料金体系に従って請求されます（Gemini には無料枠があります）。

Langria は個人による独立したプロジェクトであり、OpenAI・Anthropic・Google とは提携しておらず、これらの企業による承認を受けたものではありません。
```

## Appのプライバシー（App Privacy）

アプリ自身は何も集めませんが、Google Mobile Ads SDK が広告のためにデータを集めるので、それを申告します（Google の案内: <https://developers.google.com/admob/ios/privacy/data-disclosure>）。トラッキングの許可（ATT）を求めているので、「トラッキングに使用」を1つ以上申告しないと審査で指摘されます。

**データを収集していますか**: はい

| データの種類 | 用途 | ユーザーに関連付け | トラッキング |
| --- | --- | --- | --- |
| 位置情報 → おおよその位置情報（IP アドレスから推定） | 第三者広告、分析 | いいえ | はい |
| ID → デバイス ID（IDFA など） | 第三者広告、分析 | いいえ | はい |
| 使用状況データ → 製品の操作 | 第三者広告、分析 | いいえ | はい |
| 使用状況データ → 広告データ | 第三者広告、分析 | いいえ | はい |
| 診断 → クラッシュデータ | 分析 | いいえ | いいえ |
| 診断 → パフォーマンスデータ | 第三者広告、分析 | いいえ | いいえ |
| 診断 → その他の診断データ | 第三者広告、分析 | いいえ | いいえ |

申告しないもの（理由）:

- **翻訳する文章・写真から読んだ文字**: 利用者が自分のAPIキーで選んだAIサービスへ、翻訳のためにその場で送るだけで、開発者や開発者の提携先は受け取りません。
- **写真・音声**: 写真は端末の中で読み、送りません。音声認識を Apple に送る場合は Apple の処理で、アプリは保存しません。
- **APIキー・設定**: 端末（と、オンにした場合はペアの Apple Watch）の中にだけ保存します。

SDK を更新したら、Google の案内とプライバシーレポート（Xcode の Organizer でアーカイブを右クリック → Generate Privacy Report）を見て、変わっていないか確かめてください。

## 年齢制限（Age Rating）

すべての項目に「なし」/「いいえ」と答えます（暴力・性的表現・ギャンブルなし、制限のないWebアクセスなし、利用者どうしのやり取り・ユーザー生成コンテンツの共有なし、広告は Google の一般的な広告）。結果は 4+ です。広告の内容は AdMob の **ブロックの管理 → 機密性の高いカテゴリ** と **広告コンテンツのフィルタ（最大 G など）** で年齢制限に合わせます。

## 輸出コンプライアンス

`ITSAppUsesNonExemptEncryption = NO` を Info.plist に入れているので、ビルドごとの質問は出ません（使う暗号は HTTPS と Apple のキーチェーンだけ）。

## App Review に関する情報

**サインインが必要**: いいえ（チェックを外す）

**連絡先**: 自分の名前・電話番号・メールアドレス

**メモ**（審査用の Gemini APIキーを作って `<API_KEY>` に入れます。審査が終わったら Google AI Studio で削除します）

```text
Langria is a translator that calls the AI service the user chooses (OpenAI, Anthropic or Google Gemini) with the user's own API key. There is no account and no server of our own.

To test:
1. Open Settings (gear icon) → AI service: Gemini.
2. Paste this API key into "API key" and close Settings:
   <API_KEY>
   (a key created only for this review, on Google's free tier)
3. Type or paste text in the top box; the translation appears below after a moment.
4. Camera / photo buttons: the text in the photo is read on the device (Vision) and translated. The microphone button turns speech into text.
5. Apple Watch: in Settings turn on "Use on Apple Watch"; the key and settings are sent to the watch app, which calls the API itself.

Ads: a Google AdMob banner is shown at the end of the page. On first launch the app shows Google's consent form where required by law (EEA/UK), then the App Tracking Transparency prompt. Declining tracking does not limit any feature.

Langria is not affiliated with OpenAI, Anthropic or Google; their names are used only to say which services the app can call.
```

```text
（日本語訳・参考）
Langria は、利用者が選んだAIサービス（OpenAI・Anthropic・Google Gemini）を利用者自身のAPIキーで呼び出す翻訳アプリです。アカウントも独自のサーバーもありません。
試し方: 設定でサービスを Gemini にし、上のキーを貼り付けて、上の欄に文章を入れる。カメラ・写真の文字は端末の中で読み取る。Apple Watch は設定の「Apple Watch で使う」をオンにする。
広告: ページの最後に AdMob のバナー。初回起動時に、必要な地域では Google の同意フォーム、続いて ATT のダイアログを出す。拒否しても機能は制限しない。
```
