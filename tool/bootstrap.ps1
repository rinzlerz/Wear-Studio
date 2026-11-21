<#
.SYNOPSIS
  Generates the Flutter/Gradle boilerplate for Wear Studio and verifies the build.

.DESCRIPTION
  The repository contains only hand-written source. This script asks your
  installed Flutter SDK to generate the platform boilerplate (Gradle wrapper,
  settings, launcher icons, styles), so the versions always match your SDK.
  Then it applies the Wear Studio specific settings:

    * both apps use applicationId/namespace com.wearstudio.app
      (the Wear OS Data Layer only connects apps with the same id and key)
    * minSdk: watch 30 (Wear OS 3+), phone 26, plugin 23
    * the platform plugin depends on play-services-wearable

  Hand-written files are backed up before `flutter create` and restored
  afterwards, so nothing authored is overwritten. Safe to run repeatedly.

.PARAMETER SkipChecks
  Skip `flutter analyze`, the tests and the debug APK builds.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tool\bootstrap.ps1
#>
param([switch]$SkipChecks)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$applicationId = 'com.wearstudio.app'
$wearableDependency = 'com.google.android.gms:play-services-wearable:19.0.0'

function Step($message) { Write-Host "`n==> $message" -ForegroundColor Cyan }

function Invoke-Checked {
  param([string]$Exe, [string[]]$Arguments, [string]$WorkDir = $root)
  Push-Location $WorkDir
  try {
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "'$Exe $($Arguments -join ' ')' failed with exit code $LASTEXITCODE" }
  } finally { Pop-Location }
}

function Invoke-FlutterCreate {
  param([string]$Dir, [string[]]$CreateArgs, [string]$Marker)
  $full = Join-Path $root $Dir
  if (Get-ChildItem (Join-Path $full $Marker) -ErrorAction SilentlyContinue) {
    Write-Host "   already generated, skipping flutter create"
    return
  }
  $backup = Join-Path ([IO.Path]::GetTempPath()) ("wear-studio-" + [Guid]::NewGuid())
  Copy-Item $full $backup -Recurse
  try {
    Invoke-Checked flutter (@('create', '--no-pub', '--platforms=android', '--org', 'com.wearstudio') + $CreateArgs + @('.')) $full
  } finally {
    # Restore every authored file on top of whatever was generated.
    Copy-Item (Join-Path $backup '*') $full -Recurse -Force
    Remove-Item $backup -Recurse -Force
  }
}

function Update-File {
  param([string]$Path, [scriptblock]$Transform)
  $text = Get-Content $Path -Raw
  $updated = & $Transform $text
  if ($updated -ne $text) {
    # UTF-8 without BOM (Windows PowerShell 5 adds a BOM with Set-Content).
    [IO.File]::WriteAllText($Path, $updated)
    Write-Host "   patched $Path"
  }
}

function Remove-WithRetry([string]$Path) {
  # Editors (VS Code's Dart extension) briefly lock newly created folders.
  for ($i = 1; $i -le 10; $i++) {
    try { Remove-Item $Path -Recurse -Force -ErrorAction Stop; Write-Host "   removed $Path"; return }
    catch { Start-Sleep -Seconds 2 }
  }
  # Leftover template files are harmless (the analyzer ignores them), so warn
  # instead of stopping. Delete the folder by hand once VS Code lets go of it.
  Write-Warning "Could not delete '$Path' (another program is using it). Skipping; you can delete it by hand later."
}

function Get-GradleFile([string]$dir) {
  foreach ($name in 'build.gradle.kts', 'build.gradle') {
    $candidate = Join-Path $dir $name
    if (Test-Path $candidate) { return $candidate }
  }
  throw "No Gradle build file in $dir"
}

Step 'Checking Flutter'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'flutter is not on PATH. Install Flutter (stable) first: https://docs.flutter.dev/get-started/install/windows'
}
Invoke-Checked flutter @('--version')

# ------------------------------------------------------------------ plugin
Step 'Generating platform plugin boilerplate (packages/platform)'
Invoke-FlutterCreate 'packages/platform' @('--template=plugin', '--project-name', 'wear_studio_platform') 'android/build.gradle*'
$plugin = Join-Path $root 'packages/platform'
# Remove template sample code that we replace with our own implementation.
foreach ($generated in @(
    'example',
    'lib/wear_studio_platform_platform_interface.dart',
    'lib/wear_studio_platform_method_channel.dart',
    'test/wear_studio_platform_test.dart',
    'test/wear_studio_platform_method_channel_test.dart',
    'android/src/test')) {
  $p = Join-Path $plugin $generated
  if (Test-Path $p) { Remove-WithRetry $p }
}
Update-File (Get-GradleFile (Join-Path $plugin 'android')) {
  param($t)
  # Wearable library needs a higher minSdk than Flutter's plugin default.
  $t = $t -replace 'minSdk\s*=\s*\d+', 'minSdk = 23'
  $t = $t -replace 'minSdk\s+\d+', 'minSdk 23'
  $t = $t -replace 'minSdkVersion\s+\d+', 'minSdkVersion 23'
  # `api` (not `implementation`) so the apps compiling GeneratedPluginRegistrant
  # can also see the Wearable classes.
  $t = $t -replace 'implementation(\("com\.google\.android\.gms:play-services-wearable)', 'api$1'
  if ($t -match 'play-services-wearable') { return $t }
  # Parenthesised form is valid in both Groovy and Kotlin DSL.
  return $t.TrimEnd() + "`n`ndependencies {`n    api(`"$wearableDependency`")`n}`n"
}

# -------------------------------------------------------------------- apps
foreach ($app in @(
    @{ Dir = 'apps/companion'; Name = 'wear_studio_companion'; MinSdk = 26 },
    @{ Dir = 'apps/wear';      Name = 'wear_studio_wear';      MinSdk = 30 })) {
  Step "Generating Android boilerplate ($($app.Dir))"
  Invoke-FlutterCreate $app.Dir @('--project-name', $app.Name) 'android/settings.gradle*'
  $appDir = Join-Path $root $app.Dir

  # Template MainActivity lives in a package named after the project; ours is
  # in com/wearstudio/app.
  $templateKotlin = Join-Path $appDir "android/app/src/main/kotlin/com/wearstudio/$($app.Name)"
  if (Test-Path $templateKotlin) { Remove-WithRetry $templateKotlin }

  Update-File (Get-GradleFile (Join-Path $appDir 'android/app')) {
    param($t)
    $t = $t -replace '(applicationId\s*=?\s*)"[^"]*"', "`$1`"$applicationId`""
    $t = $t -replace '(namespace\s*=?\s*)"[^"]*"', "`$1`"$applicationId`""
    if ($app.MinSdk) {
      $t = $t -replace 'minSdk\s*=\s*[^\r\n]+', "minSdk = $($app.MinSdk)"
      $t = $t -replace 'minSdkVersion\s+[^\r\n]+', "minSdkVersion $($app.MinSdk)"
    }
    return $t
  }
}

Step 'Resolving dependencies (pub workspace)'
Invoke-Checked flutter @('pub', 'get')

Step 'Formatting'
Invoke-Checked dart @('format', 'apps', 'packages')

if ($SkipChecks) { Write-Host "`nDone (checks skipped)." -ForegroundColor Green; exit 0 }

Step 'Analyzing'
# Infos are style hints; only warnings and errors fail the build.
Invoke-Checked flutter @('analyze', '--no-fatal-infos', 'apps', 'packages')

Step 'Testing'
Invoke-Checked dart @('test') (Join-Path $root 'packages/core')
Invoke-Checked flutter @('test') (Join-Path $root 'packages/platform')
Invoke-Checked flutter @('test') (Join-Path $root 'apps/companion')
Invoke-Checked flutter @('test') (Join-Path $root 'apps/wear')

Step 'Building debug APKs'
Invoke-Checked flutter @('build', 'apk', '--debug') (Join-Path $root 'apps/companion')
Invoke-Checked flutter @('build', 'apk', '--debug') (Join-Path $root 'apps/wear')

Write-Host "`nAll checks passed. Next: docs/development/setup.md (run on emulators)." -ForegroundColor Green
