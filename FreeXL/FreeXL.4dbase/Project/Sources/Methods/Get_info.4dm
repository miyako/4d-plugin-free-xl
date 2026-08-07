//%attributes = {"preemptive":"capable"}
$path:=Get 4D folder:C485(Current resources folder:K5:16)+"test.xls"

//opening the .xls file
//similar to freexl_open(), 
//except that an abbreviated parsing step is performed. 
//This makes it faster, but does not support queries for cell values.
$error:=FreeXL_Open_info($path; $ref)

//querying general information
//FREEXL_CFBF_VER_3 or FREEXL_CFBF_VER_4
$error:=FreeXL_Get_info($ref; FREEXL_CFBF_VERSION; $cfbfVersion)
//FREEXL_CFBF_SECTOR_512 or FREEXL_CFBF_SECTOR_4096
$error:=FreeXL_Get_info($ref; FREEXL_CFBF_SECTOR_SIZE; $sectorSize)
//the total count of FAT entries in the file
$error:=FreeXL_Get_info($ref; FREEXL_CFBF_FAT_COUNT; $fatCount)
//one of FREEXL_BIFF_VER_2, FREEXL_BIFF_VER_3, FREEXL_BIFF_VER_4, FREEXL_BIFF_VER_5, FREEXL_BIFF_VER_8
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_VERSION; $biffVersion)
//FREEXL_BIFF_MAX_RECSZ_2080 or FREEXL_BIFF_MAX_RECSZ_8224
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_MAX_RECSIZE; $maxSize)
//FREEXL_BIFF_DATEMODE_1900orFREEXL_BIFF_DATEMODE_1904
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_DATEMODE; $dateMode)
//FREEXL_BIFF_OBFUSCATED or FREEXL_BIFF_PLAIN
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_PASSWORD; $password)
//FREEXL_BIFF_ASCII, code page no., FREEXL_BIFF_UTF16LE or FREEXL_BIFF_MACROMAN
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_CODEPAGE; $codepage)
//the total number of worksheets
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_SHEET_COUNT; $sheetCount)
//the total number of Single String Table entries
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_STRING_COUNT; $stringCount)
//the total number of format entries)
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_FORMAT_COUNT; $formatCount)
//the number of extended format entries
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_XF_COUNT; $xfCount)
//close
$error:=FreeXL_Close($ref)