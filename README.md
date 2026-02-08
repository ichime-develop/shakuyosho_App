# しゃくよーしょアプリ (shakuyousho_app)

友人やグループ内での「立替・割り勘・貸し借り」を、借用書風UIでシンプルに記録・共有できる Flutter アプリです。

---

## 📱 概要
- 個人またはグループ単位での貸し借りを登録・精算
- イベント（旅行・飲み会など）ごとの立替履歴を自動整理
- 透明性と合意形成を重視したUI設計（借用書スタイル）
- Flutter + Riverpod + go_router 構成

---

## 📘 開発ドキュメント

| ドキュメント | 内容 |
|---------------|------|
| [docs/README_ARCHITECTURE.md](docs/README_ARCHITECTURE.md) | レイヤー構成・依存ルール・命名規約 |
| [docs/SCREEN_MAP.md](docs/SCREEN_MAP.md) | 画面一覧・画面遷移マップ（Copilot参照用） |
| [docs/README_ERROR_HANDLING.md](docs/README_ERROR_HANDLING.md) | エラー設計（AppError） |
| Notion プロジェクトページ | 仕様・タスク管理（非公開） |

---

## 🧱 環境構築手順

環境構築・バージョン固定方法は [しゃくよーしょ開発環境構築手順書（2025年版）](docs/ENV_SETUP.md) を参照。

---

## 🚀 実行

```bash
fvm flutter pub get
fvm flutter run
```

---

## 🤝 開発メンバー

| 名前 | 役割 |
|------|------|
| 市川 慶汰 | ロジック担当 / 設計・仕様策定 |
| 坂口 | UI・ロジック両担当 |

---

## 🧭 参考リンク
- [Flutter documentation](https://docs.flutter.dev)
- [Riverpod docs](https://riverpod.dev)
- [go_router package](https://pub.dev/packages/go_router)
