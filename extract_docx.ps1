$word = New-Object -ComObject Word.Application
$word.Visible = $false

$files = @(
    "form_templates\Social Service\2025 CASE FOLDER.docx",
    "form_templates\Home Life Service\FINAL INVENTORY UPON DISCHARGE 2025.docx",
    "form_templates\Home Life Service\FINAL PROGRESS NOTES 2025.docx",
    "form_templates\Home Life Service\FINAL INVENTORY UPON ADMISSION 2025.docx",
    "form_templates\Home Life Service\FINAL INCIDENT REPORT 2025.docx",
    "form_templates\Home Life Service\FIINAL NEW OUT ON PASS 1.docx",
    "form_templates\Home Life Service\FINAL INVENTORY REPORTS 2025.docx",
    "form_templates\Psychological Service\Psych Service Progress Notes.docx",
    "form_templates\Psychological Service\Psych Service Group Session I Activity.docx",
    "form_templates\Psychological Service\Inter-Service Referral (1).docx",
    "form_templates\Psychological Service\Individual Sessions Report Blank Template.docx",
    "form_templates\Psychological Service\Initial Psychological Assessment.docx",
    "form_templates\Psychological Service\Psychometricians Report.docx"
)

$basePath = "E:\Capstone\ElderCare"

foreach ($file in $files) {
    $fullPath = Join-Path $basePath $file
    Write-Host "=========================================="
    Write-Host "FILE: $file"
    Write-Host "=========================================="
    
    try {
        $doc = $word.Documents.Open($fullPath)
        
        # Get tables info
        Write-Host "Tables in document: $($doc.Tables.Count)"
        
        # Get content
        $content = $doc.Content.Text
        Write-Host $content
        
        $doc.Close($false)
    } catch {
        Write-Host "Error reading file: $_"
    }
    
    Write-Host "`n`n"
}

$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
