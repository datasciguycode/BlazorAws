# Blazor WASM App Hosted in AWS:

## Human:  Install "Blazor Web App" Template in Visual Studio Config for https, Auto (Server and WebAssembly) *

# Update starting parameters in BuildMe2.ps1 if necessary.

# Init - Open main project VS Code and run this script.
. .\BuildMe\BuildMe2.ps1

# Git *
Initialize-Git

# Add DB Connections (appsettings.json, appsettings.Development.json") 
Add-Connections -p_strConnection $strConnection -p_strProjectFolder $strProjectFolder

# Add EF Models and DbContext (Open SQL Server) 
Install-EntityFramework -p_AddModels $true -p_strProjectFilePath ".\Infrastructure\Infrastructure.csproj" -p_strOutputFolder "..\Domain\Models" # new
# New-Item -ItemType Directory -Path ".\Infrastructure\Contexts"
# Move-Item -Path ".\Domain\Models\${strDbName}Context.cs" -Destination ".\Infrastructure\Contexts\${strDbName}Context.cs"

## Human:  Copy models over & update namespaces on client until shared project is created.

# Add-GenericIRepositoryFile  # new
Add-GenericRepositoryFile  # new

# Reference DbContext in Program.cs 
Add-DbContextRef -p_strProjectName $strProjectName -p_strDbName $strDbName

# Add Repository, Service, and Controller files in respective folders 
## Add-DbAccessFiles -p_strProjectName $strProjectName -p_strProjectFolder $strProjectFolder

# Add Repository, Service, and Controller references in Program.cs 
## Add-GenericRepoAndServiceRef -p_strProjectFolder $strProjectFolder

# Add references to controllers in Program.cs 
## Add-ControllersRef -p_strProjectFolder $strProjectFolder

# Add BaseUri to client and server appsettings.json 
Add-BaseUri -p_strProjectFolder $strProjectFolder -p_strAppSettingsFilePath "$strProjectFolder\appsettings.json" # *
Add-BaseUri -p_strProjectFolder $strProjectFolder -p_strAppSettingsFilePath "$strProjectFolder.Client\wwwroot\appsettings.json"

# Add HttpClient Services to program.cs 
Add-HttpClientRef -p_strClientProjectFolder "$strProjectFolder.Client"

# Add Swagger 
## Add-Swagger -p_strProjectFolder $strProjectFolder -p_strProjectFilePath $strProjectFilePath

# Add QuickGrid Package to Client 
Install-Package -p_strProjectFilePath $strClientProjectFilePath -p_strPackageName "Microsoft.AspNetCore.Components.QuickGrid"

# Add Razor Page with QuickGrid accessing server controller pasing model and returning result.AsQueryable();  
Add-ModelSpecificPageFiles

# Add Domain library 
# dotnet new classlib -n "Domain" -o ".\Domain"  # new
# dotnet sln "$strProjectName.sln" add ".\Domain\Domain.csproj"  # new

# Add Infrastructure library 
# dotnet new classlib -n "Infrastructure" -o ".\Infrastructure"  # new
# dotnet sln "$strProjectName.sln" add ".\Infrastructure\Infrastructure.csproj"  # new

# Build
dotnet build .\$strProjectName

# Run
dotnet run --project $strProjectFilePath --launch-profile https

# Watch Run 
dotnet watch run --project $strProjectFilePath --launch-profile https

# Debug
dotnet run --configuration Debug --project $strProjectFilePath --launch-profile https