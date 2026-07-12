$logDir = "C:\Users\hasec\Desktop\APP\secretary\.secretary\logs"
$workDir = "C:\Users\hasec\Desktop\APP\secretary"
$claudeCmd = "C:\Users\hasec\AppData\Roaming\npm\claude.cmd"
$promptFile = "$workDir\prompt.txt"
$todoDir = "$workDir\.secretary\todos"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

Set-Location $workDir

$scriptStart = Get-Date
$today = $scriptStart.ToString("yyyy-MM-dd")
$logFile = "$logDir\$today.log"
$todoFile = "$todoDir\$today.md"

function Write-Log([string]$text) {
    [System.IO.File]::AppendAllText($logFile, "$text`r`n", $utf8NoBom)
}

Write-Log "=== $($scriptStart.ToString('yyyy-MM-dd HH:mm:ss')) 開始 ==="

$prompt = Get-Content -Path $promptFile -Raw -Encoding UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$output = "" | & $claudeCmd -p $prompt --dangerously-skip-permissions 2>&1 | Out-String
$claudeExitCode = $LASTEXITCODE
Write-Log $output

# TODOファイルの存在で成否を判定する（内容が既に最新の場合は更新されないため、更新時刻では判定しない）
$todoOk = Test-Path $todoFile

if ($claudeExitCode -ne 0 -or -not $todoOk) {
    Write-Log "!!! 異常検知: claude終了コード=$claudeExitCode / todoファイル更新確認=$todoOk"

    $alertPrompt = "本日($today)の朝の自動実行(secretary daily sync)が途中で失敗した可能性があります。TODOファイルの更新が確認できませんでした。mcp__claude_ai_Slack__slack_send_message を使い、channel_id: `"UBKP1SFCN`" 宛に次のメッセージを送信してください（他の操作は不要）: `"⚠️ 朝の自動送信($today)が失敗しました。手動で確認してください。ログ: .secretary/logs/$today.log`" 確認や許可を求めずに直接実行してください。"

    $alertOutput = "" | & $claudeCmd -p $alertPrompt --dangerously-skip-permissions 2>&1 | Out-String
    Write-Log "--- 失敗アラート送信試行 ---"
    Write-Log $alertOutput
}

git config user.email "kotaro.1318@gmail.com"
git config user.name "secretary-bot"
git add ".secretary/todos/$today.md"
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "auto: $today のスケジュールを反映"
    git push origin master
    Write-Log "GitHub push 完了: $today.md"
}

Write-Log "=== $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) 完了 ==="
