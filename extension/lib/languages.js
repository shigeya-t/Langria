// Target languages offered by the web app and the extension. Keys are the
// language names given to the model; values are the labels shown in the
// dropdowns, per UI language, and `locale` is the BCP 47 tag the iOS and
// Android apps use for voice input and reading aloud. `custom` is the "Other" choice, whose name
// the user types in.
// A classic script that sets `LangriaLanguages`, so the web app can load it
// with a plain <script> tag and the extension's modules can import it.
globalThis.LangriaLanguages = {
  targets: {
    English: { en: 'English', ja: '英語', locale: 'en-US' },
    Japanese: { en: 'Japanese', ja: '日本語', locale: 'ja-JP' },
    'Simplified Chinese': { en: 'Chinese (Simplified)', ja: '中国語（簡体字）', locale: 'zh-CN' },
    'Traditional Chinese': { en: 'Chinese (Traditional)', ja: '中国語（繁体字）', locale: 'zh-TW' },
    Korean: { en: 'Korean', ja: '韓国語', locale: 'ko-KR' },
    French: { en: 'French', ja: 'フランス語', locale: 'fr-FR' },
    German: { en: 'German', ja: 'ドイツ語', locale: 'de-DE' },
    Spanish: { en: 'Spanish', ja: 'スペイン語', locale: 'es-ES' },
    Italian: { en: 'Italian', ja: 'イタリア語', locale: 'it-IT' },
    Portuguese: { en: 'Portuguese', ja: 'ポルトガル語', locale: 'pt-BR' },
    Russian: { en: 'Russian', ja: 'ロシア語', locale: 'ru-RU' },
    Vietnamese: { en: 'Vietnamese', ja: 'ベトナム語', locale: 'vi-VN' },
    Thai: { en: 'Thai', ja: 'タイ語', locale: 'th-TH' },
    Indonesian: { en: 'Indonesian', ja: 'インドネシア語', locale: 'id-ID' }
  },
  custom: 'other'
};
