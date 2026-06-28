$logDir = "C:\Users\hasec\OneDrive\Desktop\secretary\.secretary\logs"
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
$workDir = "C:\Users\hasec\OneDrive\Desktop\secretary"
$claudeCmd = "C:\Users\hasec\AppData\Roaming\npm\claude.ps1"

Set-Location $workDir

$prompt = @"
今日のGoogleカレンダーの予定を確認し、secretaryシステムのTODOファイルに反映してください。

手順:
1. mcp__google-calendar__list-events で今日（Asia/Tokyo）の primary カレンダーのイベントを取得する
2. .secretary\todos\YYYY-MM-DD.md（今日の日付）を確認する
   - ファイルがない場合: .secretary\todos\_template.md をベースに新規作成し、日付・曜日を置換する
   - ファイルがある場合: ## スケジュール セクションのみ更新（他は変更しない）
3. ## スケジュール セクションを ## 最優先 の直前に配置する

スケジュールセクション形式（イベントあり）:
## スケジュール

- [ ] HH:MM～HH:MM イベントタイトル（場所があれば括弧内に追記）

スケジュールセクション形式（イベントなし）:
## スケジュール

（本日の予定なし）
"@

Add-Content -Path $logFile -Value "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 開始 ==="

& powershell -File $claudeCmd -p $prompt 2>&1 | Tee-Object -FilePath $logFile -Append

# GitHubにpush（クラウドルーティンがtodosファイルを読み込むため）
git config user.email "kotaro.1318@gmail.com"
git config user.name "secretary-bot"
$today = (Get-Date).ToUniversalTime().AddHours(9).ToString("yyyy-MM-dd")
git add ".secretary/todos/$today.md"
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "auto: $today のスケジュールを反映"
    git push origin master
    Add-Content -Path $logFile -Value "GitHub push 完了: $today.md"
}

Add-Content -Path $logFile -Value "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完了 ==="
