4d-plugin-free-xl
==========

A plugin to read data from XLS documents using the FreeXL library.

##Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|🆗|🆗|🆗|🆗|

Commands
---

```
FreeXL_Get_worksheet_name
FreeXL_Get_info
FreeXL_Close
FreeXL_Open_info
FreeXL_Open
FreeXL_Set_active_worksheet
FreeXL_Get_active_worksheet
FreeXL_Worksheet_dimensions
FreeXL_Get_cell_value
```

About
-----
This plugin is a binding of the [FreeXL](https://www.gaia-gis.it/fossil/freexl/index) library.

The focus is on data; complex structures such as pivot tables, fonts, macros, formats are all igonred.

###Update

``FreeXL_Get_cell_value`` now returns the cell value type in ``$7``. The type can be one of the following:

```
FREEXL_CELL_NULL 101
FREEXL_CELL_INT 102
FREEXL_CELL_DOUBLE 103
FREEXL_CELL_TEXT 104
FREEXL_CELL_SST_TEXT 105
FREEXL_CELL_DATE 106
FREEXL_CELL_DATETIME 107
FREEXL_CELL_TIME 108
```

Example
-------
```
$path:=Get 4D folder(Current resources folder)+"tester1.xls"

  //opening the .xls file
  //similar to freexl_open(), 
  //except that an abbreviated parsing step is performed. 
  //This makes it faster, but does not support queries for cell values.
$error:=FreeXL_Open_info ($path;$ref)

  //querying general information
  //FREEXL_CFBF_VER_3 or FREEXL_CFBF_VER_4
$error:=FreeXL_Get_info ($ref;FREEXL_CFBF_VERSION;$cfbfVersion)
  //FREEXL_CFBF_SECTOR_512 or FREEXL_CFBF_SECTOR_4096
$error:=FreeXL_Get_info ($ref;FREEXL_CFBF_SECTOR_SIZE;$sectorSize)
  //the total count of FAT entries in the file
$error:=FreeXL_Get_info ($ref;FREEXL_CFBF_FAT_COUNT;$fatCount)
  //one of FREEXL_BIFF_VER_2, FREEXL_BIFF_VER_3, FREEXL_BIFF_VER_4, FREEXL_BIFF_VER_5, FREEXL_BIFF_VER_8
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_VERSION;$biffVersion)
  //FREEXL_BIFF_MAX_RECSZ_2080 or FREEXL_BIFF_MAX_RECSZ_8224
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_MAX_RECSIZE;$maxSize)
  //FREEXL_BIFF_DATEMODE_1900orFREEXL_BIFF_DATEMODE_1904
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_DATEMODE;$dateMode)
  //FREEXL_BIFF_OBFUSCATED or FREEXL_BIFF_PLAIN
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_PASSWORD;$password)
  //FREEXL_BIFF_ASCII, code page no., FREEXL_BIFF_UTF16LE or FREEXL_BIFF_MACROMAN
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_CODEPAGE;$codepage)
  //the total number of worksheets
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_SHEET_COUNT;$sheetCount)
  //the total number of Single String Table entries
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_STRING_COUNT;$stringCount)
  //the total number of format entries)
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_FORMAT_COUNT;$formatCount)
  //the number of extended format entries
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_XF_COUNT;$xfCount)
  //close
$error:=FreeXL_Close ($ref)
```

```
$path:=Get 4D folder(Current resources folder)+"tester1.xls"

  //opening the .xls file
$error:=FreeXL_Open ($path;$ref)

  //the total number of worksheets
$error:=FreeXL_Get_info ($ref;FREEXL_BIFF_SHEET_COUNT;$sheetCount)
  //names of each worksheet
ARRAY TEXT($names;$sheetCount)
For ($i;1;$sheetCount)
  //start from 1
$error:=FreeXL_Get_worksheet_name ($ref;$i;$names{$i})
End for 

$error:=FreeXL_Set_active_worksheet ($ref;1)

$error:=FreeXL_Worksheet_dimensions ($ref;$rows;$columns)

For ($r;1;$rows)
For ($c;1;$columns)
$error:=FreeXL_Get_cell_value ($ref;$r;$c;$integer;$real;$text)
End for 
End for 

  //close
$error:=FreeXL_Close ($ref)
```
