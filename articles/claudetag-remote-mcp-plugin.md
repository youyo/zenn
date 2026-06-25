---
title: "Claude Tag で Remote MCP を使う：認証情報タブの役割とプラグイン配布"
emoji: "🏷️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ai", "mcp", "claude", "aws", "lambda"]
published: true
---

:::message
この記事の内容は人間によって検証され、生成 AI にまとめてもらいました。
:::

最近は Remote MCP Server ばかり作っています。
今回は2026年6月にリリースされた **Claude Tag** で Remote MCP Server を使う際に、認証まわりで得た知見をまとめます。

## TL;DR

- Claude Tag の「認証情報」タブは、許可ウェブサイトへのアクセスに使う認証情報を管理する仕組み
- Remote MCP の接続設定はプラグインの `plugin.json` で配布できる
- プラグインには接続先 URL だけ書けばよい。認証情報はタブで別管理できる（プラグインにシークレットを含めなくてよい）
- MCP 認証に使うトークンと、その先のサービス認証に使うクレデンシャルは分けて管理すべき
- Bearer 認証のままでは改善の余地あり（認証情報タブは OAuth 2.0 にも対応済み）

## 構成

今回構築したのは次の構成です。

```
Claude Tag
  └── Remote MCP サーバー（Lambda Function URL + Bearer 認証）
        └── Backlog API（Backlog API key はサーバー側に設定）
```

MCP サーバーは [youyo/logvalet](https://github.com/youyo/logvalet)（Backlog 向け CLI/MCP）を AWS Lambda + Lambda Web Adapter でホストしています。

## 認証情報タブの役割

Claude Tag の設定画面には「認証情報」タブがあります（「アプリを連携する」ダイアログ）。ここでは次のような認証情報タイプを登録できます。

![アプリを連携するダイアログ](/images/claudetag-remote-mcp-plugin/1.png)

- Bearer
- Basic
- Body parameter
- AWS SigV4
- GCP access token / GCP IAP
- OAuth 2.0 JWT bearer / client credentials / authorization code

**これは「許可ウェブサイトへのアクセスに使う認証情報を管理する仕組み」です。**

MCP 接続先を直接指定する場所ではなく、「このホストに接続するときはこの認証情報を使う」というルールを定義します。MCP サーバーへの接続そのものはプラグインが担います。

:::message
Bearer タイプは確認済みです。他の認証タイプ（OAuth 2.0 等）の MCP 接続での挙動は未検証です。
:::

## Remote MCP の接続設定はプラグインで配布できる

### 配布の仕組み

プラグインの配布には、Claude Team / Enterprise の組織プラグイン機能を使います。

1. `plugin.json` を含むプラグインを GitHub リポジトリに push する
2. Claude の組織設定でそのリポジトリを GitHub 同期ソースとして登録する
3. Claude Tag のプラグインタブに組織のプラグインが表示され、有効化できる

この仕組みに乗ることで、組織内のメンバーに MCP 接続設定を一括配布できます。

### plugin.json の書き方

`mcpServers` フィールドに接続先を書くだけです。ファイルは `plugins/{name}/.claude-plugin/plugin.json` に配置します。

```json
{
  "name": "for-claudetag",
  "description": "Backlog MCP server connection for Claude Tag",
  "version": "1.0.0",
  "mcpServers": {
    "logvalet-mcp": {
      "type": "http",
      "url": "https://xxx.lambda-url.ap-northeast-1.on.aws/mcp"
    }
  }
}
```

**プラグインには接続先 URL だけ書き、認証情報は別管理できます。**

`headers: { Authorization: "Bearer ${TOKEN}" }` のように書きたくなりますが、認証情報タブに登録したクレデンシャルが同一ホストへの MCP 接続時に適用されるため、プラグインに含める必要はありません。実際に `headers.Authorization` なしの状態で接続を試みたところ、正常に動作することを確認しています。

接続先（URL）と認証情報を切り離して管理できる利点：

- プラグインをリポジトリで公開してもシークレットが含まれない
- トークンのローテートはプラグインと独立して行える

有効化するとプラグインタブに表示されます。

![for-claudetag プラグインが有効化された状態](/images/claudetag-remote-mcp-plugin/2.png)

## 2層の認証を分けて考える

Remote MCP 構成では認証が2つのレイヤーに分かれます。

| レイヤー | 役割 | 今回の実装 |
|---------|------|-----------|
| **MCP 認証** | Claude Tag → MCP サーバーへのアクセス制御 | Bearer Token（認証情報タブで管理） |
| **サービス認証** | MCP サーバー → Backlog へのアクセス認証 | Backlog API key（サーバー側の SSM に設定） |

この2つを分けることが重要です。**Claude Tag（クライアント）が持つのは MCP の Bearer Token だけ。Backlog API key はサーバー側に留まります。**

もし同じ値を使いまわしてしまうと、クライアントが Backlog のクレデンシャルを直接持つことになり、サーバー側での管理が意味をなさなくなります。

### 実質 Claude Tag 専用のサーバーになる

Backlog API key がサーバー側に固定設定されるということは、このサーバーを使う誰もが「その Backlog アカウントとして」Backlog を操作することになります。つまり**このサーバーは実質 Claude Tag 専用の Backlog 連携サーバーです**。

MCP Bearer Token を持つ人全員が同じ Backlog ユーザーとして操作する、という設計上の前提になっています。

## Bearer 認証のままでは改善の余地あり

現在の MCP 認証は静的 Bearer Token です。静的トークンは失効させる仕組みがなく、漏洩時のリスクがあります。

認証情報タブには **OAuth 2.0 の選択肢がすでに存在します**（JWT bearer / client credentials / authorization code）。クレデンシャル衛生の観点では、短命トークン・自動リフレッシュ・標準的な失効が使える OAuth 2.0 の方が優れています。MCP サーバー側が対応すれば、より安全な構成にできます。

現状の Bearer 認証で運用する場合は、Bearer Token の定期ローテートを徹底することが重要です。

## まとめ

| 項目 | 内容 |
|------|------|
| 認証情報タブの役割 | 許可ウェブサイトへの接続に使う認証情報の管理（Bearer/Basic/OAuth 2.0 等） |
| Remote MCP 接続の設定場所 | プラグインの `plugin.json`（`mcpServers` フィールド） |
| プラグインへのシークレット記載 | 不要。接続先 URL のみ書けば、認証情報はタブで別管理できる |
| 2層の認証の分離 | MCP Bearer Token（クライアント管理）と Backlog API key（サーバー管理）は別物 |
| 現状の課題 | Bearer 認証は静的トークン。認証情報タブには OAuth 2.0 もあり、より安全な選択肢がある |

Claude Tag はリリースされたばかりで情報が少ないですが、認証情報タブとプラグインを組み合わせることで、シークレットをクライアントに持たせずに Remote MCP を利用できます。

最後に実際に動作している様子です。Slack から Backlog の課題について質問すると、MCP 経由で Claude Tag が回答を返しています。

![Slack で Claude Tag が Backlog の課題情報を返答している様子](/images/claudetag-remote-mcp-plugin/3.png)
