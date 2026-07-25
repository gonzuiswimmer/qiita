# 概要

qiitaの執筆記事をgit管理するプロジェクトです。
`qiita-cli`の実行環境をdockerで仮想化し、可用性を高めています。<br>
また、mainブランチへのコミットで`Github Actions`を読んで、自動的にqiitaへの記事投稿ができるようなフローにしています。

## 環境

- Docker 29.5.2
- node 24^
- qiita-cli 1.7.0

## 始め方

### 環境構築

1. Dockerコンテナのビルドと立ち上げ

```
docker compose build
docker compose up -d
```

2. `qiita-container`へのアクセス

```
docker exec -it qiita-container sh
```

3. qiita-cliを使ってログイン

```
npx qiita login
```

### 記事作成・編集

#### ディレクトリ構造

```
QIITA
  ┠.cursor/commands  　　　　　# セルフレビュー用のコマンドプロンプト
  ┠.github/workflows          # 自動投稿用のワークフロー
  ┠draft_templates/           # 編集中の記事はここに格納
  ┠drafts/                    # 記事ジャンルごとのテンプレート
  ┃  ┠episode_memo.md
  ┃  ┠structure_memo.md
  ┃  ┠technique_handson.md
  ┃  ┠tips.md
  ┃  └trouble_shooting.md
  ┠node_modules/
  ┠public/                    # 公開記事はここに格納。draft_templatesからここに移し、commitすることで投稿される
  ┃  └Article.md
  ┠.gitignore
  ┠docker-compose.yml
  ┠Dockerfile                 # qiita-cliの実行環境構築用。ローカル環境を汚したくない人向け
  ┠package-lock.json
  ┠package.json
  ┠qiita.config.json
  └README.md
```

#### 記事執筆手順

- `draft_templates`のテンプレート、またはコマンドで`drafts`配下に記事を作成

```
npx new ../drafts/${ARTICLE_TITLE}
```

- `drafts`配下の記事を編集
- `npx qiita preview`でプレビューを表示。必要に応じて画像アップロードなどを実施
- 終わったら`/sefl-preview`コマンドでセルフレビュー
- `public`ディレクトリへ移行

```
mv ./drafts/${ARTICLE_TITLE} ./public/${ARTICLE_TITLE}
```

- コミット＆プッシュで公開
