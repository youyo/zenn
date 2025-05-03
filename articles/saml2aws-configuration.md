---
title: "saml2aws: AWSの認証を簡単に行うツール"
emoji: "🔐"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["aws", "saml", "cli", "認証"]
published: true
---

## はじめに

AWSアカウントにアクセスする際、特に企業環境ではSAML認証を使用することが多いです。ブラウザを開いてIDプロバイダーにログインし、ロールを選択するというプロセスは、頻繁に行うには少し面倒です。

この問題を解決するのが「saml2aws」です。saml2awsを使用すると、コマンドラインからAWS SAMLベースのIDプロバイダーに対して認証を行い、一時的な認証情報を取得することができます。

この記事では、AWS IAM Identity Centerのアプリケーション連携先へのSAMLログインを前提として、saml2awsの基本的な設定と使用方法を紹介します。

## saml2awsとは

saml2awsは、SAML 2.0に対応したIDプロバイダーを使用してAWSへのフェデレーション認証を簡素化するためのCLIツールです。複数のAWSアカウントやロールを効率的に切り替えることができ、AWS CLIやSDKと組み合わせて使用できます。

## インストール方法

saml2awsは以下のコマンドでインストールできます（macOSの例）：

```bash
brew install saml2aws
```

他のプラットフォームの場合は、[公式ドキュメント](https://github.com/Versent/saml2aws)を参照してください。

## 基本的な設定

saml2awsを使用するには、最小限の設定が必要です。

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
- IdPプロバイダーとして「Browser」を使用（ブラウザベースの認証）
- MFAを「Auto」に設定
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
- 対応するAWSプロファイル名を指定
- IDプロバイダーのURLを指定
- ヘッドレスモードを有効化（バックグラウンドでブラウザを操作）

## 使用方法

### 初回使用時の設定

saml2awsを初めて使用する場合は、ブラウザドライバーをダウンロードする必要があります：

```bash
saml2aws login -a profile-name --skip-prompt --download-browser-driver
```

このオプションは初回のみ必要で、ブラウザ自動操作に必要なドライバーをダウンロードします。

### 基本的なログイン

設定したプロファイルを使用してログインするには：

```bash
saml2aws login -a profile-name --skip-prompt
```

このコマンドを実行すると、ブラウザが開き、IDプロバイダーのログインページが表示されます。認証が完了すると、AWS一時認証情報が取得され、指定したプロファイルに保存されます。

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

### 高速ログイン

オプションを追加してログイン処理をより高速かつ静かに行うことができます：

```bash
saml2aws login -a profile-name --skip-prompt --quiet --force
```

このコマンドは出力を抑制し、既存の認証情報を上書きします。実行時間の例：

```bash
$ time saml2aws login -a profile-name --skip-prompt --quiet --force
saml2aws login -a profile-name --skip-prompt --quiet --force  1.34s user 0.41s system 50% cpu 3.470 total
```

### AWSコンソールを開く

AWS管理コンソールをブラウザで開くには：

```bash
saml2aws console -a profile-name --skip-prompt --quiet
```

このコマンドは一時認証情報を使用してAWS管理コンソールのセッションURLを生成し、ブラウザで開きます。

## まとめ

saml2awsを使用することで、AWSの認証プロセスを簡素化し、効率的に作業することができます。特に複数のAWSアカウントやロールを使い分ける場合に便利です。

基本的な設定さえ済ませば、数秒でAWS CLIの認証が完了し、すぐに作業を開始できます。また、GUI操作が必要な場合も簡単にAWS管理コンソールを開くことができます。

## 参考リンク

- [saml2aws 公式ドキュメント](https://github.com/Versent/saml2aws)
