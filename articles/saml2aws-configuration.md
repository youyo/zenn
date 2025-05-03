---
title: "saml2aws: AWSの認証を簡単に行うツール"
emoji: "🔐"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["aws", "saml", "cli"]
published: false
---

## はじめに

AWS アカウントにアクセスする際、特に企業環境では SAML 認証を使用することが多いです。ブラウザを開いて ID プロバイダーにログインし、ロールを選択するというプロセスは、頻繁に行うには少し面倒です。

この問題を解決するのが「saml2aws」です。saml2aws を使用すると、コマンドラインから AWS SAML ベースの ID プロバイダーに対して認証を行い、一時的な認証情報を取得することができます。

この記事では、AWS IAM Identity Center のアプリケーション連携先への SAML ログインを前提として、saml2aws の基本的な設定と使用方法を紹介します。

## saml2aws とは

saml2aws は、SAML 2.0 に対応した ID プロバイダーを使用して AWS へのフェデレーション認証を簡素化するための CLI ツールです。複数の AWS アカウントやロールを効率的に切り替えることができ、AWS CLI や SDK と組み合わせて使用できます。

## インストール方法

saml2aws は以下のコマンドでインストールできます（macOS の例）：

```bash
brew install saml2aws
```

他のプラットフォームの場合は、[公式ドキュメント](https://github.com/Versent/saml2aws)を参照してください。

## 基本的な設定

saml2aws を使用するには、最小限の設定が必要です。

### シェル設定

`.zshrc`（または使用しているシェルの設定ファイル）に以下の設定を追加します：

```bash
# saml2aws
eval "$(saml2aws --completion-script-zsh)"
export SAML2AWS_IDP_PROVIDER=Browser
export SAML2AWS_MFA=Auto
export SAML2AWS_USERNAME='your-email@example.com'
```

この例では:

- シェル補完を有効にしています
- IdP プロバイダーとして「Browser」を使用（ブラウザベースの認証）
- MFA を「Auto」に設定
- ユーザー名（メールアドレス）を設定

### プロファイル設定

`.saml2aws`ファイルにプロファイルを設定します：

```
[profile-name]
name                    = profile-name
aws_profile             = profile-name
url                     = https://your-idp-url.com/start/#/saml/default/...
headless                = true
```

この例では:

- プロファイル名を指定
- 対応する AWS プロファイル名を指定
- ID プロバイダーの URL を指定
- ヘッドレスモードを有効化（バックグラウンドでブラウザを操作）

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

このコマンドを実行すると、ブラウザが開き、ID プロバイダーのログインページが表示されます。認証が完了すると、AWS 一時認証情報が取得され、指定したプロファイルに保存されます。

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

Your new access key pair has been stored in the AWS configuration.
Note that it will expire at YYYY-MM-DD HH:MM:SS +0900 JST
To use this credential, call the AWS CLI with the --profile option (e.g. aws --profile profile-name ec2 describe-instances).
```

### AWS コンソールを開く

AWS 管理コンソールをブラウザで開くには：

```bash
saml2aws console -a profile-name --skip-prompt --quiet
```

このコマンドは一時認証情報を使用して AWS 管理コンソールのセッション URL を生成し、ブラウザで開きます。

## まとめ

saml2aws を使用することで、AWS の認証プロセスを簡素化し、効率的に作業することができます。特に複数の AWS アカウントやロールを使い分ける場合に便利です。

基本的な設定さえ済ませば、数秒で AWS CLI の認証が完了し、すぐに作業を開始できます。また、GUI 操作が必要な場合も簡単に AWS 管理コンソールを開くことができます。

## 参考リンク

- [saml2aws 公式ドキュメント](https://github.com/Versent/saml2aws)
