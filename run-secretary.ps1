$logDir = "C:\Users\hasec\Desktop\APP\secretary\.secretary\logs"
$workDir = "C:\Users\hasec\Desktop\APP\secretary"
$claudeCmd = "C:\Users\hasec\AppData\Roaming\npm\claude.cmd"
$promptFile = "$workDir\prompt.txt"

Set-Location $workDir

$today = (Get-Date).AddHours(0).ToString("yyyy-MM-dd")
$logFile = "$logDir\$today.log"

Add-Content -Path $logFile -Value "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 開始 ==="

$prompt = Get-Content -Path $promptFile -Raw -Encoding UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
"" | & $claudeCmd -p $prompt --dangerously-skip-permissions 2>&1 | Tee-Object -FilePath $logFile -Append

git config user.email "kotaro.1318@gmail.com"
git config user.name "secretary-bot"
git add ".secretary/todos/$today.md"
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "auto: $today のスケジュールを反映"
    git push origin master
    Add-Content -Path $logFile -Value "GitHub push 完了: $today.md"
}

Add-Content -Path $logFile -Value "=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完了 ==="
