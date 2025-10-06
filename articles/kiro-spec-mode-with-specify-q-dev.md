---
title: "Amazon Q Developer + Spec KitでKiroのSpec Mode的な開発をしてみる"
emoji: "🚀"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ai", "kiro", "speckit", "amazonq"]
published: true
---

:::message
この記事の内容は人間によって検証され、生成 AI にまとめてもらいました。
:::

Kiro の Spec Mode, とてもいいですよね。
せっかくなら Kiro 以外でも同じことをしたいなと思ったので Amazon Q Developer と Spec Kit の組み合わせで同じようなことができないか試してみました。

## Kiro Spec Mode とは

Kiro は最近 AWS が出した AI 統合型の IDE です。VS Code ベースで作られていて、2 つの開発モードがあります。

- **Vibe Coding**: いわゆる普通の AI コーディング（GitHub Copilot や Cursor みたいなやつ）
- **Spec Mode**: Spec-Driven 開発をやれるやつ

### Spec Mode の特徴

コードを書く前に 3 つのドキュメントを自動生成します。

1. `requirements.md` - ユーザーストーリーと受け入れ基準（EARS 記法）
2. `design.md` - アーキテクチャ図、インターフェース、API 概要
3. `tasks.md` - ステップバイステップの実装手順

**Requirements → Design → Tasks → Testing** という流れを強制することで、「SWE ベストプラクティスを自動適用する」と評価されています。

- すべての機能に対してユニットテストを自動生成
- セキュリティスキャン、Linting、README 更新も自動化
- Autopilot モードで完全自動実装も可能

すごい。

## 代替手段: Spec Kit + Amazon Q Developer

使ったのはこの 2 つ:

**Spec Kit (GitHub Spec Kit)**
https://github.com/github/spec-kit

- Spec-Driven Development Toolkit
- CLI ベースのワークフロー管理（CLI コマンド: `specify`）
- テンプレート駆動のドキュメント生成

**Amazon Q Developer**

- AWS の AI コーディングアシスタント
- VS Code / JetBrains / CLI で利用可能
- プロンプトベースの実装

Spec Kit でスペック管理、Q Dev で実装という組み合わせです。

### セットアップ

```bash
# Spec Kitのインストール（uvを使用）
$ uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# プロジェクト初期化（Amazon Q を使う場合）
$ specify init --ai q --here
```

Amazon Q を選ぶと `.amazonq/prompt/` 配下にプロンプトテンプレートが生成されます。

```
╭───────────────────────────────────────────────────── Next Steps ─────────────────────────────────────────────────────╮
│                                                                                                                      │
│  1. You're already in the project directory!                                                                         │
│  2. Start using slash commands with your AI agent:                                                                   │
│     2.1 /constitution - Establish project principles                                                                 │
│     2.2 /specify - Create baseline specification                                                                     │
│     2.3 /plan - Create implementation plan                                                                           │
│     2.4 /tasks - Generate actionable tasks                                                                           │
│     2.5 /implement - Execute implementation                                                                          │
│                                                                                                                      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

╭──────────────────────────────────────────────── Enhancement Commands ────────────────────────────────────────────────╮
│                                                                                                                      │
│  Optional commands that you can use for your specs (improve quality & confidence)                                    │
│                                                                                                                      │
│  ○ /clarify (optional) - Ask structured questions to de-risk ambiguous areas before planning (run before /plan if    │
│  used)                                                                                                               │
│  ○ /analyze (optional) - Cross-artifact consistency & alignment report (after /tasks, before /implement)             │
│                                                                                                                      │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```

Next Step としては /コマンド が表示されますが、Q Dev では `@` から始まるプロンプトとして呼び出すことができます。

### 実行例

以下のような感じで、基本的に指示されるがままに入力していけば ok です。

```bash
# 0. Spec Kitのインストール（まだの場合）
$ uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# 1. プロジェクト初期化
$ specify init --ai q --here

# 2. VS Codeで憲章作成
> @constitution

# プロジェクトの原則（TDD、アーキテクチャなど）を確立
# → .specify/memory/constitution.md が生成される

# 3. 仕様作成
> @specify golangでmarkdownファイルをpdfに変換するCLIを作成したい

# 機能要件を定義
# → specs/001-xxx/spec.md が生成される

# 4. 曖昧性の解消
> @clarify

# 5つの質問に回答してスペックを明確化
# 例: Markdownの仕様（GFM？）、画像処理の方法、PDFフォーマットなど

# 5. 実装計画
> @plan

# 技術スタック選定、データモデル、契約の定義
# → plan.md, research.md, data-model.md, contracts/ が生成される

# 6. タスク生成
> @tasks

# 71タスクが自動生成される（TDDフローに沿った順序）

# 7. 実装
> @implement

# テストファースト開発で段階的に実装
```

できたもの

https://github.com/youyo/mdqpdf

```
$ ./mdqpdf --help
mdqpdf - Markdown to PDF Converter

Usage:
  mdqpdf <input.md> [output.pdf]
  mdqpdf --help
  mdqpdf --version

Arguments:
  <input.md>     Path to input Markdown file (required)
  [output.pdf]   Path to output PDF file (optional, defaults to <input>.pdf)

Flags:
  --help, -h     Display this help message
  --version, -v  Display version information
  --verbose      Enable verbose logging

Examples:
  mdqpdf README.md
  mdqpdf README.md output/readme.pdf
  mdqpdf --verbose README.md
```

```
$ ./mdqpdf README.md
Converting README.md to PDF...
PDF generated: README.pdf (3 pages, 4.3 KB)
Conversion completed in 0.00s
```

## Kiro との体感での比較

- 事前に Spec が作成される点は同じなので、クオリティも大体同じくらいな気がする
- Kiro は IDE に完全統合されているので UX は圧倒的に良い
- Spec Kit は 好きな IDE 、好きなコーディングエージェントを使い続けられるのがメリット

## まとめ

Kiro の Spec Mode は素晴らしい機能ですが、Spec Kit + Amazon Q Developer の組み合わせでも同様の Spec-Driven Development を実現できました。

両者の主な違いは以下の通りです:

- **Kiro**: IDE 完全統合で UX が優れている、Autopilot モードで完全自動化も可能
- **Spec Kit + Q Dev**: 使い慣れた IDE とコーディングエージェントをそのまま使える柔軟性がある

どちらを選ぶかは、「統合された体験を重視するか」「既存の開発環境を維持したいか」という選択になります。

重要なのは、**仕様を先に書く**というアプローチ自体です。Spec Kit のようなツールを使えば、どんな AI コーディングアシスタントでも Spec-Driven な開発フローを取り入れられます。

「とりあえずコードを書き始める」のではなく、要件・設計・タスクを明確にしてから実装する。この一手間が、保守性の高いコードと確実な実装につながります。

## 参考リンク

- Kiro: https://kiro.dev/
- Specify (GitHub Spec Kit): https://github.com/github/spec-kit
- 今回作ったサンプル: https://github.com/youyo/mdqpdf
