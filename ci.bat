@echo off
@setlocal

pushd %~dp0\integration_tests\issue61
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

pushd %~dp0\integration_tests\issue109
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

pushd %~dp0\integration_tests\issue116
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd
