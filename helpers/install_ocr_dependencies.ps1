# PowerShell script to install OCR dependencies with correct numpy version
# Run this script to set up the environment for ocr_region_test.py

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OCR Dependencies Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if virtual environment exists
$venvPath = ".venv"
if (Test-Path $venvPath) {
    Write-Host "✓ Virtual environment found: $venvPath" -ForegroundColor Green
    $pythonExe = "$venvPath\Scripts\python.exe"
} else {
    Write-Host "! No virtual environment found" -ForegroundColor Yellow
    Write-Host "  Using system Python" -ForegroundColor Yellow
    $pythonExe = "python"
}

Write-Host ""
Write-Host "Step 1: Installing numpy < 2.0 (required for PaddleOCR)" -ForegroundColor Yellow
& $pythonExe -m pip install "numpy<2.0" --force-reinstall

Write-Host ""
Write-Host "Step 2: Installing screenshot capture library" -ForegroundColor Yellow
& $pythonExe -m pip install mss

Write-Host ""
Write-Host "Step 3: Installing image processing libraries" -ForegroundColor Yellow
& $pythonExe -m pip install Pillow

Write-Host ""
Write-Host "Step 4: Installing PaddlePaddle (OCR engine)" -ForegroundColor Yellow
& $pythonExe -m pip install paddlepaddle

Write-Host ""
Write-Host "Step 5: Installing PaddleOCR" -ForegroundColor Yellow
& $pythonExe -m pip install paddleocr

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run: python ocr_region_test.py" -ForegroundColor Cyan
Write-Host ""
