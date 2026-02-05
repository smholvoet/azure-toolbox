# Searches for specific blobs in an Azure storage container and returns the exact name
# tested in a container with nearly 2.000.000 blobs (>600GB)

$storageAccountName = "<storageAccountName>"
$containerName      = "<containerName>"         
$downloadDirectory  = "C:\Users\<user>\Downloads\blob-downloads\output\"
$storageKey         = "<storageKey>" 
$fileSuffix         = ".PDF"
$i                  = 0

# Verify storage account connection
$connectionTest = az storage container exists `
                  --account-name $storageAccountName `
                  --account-key $storageKey `
                  --name $containerName `
                  --query "exists" `
                  -o tsv

if (-not $connectionTest -or $connectionTest -ne "true") {
    Write-Host "Failed to connect to the storage account or container. Please check your credentials." -ForegroundColor Red
    return
}
else {
    Write-Host "Successfully connected to the storage account and container." -ForegroundColor Green
}

# Create log file before stalking bulk operation
$logFilePath = $downloadDirectory + (Get-Date -Format "yyyyMMdd_HHmmss") + "_blob-download_log.txt"
Start-Transcript -Path $logFilePath -Append

# Import CSV containing first part of the blob name which is known
$ImportFile  = Import-Csv -Path $inputFilePath -Delimiter ";" 
$RowsToProcess = $ImportFile.Count
$ImportFIle | ForEach-Object {
    $CustId = $_.InvoiceAccount
    $FileNamePrefix = "sub/folder/" + $_.FilePrefix

    # Search for blob
    $blob = az storage blob list `
            --account-name $storageAccountName `
            --account-key $storageKey `
            --container-name $containerName `
            --prefix $FileNamePrefix `
            --query "[].name | [0]" `
            -o tsv

    if ($blob) {
        $blob >> "$downloadDirectory\blobs.txt"
    }
    else {
        Write-Host "$fileNamePrefix not found, skipping..."
    }

    $i++

    Write-Progress `
    -Activity "Building blobs.txt" `
    -Status "$i of $RowsToProcess processed" `
    -PercentComplete (($i / $RowsToProcess) * 100)
}


Stop-Transcript
