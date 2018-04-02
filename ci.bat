@echo off
@setlocal

pushd %~dp0\integration\issue61
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

pushd %~dp0\integration\issue109
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

pushd %~dp0\integration\issue116
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd
