$RunLogFile = Join-Path $env:TEMP "SimpleWindowsTool-log.txt"
$script:RunLogStart = Get-Date
$script:RunLogLabel = ""
$script:RunLogStats = @{ OK = 0; FAILED = 0; SKIPPED = 0 }

function Limit-RunLog {
    param([int]$KeepRuns = 20)
    if (-not (Test-Path -LiteralPath $RunLogFile)) { return }
    try {
        $lines = @(Get-Content -LiteralPath $RunLogFile -Encoding UTF8 -ErrorAction Stop)
        $starts = @(for ($n = 2; $n -lt $lines.Count; $n++) {
            if ($lines[$n] -like " Simple Windows 11 Tool   |*" -and $lines[$n - 1] -like "=====*") { $n - 2 }
        })
        if ($starts.Count -ge $KeepRuns) {
            $from = $starts[$starts.Count - ($KeepRuns - 1)]
            Set-Content -LiteralPath $RunLogFile -Value $lines[$from..($lines.Count - 1)] -Encoding UTF8
        } elseif ($starts.Count -eq 0 -and (Get-Item -LiteralPath $RunLogFile).Length -gt 1MB) {
            Remove-Item -LiteralPath $RunLogFile -Force
        }
    } catch { }
}

function Write-RunLog {
    param([Parameter(ValueFromPipeline = $true)][string]$Message)
    process {
        $time = (Get-Date).ToString("HH:mm:ss")
        $rule = "=" * 96
        $lines = New-Object System.Collections.Generic.List[string]
        if ($Message -like "=== Run started*") {
            Limit-RunLog
            $script:RunLogStart = Get-Date
            $script:RunLogStats = @{ OK = 0; FAILED = 0; SKIPPED = 0; Failures = New-Object System.Collections.Generic.List[string] }
            $lines.Add("")
            $lines.Add($rule)
            $lines.Add(" Simple Windows 11 Tool   |   " + $script:RunLogStart.ToString("dddd d MMMM yyyy, HH:mm:ss"))
            if ($script:RunLogLabel) { $lines.Add(" Page: $($script:RunLogLabel)") }
            $lines.Add($rule)
            $lines.Add((" {0,-8}  {1,-8} {2,-9} {3,-44} {4}" -f "TIME", "STATUS", "ACTION", "ITEM", "DETAILS"))
        } elseif ($Message -like "=== Run completed*" -or $Message -like "=== Run cancelled*") {
            $took = [int]((Get-Date) - $script:RunLogStart).TotalSeconds
            $st = $script:RunLogStats
            $ending = if ($Message -like "*cancelled*") { " Cancelled: " + (($Message -replace '^=== Run cancelled:\s*', '') -replace '\s*===$', '') } else { " Finished" }
            $lines.Add("-" * 96)
            $lines.Add("$ending   |   $($st.OK) OK, $($st.FAILED) failed, $($st.SKIPPED) skipped   |   took ${took}s")
            if ($st.Failures.Count -gt 0) {
                $lines.Add("")
                $lines.Add(" Needs attention:")
                foreach ($f in $st.Failures) { $lines.Add("   - $f") }
            }
            $lines.Add($rule)
        } elseif ($Message -match '^(Starting|Finished|Failed|Skipped|Cancelled) (\w+): (.*)$') {
            if ($Matches[1] -eq "Starting") { return }
            $status = @{ Finished = "OK"; Failed = "FAILED"; Skipped = "SKIPPED"; Cancelled = "STOPPED" }[$Matches[1]]
            $action = (Get-Culture).TextInfo.ToTitleCase($Matches[2])
            $name = $Matches[3]
            $detail = ""
            if ($name -match '^(.*?)\s*\[([^\]]+)\]\s*(.*)$') {
                $name = $Matches[1]
                $detail = ($Matches[2] + " " + $Matches[3]).Trim()
            } elseif ($status -ne "OK" -and $name -match '^(.*?) - (.*)$') {
                $name = $Matches[1]
                $detail = $Matches[2]
            }
            if ($status -eq "OK") { $script:RunLogStats.OK++ }
            elseif ($status -eq "FAILED") {
                $script:RunLogStats.FAILED++
                $script:RunLogStats.Failures.Add("$name ($action) - $(($detail -replace '^[\d.]+s\s*-?\s*', ''))")
            }
            else { $script:RunLogStats.SKIPPED++ }
            $lines.Add((" {0,-8}  {1,-8} {2,-9} {3,-44} {4}" -f $time, $status, $action, $name, $detail))
        } elseif ($Message -match '^Already installed: (.*)$') {
            $script:RunLogStats.OK++
            $lines.Add((" {0,-8}  {1,-8} {2,-9} {3,-44} {4}" -f $time, "OK", "Install", $Matches[1], "already installed"))
        } elseif ($Message -match '^\s') {
            $lines.Add((" " * 30) + $Message.Trim())
        } else {
            $lines.Add((" {0,-8}  {1,-8} {2}" -f $time, "NOTE", $Message))
        }
        try { Add-Content -Path $RunLogFile -Value $lines -Encoding UTF8 } catch { }
    }
}
