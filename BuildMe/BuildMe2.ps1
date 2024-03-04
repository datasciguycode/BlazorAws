# BuildMe2.ps1 - Used to run multiple steps for higher level commands in BuildMe1.ps1

Clear-Host

. .\BuildMe\BuildMe3.ps1

# ---------------------------------------------------------------------------

# Init
$strDbName = "WagePeace"
$strProjectName = "BlazorApp"
$strProjectFolder = ".\$strProjectName"
$strProjectFilePath = "$strProjectFolder\$strProjectName.csproj"
$strClientProjectFilePath = "$strProjectFolder.Client\$strProjectName.Client.csproj"
$strConnection = "Server=LAPTOP-8PG7T653\SQLEXPRESS;Database=$strDbName;Trusted_Connection=True;TrustServerCertificate=true"

# ---------------------------------------------------------------------------

function Add-ModelSpecificPageFiles {

    param ([string]$p_strProjectFolder)
    
    $strConnection = Get-DefaultConnection -p_strJsonFilePath ".\$p_strProjectFolder\appsettings.Development.json"
    $aryTableNames = Get-DbTableNames -p_strConnectionString $strConnection

    foreach ($strTableName in $aryTableNames) {
        $fieldTable = Get-DbFieldTable -p_strConnectionString $strConnection -p_strTableName $strTableName
        Add-ModelSpecificPageFile -p_strProjectName $strProjectName -p_strProjectFolder $p_strProjectFolder -p_strTableName $strTableName -p_fieldTable $fieldTable    
    }
}

# ---------------------------------------------------------------------------

function Add-ControllersByModel {

    # Not necessary to run this function if using generic controllers:
    Add-CodeGenerator -p_strProjectFilePath $strProjectFilePath
    Add-Controllers -p_strProjectName $strProjectName -p_strProjectFilePath $strProjectFilePath -p_strDbContext "${strDbName}Context"
}
# ---------------------------------------------------------------------------
function Add-Connections {

    param (
        [string]$p_strConnection,
        [string]$p_strProjectFolder
    )
    
    Add-Connection -p_strConnection $p_strConnection -p_strFilePath "$p_strProjectFolder\appsettings.json"
    Add-Connection -p_strConnection $p_strConnection -p_strFilePath "$p_strProjectFolder\appsettings.Development.json"
}

# ---------------------------------------------------------------------------

function Add-BlazorApp {
    param 
    (
        [string]$p_strProject
    )

    # Create Blazor WebAssembly project with ASP.NET Core hosted backend
    dotnet new blazor -o $p_strProject

    # Add the project to a new solution
    <#
        dotnet new sln --name $p_strProject
        dotnet sln $p_strProject.sln add $p_strProject/Server/$p_strProject.Server.csproj
        dotnet sln $p_strProject.sln add $p_strProject/Client/$p_strProject.Client.csproj
        dotnet sln $p_strProject.sln add $p_strProject/Shared/$p_strProject.Shared.csproj    
    #>
}

# ---------------------------------------------------------------------------

function Add-API {
    param 
    (
        [string]$p_strProject
        , [string]$p_strProjectPath
    )

    # Create API
    dotnet new webapi -o $p_strProject --framework net8.0 --use-controllers
    dotnet new sln --name BlazorApp
    dotnet sln BlazorApp.sln add $p_strProjectPath
}

# ---------------------------------------------------------------------------

function Initialize-Git {
    dotnet new gitignore
    git init
    Write-Host "Git initialized."  
}

# ---------------------------------------------------------------------------

function Add-Connection {
    param 
    (
        [string]$p_strConnection
        , [string]$p_strFilePath
    )

    $json = Get-Content -Path $p_strFilePath  | ConvertFrom-Json
    $json | Add-Member -Type NoteProperty -Name ConnectionStrings -Value @{DefaultConnection = $p_strConnection }
    $json | ConvertTo-Json -Depth 32 | Set-Content -Path $p_strFilePath
}

# ---------------------------------------------------------------------------

function Set-InvariantGlobalization {
    param 
    (
        [string]$p_strProject
    )

    $p_strOldText = "<InvariantGlobalization>true</InvariantGlobalization>"
    $p_strNewText = "<InvariantGlobalization>false</InvariantGlobalization>"

    # Set InvariantGlobalization to false
    Update-TextInFile -p_strFilePath ".\$p_strProject\$p_strProject.csproj" -p_strOldText $p_strOldText -p_strNewText $p_strNewText
}

# ---------------------------------------------------------------------------

function Install-EntityFramework {
    param 
    (
        [bool]$p_AddModels
        ,[string]$p_strProjectFilePath
        ,[string]$p_strOutputFolder = "Models"
    )

    $strConnection = Get-DefaultConnection -p_strJsonFilePath ".\$strProjectFolder\appsettings.Development.json"
    $strSqlServerPackage = "Microsoft.EntityFrameworkCore.SqlServer"

    # Add Entities
    Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName $strSqlServerPackage

    if ($p_AddModels) {
        Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName "Microsoft.EntityFrameworkCore.Design"
        dotnet ef dbcontext scaffold $strConnection $strSqlServerPackage --output-dir $p_strOutputFolder --force  --project $p_strProjectFilePath --data-annotations --use-database-names --no-pluralize
    }
}

# ---------------------------------------------------------------------------

function Add-CodeGenerator {
    param 
    (
        [string]$p_strProjectFilePath
    )

    dotnet tool install --global "dotnet-aspnet-codegenerator"
    Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName "Microsoft.EntityFrameworkCore.Tools"
    Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName "Microsoft.VisualStudio.Web.CodeGeneration.Design"
}

# ---------------------------------------------------------------------------

function Add-Swagger {
    param 
    (
        [string]$p_strProjectFolder
        ,[string]$p_strProjectFilePath
    )

    # Add packages
    Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName "Swashbuckle.AspNetCore.Swagger"
    Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName "Swashbuckle.AspNetCore.SwaggerGen"
    Install-Package -p_strProjectFilePath $p_strProjectFilePath -p_strPackageName "Swashbuckle.AspNetCore.SwaggerUI"

    # Add Services
    $strLineToFind = "// Add services to the container"
    $strLineToAdd = @"
builder.Services.AddEndpointsApiExplorer(); // new
builder.Services.AddSwaggerGen();  // new
"@
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $false -p_bBlankLineAbove $true -p_bBlankLineBelow $false


    # Add Apps
    $strLineToFind = "app.UseWebAssemblyDebugging();"
    $strLineToAdd = @"
    app.UseSwagger();    // new
    app.UseSwaggerUI();  // new
"@
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $false -p_bBlankLineAbove $true -p_bBlankLineBelow $false
}

# ---------------------------------------------------------------------------

function Add-Controllers {
    param 
    (
        [string]$p_strProjectName
        , [string]$p_strProjectFilePath
        , [string]$p_strDbContext
    )

    Get-ChildItem ".\BlazorApp\BlazorApp\Models" -Filter *.cs | Where-Object { $_.Name -ne 'WagePeaceContext.cs' } | ForEach-Object {        
        dotnet-aspnet-codegenerator -p ".\$p_strProjectName\$p_strProjectName\$p_strProjectName.csproj" controller -name "$($_.BaseName)Controller" -api -m "$p_strProjectName.Models.$($_.BaseName)" -dc $p_strDbContext -outDir "Controllers" -namespace "$p_strProjectName.Controllers"
    }
}

# ---------------------------------------------------------------------------

function Build-DatabaseScript {
    param 
    (
        [string]$p_strProject
        , [string]$p_strDbName
    )

    dotnet ef dbcontext script --output ".\$p_strProject\$p_strDbName.sql" --project ".\$p_strProject\$p_strProject.csproj" --context "${p_strDbName}Context"
}

# ---------------------------------------------------------------------------

function Install-Package {    
    param 
    (
        [string]$p_strProjectFilePath
        , [string]$p_strPackageName
    )

    $installedPackages = dotnet list $p_strProjectFilePath package | Out-String

    if (($installedPackages -match $p_strPackageName)) {       
        Write-Host "$p_strPackageName is already installed."
    }
    else {
        dotnet add $p_strProjectFilePath package $p_strPackageName
    }
}

# ---------------------------------------------------------------------------

function Uninstall-Package {    
    param (
        [string]$p_strProjectFilePath
        , [string]$p_strPackageName
    )

    $installedPackages = dotnet list $p_strProjectFilePath package | Out-String

    if (($installedPackages -match $p_strPackageName)) {
        dotnet remove $p_strProjectFilePath package $p_strPackageName
    }
    else {        
        Write-Host "$p_strPackageName is not installed."
    }
}

# ---------------------------------------------------------------------------

function Add-DbAccessFiles {
    param (
        [string]$p_strProjectName
        , [string]$p_strProjectFolder
    )

    # Add Repository, Service, and Controller files and references in Program.cs
    Add-GenericRepositoryFile -p_strProjectName $p_strProjectName -p_strProjectFolder $p_strProjectFolder
    Add-GenericServiceFile -p_strProjectName $p_strProjectName -p_strProjectFolder $p_strProjectFolder
    Add-GenericControllerFile -p_strProjectName $p_strProjectName -p_strProjectFolder $p_strProjectFolder

    $files = Get-ChildItem -Path "$p_strProjectFolder/Models" -File

    foreach ($file in $files) {
        if ($file.BaseName -notmatch "context") {
            Add-ModelSpecificControllerFile -p_strModelName $file.BaseName -p_strProjectName $p_strProjectName -p_strProjectFolder $p_strProjectFolder
        }
    }    
}

# ---------------------------------------------------------------------------
function Get-ApplicationUrl {
    
    param (
        [string]$p_strProjectFolder
    )

    $strFilePath = "$p_strProjectFolder\Properties\launchSettings.json"

    $json = Get-Content $strFilePath | ConvertFrom-Json

    return ($json.profiles.https.applicationUrl -split ';')[0]
}

# ---------------------------------------------------------------------------

function Add-BaseUri {

    param 
    (
        [string]$p_strProjectFolder
        ,[string]$p_strAppSettingsFilePath
    )

    $strUrl = Get-ApplicationUrl -p_strProjectFolder $p_strProjectFolder
    $json = Get-Content -Path $p_strAppSettingsFilePath  | ConvertFrom-Json
    $json | Add-Member -Type NoteProperty -Name "BaseUri" -Value $strUrl
    $json | ConvertTo-Json -Depth 32 | Set-Content -Path $p_strAppSettingsFilePath
}

# ---------------------------------------------------------------------------
