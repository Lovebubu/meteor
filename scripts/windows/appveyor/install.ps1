﻿# Appveyor already sets $PLATFORM to exactly what we don't want, so
# we'll prepend it with 'windows_' if that seems to be the case.
If ($env:PLATFORM -Match '^x86|x64$') {
  $env:PLATFORM = "windows_${env:PLATFORM}"
}

$dirCheckout = (Get-Item $PSScriptRoot).parent.parent.parent.FullName
$meteorBat = Join-Path $dirCheckout 'meteor.bat'

Write-Host "Updating submodules recursively..." -ForegroundColor Magenta
# Appveyor suggests -q flag for 'git submodule...' https://goo.gl/4TFAHm
& git.exe -C "$dirCheckout" submodule -q update --init --recursive

If ($LASTEXITCODE -ne 0) {
  throw "Updating submodules failed."
}

Write-Host "Running 'meteor --get-ready'..." -ForegroundColor Magenta
# By redirecting error to host, we avoid a shocking/false error color,
# since --get-ready and --version can print (anything) to STDERR and
# PowerShell will interpret that as something being terribly wrong.
& "$meteorBat" --get-ready 2>&1 | Write-Host -ForegroundColor Green

If ($LASTEXITCODE -ne 0) {
  throw "Running .\meteor --get-ready failed."
}

# This should no longer be necessary with Meteor 1.6, which will
# automatically install these dependencies when they're not found in the
# dev bundle, but for good measure, we'll install them ahead of time,
# and to also cover Meteor 1.5.
Write-Host "Installing test npm dependencies..." `
  -ForegroundColor Magenta
& "$meteorBat" npm install --prefix "${dirCheckout}\dev_bundle\lib" `
  phantomjs-prebuilt `
  browserstack-webdriver

If ($LASTEXITCODE -ne 0) {
  throw "Installing npm dependencies required for testing has failed."
}
