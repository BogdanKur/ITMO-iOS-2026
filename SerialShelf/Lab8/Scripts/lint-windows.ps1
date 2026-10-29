param([switch]$Json)
$ErrorActionPreference = 'Stop'
$shelfLabPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop is required. The official SwiftLint image runs in Linux containers.'
}
$shelfReporter = if ($Json) { 'json' } else { 'xcode' }
$shelfMount = "type=bind,source=$shelfLabPath,target=/work,readonly"
& docker run --rm --mount $shelfMount --workdir /work --entrypoint swiftlint `
    ghcr.io/realm/swiftlint:0.65.1 lint --strict --no-cache --reporter $shelfReporter
exit $LASTEXITCODE
