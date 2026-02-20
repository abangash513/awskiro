# NXOP Data Governance Framework - Convert to Word
# This script helps convert the markdown document to Microsoft Word format

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NXOP Governance Document Converter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if the markdown file exists
$mdFile = "NXOP-Data-Governance-Framework-Detailed.md"
if (-not (Test-Path $mdFile)) {
    Write-Host "ERROR: Cannot find $mdFile" -ForegroundColor Red
    Write-Host "Please make sure you're running this script in the correct directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found: $mdFile" -ForegroundColor Green
Write-Host ""

# Check if Pandoc is installed
$pandocInstalled = $false
try {
    $pandocVersion = pandoc --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $pandocInstalled = $true
        Write-Host "Pandoc is installed" -ForegroundColor Green
    }
} catch {
    Write-Host "Pandoc is not installed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Conversion Options:" -ForegroundColor Cyan
Write-Host "1. Use Pandoc (Best formatting - requires Pandoc)" -ForegroundColor White
Write-Host "2. Use Microsoft Word (Open .md file directly)" -ForegroundColor White
Write-Host "3. Show installation instructions for Pandoc" -ForegroundColor White
Write-Host "4. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Select option (1-4)"

switch ($choice) {
    "1" {
        if (-not $pandocInstalled) {
            Write-Host ""
            Write-Host "ERROR: Pandoc is not installed" -ForegroundColor Red
            Write-Host "Please select option 3 to see installation instructions" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host ""
        Write-Host "Converting with Pandoc..." -ForegroundColor Cyan
        
        $outputFile = "NXOP-Data-Governance-Framework-Detailed.docx"
        
        # Convert with table of contents
        pandoc $mdFile -o $outputFile --toc --toc-depth=3
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "SUCCESS: Document converted!" -ForegroundColor Green
            Write-Host "Output file: $outputFile" -ForegroundColor Green
            Write-Host ""
            Write-Host "Opening document..." -ForegroundColor Cyan
            Start-Process $outputFile
        } else {
            Write-Host ""
            Write-Host "ERROR: Conversion failed" -ForegroundColor Red
            Write-Host "Please check the error messages above" -ForegroundColor Yellow
        }
    }
    
    "2" {
        Write-Host ""
        Write-Host "Opening Microsoft Word..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Instructions:" -ForegroundColor Yellow
        Write-Host "1. Word will open the markdown file" -ForegroundColor White
        Write-Host "2. Click File -> Save As" -ForegroundColor White
        Write-Host "3. Choose format: Word Document (*.docx)" -ForegroundColor White
        Write-Host "4. Save as: NXOP-Data-Governance-Framework-Detailed.docx" -ForegroundColor White
        Write-Host ""
        
        # Try to open with Word
        try {
            Start-Process "winword.exe" -ArgumentList $mdFile
            Write-Host "Microsoft Word opened successfully" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: Could not open Microsoft Word" -ForegroundColor Red
            Write-Host "Please open Word manually and open the file: $mdFile" -ForegroundColor Yellow
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Pandoc Installation Instructions" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Option 1: Download Installer" -ForegroundColor Yellow
        Write-Host "1. Visit: https://pandoc.org/installing.html" -ForegroundColor White
        Write-Host "2. Download the Windows installer (.msi)" -ForegroundColor White
        Write-Host "3. Run the installer" -ForegroundColor White
        Write-Host "4. Restart PowerShell" -ForegroundColor White
        Write-Host "5. Run this script again" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2: Using Chocolatey (if installed)" -ForegroundColor Yellow
        Write-Host "Run: choco install pandoc" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 3: Using Winget (Windows 10/11)" -ForegroundColor Yellow
        Write-Host "Run: winget install --id JohnMacFarlane.Pandoc" -ForegroundColor White
        Write-Host ""
        Write-Host "After installation, run this script again and select option 1" -ForegroundColor Green
    }
    
    "4" {
        Write-Host ""
        Write-Host "Exiting..." -ForegroundColor Cyan
        exit 0
    }
    
    default {
        Write-Host ""
        Write-Host "Invalid option. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review the Word document" -ForegroundColor White
Write-Host "2. Fill in all [TBD] placeholders" -ForegroundColor White
Write-Host "3. Add American Airlines branding" -ForegroundColor White
Write-Host "4. Customize content as needed" -ForegroundColor White
Write-Host "5. Obtain approvals" -ForegroundColor White
Write-Host "6. Begin implementation" -ForegroundColor White
Write-Host ""
Write-Host "For more information, see:" -ForegroundColor Yellow
Write-Host "- DELIVERY-SUMMARY.md" -ForegroundColor White
Write-Host "- CONVERT-TO-WORD-INSTRUCTIONS.md" -ForegroundColor White
Write-Host "- NXOP-Governance-Document-Summary.md" -ForegroundColor White
Write-Host ""
