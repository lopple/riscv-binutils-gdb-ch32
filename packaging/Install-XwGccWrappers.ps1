param(
    [Parameter(Mandatory = $true)]
    [string] $Prefix,

    [Parameter(Mandatory = $true)]
    [string] $WrapperExe
)

$ErrorActionPreference = 'Stop'

foreach ($tool in @('gcc', 'g++', 'c++')) {
    $path = Join-Path $Prefix "bin\riscv-none-embed-$tool.exe"
    if (Test-Path -LiteralPath $path) {
        $directory = Split-Path -Parent $path
        $fileName = Split-Path -Leaf $path
        $realName = $fileName -replace '\.exe$', '.real.exe'
        $realPath = Join-Path $directory $realName
        if (Test-Path -LiteralPath $realPath) {
            throw "Refusing to overwrite existing wrapper target: $realPath"
        }
        Move-Item -LiteralPath $path -Destination $realPath
        Copy-Item -LiteralPath $WrapperExe -Destination $path
    }
}
