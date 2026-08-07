//%attributes = {"preemptive":"capable"}
$path:=Get 4D folder:C485(Current resources folder:K5:16)+"test.xls"

//opening the .xls file
$error:=FreeXL_Open($path; $ref)

//the total number of worksheets
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_SHEET_COUNT; $sheetCount)
//names of each worksheet
ARRAY TEXT:C222($names; $sheetCount)
For ($i; 1; $sheetCount)
	//start from 1
	$error:=FreeXL_Get_worksheet_name($ref; $i; $names{$i})
End for 

$error:=FreeXL_Set_active_worksheet($ref; 1)

$error:=FreeXL_Worksheet_dimensions($ref; $rows; $columns)

For ($r; 1; $rows)
	For ($c; 1; $columns)
		$error:=FreeXL_Get_cell_value($ref; $r; $c; \
			$intValue; \
			$realValue; \
			$textValue; \
			$valueType)
	End for 
End for 

//close
$error:=FreeXL_Close($ref)