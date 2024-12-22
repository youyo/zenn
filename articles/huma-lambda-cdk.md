---
title: "LambdaWebAdapterを使ってhumaをLambdaで動かす"
emoji: "⚙️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [awscdk, aws, lambda, go]
published: false
---

huma が勢いがあるそうですね。

https://zenn.dev/mercy34/articles/1fa551165d8ac1

huma を Lamda Web Adapter(LWA)を使って AWS Lambda 上で動かしてみました。
LWA はコンテナイメージで動かす内容が多いように感じています。
Go 製なのでワンバイナリにもなるしコンテナ化しなくても動かすことには苦労しないだろうってことで、今回は `provided.al2023` の runtime で動かしてみることにしました。

https://github.com/awslabs/aws-lambda-web-adapter

ソースコード一式がこちら。

https://github.com/youyo/huma-lambda-cdk

```go:src/main.go
package main

import (
	"context"
	"fmt"
	"net/http"

	"github.com/danielgtaylor/huma/v2"
	"github.com/danielgtaylor/huma/v2/adapters/humago"
	"github.com/danielgtaylor/huma/v2/humacli"

	_ "github.com/danielgtaylor/huma/v2/formats/cbor"
)

// Options for the CLI. Pass `--port` or set the `SERVICE_PORT` env var.
type Options struct {
	Port int `help:"Port to listen on" short:"p" default:"8888"`
}

// GreetingOutput represents the greeting operation response.
type GreetingOutput struct {
	Body struct {
		Message string `json:"message" example:"Hello, world!" doc:"Greeting message"`
	}
}

func main() {
	// Create a CLI app which takes a port option.
	cli := humacli.New(func(hooks humacli.Hooks, options *Options) {
		// Create a new router & API
		router := http.NewServeMux()
		api := humago.New(router, huma.DefaultConfig("My API", "1.0.0"))

		// Register GET /greeting/{name}
		huma.Register(api, huma.Operation{
			OperationID: "get-greeting",
			Method:      http.MethodGet,
			Path:        "/greeting/{name}",
			Summary:     "Get a greeting",
			Description: "Get a greeting for a person by name.",
			Tags:        []string{"Greetings"},
		}, func(ctx context.Context, input *struct {
			Name string `path:"name" maxLength:"30" example:"world" doc:"Name to greet"`
		}) (*GreetingOutput, error) {
			resp := &GreetingOutput{}
			resp.Body.Message = fmt.Sprintf("Hello, %s!", input.Name)
			return resp, nil
		})

		// Tell the CLI how to start your router.
		hooks.OnStart(func() {
			http.ListenAndServe(fmt.Sprintf("%s:%d", "0.0.0.0", options.Port), router)
		})
	})

	// Run the CLI. When passed no commands, it starts the server.
	cli.Run()
}
```

```go:src/go.mod
module github.com/youyo/huma-lambda-cdk/src

go 1.23.4

require github.com/danielgtaylor/huma/v2 v2.27.0

require (
	github.com/fxamacker/cbor/v2 v2.7.0 // indirect
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/spf13/cobra v1.8.1 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	github.com/x448/float16 v0.8.4 // indirect
)
```

huma のコード自体はドキュメントにある通りです。

## Lambda Web Adapter の設定

```typescript:src/huma-lambda-cdk-stack.ts
import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as lambda_go from "@aws-cdk/aws-lambda-go-alpha";
import * as lambda from "aws-cdk-lib/aws-lambda";

export class HumaLambdaCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const func = new lambda_go.GoFunction(this, "Func", {
      entry: "src",
      runtime: lambda.Runtime.PROVIDED_AL2023,
      architecture: lambda.Architecture.ARM_64,
      layers: [
        lambda.LayerVersion.fromLayerVersionArn(
          this,
          "LambdaAdapterLayerArm64",
          "arn:aws:lambda:ap-northeast-1:753240598075:layer:LambdaAdapterLayerArm64:23"
        ),
      ],
      environment: {
        PORT: "8888",
      },
    });
    func.addFunctionUrl({
      authType: lambda.FunctionUrlAuthType.NONE,
    });
  }
}
```

go のビルドを Lambda 関数の作成には `@aws-cdk/aws-lambda-go-alpha` を利用しています。alpha ですが便利なので利用します。
LWA で動かすには `PORT` の環境変数設定が必要です。これは huma のコードで指定しているポート番号です。(デフォルトが 8888 なのでそれを設定)
layer の arn は公式 Docs を参考に設定します。

https://github.com/awslabs/aws-lambda-web-adapter/tree/main?tab=readme-ov-file#lambda-functions-packaged-as-zip-package-for-aws-managed-runtimes

動作確認のために認証なしの FunctionURL を作成しています。

これをデプロイして `${FunctionURL}/docs` へアクセスすると期待通りのレスポンスが返ってきます。

![](/images/huma-lambda-cdk/1.png)

無事に動作しました 🙂
わざわざ Dockerfile を用意する必要もなく、楽でいいですね。
