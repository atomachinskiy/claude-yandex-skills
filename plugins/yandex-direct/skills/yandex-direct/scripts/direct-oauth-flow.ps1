# direct-oauth-flow.ps1 - Native PowerShell OAuth wizard for Yandex Direct (Windows).
# ASCII-only on purpose: avoids any Cyrillic encoding pitfalls in PowerShell 5.x parser.
# Yandex Direct requires its OWN OAuth-app (separate from the shared "Ya-Claud-Klients"),
# because the API access application is bound to a specific client_id.
#
# Captures access_token via implicit flow and writes it to
# %USERPROFILE%\.claude\secrets\yandex-direct-app.json
#
# Usage (in PowerShell):
#   powershell.exe -ExecutionPolicy Bypass -File direct-oauth-flow.ps1
#   powershell.exe -ExecutionPolicy Bypass -File direct-oauth-flow.ps1 -Browser yandex
#   powershell.exe -ExecutionPolicy Bypass -File direct-oauth-flow.ps1 -Status
#
# Browsers: yandex, chrome, firefox, edge, default, none

[CmdletBinding()]
param(
    [ValidateSet('yandex','chrome','firefox','edge','default','none','')]
    [string]$Browser = '',
    [switch]$Status
)

$ErrorActionPreference = 'Stop'

# Make sure console can render Cyrillic OUTPUT from Yandex API responses
# without affecting how this script file itself is parsed.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# Dedicated Direct OAuth-app: "Claud direct"
$ClientId    = if ($env:YANDEX_DIRECT_CLIENT_ID) { $env:YANDEX_DIRECT_CLIENT_ID } else { '040b84bb83e74fa6abe6619c7ea0f688' }
$AppName     = 'Claud direct'
$SecretsDir  = Join-Path $env:USERPROFILE '.claude\secrets'
$TokenFile   = Join-Path $SecretsDir 'yandex-direct-app.json'

# IMPORTANT: keep the URL inside double quotes so PowerShell does not parse `&`.
$AuthorizeUrl = "https://oauth.yandex.ru/authorize?response_type=token&force_confirm=yes&client_id=$ClientId"

function Show-Status {
    if (-not (Test-Path $TokenFile)) {
        Write-Host "No Direct token file at $TokenFile" -ForegroundColor Yellow
        Write-Host "Run: powershell -ExecutionPolicy Bypass -File direct-oauth-flow.ps1"
        exit 1
    }
    $tok = (Get-Content $TokenFile -Raw | ConvertFrom-Json).access_token
    if (-not $tok) {
        Write-Host "Token file is malformed: $TokenFile" -ForegroundColor Red
        exit 1
    }
    Write-Host "Direct token: $($tok.Substring(0,18))..."
    Write-Host "-> Live-check Direct API:"
    try {
        $body = '{"method":"get","params":{"FieldNames":["ClientId","Login"]}}'
        $resp = Invoke-RestMethod -Uri 'https://api.direct.yandex.com/json/v5/clients' `
                                  -Method Post `
                                  -Headers @{
                                      Authorization     = "Bearer $tok"
                                      'Accept-Language' = 'ru'
                                  } `
                                  -ContentType 'application/json; charset=utf-8' `
                                  -Body $body `
                                  -TimeoutSec 20
        $resp | ConvertTo-Json -Depth 6 | Write-Host
        exit 0
    } catch {
        Write-Host "Direct API call failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

if ($Status) { Show-Status }

# --- Ensure secrets dir exists -------------------------------------------------
if (-not (Test-Path $SecretsDir)) {
    New-Item -ItemType Directory -Path $SecretsDir -Force | Out-Null
}

Write-Host ''
Write-Host '==============================================================='
Write-Host "  Yandex Direct OAuth - issue a token for the '$AppName' app"
Write-Host '==============================================================='
Write-Host ''
Write-Host 'What will happen:'
Write-Host '  1. Browser opens the Yandex authorize page.'
Write-Host "  2. You log in with the Yandex account that owns the Direct cabinet."
Write-Host '  3. You click "Allow" / "Razreshit".'
Write-Host '  4. Yandex redirects to a page whose URL contains'
Write-Host '     #access_token=...&token_type=bearer&...'
Write-Host '  5. Copy the WHOLE redirected URL (or just the token part)'
Write-Host '     and paste it here, then press Enter.'
Write-Host ''
Write-Host 'Authorize URL:'
Write-Host "  $AuthorizeUrl"
Write-Host ''

# --- Browser open --------------------------------------------------------------
function Open-InBrowser {
    param([string]$Choice, [string]$Url)
    switch ($Choice) {
        'none'    { return $false }
        'default' { Start-Process $Url; return $true }
        'yandex'  {
            $candidates = @(
                (Join-Path $env:LOCALAPPDATA 'Yandex\YandexBrowser\Application\browser.exe'),
                (Join-Path ${env:ProgramFiles} 'Yandex\YandexBrowser\Application\browser.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'Yandex\YandexBrowser\Application\browser.exe')
            )
            foreach ($exe in $candidates) {
                if ($exe -and (Test-Path $exe)) {
                    Start-Process -FilePath $exe -ArgumentList $Url
                    return $true
                }
            }
            return $false
        }
        'chrome'  {
            try { Start-Process -FilePath 'chrome.exe' -ArgumentList $Url; return $true }
            catch {
                $cands = @(
                    (Join-Path ${env:ProgramFiles} 'Google\Chrome\Application\chrome.exe'),
                    (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe')
                )
                foreach ($exe in $cands) {
                    if ($exe -and (Test-Path $exe)) { Start-Process -FilePath $exe -ArgumentList $Url; return $true }
                }
                return $false
            }
        }
        'firefox' {
            try { Start-Process -FilePath 'firefox.exe' -ArgumentList $Url; return $true }
            catch {
                $cands = @(
                    (Join-Path ${env:ProgramFiles} 'Mozilla Firefox\firefox.exe'),
                    (Join-Path ${env:ProgramFiles(x86)} 'Mozilla Firefox\firefox.exe')
                )
                foreach ($exe in $cands) {
                    if ($exe -and (Test-Path $exe)) { Start-Process -FilePath $exe -ArgumentList $Url; return $true }
                }
                return $false
            }
        }
        'edge'    {
            try { Start-Process -FilePath 'msedge.exe' -ArgumentList $Url; return $true }
            catch { return $false }
        }
    }
    return $false
}

# --- Browser selection ---------------------------------------------------------
if (-not $Browser) {
    Write-Host 'Which browser to open?'
    Write-Host '  [1] Yandex Browser  (recommended - usually already logged in)'
    Write-Host '  [2] Google Chrome'
    Write-Host '  [3] Firefox'
    Write-Host '  [4] Microsoft Edge'
    Write-Host '  [5] System default'
    Write-Host '  [6] Do not open - I will copy the URL myself'
    Write-Host ''
    $sel = Read-Host 'Choice [1-6, Enter = 1]'
    switch ($sel) {
        '2' { $Browser = 'chrome' }
        '3' { $Browser = 'firefox' }
        '4' { $Browser = 'edge' }
        '5' { $Browser = 'default' }
        '6' { $Browser = 'none' }
        default { $Browser = 'yandex' }
    }
}

if ($Browser -eq 'none') {
    Write-Host ''
    Write-Host '-> Not opening a browser. Copy the authorize URL above and open it manually.'
} else {
    if (Open-InBrowser -Choice $Browser -Url $AuthorizeUrl) {
        Write-Host ''
        Write-Host "-> Opened authorize URL in '$Browser'."
    } else {
        Write-Host ''
        Write-Host "-> Could not open '$Browser' (not found or unsupported). Open the URL above manually."
    }
}

# --- Read pasted token / URL ---------------------------------------------------
Write-Host ''
Write-Host 'After you click "Allow", the address bar will contain'
Write-Host '#access_token=XXXX&token_type=bearer&...'
Write-Host 'Paste either the WHOLE redirected URL or just the token value:'
$Pasted = Read-Host 'access_token (or full URL)'

$Pasted = ($Pasted -replace '\s', '')
if (-not $Pasted) {
    Write-Host 'ERROR: empty input. Aborting.' -ForegroundColor Red
    exit 1
}

# Extract access_token from URL fragment if a full URL was pasted
$Token = $Pasted
if ($Pasted -match 'access_token=([^&\s#]+)') {
    $Token = $Matches[1]
}

if ($Token.Length -lt 30) {
    Write-Host "ERROR: token looks too short (length $($Token.Length)). Aborting." -ForegroundColor Red
    exit 1
}

# --- Validate token via login.yandex.ru ---------------------------------------
Write-Host ''
Write-Host 'Validating token via login.yandex.ru/info ...'
try {
    $info = Invoke-RestMethod -Uri 'https://login.yandex.ru/info?format=json' `
                              -Headers @{ Authorization = "OAuth $Token" } `
                              -TimeoutSec 15
} catch {
    Write-Host "ERROR: token rejected by Yandex: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (-not $info.login) {
    Write-Host 'ERROR: Yandex /info returned no login. Aborting.' -ForegroundColor Red
    exit 1
}

# --- Persist token -------------------------------------------------------------
$IssuedAt  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$ExpiresAt = (Get-Date).ToUniversalTime().AddDays(365).ToString("yyyy-MM-ddTHH:mm:ssZ")

$payload = [ordered]@{
    access_token        = $Token
    client_id           = $ClientId
    app_name            = $AppName
    issued_at           = $IssuedAt
    expires_at_estimate = $ExpiresAt
    yandex_login        = $info.login
    yandex_user_id      = "$($info.id)"
    note                = "Direct OAuth-app token (separate from shared yandex-app.json). Issued via implicit-flow on Windows. If a request returns 401, re-run direct-oauth-flow.ps1."
}

# Write file as UTF-8 WITHOUT BOM so other tools that read JSON don't choke.
$json = ($payload | ConvertTo-Json -Depth 4)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($TokenFile, $json, $utf8NoBom)

# Restrict ACL: only current user (and SYSTEM) can read/write the token file.
try {
    $acl = New-Object System.Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)  # disable inheritance, drop inherited rules
    $me = "$env:USERDOMAIN\$env:USERNAME"
    $rule1 = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $me, 'FullControl', 'Allow')
    $rule2 = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'NT AUTHORITY\SYSTEM', 'FullControl', 'Allow')
    $acl.AddAccessRule($rule1)
    $acl.AddAccessRule($rule2)
    Set-Acl -Path $TokenFile -AclObject $acl
} catch {
    Write-Host "WARN: could not lock down ACL on $TokenFile : $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host "  App:      $AppName  (client_id=$ClientId)"
Write-Host "  Account:  $($info.login)  (id=$($info.id))"
Write-Host "  Token:    $TokenFile"
Write-Host '  ACL:      restricted to your user + SYSTEM'
Write-Host ''
Write-Host 'The yandex-direct skill will now use this token automatically.'
Write-Host 'Recheck later:  powershell -ExecutionPolicy Bypass -File direct-oauth-flow.ps1 -Status'
