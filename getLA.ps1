# List all available LDAP Attributes.

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$ADSearch = New-Object System.DirectoryServices.DirectorySearcher
$ADSearch.SearchRoot ="LDAP://$Domain"
$ADSearch.SearchScope = "subtree"
$ADSearch.Filter = '(objectcategory=user)'
$ADSearch.PageSize = 500
$ADSearch.FindAll() | ForEach-Object {
    $_.Properties.Keys
} | Group-Object
