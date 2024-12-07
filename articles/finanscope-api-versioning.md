---
title: "FinanScope バックエンドAPIのバージョニング"
emoji: "⚙️"
type: "tech"
topics: ["aws", "apigateway", "lambda", "awscdk", "versioning"]
published: false
---

この記事は[デジタルキューブグループ エンジニアチームアドベントカレンダー 2024](https://qiita.com/advent-calendar/2024/digitalcube-heptagon) 12 月 9 日の記事です。

---

API を公開する際にバージョニングを行うことはよくあります。
API のバージョニングにはいくつかの方法がありますが、代表的なものとして以下が挙げられます。

- パスベース
- ヘッダベース
- クエリパラメータベース

パスベースのバージョニングは以下のようにパスにバージョンを含める方法です。

```
/v1/users
/v2/users
```

[FinanScope](https://finanscope.jp/)のバックエンド API ではこのパスベースのバージョニングを採用しています。
また、サーバーレスアーキテクチャを採用しており、API Gateway / Lambda を AWS CDK を使ってコード管理しています。この記事ではどのように API バージョニングを実現しているかを紹介します。

## どのようにバージョニングするか？

API Gateway / Lambda の構成でバージョニングを実現するには大きく二つの方法があるかと思います。
こちらで紹介されている **API Gateway のステージを利用する方法** と **API Gateway 自体をバージョンごとに分ける方法** です。

https://speakerdeck.com/gawa/develop-effective-web-api-versioning?slide=19

FinanScope では後者の **API Gateway 自体を分ける** ことでバージョニングを実現しています。
Git ブランチを `dev/v1`, `dev/v2`のように分けて、それぞれのブランチが 1 スタックとなるようにデプロイパイプラインも構築しています。
ブランチごとにスタックを分けるためにスタック名にブランチ名を含めるようにしています。
ブランチ名にはバージョン以外に環境名を含めることで、環境ごとにバージョンを分けることもできるようにしています。
環境毎にデプロイ先を分けるためにブランチ名に環境名を含めていますが、不要な場合は省略可能です。

```shell
echo "STAGE=`echo ${{ github.ref_name }} | cut -d'/' -f1`" >> "$GITHUB_OUTPUT"
echo "VERSION=`echo ${{ github.ref_name }} | cut -d'/' -f2`" >> "$GITHUB_OUTPUT"
```

ブランチ名から取得した環境名とバージョン名を AWS CDK のコンテキストに渡してデプロイすることで、バージョニングを実現しています。

```shell
npx cdk deploy --all --ci --require-approval never -c stage=${{ steps.get_vars.outputs.STAGE }} -c version=${{ steps.get_vars.outputs.VERSION }}
```

## AWS CDK と GitHub Actions での実装

AWS CDK で API Gateway と Lambda をデプロイするスタックの一部抜粋です。

```ts:bin/cdk-app.ts
#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "aws-cdk-lib";
import { ApiStack } from "../lib/stacks/api";

const app = new cdk.App();
const stage = app.node.tryGetContext("stage");
const version = app.node.tryGetContext("version");

new ApiStack(
  app,
  `sample-api-${stage}-${version}`,
  {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION,
    },
  },
  stage,
  version
);
```

```ts:lib/stacks/api.ts
import * as constructs from "constructs";
import * as cdk from "aws-cdk-lib";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as apigateway from "aws-cdk-lib/aws-apigateway";

export class ApiStack extends cdk.Stack {
  constructor(scope: constructs.Construct, id: string, props: cdk.StackProps, stage: string, version: string) {
    super(scope, id, props);

    // Lambda Function
    const lambdaSamplesPost = new lambda.Function(this, "LambdaSamplesPost", {
      runtime: lambda.Runtime.PYTHON_3_12,
      handler: "index.handler",
      code: lambda.Code.fromAsset("src/lambda"),
    });

    // API Gateway
    const api = new apigateway.RestApi(this, "ApiGateway", {
      deployOptions: {
        stageName: version,
      },
    });
    const apiSamples = api.root.addResource("samples");
    apiSamples.addMethod("POST", new apigateway.LambdaIntegration(lambdaSamplesPost));
  }
}
```

```yaml:.github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches:
      - prod/v*
      - stg/v*
      - dev/v*

jobs:
  deploy:
    name: deploy
    runs-on: ubuntu-latest
    permissions: write-all

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Get variables
        id: get_vars
        run: |
          echo "STAGE=`echo ${{ github.ref_name }} | cut -d'/' -f1`" >> "$GITHUB_OUTPUT"
          echo "VERSION=`echo ${{ github.ref_name }} | cut -d'/' -f2`" >> "$GITHUB_OUTPUT"

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: |
          npm update -g npm
          npm install

      - name: Deploy for ${{ github.ref_name }}
        run: |
          npx cdk deploy --all --ci --require-approval never -c stage=${{ steps.get_vars.outputs.STAGE }} -c version=${{ steps.get_vars.outputs.VERSION }}
```

上記コードでデプロイすることで、`https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/v1/samples` のようにバージョンを含めたパスで API を公開することができます。

## バージョンごとの API Gateway を 1 つの独自ドメインにまとめる

バージョン毎に API Gateway を作成すると、それぞれの API Gateway に異なるドメインが割り当てられます。
[先ほどの資料](https://speakerdeck.com/gawa/develop-effective-web-api-versioning?slide=22)ではカスタムドメインを使ってバージョンごとの API Gateway を 1 つの独自ドメインにまとめる方法が紹介されています。

FinanScope ではカスタムドメインは利用せず CloudFront を使って一つにまとめています。
API 以外のサブシステムでも CloudFront を利用しており、CDK のコード資産を使いまわせて都合がよかったということと、将来的にオリジンとして API Gateway 以外のリソースも含める可能性があるかなと考えたため CloudFront を採用しました。

CloudFront ディストリビューションはバージョン単位で増えてしまっては困るので、別リポジトリ/別スタックで管理しています。
この辺りのスタック間の参照にはパラメーターストアを利用しています。

また、CloudFront のオリジンとして API Gateway を指定する場合にはオリジンリクエストポリシーを **AllViewerExceptHostHeader** とする必要があります。カスタムポリシーでも問題ありませんが、 `Host` ヘッダーを含めると API Gateway がエラーをかえすため注意が必要です。

## 最後に

API Gateway をバージョンごとに分けることで、バージョニングを実現することができました。
しかしこのやり方はスタックが増えます。そしてスタック数が増えるとデプロイ時間が増えるというデメリットがあります。
現状 FinanScope ではデフォルトビヘイビアを含めて 34 のビヘイビアが登録されています。(1 バージョンにつきさらに複数 API があるため)
そのためデプロイ時間が長くなってしまっています。
スタックをできるだけまとめればいいという話もありますが、リソース上限という別の問題もあったりするので今のところは仕方ないかなと思っています。
https://dev.classmethod.jp/articles/cdk-stack-splitting-nested-stack-solution/

今後もより良い方法を模索していきたいと思います。
