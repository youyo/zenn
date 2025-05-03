---
title: "saml2aws: AWSの認証を簡単に行うツール"
emoji: "🔐"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["aws", "saml", "cli"]
published: true
---

## はじめに

AWS への SSO（シングルサインオン）や多要素認証（MFA）を日常的に利用するエンジニアにとって、saml2aws は CLI から安全かつ効率的に認証情報を取得できる必須ツールです。

AWS アカウントにアクセスする際、特に企業環境では SAML 認証を使用することが多いですが、ブラウザを開いて ID プロバイダーにログインし、ロールを選択するというプロセスは、頻繁に行うには少し面倒です。

この問題を解決するのが「saml2aws」です。saml2aws を使用すると、コマンドラインから AWS SAML ベースの ID プロバイダーに対して認証を行い、一時的な認証情報を取得することができます。

この記事では、AWS IAM Identity Center（旧 AWS SSO）のアプリケーション連携先への SAML ログインを前提として、saml2aws の基本的な設定と使用方法を紹介します。

## saml2aws とは

`saml2aws` は、SAML 2.0 対応の IdP（IdP 例: AWS IAM Identity Center, Okta, ADFS, AzureAD, Google Workspace, Keycloak など）から AWS CLI/SDK 用の一時認証情報を取得するためのコマンドラインツールです。
主な特徴は以下の通りです。

- SAML 認証を自動化し、AWS CLI や Terraform 等のツールと連携可能
- 複数アカウント・複数ロールの切り替えが容易
- MFA やヘッドレスブラウザ認証にも対応
- クロスプラットフォーム（macOS, Linux, Windows）

saml2aws は、SAML 2.0 に対応した ID プロバイダーを使用して AWS へのフェデレーション認証を簡素化するための CLI ツールです。複数の AWS アカウントやロールを効率的に切り替えることができ、AWS CLI や SDK と組み合わせて使用できます。

## インストール方法

### Homebrew（macOS）

saml2aws は以下のコマンドでインストールできます（macOS の例）：

```bash
brew install saml2aws
```

他のプラットフォーム（Linux, Windows）は[公式ドキュメント](https://github.com/Versent/saml2aws)を参照してください。

## 基本的な設定

saml2aws を使用するには、最小限の設定が必要です。
**ポイント：**

- IdP ごとに必要なパラメータや挙動が異なるため、公式ドキュメントや自社の IdP 管理者の指示も参照してください。

### シェル設定

`.zshrc`（または使用しているシェルの設定ファイル）に以下の設定を追加します（bash の場合は`.bashrc`等）：

```bash
# saml2aws
eval "$(saml2aws --completion-script-zsh)"
# IdPプロバイダーは利用環境に応じて変更してください（例: ADFS, Okta, KeyCloak など）
# 一覧: https://github.com/Versent/saml2aws#supported-idp-list
export SAML2AWS_IDP_PROVIDER=Browser
export SAML2AWS_MFA=Auto
export SAML2AWS_USERNAME='your-email@example.com'
```

この例のポイント:

- シェル補完を有効にしています
- IdP プロバイダーとして「Browser」を使用（ブラウザベースの認証）
- MFA を「Auto」に設定
- ユーザー名（メールアドレス）を設定

### プロファイル設定（.saml2aws）

複数の AWS アカウントやロールを使い分ける場合、`.saml2aws`ファイルでプロファイルを管理します。

`.saml2aws`ファイルにプロファイルを設定します：

```
[profile-name]
name                    = profile-name
aws_profile             = profile-name
url                     = https://your-idp-url.com/start/#/saml/default/...
headless                = true
```

この例のポイント:

- プロファイル名を指定
- 対応する AWS プロファイル名を指定
- ID プロバイダーの URL を指定
- ヘッドレスモードを有効化（バックグラウンドでブラウザを操作、動作しない場合は `false` に変更してください）
- `url`は自社 IdP の SAML ログイン URL に合わせて設定

## プロファイルの対話的作成

`saml2aws configure -a profile-name` で対話的にプロファイルを作成・編集できます。
コマンド実行後、プロンプトに従って必要な情報（IdP 種別・URL・ユーザー名・MFA 方式など）を入力してください。

## よくあるトラブルと Tips

- **MFA 認証が失敗する場合**
  IdP やネットワーク環境によっては MFA 入力が必要な場合があります。`--skip-prompt` で自動化できない場合は、プロンプトに従って手動入力してください。

- **headless モードで失敗する場合**
  headless=true で動作しない場合は false に変更し、ブラウザを可視化してデバッグしてください。

- **プロファイルの切り替え**
  `-a profile-name` で複数プロファイルを使い分けられます。

- **AWS CLI との連携**
  認証情報は `~/.aws/credentials` に保存されるため、`aws --profile profile-name` で利用できます。

---

## 使用方法

### 初回使用時の設定

saml2aws を初めて使用する場合は、ブラウザドライバーをダウンロードする必要があります：

```bash
saml2aws login -a profile-name --download-browser-driver
```

このオプションは初回のみ必要で、ブラウザ自動操作に必要なドライバーをダウンロードします。

### 基本的なログイン

設定したプロファイルを使用してログインするには：

```bash
saml2aws login -a profile-name --skip-prompt
```

- MFA や初回ログイン時はプロンプトが表示される場合があります

このコマンドを実行すると、ブラウザが開き、ID プロバイダーのログインページが表示されます。認証が完了すると、AWS 一時認証情報が取得され、指定したプロファイルに保存されます。

**認証情報の保存先:**
`~/.aws/credentials` に `[profile-name]` セクションとして保存されます。

出力例：

```
Using IdP Account profile-name to access Browser https://your-idp-url.com/...
Authenticating as your-email@example.com ...
INFO[0000] opening browser                               URL="https://your-idp-url.com/..." provider=browser
INFO[0002] waiting ...                                   provider=browser
INFO[0003] saving storage state                          provider=browser
INFO[0003] clean up browser                              provider=browser
Selected role: arn:aws:iam::123456789012:role/YourRole
Requesting AWS credentials using SAML assertion.
Logged in as: arn:aws:sts::123456789012:assumed-role/YourRole/your-email@example.com

Your new access key pair has been stored in the AWS configuration (~/.aws/credentials)。
（`aws configure list` で内容を確認できます）
Note that it will expire at YYYY-MM-DD HH:MM:SS +0900 JST
To use this credential, call the AWS CLI with the --profile option (e.g. aws --profile profile-name ec2 describe-instances).
```

### AWS コンソールを開く

AWS 管理コンソールをブラウザで開くには：

```bash
saml2aws console -a profile-name --skip-prompt --quiet
```

このコマンドは一時認証情報を使用して AWS 管理コンソールのセッション URL を生成し、ブラウザで開きます。
**注意:** セッションの有効期限に注意し、必要に応じて再ログインしてください。

## まとめ

- saml2aws を使うことで AWS 認証の自動化・効率化が可能
- 複数アカウント・ロールの切り替えや MFA にも柔軟に対応

saml2aws を使用することで、AWS の認証プロセスを簡素化し、効率的に作業することができます。特に複数の AWS アカウントやロールを使い分ける場合に便利です。

基本的な設定さえ済ませば、数秒で AWS CLI の認証が完了し、すぐに作業を開始できます。また、GUI 操作が必要な場合も簡単に AWS 管理コンソールを開くことができます。

## 参考リンク

- [saml2aws 公式ドキュメント](https://github.com/Versent/saml2aws)
