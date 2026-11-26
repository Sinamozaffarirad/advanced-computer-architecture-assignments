$ErrorActionPreference = 'Stop'

# The starter reads both memory files at startup and rewrites the data file.
$simulationDir = New-Item -ItemType Directory -Path (
    Join-Path ([IO.Path]::GetTempPath()) ('mips-highlighted-' + [guid]::NewGuid().ToString('N'))
)

Push-Location -LiteralPath $simulationDir.FullName
try {
    @('0' * 32) * 256 | Set-Content -Encoding Ascii instructionmemory.txt
    @('0' * 32) * 512 | Set-Content -Encoding Ascii datamemory.txt

    vlib work
    if ($LASTEXITCODE -ne 0) { throw 'Questa could not create the work library.' }

    $sources = @('ELMNTS1.v', 'cntrlr.v', 'datapath.v', 'mips.v', 'Tb_highlighted.v') |
        ForEach-Object { Join-Path $PSScriptRoot $_ }
    vlog -sv @sources
    if ($LASTEXITCODE -ne 0) { throw 'Questa compilation failed.' }

    vsim -c -l simulation.log tb_highlighted -do 'run -all; quit -f'
    if ($LASTEXITCODE -ne 0 -or
        -not (Select-String -LiteralPath simulation.log -Pattern '^# PASS: \d+ highlighted R-type instruction checks$' -Quiet)) {
        throw "Verification failed. See $($simulationDir.FullName)."
    }
} finally {
    Pop-Location
}
