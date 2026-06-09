# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリについて

[Zenn](https://zenn.dev) の記事・本を管理するコンテンツリポジトリ。zenn-cli を使ってローカルプレビューと記事管理を行う。

## コマンド

```bash
# ローカルプレビュー（http://localhost:8000）
make preview
# または
npx zenn preview

# 新規記事を作成
make article
# または
npx zenn new:article --type tech --emoji ⚙️
```

## 記事フォーマット

`articles/` 以下の Markdown ファイルのフロントマター:

```yaml
---
title: "記事タイトル"
emoji: "⚙️"
type: "tech"  # tech: 技術記事 / idea: アイデア
topics: ["aws", "cdk"]  # 小文字必須
published: true  # false で下書き
---
```

**重要**: `topics` は必ず小文字で記載すること。

## ディレクトリ構成

- `articles/` — 記事ファイル（`.md`）
- `books/` — 本のディレクトリ
- `images/` — 記事で使用する画像（`images/<記事スラッグ>/` 以下に配置）

## 著者の記事執筆スタイル

記事を書く際はこの文体・スタイルに合わせること。

**文体**
- ですます調が基調。「〜ってことで」「〜でいいですね」「〜なー」等の話し言葉を自然に混在させる
- 短文志向。一文を短く切る。「すごい。」「作りました。」のような1〜2語文も自然
- 個人的な感想・動機・設計意図は別段落にまとめず、説明文の中に「ので」「ですが」でつなげて差し込む
- 失敗・限界・試行錯誤を率直に書く（謙虚な自己開示）

**構成パターン**
1. 動機・背景（1〜3文。長い前置きは書かない）
2. GitHubリンクを早期に提示
3. 概要・設計意図 → 技術詳細（コードブロック中心）
4. まとめ（1〜3文で短く締める＋🙂）

**Markdown記法**
- GitHub/外部URLは `[テキスト](URL)` より URL 直貼り（Zennのカード表示）を好む
- コードブロックはファイル名付きで明示（`` ```go:main.go `` 等）
- 絵文字は記事末尾に🙂を1つ使う（それ以外は基本使わない）

**参考**: 過去記事は https://zenn.dev/youyo
