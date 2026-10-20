// UI text in English and Japanese, shared by the web app, the extension's
// pages, its service worker and its content script, and the iOS app (which
// runs it in JavaScriptCore). Japanese is used when the browser's language is
// Japanese, English otherwise, unless the user picked one with the language
// switch (stored by each caller: `langria-ui-language` in the web app's
// localStorage and the iOS app's UserDefaults, `uiLanguage` in the extension's
// storage).
// A classic script that sets `LangriaI18n`, like vault.js and languages.js.
(() => {
  // The extension injects this with content.js every time; keep the first
  // copy, whose language content.js has already set.
  if (globalThis.LangriaI18n) return;
  const messages = {
    en: {
      'lang.switch': 'Display language',

      // Web app
      'web.theme': 'Switch theme',
      'web.themeTitle': 'Theme',
      'web.openSettings': 'Open settings',
      'web.settings': 'Settings',
      'web.workspace': 'Translation workspace',
      'web.autoDetect': 'Detect language',
      'web.swap': 'Swap original and translation',
      'web.targetLanguage': 'Target language',
      'web.original': 'Original',
      'web.clear': 'Clear',
      'web.sourcePlaceholder': 'Enter text to translate',
      'web.characters': '{count} characters',
      'web.copyOriginal': 'Copy original',
      'web.translation': 'Translation',
      'web.empty': 'Your translation will appear here',
      'web.copyTranslation': 'Copy translation',
      'web.footerAuto': 'Detects the source language automatically',
      'web.footerShortcut': '⌘ + Enter to translate',
      'web.closeSettings': 'Close settings',
      'web.settingsDescription': 'Enter the API key for the selected AI service. Keys are stored only in this browser.',
      'web.showKey': 'Show API key',
      'web.securityNote': 'This app has no server, so your API keys are sent straight from your device to each service.',
      'web.closeNotice': 'Close notice',
      'web.close': 'Close',
      'web.demoNotice': '<strong>This page is a demo.</strong> You can set up your own copy from the <a href="https://github.com/shigeya-t/Langria" target="_blank" rel="noopener noreferrer">GitHub repository</a>. API keys you enter here are stored only in your browser’s local storage and are never collected by this site. Other pages on shigeya-t.github.io could read them, though, so encrypt them in Settings or set up your own copy.',
      'web.modelOf': '{name} model',
      'web.noKey': 'Set an API key to translate. Open Settings at the top right to enter it.',
      'web.enterTarget': 'Enter a target language.',
      'web.locked': 'API keys are locked.',
      'web.unlockPasskey': 'Unlock with a passkey (Touch ID, etc.) and translate',
      'web.unlockPassphrase': 'Unlock and translate',
      'web.swapped': 'Swapped original and translation (target: {lang})',
      'web.copiedToSource': 'Copied the translation into the original',
      'web.savedProvider': '{name} settings saved',
      'status.ready': 'Ready',
      'status.locked': 'API keys are locked',
      'status.noKey': 'No API key set',
      'status.noTarget': 'No target language',
      'status.translating': 'Translating…',
      'status.done': 'Translated',
      'status.error': 'Something went wrong',

      // Shared labels
      'mode.label': 'Translation mode',
      'mode.faithful': 'Faithful',
      'mode.natural': 'Natural',
      'mode.business': 'Business',
      'mode.casual': 'Casual & social',
      'mode.technical': 'Technical',
      'target.other': 'Other…',
      'target.customPlaceholder': 'Language name (e.g. Arabic)',
      'target.customLabel': 'Target language name',
      'settings.eyebrow': 'LOCAL SETTINGS',
      'settings.title': 'Connection settings',
      'settings.apiKey': 'API key',
      'settings.keyPlaceholder': 'Paste your API key',
      'settings.lockedPlaceholder': 'Unlock to edit',
      'settings.model': 'Model',
      'settings.save': 'Save',
      'settings.show': 'Show',
      'settings.hide': 'Hide',
      'settings.commit': 'Commit',
      'settings.repo': 'Source code on GitHub ↗',
      'passphrase': 'Passphrase',
      'copied': 'Copied',
      'unlocked': 'Unlocked',

      // Errors
      'error.noDetail': 'The service did not return any error details.',
      'error.detail': 'Details: {detail}',
      'error.auth': 'Check your API key. The {name} API key is invalid or lacks permission.',
      'error.rateLimit': 'You have hit a usage limit or sent too many requests in a short time. Wait a moment and try again.',
      'error.model': 'Check the model or API settings. Current model: {model}',
      'error.http': '{name} returned an error (HTTP {status}).',
      'error.networkWeb': 'Could not connect to {name}. Check your network connection, browser extensions, or any restrictions on API access from the browser.',
      'error.network': 'Could not connect to {name}. Check your network connection.',
      'error.timeout': '{name} did not respond in time. Try again in a moment.',
      'error.blocked': '{name} declined to translate this text ({reason}).',
      'error.unexpected': 'An unexpected error occurred.',
      'error.emptyWeb': 'No translation came back: the model did not reply with text. Check the model name in Settings.',
      'error.empty': 'No translation came back. Check the model name in Settings.',
      'error.truncated': 'The translation was cut off at the model\'s output limit. Translate a shorter passage at a time.',
      'error.locked': 'API keys are locked. Unlock them in Langria settings.',
      'error.missingKey': 'No {name} API key is set. Enter it in Settings.',
      'error.missingKeyVault': 'Your encrypted API keys do not include a {name} key. Unlock them in Settings and enter it.',

      // Extension
      'ext.actionTitle': 'Translate the page with Langria',
      'ext.menuSelection': 'Translate “%s” with Langria',
      'ext.menuPage': 'Translate this page with Langria',
      'ext.missingTarget': 'No target language entered. Open Langria in the toolbar and type a language name under “Other”.',
      'ext.missingTargetPopup': 'No target language entered. Type a language name under “Other” in the popup.',
      'ext.startFailed': 'Could not start translating.',
      'ext.bubble': 'Langria translation',
      'ext.close': 'Close',
      'ext.copy': 'Copy',
      'popup.aiService': 'AI service',
      'popup.target': 'Translate to',
      'popup.translate': 'Translate this page',
      'popup.stop': 'Stop and show original',
      'popup.restore': 'Show original',
      'popup.retry': 'Translate again',
      'popup.translating': 'Translating what’s on screen…',
      'popup.translatingCount': 'Translating what’s on screen… {done} / {total}',
      'popup.translated': 'Translated {total} items on screen. More is translated as you scroll.',
      'popup.nothing': 'Nothing on screen needs translating. More is translated as you scroll.',
      'popup.lockedPassphrase': 'API keys are locked. Enter your passphrase to translate.',
      'popup.lockedPasskey': 'API keys are locked. Starting a translation opens a window to unlock them with your passkey.',
      'popup.retranslateFailed': 'Could not translate again. Reload the page and try again.',
      'popup.unsupported': 'This page (a browser page, the Web Store, etc.) cannot be translated.',
      'popup.enterTarget': 'Enter a target language name.',
      'popup.starting': 'Starting translation…',
      'popup.startFailed': 'Could not start translating. Reload the page and try again.',
      'popup.shortcut': 'Alt+Shift+T toggles',
      'options.pageTitle': 'Langria Settings',
      'options.description': 'Enter the API key and model for each AI service. Keys are stored only in this browser’s extension storage (<code>chrome.storage.local</code>).',
      'options.rateLimit': 'Max requests per minute',
      'options.rateHint': '0 = unlimited',
      'options.saved': 'Settings saved',
      'options.securityNote': 'When translating, the page text and your API key go straight from the extension to each AI service’s API, not through any server. Password fields, text inputs and code blocks are not translated.',
      'unlock.pageTitle': 'Unlock Langria',
      'unlock.message': 'API keys are locked. Translation continues once you unlock them.',
      'unlock.button': 'Unlock',
      'unlock.passkey': 'Unlock with a passkey (Touch ID, etc.)',
      'unlock.notStarted': 'Unlocked, but the translation could not start. Please try again.',

      // API key encryption (vault.js)
      'vault.title': 'API key encryption',
      'vault.methodPasskey': 'a passkey (Touch ID, etc.)',
      'vault.methodPassphrase': 'a passphrase',
      'vault.unsupportedData': 'The data returned by the passkey is in an unsupported format. Encrypt with a passphrase instead.',
      'vault.originFile': 'Not available on a page opened as a file. Open it over https or at http://localhost.',
      'vault.originUrl': 'Not available at this URL. Open it over https (with a domain name) or at http://localhost.',
      'vault.noPasskeys': 'This browser does not support passkeys.',
      'vault.noPrf': 'This browser does not support encrypting with a passkey (PRF).',
      'vault.noBiometrics': 'Touch ID or other biometrics are not available on this device.',
      'vault.prfUnsupported': 'This browser or authenticator does not support encrypting with a passkey (PRF). Encrypt with a passphrase instead.',
      'vault.userName': 'Langria API keys',
      'vault.tooShort': 'Use a passphrase of at least {min} characters.',
      'vault.wrongPasskey': 'Could not decrypt. Use the same passkey you encrypted with.',
      'vault.wrongPassphrase': 'Wrong passphrase.',
      'vault.cancelled': 'Authentication was cancelled or timed out.',
      'vault.registered': 'This passkey is already registered.',
      'vault.security': 'Passkeys are not available on this page ({message}). Open it over https or at http://localhost, or encrypt with a passphrase.',
      'vault.notSupported': 'Passkeys cannot be created here ({message}). Encrypt with a passphrase instead.',
      'vault.createHint': ' Password managers such as 1Password sometimes cannot save a passkey for this page. In their dialog, choose another option such as a security key to create it in the browser’s own dialog, or encrypt with a passphrase.',
      'vault.methods': 'How API keys are stored',
      'vault.none': 'Do not encrypt',
      'vault.noneNote': 'Keys are saved in this browser without encryption.',
      'vault.passkey': 'Encrypt with a passkey (Touch ID, etc.)',
      'vault.passkeyNote': 'Unlock with Touch ID or similar when you start using it.',
      'vault.passphrase': 'Encrypt with a passphrase',
      'vault.passphraseNote': 'Enter the passphrase to unlock when you start using it.',
      'vault.editPlaceholder': 'Enter the passphrase to edit the keys',
      'vault.sessionUnlocked': 'Your API keys are stored encrypted with {method}. They stay unlocked for translating until you close the browser.',
      'vault.reauth': 'Authenticate again to change the keys or how they are stored on this page.',
      'vault.lock': 'Lock',
      'vault.editPasskey': 'Edit keys (authenticate with passkey)',
      'vault.edit': 'Edit keys',
      'vault.locked': 'API keys are locked. Unlock them to translate or to change how they are stored.',
      'vault.unlockPasskey': 'Unlock with a passkey (Touch ID, etc.)',
      'vault.unlock': 'Unlock',
      'vault.lostPasskey': 'Can’t use your passkey? (deletes the saved keys)',
      'vault.forgotPassphrase': 'Forgot your passphrase? (deletes the saved keys)',
      'vault.apply': 'Switch to this method',
      'vault.cancel': 'Cancel',
      'vault.choosePassphrase': 'Choose a passphrase. If you forget it, the keys cannot be decrypted, so keep it in 1Password or your keychain.',
      'vault.passphrasePlaceholder': 'Passphrase (at least {min} characters)',
      'vault.confirmPlaceholder': 'Enter it again',
      'vault.passkeyNext': 'Switching opens a prompt (Touch ID, etc.) to create a passkey.',
      'vault.passkeyExtensionNote': 'Password managers such as 1Password may not support passkeys for Chrome extensions.',
      'vault.noneNext': 'Stop encrypting and store the API keys in this browser unencrypted.',
      'vault.unlockedNow': 'Your API keys are stored encrypted with {method}. They are unlocked right now.',
      'vault.plain': 'Your API keys are stored in this browser unencrypted.',
      'vault.mismatch': 'The passphrases do not match.',
      'vault.resetConfirm': 'This deletes the encrypted API keys. You will need to enter them again. Continue?',

      // iOS app
      'ios.settingsDescription': 'Enter the API key and model for each AI service. Keys are stored only in this device’s keychain.',
      'ios.camera': 'Take a photo',
      'ios.photo': 'Choose a photo',
      'ios.removeImage': 'Remove image',
      'ios.reading': 'Reading text…',
      'ios.noText': 'No text was found in the image.',
      'ios.ocrFailed': 'Could not read text from the image.',
      'ios.imageFailed': 'Could not load the image.',
      'ios.ocrNote': 'Text in photos is read on this device. Only the text is sent for translation.',
      'ios.lockTitle': 'API key lock',
      'ios.lockToggle': 'Unlock with {method}',
      'ios.lockNote': 'Keys are always stored in the keychain. When this is on, {method} is needed each time you open the app.',
      'ios.unlockButton': 'Unlock with {method} and translate',
      'ios.unlockReason': 'Unlock your API keys',
      'ios.passcode': 'the device passcode',
      'ios.noPasscode': 'Set a device passcode to lock the API keys.',
      'ios.keychainError': 'Could not access the keychain ({detail}).',
      'ios.displayLanguage': 'Display language',
      'ios.system': 'System',
      'ios.appearance': 'Appearance',
      'ios.light': 'Light',
      'ios.dark': 'Dark',
      'ios.done': 'Done',
      'ios.version': 'Version',
      'ios.adPrivacy': 'Ad privacy choices',
      'ios.dictate': 'Voice input',
      'ios.dictateHint': 'Touch and hold to choose the language you speak.',
      'ios.stopDictation': 'Stop voice input',
      'ios.dictationLanguage': 'Language you speak',
      'ios.listening': 'Listening ({lang})…',
      'ios.speechDenied': 'To use voice input, allow the microphone and speech recognition for Langria in the Settings app.',
      'ios.speechUnavailable': 'Voice input is not available for {lang} on this device.',
      'ios.speechFailed': 'Voice input stopped ({detail}).',
      'ios.speak': 'Read aloud',
      'ios.stopSpeaking': 'Stop reading aloud',
      'ios.unsavedTitle': 'Discard unsaved changes?',
      'ios.unsavedMessage': 'The API key or model you changed for {name} has not been saved.',
      'ios.discard': 'Discard changes'
    },
    ja: {
      'lang.switch': '表示言語',

      'web.theme': '表示テーマを切り替え',
      'web.themeTitle': 'テーマ切替',
      'web.openSettings': '設定を開く',
      'web.settings': '設定',
      'web.workspace': '翻訳ワークスペース',
      'web.autoDetect': '言語を自動判別',
      'web.swap': '原文と翻訳を入れ替え',
      'web.targetLanguage': '翻訳先の言語',
      'web.original': '原文',
      'web.clear': 'クリア',
      'web.sourcePlaceholder': '翻訳したいテキストを入力',
      'web.characters': '{count} 文字',
      'web.copyOriginal': '原文をコピー',
      'web.translation': '翻訳',
      'web.empty': 'ここに翻訳が表示されます',
      'web.copyTranslation': '翻訳をコピー',
      'web.footerAuto': '原文の言語を自動判別して翻訳します',
      'web.footerShortcut': '⌘ + Enter で翻訳',
      'web.closeSettings': '設定を閉じる',
      'web.settingsDescription': '選択中のAIサービスのAPIキーを入力してください。キーはこのブラウザ内にのみ保存されます。',
      'web.showKey': 'APIキーを表示',
      'web.securityNote': 'このアプリはサーバーを経由しないため、APIキーはご自身の端末から各サービスへ直接送信されます。',
      'web.closeNotice': '注意書きを閉じる',
      'web.close': '閉じる',
      'web.demoNotice': '<strong>このページはデモ用です。</strong><a href="https://github.com/shigeya-t/Langria" target="_blank" rel="noopener noreferrer">GitHub のリポジトリ</a>から自分用にセットアップして使うこともできます。ここで入力したAPIキーはブラウザのローカルストレージにだけ保存され、このサイトで収集されることはありません。ただし、同じ shigeya-t.github.io のほかのページからは読み取れるため、設定で暗号化するか、自分用にセットアップしてお使いください。',
      'web.modelOf': '{name} のモデル',
      'web.noKey': 'APIキーを設定すると翻訳できます。右上の設定から入力してください。',
      'web.enterTarget': '翻訳先の言語を入力してください。',
      'web.locked': 'APIキーはロックされています。',
      'web.unlockPasskey': 'パスキー（Touch ID など）で解除して翻訳',
      'web.unlockPassphrase': '解除して翻訳',
      'web.swapped': '原文と翻訳を入れ替えました（翻訳先: {lang}）',
      'web.copiedToSource': '翻訳結果を原文にコピーしました',
      'web.savedProvider': '{name} の設定を保存しました',
      'status.ready': '準備完了',
      'status.locked': 'APIキーがロックされています',
      'status.noKey': 'APIキーが未設定です',
      'status.noTarget': '翻訳先が未入力です',
      'status.translating': '翻訳しています…',
      'status.done': '翻訳完了',
      'status.error': 'エラーが発生しました',

      'mode.label': '翻訳モード',
      'mode.faithful': '原文に忠実',
      'mode.natural': 'ネイティブらしい自然な訳',
      'mode.business': 'ビジネス文書向け',
      'mode.casual': '会話・SNS向け',
      'mode.technical': '技術文書向け',
      'target.other': 'その他…',
      'target.customPlaceholder': '言語名（例: アラビア語）',
      'target.customLabel': '翻訳先の言語名',
      'settings.eyebrow': 'LOCAL SETTINGS',
      'settings.title': '接続設定',
      'settings.apiKey': 'API キー',
      'settings.keyPlaceholder': 'API key を貼り付け',
      'settings.lockedPlaceholder': 'ロックを解除すると編集できます',
      'settings.model': 'モデル',
      'settings.save': '保存する',
      'settings.show': '表示',
      'settings.hide': '隠す',
      'settings.commit': 'コミット',
      'settings.repo': 'ソースコード（GitHub）↗',
      'passphrase': 'パスフレーズ',
      'copied': 'コピーしました',
      'unlocked': 'ロックを解除しました',

      'error.noDetail': 'サービスから詳細なエラー情報を取得できませんでした。',
      'error.detail': '詳細: {detail}',
      'error.auth': 'APIキーを確認してください。{name} 用のAPIキーが無効、または権限不足です。',
      'error.rateLimit': '利用上限に達しているか、短時間にリクエストが集中しています。しばらく待ってから再試行してください。',
      'error.model': 'モデルまたはAPIの設定を確認してください。現在のモデル: {model}',
      'error.http': '{name} でエラーが発生しました（HTTP {status}）。',
      'error.networkWeb': '{name} に接続できませんでした。ネットワーク接続、ブラウザの拡張機能、またはブラウザからのAPI接続制限を確認してください。',
      'error.network': '{name} に接続できませんでした。ネットワーク接続を確認してください。',
      'error.timeout': '{name} から時間内に応答がありませんでした。しばらくしてから再試行してください。',
      'error.blocked': '{name} がこのテキストの翻訳を拒否しました（{reason}）。',
      'error.unexpected': '予期しないエラーが発生しました。',
      'error.emptyWeb': '翻訳結果を取得できませんでした。モデルからテキスト形式の応答が返らなかったため、設定のモデル名を確認してください。',
      'error.empty': '翻訳結果を取得できませんでした。設定のモデル名を確認してください。',
      'error.truncated': 'モデルの出力上限に達したため、翻訳が途中で切れました。原文を短く分けて翻訳してください。',
      'error.locked': 'APIキーがロックされています。Langria の設定画面でロックを解除してください。',
      'error.missingKey': '{name} のAPIキーが未設定です。設定画面から入力してください。',
      'error.missingKeyVault': '暗号化して保存したAPIキーに {name} のキーが含まれていません。設定画面でロックを解除してから入力してください。',

      'ext.actionTitle': 'Langria でページを翻訳',
      'ext.menuSelection': 'Langria で「%s」を翻訳',
      'ext.menuPage': 'Langria でこのページを翻訳',
      'ext.missingTarget': '翻訳先の言語が未入力です。ツールバーの Langria で「その他」の言語名を入力してください。',
      'ext.missingTargetPopup': '翻訳先の言語が未入力です。ポップアップの「その他」に言語名を入力してください。',
      'ext.startFailed': '翻訳を開始できませんでした。',
      'ext.bubble': 'Langria 翻訳',
      'ext.close': '閉じる',
      'ext.copy': 'コピー',
      'popup.aiService': 'AIサービス',
      'popup.target': '翻訳先',
      'popup.translate': 'このページを翻訳',
      'popup.stop': '翻訳を中止して原文に戻す',
      'popup.restore': '原文に戻す',
      'popup.retry': 'もう一度翻訳',
      'popup.translating': '表示中の部分を翻訳しています…',
      'popup.translatingCount': '表示中の部分を翻訳しています… {done} / {total}',
      'popup.translated': '表示中の {total} 箇所を翻訳しました。スクロールすると続きを順次翻訳します。',
      'popup.nothing': '表示中に翻訳が必要なテキストはありません。スクロールすると続きを翻訳します。',
      'popup.lockedPassphrase': 'APIキーがロックされています。パスフレーズを入力して翻訳してください。',
      'popup.lockedPasskey': 'APIキーがロックされています。翻訳を始めると、パスキーで解除する画面が開きます。',
      'popup.retranslateFailed': '再翻訳できませんでした。ページを再読み込みしてからもう一度お試しください。',
      'popup.unsupported': 'このページ（ブラウザの内部ページやWebストアなど）は翻訳できません。',
      'popup.enterTarget': '翻訳先の言語名を入力してください。',
      'popup.starting': '翻訳を開始しています…',
      'popup.startFailed': '翻訳を開始できませんでした。ページを再読み込みしてからもう一度お試しください。',
      'popup.shortcut': 'Alt+Shift+T で切替',
      'options.pageTitle': 'Langria 設定',
      'options.description': '各AIサービスのAPIキーとモデル名を入力してください。キーはこのブラウザの拡張機能ストレージ（<code>chrome.storage.local</code>）にのみ保存されます。',
      'options.rateLimit': '1分あたりの最大リクエスト数',
      'options.rateHint': '0 = 制限なし',
      'options.saved': '設定を保存しました',
      'options.securityNote': '翻訳時は、ページのテキストとAPIキーが拡張機能から各AIサービスのAPIへ直接送信されます。サーバーを経由しません。パスワード入力欄・テキスト入力欄・コードブロックは翻訳の対象外です。',
      'unlock.pageTitle': 'Langria ロック解除',
      'unlock.message': 'APIキーがロックされています。解除すると翻訳を続けます。',
      'unlock.button': 'ロックを解除',
      'unlock.passkey': 'パスキー（Touch ID など）で解除',
      'unlock.notStarted': 'ロックを解除しました。翻訳を開始できなかったため、もう一度お試しください。',

      'vault.title': 'APIキーの暗号化',
      'vault.methodPasskey': 'パスキー（Touch ID など）',
      'vault.methodPassphrase': 'パスフレーズ',
      'vault.unsupportedData': 'パスキーから受け取ったデータの形式に対応していません。パスフレーズで暗号化してください。',
      'vault.originFile': 'ファイルとして開いたページでは使えません。https または http://localhost で開いてください。',
      'vault.originUrl': 'このURLでは使えません。https（ドメイン名）または http://localhost で開いてください。',
      'vault.noPasskeys': 'このブラウザはパスキーに対応していません。',
      'vault.noPrf': 'このブラウザはパスキーによる暗号化（PRF）に対応していません。',
      'vault.noBiometrics': 'この端末では Touch ID などの生体認証を使えません。',
      'vault.prfUnsupported': 'このブラウザまたは認証器は、パスキーによる暗号化（PRF）に対応していません。パスフレーズで暗号化してください。',
      'vault.userName': 'Langria APIキー',
      'vault.tooShort': 'パスフレーズは{min}文字以上にしてください。',
      'vault.wrongPasskey': '復号できませんでした。暗号化したときと同じパスキーで認証してください。',
      'vault.wrongPassphrase': 'パスフレーズが違います。',
      'vault.cancelled': '認証がキャンセルされたか、時間切れになりました。',
      'vault.registered': 'このパスキーはすでに登録されています。',
      'vault.security': 'このページではパスキーを使えません（{message}）。https または http://localhost で開くか、パスフレーズで暗号化してください。',
      'vault.notSupported': 'この環境ではパスキーを作成できません（{message}）。パスフレーズで暗号化してください。',
      'vault.createHint': ' 1Password などのパスワード管理ツールは、このページのパスキーを保存できないことがあります。その画面でセキュリティキーなど別の方法を選んでブラウザ標準の画面で作成するか、パスフレーズで暗号化してください。',
      'vault.methods': 'APIキーの保存方法',
      'vault.none': '暗号化しない',
      'vault.noneNote': '暗号化せずに、このブラウザに保存します。',
      'vault.passkey': 'パスキー（Touch ID など）で暗号化',
      'vault.passkeyNote': '使い始めるときに Touch ID などで解除します。',
      'vault.passphrase': 'パスフレーズで暗号化',
      'vault.passphraseNote': '使い始めるときにパスフレーズを入力して解除します。',
      'vault.editPlaceholder': 'キーを編集するときはパスフレーズを入力',
      'vault.sessionUnlocked': 'APIキーは{method}で暗号化して保存されています。ブラウザを閉じるまでロック解除中で、翻訳に使えます。',
      'vault.reauth': 'この画面でキーや保存方法を変更するときは、もう一度認証してください。',
      'vault.lock': 'ロックする',
      'vault.editPasskey': 'キーを編集する（パスキーで認証）',
      'vault.edit': 'キーを編集する',
      'vault.locked': 'APIキーはロックされています。翻訳や保存方法の変更には、ロックを解除してください。',
      'vault.unlockPasskey': 'パスキー（Touch ID など）で解除',
      'vault.unlock': '解除する',
      'vault.lostPasskey': 'パスキーを使えない場合（保存したキーを削除）',
      'vault.forgotPassphrase': 'パスフレーズを忘れた場合（保存したキーを削除）',
      'vault.apply': 'この方法に変更',
      'vault.cancel': 'キャンセル',
      'vault.choosePassphrase': 'パスフレーズを決めてください。忘れると復号できないため、1Password やキーチェーンに保管しておくと安心です。',
      'vault.passphrasePlaceholder': 'パスフレーズ（{min}文字以上）',
      'vault.confirmPlaceholder': 'もう一度入力',
      'vault.passkeyNext': '変更すると、パスキーを作成する認証画面（Touch ID など）が開きます。',
      'vault.passkeyExtensionNote': '1Password などのパスワードマネージャーは Chrome 拡張機能のパスキーに対応していないことがあります。',
      'vault.noneNext': '暗号化をやめて、APIキーを暗号化せずにこのブラウザに保存します。',
      'vault.unlockedNow': 'APIキーは{method}で暗号化して保存されています。いまはロック解除中です。',
      'vault.plain': 'APIキーは暗号化されずにこのブラウザに保存されています。',
      'vault.mismatch': '確認用のパスフレーズが一致しません。',
      'vault.resetConfirm': '暗号化して保存したAPIキーを削除します。キーはあとで入力し直してください。よろしいですか？',

      'ios.settingsDescription': 'AIサービスごとにAPIキーとモデルを入力します。キーはこの端末のキーチェーンにだけ保存されます。',
      'ios.camera': '写真を撮る',
      'ios.photo': '写真を選ぶ',
      'ios.removeImage': '画像を外す',
      'ios.reading': '文字を読み取り中…',
      'ios.noText': '画像から文字が見つかりませんでした。',
      'ios.ocrFailed': '画像の文字を読み取れませんでした。',
      'ios.imageFailed': '画像を読み込めませんでした。',
      'ios.ocrNote': '写真の文字はこの端末の中で読み取ります。翻訳のために送るのは文字だけです。',
      'ios.lockTitle': 'APIキーのロック',
      'ios.lockToggle': '{method}でロックを解除する',
      'ios.lockNote': 'キーはいつもキーチェーンに保存されます。オンにすると、アプリを開くたびに{method}が必要になります。',
      'ios.unlockButton': '{method}でロックを解除して翻訳',
      'ios.unlockReason': 'APIキーのロックを解除します',
      'ios.passcode': '端末のパスコード',
      'ios.noPasscode': 'APIキーをロックするには、端末のパスコードを設定してください。',
      'ios.keychainError': 'キーチェーンを使えませんでした（{detail}）。',
      'ios.displayLanguage': '表示言語',
      'ios.system': '端末の設定',
      'ios.appearance': '表示テーマ',
      'ios.light': 'ライト',
      'ios.dark': 'ダーク',
      'ios.done': '完了',
      'ios.version': 'バージョン',
      'ios.adPrivacy': '広告のプライバシー設定',
      'ios.dictate': '音声入力',
      'ios.dictateHint': '長押しで、話す言語を選べます。',
      'ios.stopDictation': '音声入力を止める',
      'ios.dictationLanguage': '話す言語',
      'ios.listening': '聞き取り中（{lang}）…',
      'ios.speechDenied': '音声入力を使うには、設定アプリで Langria にマイクと音声認識を許可してください。',
      'ios.speechUnavailable': 'この端末では{lang}の音声入力を使えません。',
      'ios.speechFailed': '音声入力が止まりました（{detail}）。',
      'ios.speak': '読み上げ',
      'ios.stopSpeaking': '読み上げを止める',
      'ios.unsavedTitle': '保存していない変更を破棄しますか？',
      'ios.unsavedMessage': '{name}のAPIキーまたはモデルの変更は、まだ保存されていません。',
      'ios.discard': '変更を破棄'
    }
  };
  const languages = { en: 'English', ja: '日本語' };
  let current = detect();

  // In the extension, Chrome's UI language (the service worker's navigator
  // may not follow it); in the web app, the browser's language.
  function detect() {
    const language = globalThis.chrome?.i18n?.getUILanguage?.() || globalThis.navigator?.language || '';
    return /^ja\b/i.test(language) ? 'ja' : 'en';
  }

  // `choice` is the language picked with the switch, or empty to follow the browser.
  function setLanguage(choice) {
    current = messages[choice] ? choice : detect();
    return current;
  }

  function t(key, params = {}) {
    const text = messages[current][key] ?? messages.en[key] ?? key;
    return text.replace(/\{(\w+)\}/g, (match, name) => (name in params ? params[name] : match));
  }

  // Label of a LangriaLanguages target in the UI language.
  function languageLabel(target) {
    const labels = globalThis.LangriaLanguages?.targets[target];
    return labels?.[current] || labels?.en || target;
  }

  // Fills elements marked with data-i18n (text), data-i18n-html (trusted
  // markup from the messages above) and data-i18n-attr ("placeholder:key;
  // aria-label:key"). Not for content scripts: it would touch the page.
  function apply(root = document) {
    if (root === document) document.documentElement.lang = current;
    root.querySelectorAll('[data-i18n]').forEach((element) => { element.textContent = t(element.dataset.i18n); });
    root.querySelectorAll('[data-i18n-html]').forEach((element) => { element.innerHTML = t(element.dataset.i18nHtml); });
    root.querySelectorAll('[data-i18n-attr]').forEach((element) => {
      for (const pair of element.dataset.i18nAttr.split(';')) {
        const [name, key] = pair.split(':').map((part) => part.trim());
        element.setAttribute(name, t(key));
      }
    });
  }

  // Target language used until the user picks one: Japanese for a Japanese
  // UI, English otherwise.
  function defaultTarget() {
    return current === 'ja' ? 'Japanese' : 'English';
  }

  // A small EN / JA switch. `onChange(language)` stores the choice and
  // re-renders the page.
  function mountSwitch(root, onChange) {
    function render() {
      root.className = 'lang-switch';
      root.setAttribute('role', 'group');
      root.setAttribute('aria-label', t('lang.switch'));
      root.innerHTML = Object.entries(languages).map(([code, name]) => `<button type="button" lang="${code}" data-lang="${code}" title="${name}" aria-pressed="${code === current}">${code.toUpperCase()}</button>`).join('');
    }
    root.addEventListener('click', (event) => {
      const code = event.target.closest('[data-lang]')?.dataset.lang;
      if (!code || code === current) return;
      setLanguage(code);
      render();
      onChange(code);
    });
    render();
    return { render };
  }

  globalThis.LangriaI18n = { t, setLanguage, languageLabel, defaultTarget, apply, mountSwitch, get language() { return current; } };
})();
