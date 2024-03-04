# BuildMe3.ps1 - Used to add files to a project

. .\BuildMe\BuildMe4.ps1

# ---------------------------------------------------------------------------

function Add-GenericRepositoryFile
{
    $strContent = @"
    namespace Infrastructure.Repositories;

    using Infrastructure.Models;
    using Microsoft.EntityFrameworkCore;
    
    public interface IRepository<T> where T : class
    {
        Task<List<T>> GetAll();
        Task<T> GetById(int id);
        Task<T> Add(T entity);
        Task Update(int id, T entity);
        Task Delete(int id);
    }
    
    public class Repository<T> : IRepository<T> where T : class
    {
        private readonly WagePeaceContext _context;
        private DbSet<T> entities;
    
        public Repository(WagePeaceContext context)
        {
            _context = context;
            entities = context.Set<T>();
        }
    
        public async Task<List<T>> GetAll()
        {
            return await entities.ToListAsync();
        }
    
        public async Task<T> GetById(int id)
        {
            var entity = await entities.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException("No entity found with this ID");
            }
    
            return entity;
        }
    
        public async Task<T> Add(T entity)
        {
            if (entity == null)
            {
                throw new ArgumentException("Entity cannot be null");
            }
    
            entities.Add(entity);
            await _context.SaveChangesAsync();
    
            return entity;
        }
    
        public async Task Update(int id, T entity)
        {
            if (entity == null)
            {
                throw new ArgumentException("Entity cannot be null");
            }
    
            entities.Update(entity);
            await _context.SaveChangesAsync();
        }
    
        public async Task Delete(int id)
        {
            var entity = await entities.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException("No entity found with this ID");
            }
    
            entities.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
"@    

    New-Item -Path "./Infrastructure/Repositories" -ItemType Directory
    New-Item -Path "./Infrastructure/Repositories/Repository.cs" -ItemType "file" -Value $strContent
}

# ---------------------------------------------------------------------------

function Add-GenericIRepositoryFile
{

    $strContent = @"
    namespace Infrastructure.Repositories;

    using Infrastructure.Models;
    using Microsoft.EntityFrameworkCore;
    
    public interface IRepository<T> where T : class
    {
        Task<List<T>> GetAll();
        Task<T> GetById(int id);
        Task<T> Add(T entity);
        Task Update(int id, T entity);
        Task Delete(int id);
    }
"@

    New-Item -Path "./Domain/Repositories" -ItemType Directory
    New-Item -Path "$/Domain/Repositories/IRepository.cs" -ItemType "file" -Value $strContent
}

# ---------------------------------------------------------------------------

function Add-GenericServiceFile
{    
    param 
    (
        [string]$p_strProjectName
        ,[string]$p_strProjectFolder
    )

    $strContent = @"
    namespace $p_strProjectName.Services;

    using $p_strProjectName.Repositories;
    
    public interface IService<T> where T : class
    {
        Task<List<T>> GetAll();
        Task<T> Get(int id);
        Task Update(int id, T entity);
        Task<T> Add(T entity);
        Task Delete(int id);
    }
    
    public class Service<T> : IService<T> where T : class
    {
        private readonly IRepository<T> _repository;
    
        public Service(IRepository<T> repository)
        {
            _repository = repository;
        }
    
        public async Task<List<T>> GetAll()
        {
            return await _repository.GetAll();
        }
    
        public async Task<T> Get(int id)
        {
            return await _repository.Get(id);
        }
    
        public async Task Update(int id, T entity)
        {
            await _repository.Update(id, entity);
        }
    
        public async Task<T> Add(T entity)
        {
            return await _repository.Add(entity);
        }
    
        public async Task Delete(int id)
        {
            await _repository.Delete(id);
        }
    }
"@    

    New-Item -Path "$p_strProjectFolder/Services" -ItemType Directory
    New-Item -Path "$p_strProjectFolder/Services/GenericService.cs" -ItemType "file" -Value $strContent
}

# ---------------------------------------------------------------------------

function Add-GenericControllerFile
{    
    param 
    (
        [string]$p_strProjectName
        ,[string]$p_strProjectFolder
    )

    $strContent = @"
    using Microsoft.AspNetCore.Mvc;
    using $p_strProjectName.Services;
    
    namespace $p_strProjectName.Controllers;
    
    public class GenericController<T> : ControllerBase where T : class
    {
        protected readonly IService<T> _service;
    
        public GenericController(IService<T> service)
        {
            _service = service;
        }
    
        [HttpGet]
        public virtual async Task<IActionResult> GetAll()
        {
            var entities = await _service.GetAll();
            return Ok(entities);
        }
    
        [HttpGet("{id}")]
        public virtual async Task<IActionResult> Get(int id)
        {
            var entity = await _service.Get(id);
            if (entity == null)
            {
                return NotFound();
            }
            return Ok(entity);
        }
    
        [HttpPost]
        public virtual async Task<IActionResult> Add(T entity)
        {
            var createdEntity = await _service.Add(entity);
            //return CreatedAtAction(nameof(Get), new { id = createdEntity.Id }, createdEntity);
            return NoContent();
        }
    
        [HttpPut("{id}")]
        public virtual async Task<IActionResult> Update(int id, T entity)
        {
            await _service.Update(id, entity);
            return NoContent();
        }
    
        [HttpDelete("{id}")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            await _service.Delete(id);
            return NoContent();
        }
    }
"@
    New-Item -Path "$p_strProjectFolder/Controllers" -ItemType Directory
    New-Item -Path "$p_strProjectFolder/Controllers/GenericController.cs" -ItemType "file" -Value $strContent
}

# ---------------------------------------------------------------------------

function Add-ModelSpecificControllerFile
{    
    param 
    (
        [string]$p_strModelName
        ,[string]$p_strProjectName
        ,[string]$p_strProjectFolder
    )

    $strContent = @"    
    using Microsoft.AspNetCore.Mvc;
    using $p_strProjectName.Services;
    using $p_strProjectName.Models;
    
    namespace $p_strProjectName.Controllers;
    
    [ApiController]
    [Route("api/[controller]")]
    
    public class ${p_strModelName}Controller : GenericController<$p_strModelName>
    {
        public ${p_strModelName}Controller(IService<$p_strModelName> service) : base(service)
        {
        }
    }
"@
    New-Item -Path "$p_strProjectFolder/Controllers/${p_strModelName}Controller.cs" -ItemType "file" -Value $strContent
}

# ---------------------------------------------------------------------------

function Add-ModelSpecificPageFile
{    
    param 
    (
        $p_strProjectName
        ,$p_strProjectFolder
        ,$p_strTableName
        ,[PSObject]$p_fieldTable
    )

    # ----- Part 1 -----
    $strContent = @"
@page "/$p_strTableName"
@inject HttpClient Http
@rendermode @(new InteractiveWebAssemblyRenderMode(prerender: false))
@using Microsoft.AspNetCore.Components.QuickGrid
@using $p_strProjectName.Client.Models

@if (_isLoading)
{
    <p>Loading...</p>
}
else
{
    <br /><button class="btn btn-primary" @onclick="AddRecord">Add Record</button><br /><br />

    <QuickGrid Items="@_items.AsQueryable()">
"@
    # ----- /Part 1 -----

    # ----- Part 2 -----
    
    $isFirstRow = $true;

    foreach ($row in $p_fieldTable) {
    
        if ($isFirstRow) {
            $isFirstRow = $false
            continue
        }
        else {
            $strFieldName = $row.Name
            $strContent += @"
        
        <PropertyColumn Property="i => i.$strFieldName" Title="$strFieldName" Sortable="true" />
"@
        }
    }

    $strContent += @"
    
        <TemplateColumn Context="item">
            <button class="btn btn-primary" @onclick="() => OpenDialog(item)">edit</button>
        </TemplateColumn>
    </QuickGrid>
"@
    # ----- /Part 2 -----

    # ----- Part 3 -----
    $strContent += @"


    @if(_showDialog)
    {
    <div>
        <dialog open id="my-dialog">
            <style>
                .form-control {width: 500px;}
                .form-group {margin-bottom: 20px;}
            </style>
            <EditForm Model="@_selectedItem" OnValidSubmit="HandleValidSubmit">

                <DataAnnotationsValidator />
                <ValidationSummary />

"@
    # ----- /Part 3 -----

    $isFirstRow = $true;

    # ----- Part 4 -----
    foreach ($row in $p_fieldTable) {
        $strFieldName = $row.Name
        $strDataType = $row.DataType

        if ($isFirstRow) {
            $isFirstRow = $false
            $strContent += @"

                <input type="hidden" @bind="@_selectedItem.$strFieldName" />

"@
        }
        else {
            $strContent += @"

                <div class="form-group">
                    <label for="$strFieldName">$strFieldName</label>
                    <Input$strDataType id="$strFieldName" @bind-Value="@_selectedItem.$strFieldName" class="form-control" />
                </div>
"@
        }
    }
    # ----- /Part 4 -----

    # ----- Part 5 -----
    $strContent += @"

                <table border="0">
                    <tr>
                        <td>
                            <button type="submit" class="btn btn-primary">Submit</button>
                        </td>
                        <td>
                            <button class="btn btn-secondary" @onclick="() => _showDialog = false">Cancel</button>
                        </td>
                    </tr>
                </table>

            </EditForm>
        </dialog>
    </div>
    }
}
    
@code 
{
    bool _isLoading = true;
    bool _showDialog = false;
    $p_strTableName _selectedItem = new $p_strTableName();
    List<$p_strTableName> _items = new List<$p_strTableName>();

    // ----------------------------------------------------------------------        

    // function to open dialog
    private void OpenDialog($p_strTableName item)
    {
        _selectedItem = item;
        _showDialog = true;
    }

    // ----------------------------------------------------------------------  

    protected override async Task OnInitializedAsync()
    {
        try
        {
            _items = (await Http.GetFromJsonAsync<List<$p_strTableName>>("api/$p_strTableName")) ?? new List<$p_strTableName>();
            _isLoading = false;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            _isLoading = false;
        }
    }

    // ----------------------------------------------------------------------

    private void AddRecord()
    {
        _selectedItem = new();
        _showDialog = true;
    }

    // ----------------------------------------------------------------------

    private async Task HandleValidSubmit()
    {
        try
        {
            HttpResponseMessage response;

            if (_selectedItem.${p_strTableName}ID == 0)
            {
                // It's a new record
                response = await Http.PostAsJsonAsync("api/$p_strTableName", _selectedItem);
            }
            else
            {
                // It's an existing record
                response = await Http.PutAsJsonAsync($"api/$p_strTableName/{_selectedItem.${p_strTableName}ID}", _selectedItem);
            }

            if (response.IsSuccessStatusCode)
            {
                _showDialog = false;
                _items = (await Http.GetFromJsonAsync<List<$p_strTableName>>("api/$p_strTableName")) ?? new List<$p_strTableName>();

                Console.Write("Success!");
            }
            else
            {
                Console.Write("Unsuccessful.");
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
        }
    }

    // ----------------------------------------------------------------------  
}
"@
    # ----- /Part 5 -----
    New-Item -Path "$p_strProjectFolder/Pages/${p_strTableName}Grid.razor" -ItemType "file" -Value $strContent -Force
}

# ---------------------------------------------------------------------------
