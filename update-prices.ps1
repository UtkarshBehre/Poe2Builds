#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Session,

    [string]$Category = "",

    [int]$Interval = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$HtmlPath   = Join-Path $PSScriptRoot "prices.html"
$LeagueSlug = "Fate%20of%20the%20Vaal"
$SearchUrl  = "https://www.pathofexile.com/api/trade2/search/poe2/$LeagueSlug"
$FetchBase  = "https://www.pathofexile.com/api/trade2/fetch"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Get-Median([double[]]$values) {
    if ($values.Count -eq 0) { return $null }
    $sorted = $values | Sort-Object
    $mid    = [int]($sorted.Count / 2)
    if ($sorted.Count % 2 -eq 1) { return $sorted[$mid] }
    return [Math]::Round(($sorted[$mid - 1] + $sorted[$mid]) / 2.0, 4)
}

function Get-Mean([double[]]$values) {
    if ($values.Count -eq 0) { return $null }
    return [Math]::Round(($values | Measure-Object -Sum).Sum / $values.Count, 4)
}

function ConvertTo-ExaltedPrice([PSCustomObject]$priceObj, [int]$exPerDiv) {
    if ($null -eq $priceObj) { return $null }
    $amt      = [double]$priceObj.amount
    $currency = "$($priceObj.currency)".ToLower()
    switch -Wildcard ($currency) {
        "exalted" { return $amt }
        "exa"     { return $amt }
        "divine"  { return [Math]::Round($amt * $exPerDiv, 4) }
        "div"     { return [Math]::Round($amt * $exPerDiv, 4) }
        default   { return $null }   # chaos or other → skip
    }
}

# POST search, then GET fetch first 10 listings.
# Returns a hashtable: @{ prices=[double[]]; count=[int] }
# Sleeps $Interval seconds after each HTTP call.
# Retries up to 3 times on 429.
function Invoke-TradeSearch([hashtable]$body, [string]$sessionId, [int]$interval, [int]$exPerDiv) {
    $headers = @{
        "Content-Type" = "application/json"
        "Cookie"       = "POESESSID=$sessionId"
        "User-Agent"   = "Mozilla/5.0 (PoE2Builds price updater)"
    }

    # POST search
    $searchResult = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $bodyJson = $body | ConvertTo-Json -Depth 20 -Compress
            $resp = Invoke-WebRequest -Uri $SearchUrl -Method POST -Body $bodyJson `
                       -Headers $headers -UseBasicParsing
            $searchResult = $resp.Content | ConvertFrom-Json
            break
        } catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            if ($statusCode -eq 429) {
                $wait = 180 * $attempt
                Write-Host "  429 on search (attempt $attempt), waiting ${wait}s..." -ForegroundColor Yellow
                Start-Sleep -Seconds $wait
            } else {
                throw
            }
        }
    }
    Start-Sleep -Seconds $interval

    if ($null -eq $searchResult -or $null -eq $searchResult.id) {
        return @{ prices = @(); count = 0 }
    }

    $queryId  = $searchResult.id
    $total    = if ($searchResult.total) { [int]$searchResult.total } else { 0 }
    $ids      = $searchResult.result
    if ($null -eq $ids -or $ids.Count -eq 0) {
        return @{ prices = @(); count = $total }
    }

    # Take first 10 IDs
    $first10 = ($ids | Select-Object -First 10) -join ","
    $fetchUrl = "$FetchBase/$first10`?query=$queryId&realm=poe2"

    # GET fetch
    $fetchResult = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $resp2       = Invoke-WebRequest -Uri $fetchUrl -Method GET `
                              -Headers $headers -UseBasicParsing
            $fetchResult = $resp2.Content | ConvertFrom-Json
            break
        } catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            if ($statusCode -eq 429) {
                $wait = 180 * $attempt
                Write-Host "  429 on fetch (attempt $attempt), waiting ${wait}s..." -ForegroundColor Yellow
                Start-Sleep -Seconds $wait
            } else {
                throw
            }
        }
    }
    Start-Sleep -Seconds $interval

    if ($null -eq $fetchResult -or $null -eq $fetchResult.result) {
        return @{ prices = @(); count = $total }
    }

    $prices = [System.Collections.Generic.List[double]]::new()
    foreach ($item in $fetchResult.result) {
        try {
            $priceObj  = $item.listing.price
            $exPrice   = ConvertTo-ExaltedPrice $priceObj $exPerDiv
            if ($null -ne $exPrice -and $exPrice -gt 0) {
                $prices.Add($exPrice)
            }
        } catch { }
    }

    # Proactive rate-limit pause: every 5 searches wait 60s
    $script:tradeCallCount++
    if ($script:tradeCallCount % 5 -eq 0) {
        Write-Host "  [rate-limit pause] $($script:tradeCallCount) calls done, waiting 60s..." -ForegroundColor Cyan
        Start-Sleep -Seconds 60
    }

    return @{ prices = $prices.ToArray(); count = $total }
}

# Build the trade API query body for a normal bracket search
function New-SearchBody([string]$typeLine, [int]$ilvlMin, [nullable[int]]$ilvlMax,
                        [nullable[int]]$minRunes, [nullable[int]]$minQuality) {
    $filters = [ordered]@{}

    $ilvlFilter = [ordered]@{ min = $ilvlMin }
    if ($null -ne $ilvlMax) { $ilvlFilter.max = $ilvlMax }
    $filters.ilvl = @{ option = $null; value = $ilvlFilter }

    if ($null -ne $minRunes) {
        $filters.rune_sockets = @{ option = $null; value = @{ min = $minRunes } }
    }
    if ($null -ne $minQuality) {
        $filters.quality = @{ option = $null; value = @{ min = $minQuality } }
    }

    $body = [ordered]@{
        query = [ordered]@{
            status  = [ordered]@{ option = "any" }
            filters = [ordered]@{
                type_filters = [ordered]@{
                    filters = [ordered]@{
                        rarity = [ordered]@{ option = "normal" }
                    }
                }
                equipment_filters = [ordered]@{
                    filters = $filters
                }
                misc_filters = [ordered]@{
                    filters = [ordered]@{
                        corrupted = [ordered]@{ option = "false" }
                    }
                }
            }
            type = $typeLine
        }
        sort = [ordered]@{ price = "asc" }
    }
    return $body
}

# ---------------------------------------------------------------------------
# Load HTML and parse JSON data
# ---------------------------------------------------------------------------

Write-Host "Loading $HtmlPath ..." -ForegroundColor Cyan
$html      = [System.IO.File]::ReadAllText($HtmlPath, [System.Text.Encoding]::UTF8)
$tagStart  = $html.IndexOf('prices-data')
$jsonStart = $html.IndexOf('{', $tagStart)
$jsonEnd   = $html.IndexOf('</script>', $jsonStart)
if ($jsonStart -lt 0 -or $jsonEnd -lt 0) {
    Write-Error "Could not locate JSON data block in $HtmlPath"
    exit 1
}

$jsonText = $html.Substring($jsonStart, $jsonEnd - $jsonStart)
$data     = $jsonText | ConvertFrom-Json

$exPerDiv   = [int]$data.exaltedPerDivine
$catConfig  = $data.categoryConfig
$categories = $data.categories

Write-Host "League: $($data.league) | exPerDiv: $exPerDiv" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Determine which categories to process
# ---------------------------------------------------------------------------

$allCatNames = $categories.PSObject.Properties.Name
if ($Category -ne "") {
    if ($allCatNames -notcontains $Category) {
        Write-Error "Category '$Category' not found. Available: $($allCatNames -join ', ')"
        exit 1
    }
    $catsToProcess = @($Category)
} else {
    $catsToProcess = $allCatNames
}

# Count total bases for progress display
$totalBases = 0
foreach ($catName in $catsToProcess) {
    $totalBases += $categories.$catName.Count
}
Write-Host "Processing $($catsToProcess.Count) categories, $totalBases bases total." -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# Brackets definition (shared across all bases)
# ---------------------------------------------------------------------------
$brackets = @(
    @{ label = "75-80"; ilvlMin = 75; ilvlMax = 80 }
    @{ label = "81";    ilvlMin = 81; ilvlMax = 81 }
    @{ label = "82+";   ilvlMin = 82; ilvlMax = $null }
)

$qualityLevels = @(23, 25, 28)

# ---------------------------------------------------------------------------
# Main processing loop
# ---------------------------------------------------------------------------

$baseIdx = 0
$script:tradeCallCount = 0

foreach ($catName in $catsToProcess) {
    $cfg   = $catConfig.$catName
    $bases = $categories.$catName

    $hasSockets = $cfg.sockets -eq $true
    $hasQuality = $cfg.quality -eq $true
    $maxSockets = if ($hasSockets) { [int]$cfg.maxSockets } else { 0 }

    Write-Host "=== $catName ===" -ForegroundColor Magenta

    foreach ($base in $bases) {
        $baseIdx++
        $baseName = $base.name
        Write-Host "[$baseIdx/$totalBases] $baseName" -ForegroundColor Yellow

        # ---- Normal brackets ----
        for ($bi = 0; $bi -lt $base.brackets.Count; $bi++) {
            $br      = $base.brackets[$bi]
            $ilvlMin = [int]$br.ilvlMin
            $ilvlMax = if ($null -eq $br.ilvlMax -or $br.ilvlMax -eq '') { $null } else { [int]$br.ilvlMax }

            # Normal search
            $body   = New-SearchBody $baseName $ilvlMin $ilvlMax $null $null
            $result = Invoke-TradeSearch $body $Session $Interval $exPerDiv

            $prices = [double[]]$result.prices
            $cnt    = [int]$result.count

            $base.brackets[$bi].count      = $cnt
            $base.brackets[$bi].min        = if ($prices.Count -gt 0) { ($prices | Measure-Object -Minimum).Minimum } else { $null }
            $base.brackets[$bi].median10   = Get-Median $prices
            $base.brackets[$bi].mean10     = Get-Mean   $prices
            # median100/mean100: we only have 10 items, use same values for now
            $base.brackets[$bi].median100  = $base.brackets[$bi].median10
            $base.brackets[$bi].mean100    = $base.brackets[$bi].mean10

            $status = if ($prices.Count -gt 0) { 'OK' } elseif ($cnt -gt 0) { 'NO PRICED LISTINGS' } else { 'NO DATA' }
            $statusColor = if ($prices.Count -gt 0) { 'Green' } elseif ($cnt -gt 0) { 'DarkYellow' } else { 'DarkGray' }
            Write-Host "  [$($br.label)] $status  count=$cnt min=$($base.brackets[$bi].min) med=$($base.brackets[$bi].median10)" -ForegroundColor $statusColor

            # Socket search (extra rune)
            if ($hasSockets) {
                $bodyEx   = New-SearchBody $baseName $ilvlMin $ilvlMax ($maxSockets + 1) $null
                $resultEx = Invoke-TradeSearch $bodyEx $Session $Interval $exPerDiv

                $exPrices = [double[]]$resultEx.prices
                $exCnt    = [int]$resultEx.count

                $base.brackets[$bi].exCount = $exCnt
                $base.brackets[$bi].exMin   = if ($exPrices.Count -gt 0) { ($exPrices | Measure-Object -Minimum).Minimum } else { $null }

                $exStatus = if ($exPrices.Count -gt 0) { 'OK' } elseif ($exCnt -gt 0) { 'NO PRICED LISTINGS' } else { 'NO DATA' }
                $exStatusColor = if ($exPrices.Count -gt 0) { 'Green' } elseif ($exCnt -gt 0) { 'DarkYellow' } else { 'DarkGray' }
                Write-Host "  [$($br.label)] (sockets) $exStatus  exCount=$exCnt exMin=$($base.brackets[$bi].exMin)" -ForegroundColor $exStatusColor
            }
        }

        # ---- Quality brackets ----
        if ($hasQuality) {
            foreach ($q in $qualityLevels) {
                $qKey = "q${q}Brackets"
                if ($null -eq $base.$qKey) { continue }

                for ($bi = 0; $bi -lt $base.$qKey.Count; $bi++) {
                    $qbr     = $base.$qKey[$bi]
                    $ilvlMin = [int]$qbr.ilvlMin
                    $ilvlMax = if ($null -eq $qbr.ilvlMax -or $qbr.ilvlMax -eq '') { $null } else { [int]$qbr.ilvlMax }

                    $bodyQ   = New-SearchBody $baseName $ilvlMin $ilvlMax $null $q
                    $resultQ = Invoke-TradeSearch $bodyQ $Session $Interval $exPerDiv

                    $qPrices = [double[]]$resultQ.prices
                    $qCnt    = [int]$resultQ.count

                    $base.$qKey[$bi].count     = $qCnt
                    $base.$qKey[$bi].min       = if ($qPrices.Count -gt 0) { ($qPrices | Measure-Object -Minimum).Minimum } else { $null }
                    $base.$qKey[$bi].median10  = Get-Median $qPrices
                    $base.$qKey[$bi].mean10    = Get-Mean   $qPrices
                    $base.$qKey[$bi].median100 = $base.$qKey[$bi].median10
                    $base.$qKey[$bi].mean100   = $base.$qKey[$bi].mean10
                    $qStatus = if ($qPrices.Count -gt 0) { 'OK' } elseif ($qCnt -gt 0) { 'NO PRICED LISTINGS' } else { 'NO DATA' }
                    $qStatusColor = if ($qPrices.Count -gt 0) { 'Green' } elseif ($qCnt -gt 0) { 'DarkYellow' } else { 'DarkGray' }
                    Write-Host "  [$($qbr.label)] (${q}+q) $qStatus  count=$qCnt min=$($base.$qKey[$bi].min)" -ForegroundColor $qStatusColor
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Save updated JSON back into HTML
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "Saving prices to $HtmlPath ..." -ForegroundColor Cyan

$data.lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
$newJson          = $data | ConvertTo-Json -Depth 20 -Compress

$newHtml = $html.Substring(0, $jsonStart) + $newJson + $html.Substring($jsonEnd)
[System.IO.File]::WriteAllText($HtmlPath, $newHtml, [System.Text.Encoding]::UTF8)

Write-Host "Done! lastUpdated set to $($data.lastUpdated)" -ForegroundColor Green
