param(
    [switch]$Docker,
    [Alias("c")]
    [switch]$Clean,
    [Alias("h")]
    [switch]$Help
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Usage {
    Write-Host @"
Usage: .\make.ps1 [OPTIONS]

Build the resume PDF using pdflatex.

Options:
  -Docker     Run the build inside a texlive Docker container
  -Clean, -c  Remove build artifacts
  -Help, -h   Show this help message

Examples:
  .\make.ps1              Build the PDF
  .\make.ps1 -Docker      Build using Docker (no local TeX installation needed)
  .\make.ps1 -Clean       Clean build artifacts
"@
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($Docker) {
    if (Test-Path "/.dockerenv") {
        Write-Error "-Docker cannot be used inside a container."
        exit 1
    }
    $passArgs = @()
    if ($Clean) { $passArgs += "--clean" }
    docker run --rm -v "${ScriptDir}:/workdir" -w /workdir texlive/texlive:latest ./make.sh @passArgs
    exit $LASTEXITCODE
}

if ($Clean) {
    $extensions = @("aux", "fls", "log", "out", "pdf", "synctex.gz", "fdb_latexmk")
    foreach ($ext in $extensions) {
        Remove-Item -Force -ErrorAction SilentlyContinue "$ScriptDir/mycv.$ext"
    }
} else {
    if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
        Write-Error "pdflatex is not available. Try: .\make.ps1 -Docker"
        exit 1
    }
    pdflatex -synctex=1 -interaction=nonstopmode -file-line-error -recorder "$ScriptDir/mycv.tex"
}
