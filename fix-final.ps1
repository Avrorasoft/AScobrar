# ============================================================
# 🔧 FIX-FINAL.ps1 — Limpieza final del proyecto
# ============================================================
$ErrorActionPreference = "Continue"
$base = "C:\AScobrar\loan_collector_app"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔧  FIX FINAL — Limpieza total                       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Set-Location $base

# ============================================================
# PASO 1: Eliminar archivos .g.dart corruptos
# ============================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🗑️  PASO 1: Eliminando archivos .g.dart corruptos" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$gFiles = Get-ChildItem -Path "$base\lib" -Recurse -Filter "*.g.dart"
foreach ($f in $gFiles) {
    Remove-Item $f.FullName -Force
    Write-Host "  🗑️  $($f.Name)" -ForegroundColor Gray
}
Write-Host "  ✅ $($gFiles.Count) archivos eliminados" -ForegroundColor Green
Write-Host ""

# ============================================================
# PASO 2: dart fix --apply (elimina unused imports, etc.)
# ============================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🔨 PASO 2: Ejecutando 'dart fix --apply'" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

dart fix --apply 2>&1 | Out-Null
Write-Host "  ✅ dart fix completado" -ForegroundColor Green
Write-Host ""

# ============================================================
# PASO 3: Reemplazo masivo withOpacity → withValues(alpha: x)
# ============================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🎨 PASO 3: Reemplazando .withOpacity → .withValues(alpha: x)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$files = Get-ChildItem -Path "$base\lib" -Recurse -Filter "*.dart"
$totalReplacements = 0
$filesModified = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    $content = [regex]::Replace($content, '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)')
    
    if ($content -ne $originalContent) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($false))
        $count = ([regex]::Matches($originalContent, '\.withOpacity\([^)]+\)')).Count
        $totalReplacements += $count
        $filesModified++
        
        $shortPath = $file.FullName.Replace("$base\", "")
        Write-Host "  ✅ $shortPath " -NoNewline -ForegroundColor Green
        Write-Host "($count)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "  📊 Archivos: $filesModified | Reemplazos: $totalReplacements" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# PASO 4: Arreglar casos especiales
# ============================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🔧 PASO 4: Arreglando casos especiales" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# 4a. new_client_screen.dart: value → initialValue
$path = "$base\lib\screens\clients\new_client_screen.dart"
if (Test-Path $path) {
    $c = Get-Content $path -Raw -Encoding UTF8
    $c2 = $c -replace '(?m)(\s+)value:\s*', '$1initialValue: '
    if ($c -ne $c2) {
        [System.IO.File]::WriteAllText($path, $c2, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  ✅ new_client_screen.dart (value → initialValue)" -ForegroundColor Green
    }
}

# 4b. splash_screen.dart: quitar const innecesario
$path = "$base\lib\screens\splash\splash_screen.dart"
if (Test-Path $path) {
    $c = Get-Content $path -Raw -Encoding UTF8
    $c2 = $c -replace "Text\('💰',\s*style:\s*const\s+TextStyle", "Text('💰', style: TextStyle"
    if ($c -ne $c2) {
        [System.IO.File]::WriteAllText($path, $c2, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  ✅ splash_screen.dart (const eliminado)" -ForegroundColor Green
    }
}

# 4c. notification_service.dart: arreglar escapes
$path = "$base\lib\services\notification_service.dart"
if (Test-Path $path) {
    $c = Get-Content $path -Raw -Encoding UTF8
    $c2 = $c -replace "UriAndroidNotificationSound\('assets/sounds/\\\$soundFile\.mp3'\)", "UriAndroidNotificationSound('assets/sounds/`$soundFile.mp3')"
    if ($c -ne $c2) {
        [System.IO.File]::WriteAllText($path, $c2, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  ✅ notification_service.dart (escapes arreglados)" -ForegroundColor Green
    }
}

# 4d. loan_detail_screen.dart: agregar mounted check si falta
$path = "$base\lib\screens\loans\loan_detail_screen.dart"
if (Test-Path $path) {
    $c = Get-Content $path -Raw -Encoding UTF8
    if ($c -notmatch "if \(!mounted\) return;") {
        # Agregar mounted check después de cualquier await
        $c2 = $c -replace '(?m)(\s+)(await[^\n]+\n)(\s+)(if \(context\.mounted\))', '$1$2$3if (!mounted) return;`n$3$4'
        if ($c -ne $c2) {
            [System.IO.File]::WriteAllText($path, $c2, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  ✅ loan_detail_screen.dart (mounted check)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ℹ️  loan_detail_screen.dart (ya tiene mounted check)" -ForegroundColor Gray
    }
}

Write-Host ""

# ============================================================
# PASO 5: Verificación final
# ============================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🔍 PASO 5: Verificación final" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

$analyzeOutput = flutter analyze 2>&1
$analyzeText = $analyzeOutput -join "`n"

$errorCount = ([regex]::Matches($analyzeText, '(?m)^\s*error\s+-')).Count
$warningCount = ([regex]::Matches($analyzeText, '(?m)^\s*warning\s+-')).Count
$infoCount = ([regex]::Matches($analyzeText, '(?m)^\s*info\s+-')).Count
$totalIssues = $errorCount + $warningCount + $infoCount

Write-Host "  📊 Resultado:" -ForegroundColor Cyan
Write-Host "     🔴 Errors:   $errorCount" -ForegroundColor $(if ($errorCount -eq 0) { "Green" } else { "Red" })
Write-Host "     🟡 Warnings: $warningCount" -ForegroundColor $(if ($warningCount -eq 0) { "Green" } else { "Yellow" })
Write-Host "     🔵 Infos:    $infoCount" -ForegroundColor $(if ($infoCount -eq 0) { "Green" } else { "Blue" })
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅  ¡SIN ERRORES! Proyecto compilable                 ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║  ⚠️  Quedan $errorCount errors                                       ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  📋 Errores restantes:" -ForegroundColor Yellow
    $analyzeOutput | ForEach-Object {
        if ($_ -match "error\s+-") {
            Write-Host "     $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  🚀 Próximos pasos:" -ForegroundColor Cyan
Write-Host "     flutter run" -ForegroundColor White
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""