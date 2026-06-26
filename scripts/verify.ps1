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

Write-Host "`n▸ check non-semantic AppColors in migrated screens" -ForegroundColor Cyan
$migratedFiles = @(
    "lib/features/home/presentation/screens/home_screen.dart",
    "lib/features/workout/presentation/screens/workout_detail_screen.dart",
    "lib/features/routines/presentation/screens/routine_detail_screen.dart",
    "lib/features/exercises/presentation/screens/exercise_detail_screen.dart",
    "lib/features/profile/presentation/screens/delete_account_screen.dart",
    "lib/features/import/presentation/screens/import_screen.dart",
    "lib/features/workout/presentation/screens/active_workout_screen.dart",
    "lib/features/routines/presentation/screens/explore_routines_screen.dart"
)

$appColorMatches = @()
foreach ($file in $migratedFiles) {
    $fullPath = Join-Path (Get-Location) $file
    if (Test-Path $fullPath) {
        $matches = Select-String -Path $fullPath -Pattern "AppColors\.(?!(?:error|success|warning|rewardGold|cardGradient|cardGradientLight)\b)\w+"
        if ($matches) {
            $appColorMatches += $matches
        }
    }
}

if ($appColorMatches) {
    Write-Host "✗ Prohibited non-semantic AppColors usages found at:" -ForegroundColor Red
    $appColorMatches | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Red }
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
