--
-- Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

create table shops (shop_id, name, region) as
select
  rownum,
  'Shop #' || rownum,
  case mod(rownum, 4)
    when 0 then 'east'
    when 1 then 'west'
    when 2 then 'north'
    else 'south'
  end
from dual
connect by level <= 15
/
