# scripts/verify.ps1 — the mechanical "done" check. Mirrors ci.yml exactly.
# Agents MUST run this and see it pass before declaring a task complete.
# Usage: .\scripts\verify.ps1
#
# Exit on first failure so you fix problems in order.
$ErrorActionPreference = "Stop"

Write-Host "`n▸ check inline GoogleFonts" -ForegroundColor Cyan
$gfontMatches = Get-ChildItem -Path lib -Recurse -Filter *.dart | 
    Where-Object { 
        $_.FullName -notmatch "app_text\.dart" -and 
        $_.FullName -notmatch "app_theme\.dart" -and 
        $_.FullName -notmatch "splash_screen\.dart" -and 
        $_.FullName -notmatch "weekly_bar_chart\.dart" -and 
        $_.FullName -notmatch "routine_detail_styles\.dart" -and 
        $_.FullName -notmatch "app_error_screen\.dart" -and 
        $_.FullName -notmatch "bottom_nav_bar\.dart" -and 
        $_.FullName -notmatch "branded_line_chart\.dart"
    } | 
    Select-String -Pattern "GoogleFonts\.inter\("

if ($gfontMatches) {
    Write-Host "✗ Prohibited inline GoogleFonts.inter( usages found at:" -ForegroundColor Red
    $gfontMatches | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Red }
    exit 1
}

Write-Host "▸ format" -ForegroundColor Cyan
dart format --output=none --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) { Write-Host "✗ format failed" -ForegroundColor Red; exit 1 }

Write-Host "`n▸ analyze" -ForegroundColor Cyan
flutter analyze --fatal-infos --fatal-warnings
if ($LASTEXITCODE -ne 0) { Write-Host "✗ analyze failed" -ForegroundColor Red; exit 1 }

Write-Host "`n▸ custom_lint" -ForegroundColor Cyan
dart run custom_lint
if ($LASTEXITCODE -ne 0) { Write-Host "✗ custom_lint failed" -ForegroundColor Red; exit 1 }

Write-Host "`n▸ test" -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { Write-Host "✗ tests failed" -ForegroundColor Red; exit 1 }

Write-Host "`n✅ verify passed - desired state is mechanically confirmed." -ForegroundColor Green
