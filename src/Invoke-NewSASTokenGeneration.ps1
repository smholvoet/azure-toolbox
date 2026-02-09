# Loops over a CSV file, checks if the blob exists in Azure Storage, and generates a new URL with a SAS token if it does.
# Runtime for ~9k blobs: 8h

$storageAccountName     = "<...>"
$storageAccountKey      = "<...>"
$startDateTime          = (Get-Date).ToUniversalTime()
$endDateTime            = $startDateTime.AddYears(1)
$ImportFile             = "C:\Users\<...>\Downloads\<...>.csv"
$ExportFileOK           = "C:\Users\<...>\Downloads\OK.txt"
$ExportFileNOK          = "C:\Users\<...>\Downloads\NOK.txt"
$ExportFileCSV          = "C:\Users\<...>\Downloads\results.csv"
$logFilePath            = "C:\Users\<...>\Downloads\$((Get-Date).ToString("yyyyMMdd_HHmmss")).log"

Clear-Host
Start-Transcript -Path $logFilePath
#---------------------------------------------

Import-CSV -Path $ImportFile -Delimiter ";" | ForEach-Object {
    $DocumentNumber     = $_.DOCUMENTNUMBER
    $blobFullPath       = $_.PATH
    $containerName      = $_.PATH -split "/" | Select-Object -First 1
    $blobName           = $_.PATH -split "/" | Select-Object -Last 1

    $blobExists = az storage blob exists `
    --account-name $storageAccountName `
    --account-key $storageAccountKey `
    --container-name $containerName `
    --name $blobName `
    --output tsv

    if ($blobExists -eq "False") {
        Write-Host "$blobFullPath not found."
        $blobFullPath >> $ExportFileNOK
    }
    else {
        $sasToken = az storage blob generate-sas `
            --account-name $storageAccountName `
            --account-key $storageAccountKey `
            --container-name $containerName `
            --name $blobName `
            --permissions r `
            --start $($startDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")) `
            --expiry $($endDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")) `
            --output tsv

        $blobUri = "https://$storageAccountName.blob.core.windows.net/" + $containerName + "/" + $blobName + "?" + $sasToken

        $Record = $DocumentNumber + ";" + $blobUri
        $Record >> $ExportFileCSV
        $blobFullPath >> $ExportFileOK
        Write-Host "$blobFullPath OK, generated new URL."
    }
}

#---------------------------------------------
Stop-Transcript