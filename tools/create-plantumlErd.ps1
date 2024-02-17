<#
.SYNOPSIS
    Create a PlantUML ERD from a given database.
.DESCRIPTION
    Call the SchemaCrawler docker image to create a PlantUML ERD from a given database.
    Requires two environment variables to be set: sc_username and sc_password.
    https://www.schemacrawler.com
.PARAMETER ServerType
    The type of the database server. See the SchemaCrawler documentation for a list of supported servers.
    https://www.schemacrawler.com/database-support.html
.PARAMETER Host
    The hostname of the database server.
.PARAMETER Database
    The name of the database to connect to.
.PARAMETER OutputFilename
    The name of the file to save the PlantUML ERD to.
.EXAMPLE
    .\create-plantumlErd.ps1 -servertype sqlserver -dbhost sql.example.net 
        -database ormico-employees -DiagramName "Ormico Employee Database Schema" 
        -OutputFilename "employee-db.plantuml"
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ServerType,
    
    [Parameter(Mandatory=$true)]
    [string]$DbHost,
    
    [Parameter(Mandatory=$true)]
    [string]$Database,

    [Parameter(Mandatory=$true)]
    [string]$OutputFilename,

    [Parameter(Mandatory=$true)]
    [string]$DiagramName
)

# check for username
if (-not $env:sc_username) {
    Write-Error "Username is missing"
    return
}

# check for password
if (-not $env:sc_password) {
    Write-Error "Password is missing"
    return
}

#todo: DiagramName isn't being populated in the diagram correctly
# it may not passing from this command into docker correctly
docker run `
--rm -it `
schemacrawler/schemacrawler `
/opt/schemacrawler/bin/schemacrawler.sh `
--server=$ServerType `
--host=$DbHost `
--database=$Database `
--user=$env:sc_username `
--password=$env:sc_password `
--info-level=standard `
--command script `
--title "${$DiagramName}" `
--script-language python `
--script plantuml.py > $OutputFilename
