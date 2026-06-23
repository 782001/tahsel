# Read version from pubspec.yaml
$pubspec = Get-Content pubspec.yaml
$versionLine = $pubspec | Where-Object { $_ -match "^version:" }
$version = ($versionLine -replace "version:\s*", "")

Write-Host "Building version: $version"

# -------------------------
# 1. BUILD APK
# -------------------------
flutter build apk --release

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$apkName = "tahsel-$version.apk"
$apkNewPath = "build\app\outputs\flutter-apk\$apkName"

if (Test-Path $apkPath) {
    Copy-Item $apkPath $apkNewPath -Force
    Remove-Item $apkPath
    Write-Host "APK renamed to $apkName"
} else {
    Write-Host "APK not found!"
}

# -------------------------
# 2. BUILD WINDOWS EXE
# -------------------------
flutter build windows --release

$exeSource = "build\windows\x64\runner\Release"
$exeTarget = "build\windows\x64\runner\tahsel-windows-$version"

# create folder for versioned build
New-Item -ItemType Directory -Force -Path $exeTarget | Out-Null

Copy-Item "$exeSource\*" $exeTarget -Recurse -Force

Write-Host "EXE build copied to tahsel-$version folder"
Write-Host "EXE build copied to $exeTarget folder"
Write-Host "DONE 🚀"