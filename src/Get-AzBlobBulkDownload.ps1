# Downloads blobs from an Azure storage container in bulk, using AzCopy
# Import file should contain a list of blob names (including absolute path in case of (sub)folders)

$sasToken           = "sv=..."
$storageAccountName = "<storageAccount>"
$containerName      = "<containerName>" 
$filenameList       = Get-Content -Path "<file containing full path to blob names>"
$downloadDirectory  = "C:\Users\<user>\Downloads\blob-downloads\output\"
$AzCopy             = "C:\temp\azcopy.exe"

$fullURL = "https://$storageAccountName.blob.core.windows.net/" + $containerName + "?$sasToken"

& $AzCopy copy `
    $fullURL `
    $downloadDirectory `
    --list-of-files $filenameList