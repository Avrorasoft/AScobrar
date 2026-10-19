Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "          AUDITORIA EXHAUSTIVA DE PROYECTO ASCOBRAR       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$projectPath = "C:\AScobrar"
$flutterBin = "C:\flutter\bin"

# 1. Verificacion de Rutas y Entorno
Write-Host "`n[1] Verificando entorno y rutas..." -ForegroundColor Yellow
if (Test-Path $projectPath) {
    Write-Host "  -> Carpeta raiz C:\AScobrar: EXISTE" -ForegroundColor Green
} else {
    Write-Host "  -> ERROR FATAL: C:\AScobrar no existe." -ForegroundColor Red
    Exit
}

$env:Path = "$flutterBin;" + $env:Path
$flutterVer = (& flutter --version 2>&1) | Select-Object -First 1
Write-Host "  -> Flutter detectado: $flutterVer" -ForegroundColor White

# 2. Arbol de Archivos Criticos
Write-Host "`n[2] Comprobando integridad de archivos base..." -ForegroundColor Yellow
$criticalFiles = @(
    "pubspec.yaml",
    "lib\main.dart",
    "lib\app.dart",
    "web\index.html",
    "web\manifest.json"
)

foreach ($file in $criticalFiles) {$full = Join-Path $projectPath$file
    if (Test-Path $full) {
        $size = (Get-Item$full).Length
        Write-Host "  -> OK: $file ($size bytes)" -ForegroundColor Green
    } else {
        Write-Host "  -> FALTA: $file" -ForegroundColor Red
    }
}

# 3. Analisis del pubspec.yaml
Write-Host "`n[3] Inspeccionando pubspec.yaml..." -ForegroundColor Yellow
$pubspec = Get-Content "$projectPath\pubspec.yaml" -Raw
if ($pubspec -match "name:\s*([^\r\n]+)") {
    Write-Host "  -> Nombre del paquete declarado: '$($matches[1].Trim())'" -ForegroundColor White
}
if ($pubspec -match "sdk:\s*([^\r\n]+)") {
    Write-Host "  -> Rango SDK: $($matches[1].Trim())" -ForegroundColor White
}

# 4. Inspeccion de web\index.html
Write-Host "`n[4] Inspeccionando web\index.html..." -ForegroundColor Yellow
$indexHtml = Get-Content "$projectPath\web\index.html" -Raw
if ($indexHtml -match 'flutter_bootstrap\.js') { Write-Host "  -> Bootstrap: flutter_bootstrap.js (Motor moderno Flutter)" -ForegroundColor Cyan } elseif ($indexHtml -match 'flutter\.js') {
    Write-Host "  -> Bootstrap: flutter.js (Motor clasico Flutter)" -ForegroundColor Cyan
} else {
    Write-Host "  -> ADVERTENCIA: No se encontro etiqueta script estandar de bootstrap web." -ForegroundColor Red
}

# 5. Busqueda de subcarpetas redundantes o parasitas
Write-Host "`n[5] Busqueda de subcarpetas clonadas o anidadas..." -ForegroundColor Yellow
$subProjects = Get-ChildItem -Path $projectPath -Directory -Recurse -Filter "lib" | Where-Object { $_.FullName -ne "$projectPath\lib" }
if ($subProjects) {
    Write-Host "  -> ALERTA: Se encontraron subdirectorios lib dentro del arbol:" -ForegroundColor Red
    $subProjects | ForEach-Object { Write-Host "     $($_.FullName)" -ForegroundColor Red }
} else {
    Write-Host "  -> Ningun directorio lib parasito detectado. Raiz limpia." -ForegroundColor Green
}

# 6. Analisis estatico de codigo (flutter analyze)
Write-Host "`n[6] Ejecutando analisis estatico de codigo (flutter analyze)..." -ForegroundColor Yellow
Set-Location $projectPath$analysisOutput = (& flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1)
$analysisOutput \vert{} Select-Object -First 15 \vert{} ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }

# 7. Prueba de compilacion Web en seco
Write-Host "`n[7] Verificando compilacion Web (Dry-run de empaquetado)..." -ForegroundColor Yellow
$buildOutput = (& flutter build web --no-tree-shake-icons 2>&1)
$hasError = $false
$buildOutput | ForEach-Object {
    if ($_ -match "Error:" -or $_ -match "Exception:" -or $_ -match "Failed") {
        Write-Host "     $_" -ForegroundColor Red
        $hasError = $true
    }
}

if (-not $hasError) {
    Write-Host "  -> Compilacion web base: COMPLETADA SIN ERRORES CRITICOS." -ForegroundColor Green
} else {
    Write-Host "  -> La compilacion web genero errores bloqueantes." -ForegroundColor Red
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "                 FIN DE LA AUDITORIA                      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
