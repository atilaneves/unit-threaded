@echo off
@setlocal
setlocal EnableDelayedExpansion

echo Unit Tests
cd %~dp0\..

echo ""
echo Regular tests
dub test -q --build=unittest-cov
echo Unthreaded tests
dub run -q -c unittest-unthreaded --build=unittest-cov
echo Light tests
dub run -q -c unittest-light --build=unittest

echo ""
echo Integration tests
echo ""

echo Issue 61
pushd tests\integration_tests\issue61
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo Issue 109
pushd tests\integration_tests\issue109
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo runTestsMain
pushd tests\integration_tests\runTestsMain
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

for /D %%D in ("subpackages\*") do (
    REM the autorunner subpackage cannot be tested itself; see tests/integration_tests/autorunner
    if not "%%D" == "subpackages\autorunner" (
        echo %%D
        dub test --root=%%D
        if !errorlevel! neq 0 exit /b !errorlevel!
    )
)
