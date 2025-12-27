# 最新の Node.js（LTS / Current 含む latest タグ）
FROM node:lts-alpine

# 作業ディレクトリ
WORKDIR /app

# npm のキャッシュを抑制（イメージ肥大化防止）
ENV NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false

# デフォルトはシェル起動（開発・手動操作向け）
CMD ["sh"]
