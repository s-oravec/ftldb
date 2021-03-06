@REM
@REM Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
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

set tns_name=%1
set ftldb_schema=%2
set ftldb_pswd=%3
set "logfile=^!%~n0_%1_%2.log"
set "jarfile=^!missing_%1_%2.jar"

echo -------------------------------------------
echo ----------- DEINSTALLING FTLDB ------------
echo -------------------------------------------
echo.
echo Log file: setup\%logfile%

echo.
echo Run SQL*Plus deinstallation script.
sqlplus -L %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
  @setup/usr_uninstall setup/%logfile%

if errorlevel 1 goto :failure

echo.
echo Remove freemarker.jar classes from database.
call dropjava -user %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
  -verbose -stdout ^
  java/freemarker.jar ^
  1>> setup\%logfile%

if errorlevel 1 goto :failure

if exist setup\%jarfile% (
  echo.
  echo Remove autogenerated classes from database.
  call dropjava -user %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
    -verbose -stdout ^
    setup/%jarfile% ^
    1>> setup\%logfile%

  if errorlevel 1 goto :failure
)

echo.
echo Remove ftldb.jar classes from database.
call dropjava -user %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
  -verbose -stdout ^
  java/ftldb.jar ^
  1>> setup\%logfile%

if errorlevel 1 goto :failure

echo.
echo -------------------------------------------
echo -- DEINSTALLATION COMPLETED SUCCESSFULLY --
echo -------------------------------------------
exit /B 0

:failure
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!!!!!!! DEINSTALLATION FAILED !!!!!!!!!!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
exit /B 1

:usage
echo Wrong parameters!
echo Proper usage: %~nx0 ^<tns_name^> ^<ftldb_schema^> ^<ftldb_pswd^>
echo Example: %~nx0 orcl ftldb ftldb
exit /B 1
