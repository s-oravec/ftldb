@REM
@REM Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
@REM
@REM Licensed under the Apache License, Version 2.0 (the "License");
@REM you may not use this file except in compliance with the License.
@REM You may obtain a copy of the License at
@REM
@REM     http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing, software
@REM distributed under the License is distributed on an "AS IS" BASIS,
@REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM See the License for the specific language governing permissions and
@REM limitations under the License.
@REM

@echo off
if "%~1" == "" goto :usage
if "%~2" == "" goto :usage
if "%~3" == "" goto :usage
if "%~4" == "" goto :usage
if "%~5" == "" goto :usage

set instance_tns_name=%1
set super_user=%2
set super_user_pswd=%3
set ftldb_schema=%4
set ftldb_pswd=%5
set logfile=%~n0_%1_%4.log

set su=%super_user:S=s%
set su=%su:Y=y%
if "%su%" == "sys" set "sys_option=as sysdba"

echo -------------------------------------------
echo ------------ INSTALLING FTLDB -------------
echo -------------------------------------------
echo.
echo Log file: setup\%logfile%

echo.
echo Run SQL*Plus installation script.
sqlplus -L %super_user%/%super_user_pswd%@%instance_tns_name% %sys_option% ^
  @setup/dba_install %ftldb_schema% %ftldb_pswd% setup/%logfile%

if errorlevel 1 goto :failure

echo.
echo Load freemarker.jar classes into database.
call loadjava -user %super_user%/%super_user_pswd%@%instance_tns_name% ^
  -schema %ftldb_schema% ^
  -grant public ^
  -resolve -unresolvedok ^
  -verbose -stdout ^
  java/freemarker.jar ^
  1>> setup\%logfile%

if errorlevel 1 goto :failure

echo.
echo Load ftldb.jar classes into database.
call loadjava -user %super_user%/%super_user_pswd%@%instance_tns_name% ^
  -schema %ftldb_schema% ^
  -grant public ^
  -resolve ^
  -verbose -stdout ^
  java/ftldb.jar ^
  1>> setup\%logfile%

if errorlevel 1 goto :failure

echo.
echo -------------------------------------------
echo --- INSTALLATION COMPLETED SUCCESSFULLY ---
echo -------------------------------------------
exit /B 0

:failure
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!!!!!!!! INSTALLATION FAILED !!!!!!!!!!!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
exit /B 1

:usage
echo Wrong parameters!
echo Proper usage: %~nx0 instance_tns_name super_user super_user_pswd ftldb_schema ftldb_pswd
echo Example: %~nx0 orcl sys manager ftldb ftldb
exit /B 1