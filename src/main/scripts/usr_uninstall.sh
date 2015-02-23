#!/bin/sh
#
# Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ $# -lt 5 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
  echo Wrong parameters!
  echo Proper usage: $0 instance_tns_name ftldb_schema ftldb_pswd
  echo Example: $0 orcl ftldb ftldb
  exit 1
fi

instance_tns_name=$1
ftldb_schema=$2
ftldb_pswd=$3
logfile="$(basename $0 .sh)_${1}_${2}.log"

exit_if_failed () {
  if [ "$1" -gt 0 ]; then
    echo
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo !!!!!!!!! DEINSTALLATION FAILED !!!!!!!!!!!
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    exit 1
  fi
}

echo -------------------------------------------
echo ----------- DEINSTALLING FTLDB ------------
echo -------------------------------------------
echo
echo Log file: setup/$logfile

echo
echo Run SQL*Plus deinstallation script.
sqlplus -L $ftldb_schema/$ftldb_pswd@$instance_tns_name \
  @setup/usr_uninstall setup/$logfile

exit_if_failed $?

echo
echo Remove freemarker.jar classes from database.
dropjava -user $ftldb_schema/$ftldb_pswd@$instance_tns_name \
  -verbose -stdout \
  java/freemarker.jar \
  1>> setup/$logfile

exit_if_failed $?

echo
echo Remove ftldb.jar classes from database.
dropjava -user $ftldb_schema/$ftldb_pswd@$instance_tns_name \
  -verbose -stdout \
  java/ftldb.jar \
  1>> setup/$logfile

exit_if_failed $?

echo
echo -------------------------------------------
echo -- DEINSTALLATION COMPLETED SUCCESSFULLY --
echo -------------------------------------------
exit 0