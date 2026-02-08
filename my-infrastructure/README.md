# DevHub Shared Infrastructure (2-Step Deployment)

タイムアウトのリスクを避け、DNS設定を自分のペースで行えるよう、デプロイ手順を2段階に分割しています。
設定値は `.env` ファイルで管理するため、GitHubにPushしてもドメイン名等が漏れる心配はありません。

## ファイル構成
- `1-hosted-zone.yaml` / `1-deploy-zone.ps1`: Route 53 Hosted Zone 作成用
- `2-certificate.yaml` / `2-deploy-cert.ps1`: ACM 証明書 作成用
- `.env`: 環境変数設定ファイル（Git対象外）

## 事前準備

1. `.env.example` をコピーして `.env` を作成します。
   ```powershell
   Copy-Item .env.example .env
   ```
2. `.env` を開き、`DOMAIN_NAME` にご自身のドメインを設定します。
   ```properties
   DOMAIN_NAME=your-domain.com
   ```

## 推奨手順 (Stop & Go)

### Step 1: Hosted Zone の作成
1. PowerShell でスクリプトを実行します。
   ```powershell
   .\1-deploy-zone.ps1
   ```
2. 完了しても **まだ証明書は作られません**。AWSコンソールの Route 53 を開き、作成された Hosted Zone の **NSレコード (4つ)** を確認します。

### Step 2: ドメインレジストラ設定 (自分のペースでOK)
3. お名前.comなどの管理画面で、Step 1で確認したNSレコードを設定します。
4. **DNSの反映を待ちます**。

### Step 3: 証明書の作成
5. PowerShell でスクリプトを実行します。
   ```powershell
   .\2-deploy-cert.ps1
   ```
