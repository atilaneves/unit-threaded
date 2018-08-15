@echo off
@setlocal

rem Unit tests

rem Regular tests
dub test -q --build=unittest-cov
rem Unthreaded tests
dub run -q -c unittest-unthreaded --build=unittest-cov
rem Light tests
dub run -q -c unittest-light --build=unittest

rem Integration tests

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
