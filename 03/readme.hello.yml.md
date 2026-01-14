# SF落語：hello.yml ってぇのは何者だい

えー、GitHub Actions でございます。
宙町の長屋に住むクマエモン、今日もカタカタやっておりますと、ご隠居が言う。

「クマエモン、手で同じことを繰り返すな。機械にやらせろ」

「へえ、ご隠居。機械ってぇのは、どいつです？」

「Actions だ。お前さんの代わりに“挨拶”してくれる」

## これが当の hello.yml で

場所はこれです。

- `.github/workflows/hello.yml`

中身はこう。

```yml
name: hello-actions

on:
  workflow_dispatch: {}
  pull_request:
    branches: [ "main" ]

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: |
          echo "Hello from GitHub Actions"
          echo "repo: ${{ github.repository }}"
          echo "actor: ${{ github.actor }}"
          echo "event: ${{ github.event_name }}"
```

## いつ動くんで？

クマエモンが聞く。

「ご隠居、いつ“挨拶”が飛び出すんで？」

ご隠居が扇子でトントン。

- `workflow_dispatch`：手動で「今だ！」って押した時  
- `pull_request`：main に向けた PR を作ったり更新した時

つまり、手で叩いても動くし、PRのたびにも勝手に動く。
未来はだいたい、勝手に動きます。

## 何を言うんで？

「Hello」だけじゃ芸がないようで、実は“状況説明”でございます。

- `repo: ${{ github.repository }}`：どのリポジトリで起きたか
- `actor: ${{ github.actor }}`：誰が起こしたか
- `event: ${{ github.event_name }}`：何の用件で起きたか

ご隠居が言う。

「ログってのはな、“読ませる”もんじゃない。“分からせる”もんだ」

## 動かし方（実務）

1. `hello.yml` をコミットして push
2. PR を main に向けて作る（または更新する）
3. GitHub の Actions タブで `hello-actions` が走る

手動なら：

- Actions タブ → `hello-actions` → `Run workflow`

## これで何が嬉しい？

クマエモンが言う。

「ご隠居、挨拶だけで未来になりますかい？」

「なる。最初の一歩は“無料で動く確信”だ。  
動いたら次は、ビルドだ、テストだ、配布だ。挨拶は、その号砲だ」

えー、そんな宙町のハローワールドでございました。
おあとがよろしいようで。

