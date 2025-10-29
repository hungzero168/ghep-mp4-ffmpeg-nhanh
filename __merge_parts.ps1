param([int]$BATCH = 6)

# Ensure working directory is script directory
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $root

$partsDir = Join-Path $root '__parts'
if(-not (Test-Path $partsDir)) { New-Item -ItemType Directory -Path $partsDir | Out-Null }

Write-Output "Scanning for mp4 files..."
# sort by file name to preserve order; avoid regex conversion issues
$files = Get-ChildItem -File -Filter '*.mp4' | Sort-Object Name
if($files.Count -eq 0){ Write-Output 'No mp4 files found.'; exit 0 }

Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $partsDir 'part_*.mp4'), (Join-Path $partsDir 'list_part_*.txt') 2>$null

$batchNum = 1
$lines = @()
$countInBatch = 0

# detect NVENC availability once (ffmpeg encoder list)
function Test-Nvenc {
    try{
        $enc = & ffmpeg -hide_banner -encoders 2>&1
        return ($enc -match 'h264_nvenc') -or ($enc -match 'hevc_nvenc')
    } catch { return $false }
}
$useNvenc = Test-Nvenc

foreach ($f in $files) {
    $lines += "file '$($f.FullName)'"
    $countInBatch += 1
    if ($countInBatch -ge $BATCH) {
        $list = Join-Path $partsDir ("list_part_$batchNum.txt")
        $out = Join-Path $partsDir ("part_$batchNum.mp4")
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllLines($list, $lines, $utf8NoBom)
        Write-Output "Processing batch $batchNum (files: $countInBatch)"
        $cmd = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$list`" -c copy `"$out`""
        Write-Output $cmd
        cmd /c $cmd
        if($LASTEXITCODE -ne 0){
            Write-Output "concat-copy failed for batch $batchNum, trying re-encode fallback"
            if($useNvenc){
                $cmd2 = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$list`" -c:v h264_nvenc -preset fast -cq 19 -c:a aac `"$out`""
            } else {
                $cmd2 = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$list`" -c:v libx264 -preset fast -crf 20 -c:a aac `"$out`""
            }
            Write-Output $cmd2
            cmd /c $cmd2
        }
        # reset for next batch
        $batchNum += 1
        $lines = @()
        $countInBatch = 0
    }
}

# handle leftover
if ($countInBatch -gt 0) {
    $list = Join-Path $partsDir ("list_part_$batchNum.txt")
    $out = Join-Path $partsDir ("part_$batchNum.mp4")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($list, $lines, $utf8NoBom)
    Write-Output "Processing batch $batchNum (files: $countInBatch)"
    $cmd = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$list`" -c copy `"$out`""
    Write-Output $cmd
    cmd /c $cmd
    if($LASTEXITCODE -ne 0){
        Write-Output "concat-copy failed for batch $batchNum, trying re-encode fallback"
        if($useNvenc){
            $cmd2 = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$list`" -c:v h264_nvenc -preset fast -cq 19 -c:a aac `"$out`""
        } else {
            $cmd2 = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$list`" -c:v libx264 -preset fast -crf 20 -c:a aac `"$out`""
        }
        Write-Output $cmd2
        cmd /c $cmd2
    }
}

$master = Join-Path $partsDir 'mylist_parts.txt'
$lines = Get-ChildItem -Path $partsDir -Filter 'part_*.mp4' | Sort-Object Name | ForEach-Object { "file '$($_.FullName)'" }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($master, $lines, $utf8NoBom)
Write-Output 'Running final concat of parts...'
$final = Join-Path $root 'output.mp4'
$finalcmd = "ffmpeg -hide_banner -y -f concat -safe 0 -i `"$master`" -c copy `"$final`""
Write-Output $finalcmd
cmd /c $finalcmd

Write-Output 'Done.'
