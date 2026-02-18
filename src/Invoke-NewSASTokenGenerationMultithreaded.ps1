# Loops over a CSV file, checks if the blob exists in Azure Storage, and generates a new URL with a SAS token if it does.
# Improved version with parallel processing
# Runtime for ~9k blobs: 50 minutes

$storageAccountName = "<...>"
$storageAccountKey  = "<...>"
$endDateTime        = $startDateTime.AddYears(1)
$startDateTime      = (Get-Date).ToUniversalTime()
$startIso           = $startDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endIso             = $endDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$ImportFile         = "<...>.csv"
$ExportFileOK       = "<...>\OK.txt"
$ExportFileNOK      = "<...>\NOK.txt"
$ExportFileCSV      = "<...>\results.csv"
$logFilePath        = "<...>._$((Get-Date).ToString("yyyyMMdd_HHmmss")).log"

Clear-Host
Start-Transcript -Path $logFilePath

$rows = Import-Csv -Path $ImportFile -Delimiter ";"

$results = $rows | ForEach-Object -Parallel {
    $DocumentNumber     = $_.DOCUMENTNUMBER
    $blobFullPath       = $_.PATH
    $containerName      = $_.PATH -split "/" | Select-Object -First 1
    $blobName           = $_.PATH -split "/" | Select-Object -Last 1

    try {
        $sasToken = az storage blob generate-sas `
            --account-name $using:storageAccountName `
            --account-key $using:storageAccountKey `
            --container-name $containerName `
            --name $blobName `
            --permissions r `
            --start $using:startIso `
            --expiry $using:endIso `
            --output tsv

        Write-Host "Generated SAS token for $blobFullPath" -ForegroundColor Green

        $blobUri = "https://" + $using:storageAccountName + ".blob.core.windows.net/" + $containerName + "/" + $blobName + "?" + $sasToken

        [PSCustomObject]@{
            Status = "OK"
            Record = "$DocumentNumber;$blobUri"
            Path   = $blobFullPath
        }
    }
    catch {
        [PSCustomObject]@{
            Status = "NOK"
            Record = $null
            Path   = $blobFullPath
        }
    }
} -ThrottleLimit 80

$ok   = $results | Where-Object Status -eq "OK"
$nok  = $results | Where-Object Status -eq "NOK"

$ok  | Select-Object -ExpandProperty Record | Set-Content $ExportFileCSV
$ok  | Select-Object -ExpandProperty Path   | Set-Content $ExportFileOK
$nok | Select-Object -ExpandProperty Path   | Set-Content $ExportFileNOK

Stop-Transcript