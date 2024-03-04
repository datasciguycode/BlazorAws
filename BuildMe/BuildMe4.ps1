# BuildMe3.ps1 - Used to add references to a project

. .\BuildMe\Library.ps1

# ---------------------------------------------------------------------------

function Add-HttpClientRef {

    $strLineToAdd = "builder.Services.AddScoped(http => new HttpClient {BaseAddress = new Uri(builder.Configuration.GetSection(`"BaseUri`").Value!)});  // new"

    # Server
    $strLineToFind = "// Add services to the container."
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $false -p_bBlankLineAbove $true -p_bBlankLineBelow $true
}

# ---------------------------------------------------------------------------

function Add-DbContextRef {
    
    param 
    (
        [string]$p_strProjectName
        , [string]$p_strDbName
    )

    # Add usings:
    $strText = @"
using ${p_strProjectName}.Models;   // new
using Microsoft.EntityFrameworkCore;    // new
"@
    Add-TextToTopOfFile -p_strFilePath ".\$p_strProjectName\Program.cs" -p_strText $strText

    # Add DBContext:
    $strLineToFind = "// Add services to the container."
    $strLineToAdd = @"
builder.Services.AddDbContext<${p_strDbName}Context>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));  // new
"@
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $false -p_bBlankLineAbove $false -p_bBlankLineBelow $true
}

# ---------------------------------------------------------------------------

function Add-ControllersRef {
    param 
    (
        [string]$p_strProjectFolder
    )

    # ----- AddControllers -----
    $strLineToFind = "// Add services to the container"
    $strLineToAdd = "builder.Services.AddControllers();  // new"

    Update-TextInFile -p_strFilePath "$p_strProjectFolder\Program.cs" -p_strOldText $strOldText -p_strNewText $strNewText
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $false -p_bBlankLineAbove $true -p_bBlankLineBelow $false
    # ----- /AddControllers -----

    # ----- Update App -----
    $strLineToFind = "app.Run();"
    $strLineToAdd = "app.MapControllers();  // new"

    Update-TextInFile -p_strFilePath "$p_strProjectFolder\Program.cs" -p_strOldText $strOldText -p_strNewText $strNewText
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $true -p_bBlankLineAbove $false -p_bBlankLineBelow $true
    # ----- /Update App -----
}

# ---------------------------------------------------------------------------

function Add-GenericRepoAndServiceRef {
    param 
    (
        [string]$p_strProjectFolder
    )

# Usings:
$strText = @"
using BlazorApp.Services;   // new
using BlazorApp.Repositories;   // new
"@
    # Add to Program.cs
    Add-TextToTopOfFile -p_strFilePath "$p_strProjectFolder\Program.cs" -p_strText $strText

# Services:
    $strLineToFind = "// Add services to the container."
    $strLineToAdd = @"
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));    // new
builder.Services.AddScoped(typeof(IService<>), typeof(Service<>));  // new
"@    
    Add-LineToFile -p_strFilePath "$strProjectFolder\Program.cs" -p_strLineToFind $strLineToFind -p_strLineToAdd $strLineToAdd -p_bPutLineOnTop $false -p_bBlankLineAbove $true -p_bBlankLineBelow $false
}

# ---------------------------------------------------------------------------