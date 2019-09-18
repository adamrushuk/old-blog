$STORAGE_ACCOUNT_NAME = "virtuallyimpossiblecouk"
$CONTENT_RELATIVE_PATH = "content"
# $contentFiles = Get-ChildItem -Path $CONTENT_RELATIVE_PATH/* -Include "index.html"
$contentFiles = Get-ChildItem -Path $CONTENT_RELATIVE_PATH -Recurse

# # Load helper function
# $functionFilePath = Join-Path -Path "." -ChildPath "Find-MimeType.ps1"
# . $functionFilePath
# $contentFiles | gm
foreach ($contentFile in $contentFiles[0..300]) {
    if ($contentFile.PSIsContainer) {
        "$($contentFile.Name) is a folder"
    } else {
        "$($contentFile.Name) is a file"
    }
    # Find-MimeType -FileExtension ".html" -Verbose
    # Find-MimeType -MimeType "image/png" -Verbose
    # $contentFile | Set-AzStorageBlobContent -Container '$web' -Properties @{ ContentType = $fileMimeType } -Force
}


###

# Test az cli
az storage blob upload-batch --destination '$web' --account-name "$STORAGE_ACCOUNT_NAME" --source "$CONTENT_RELATIVE_PATH"
