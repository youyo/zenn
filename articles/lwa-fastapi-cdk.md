---
title: "Lambda Web AdapterでFastAPIを動かす"
emoji: "⚙️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [awscdk, aws, lambda, fastapi, python]
published: true
---

Lambda Web Adapter(LWA) を使って FastAPI を動かしてみます。

https://github.com/awslabs/aws-lambda-web-adapter

Docker イメージを作成して動かすパターンが多いかと思いますが、今回は ZIP ファイルを作成して動かしてみます。

## ソースコード

https://github.com/youyo/lwa-fastapi

## ポイント

```typescript
const layer = new python.PythonLayerVersion(this, "Layer", {
  entry: "src/layer",
  compatibleRuntimes: [lambda.Runtime.PYTHON_3_13],
  compatibleArchitectures: [lambda.Architecture.ARM_64],
});

const func = new lambda.Function(this, "Func", {
  runtime: lambda.Runtime.PYTHON_3_13,
  handler: "run.sh",
  code: lambda.Code.fromAsset("src/app"),
  architecture: lambda.Architecture.ARM_64,
  timeout: cdk.Duration.seconds(30),
  layers: [
    layer,
    lambda.LayerVersion.fromLayerVersionArn(
      this,
      "LambdaAdapterLayerArm64",
      "arn:aws:lambda:ap-northeast-1:753240598075:layer:LambdaAdapterLayerArm64:24"
    ),
  ],
  environment: {
    PYTHONPATH: "/var/runtime:/opt/python",
    PORT: "8000",
    AWS_LAMBDA_EXEC_WRAPPER: "/opt/bootstrap",
  },
  loggingFormat: lambda.LoggingFormat.JSON,
});
```

### アプリ本体とライブラリのレイヤーを分ける

python 関数を作成する際には `@aws-cdk/aws-lambda-python-alpha` が便利です。requirements.txt を見てライブラリをダウンロードした上で ZIP ファイルを作成してくれます。
ただしアプリコードの修正だけをしたい場合でもライブラリをダウンロードする必要が出てきてしまうため、今回はアプリ本体とライブラリを分けることにします。
関数本体は `aws-cdk-lib/aws-lambda` を使って作成します。

### 環境変数 `PYTHONPATH` を追加する

`PORT` と `AWS_LAMBDA_EXEC_WRAPPER` についてはドキュメントに記載がある通りなのですが、今回 `uvicorn` を利用しようとしたときに以下のエラーが発生しました。

> /var/task/run.sh: line xx: uvicorn: command not found

```sh:run.sh
#!/bin/bash

uvicorn \
    main:app \
    --proxy-headers \
    --host 0.0.0.0 \
    --port ${PORT}
```

フルパスで指定してみたものの、別のエラーが出てしまいました。

```sh:run.sh
#!/bin/bash

/opt/python/bin/uvicorn \
    main:app \
    --proxy-headers \
    --host 0.0.0.0 \
    --port ${PORT}
```

> /var/task/run.sh: line xx: /opt/python/bin/uvicorn: cannot execute: required file not found

それならと python モジュールで呼び出してみたものの、uvicorn が見つからないというエラーが出てしまいました。

```sh:run.sh
#!/bin/bash

python \
    -m uvicorn \
    main:app \
    --proxy-headers \
    --host 0.0.0.0 \
    --port ${PORT}

```

> /var/lang/bin/python: No module named uvicorn

ただレイヤーとして正しく追加はできているはずなので、`PYTHONPATH` を追加してみたところ意図した動作になりました。

```typescript
  environment: {
    PYTHONPATH: "/var/runtime:/opt/python",
    PORT: "8000",
    AWS_LAMBDA_EXEC_WRAPPER: "/opt/bootstrap",
  },
```

## まとめ

Lambda Web Adapter を使って FastAPI を動かすことができました。
どうしても Docker を使ってしまうとちょっとしたコード修正でもビルド時間が気になってしまい使いづらいなーと思っていたのですが、これでだいぶ楽になりそうです 🙂
