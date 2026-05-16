$ErrorActionPreference = "Stop"

$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))

Write-Host ""
Write-Host "=== Upscale local clean ==="
Write-Host "Workspace: $Root"
Write-Host ""
Write-Host "This removes local generated/downloaded files that are ignored by git:"
Write-Host "  ComfyUI_windows_portable"
Write-Host "  models_to_download"
Write-Host "  input, input_batch contents"
Write-Host "  output, output_batch contents"
Write-Host "  logs"
Write-Host "  Python __pycache__ folders"
Write-Host ""

$confirm = Read-Host "Type Y to delete these local files"
if ($confirm -notin @("Y", "y")) {
    Write-Host "Clean cancelled."
    exit 0
}

function Assert-UnderRoot {
    param([Parameter(Mandatory = $true)][string]$Path)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootWithSlash = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootWithSlash, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside workspace: $fullPath"
    }
    return $fullPath
}

function Remove-WorkspaceDir {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $target = Assert-UnderRoot (Join-Path $Root $RelativePath)
    if (Test-Path -LiteralPath $target) {
        Write-Host "Removing $target"
        Remove-Item -LiteralPath $target -Recurse -Force
    }
}

function Clear-WorkspaceDir {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $target = Assert-UnderRoot (Join-Path $Root $RelativePath)
    if (Test-Path -LiteralPath $target) {
        Write-Host "Emptying $target"
        Get-ChildItem -LiteralPath $target -Force | Remove-Item -Recurse -Force
    }
}

Remove-WorkspaceDir "ComfyUI_windows_portable"
Remove-WorkspaceDir "models_to_download"
Clear-WorkspaceDir "input"
Clear-WorkspaceDir "output"
Clear-WorkspaceDir "logs"
Clear-WorkspaceDir "input_batch"
Clear-WorkspaceDir "output_batch"

Get-ChildItem -LiteralPath $Root -Directory -Recurse -Force -Filter "__pycache__" |
    ForEach-Object {
        $target = Assert-UnderRoot $_.FullName
        Write-Host "Removing $target"
        Remove-Item -LiteralPath $target -Recurse -Force
    }

& (Join-Path $Root "scripts\prepare_workspace.bat")
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Clean finished."
