![version](https://img.shields.io/badge/version-16%2B-8331AE)
![platform](https://img.shields.io/static/v1?label=platform&message=mac-intel%20|%20mac-arm%20|%20win-64&color=blue)
[![license](https://img.shields.io/github/license/miyako/4d-plugin-free-xl)](LICENSE)
![downloads](https://img.shields.io/github/downloads/miyako/4d-plugin-free-xl/total)

The FreeXL plugin lets 4D read data out of legacy Microsoft Excel `.xls` files (BIFF2 through BIFF8, i.e. Excel 97-2003 and earlier formats) without needing Excel installed. It's a thin wrapper around the open-source [FreeXL](https://www.gaia-gis.it/fossil/freexl) C library: every plugin command maps to one FreeXL function call. You open a workbook to get a numeric handle, use that handle to query worksheet names/metadata and select the active worksheet, then read individual cell values one at a time — text comes back as UTF-8, numbers as either an integer or a real depending on how the cell was stored, and dates/times come back as pre-formatted strings rather than 4D dates.

## Summary

| Command | Returns | Purpose |
|---|---|---|
| [`FreeXL_Open`](#freexl_open) | Long | Open an `.xls` file for full access, including cell values |
| [`FreeXL_Open_info`](#freexl_open_info) | Long | Open an `.xls` file for metadata only (faster, no cell values) |
| [`FreeXL_Close`](#freexl_close) | Long | Close a workbook and release its handle |
| [`FreeXL_Get_info`](#freexl_get_info) | Long | Query workbook/file-format metadata |
| [`FreeXL_Get_worksheet_name`](#freexl_get_worksheet_name) | Long | Get the name of a worksheet by index |
| [`FreeXL_Set_active_worksheet`](#freexl_set_active_worksheet) | Long | Select which worksheet subsequent commands act on |
| [`FreeXL_Get_active_worksheet`](#freexl_get_active_worksheet) | Long | Get the index of the currently active worksheet |
| [`FreeXL_Worksheet_dimensions`](#freexl_worksheet_dimensions) | Long | Get the row/column count of the active worksheet |
| [`FreeXL_Get_cell_value`](#freexl_get_cell_value) | Long | Read one cell's value and type from the active worksheet |

**Platforms:** macOS and Windows (4D itself has no Linux runtime, so there's no Linux build to consider).

---

## Requirements & platform notes

- **All commands are marked `threadSafe: true`** in the plugin's manifest, so they can be called from preemptive 4D processes without being forced onto the main thread. This means the plugin's internal handle table is safe to hit concurrently from multiple processes — but that only covers bookkeeping *inside the plugin*. Avoid calling multiple commands against the **same** `fileRef` from two different processes at the same time (e.g. one process selecting a worksheet while another reads cells); FreeXL's own handle isn't documented as safe for that, so treat one handle as belonging to one process/thread at a time.
- **Every index is 1-based** on the 4D side: worksheet numbers, row numbers, and column numbers all start at 1, even though the underlying FreeXL library is 0-based internally. This is consistent across all nine commands — you never need to adjust for the library's own indexing.
- **`FreeXL_Open_info` cannot be used with `FreeXL_Get_cell_value`.** It performs an abbreviated parse for speed and explicitly does not support cell-value queries. If you need `FreeXL_Get_cell_value`, open the file with `FreeXL_Open` instead.
- **Always pair a successful `FreeXL_Open`/`FreeXL_Open_info` with a `FreeXL_Close`.** If the open call itself fails (non-zero result), there's nothing to close on your side — the plugin releases its internal resources for you in that case, and no handle number is ever returned.
- **A `fileRef` handle is only valid until it's closed.** The plugin reuses small integer numbers for handles as they're opened and closed, so don't hold onto a `fileRef` value after calling `FreeXL_Close` on it — reusing it will fail (or, worse, silently refer to a different, newer workbook if another one happened to get the same number).
- **Cell text and dates/times always come back as UTF-8 text**, never as native 4D dates, times, or numbers with formatting applied. `FreeXL_Get_cell_value`'s `valueType` output tells you which of its output parameters actually holds the value for a given cell — see that command's section below for the full list of type codes.

---

## FreeXL_Open

### Syntax
```4d
FreeXL_Open ( path ; fileRef ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `path` | Text | Full or relative path to the `.xls` file to open |
| `fileRef` | Longint | Receives a handle to use in every subsequent FreeXL command |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
Opens the `.xls` file and performs a full parse, which is required if you're going to call [`FreeXL_Get_cell_value`](#freexl_get_cell_value) later. If the file can't be opened or parsed, `fileRef` is left unset and the result holds the FreeXL error code (see [Error handling](#error-handling--troubleshooting) below for the full code list) — there's no handle for you to close in that case, the plugin already releases any resources FreeXL allocated internally before returning.

### Example
From the plugin's own test method (`Get_cell_data.4dm`):
```4d
//%attributes = {"preemptive":"capable"}
$path:=Get 4D folder:C485(Current resources folder:K5:16)+"test.xls"

//opening the .xls file
$error:=FreeXL_Open($path; $ref)
```

A version that checks the result before continuing:
```4d
$error:=FreeXL_Open($path; $ref)
If ($error=0)
  //... use $ref with the other FreeXL commands
  $error:=FreeXL_Close($ref)
Else
  ALERT("Could not open workbook, FreeXL error "+String($error))
End if 
```

---

## FreeXL_Open_info

### Syntax
```4d
FreeXL_Open_info ( path ; fileRef ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `path` | Text | Full or relative path to the `.xls` file to open |
| `fileRef` | Longint | Receives a handle to use in every subsequent FreeXL command |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
Similar to [`FreeXL_Open`](#freexl_open), except it performs an abbreviated parsing step. This makes it faster, but the resulting handle **does not support** [`FreeXL_Get_cell_value`](#freexl_get_cell_value) — use it when you only need [`FreeXL_Get_info`](#freexl_get_info) / [`FreeXL_Get_worksheet_name`](#freexl_get_worksheet_name)-style metadata and don't need to read actual cell contents. As with `FreeXL_Open`, a failed open leaves no handle for you to close — the plugin releases FreeXL's internal resources on your behalf.

### Example
From the plugin's own test method (`Get_info.4dm`):
```4d
//%attributes = {"preemptive":"capable"}
$path:=Get 4D folder:C485(Current resources folder:K5:16)+"test.xls"

//opening the .xls file
//similar to freexl_open(), 
//except that an abbreviated parsing step is performed. 
//This makes it faster, but does not support queries for cell values.
$error:=FreeXL_Open_info($path; $ref)
```

---

## FreeXL_Close

### Syntax
```4d
FreeXL_Close ( fileRef ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) or [`FreeXL_Open_info`](#freexl_open_info) |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
Closes the workbook and releases everything FreeXL allocated for it. Call this for every handle you successfully opened, exactly once. After this call the handle number is invalid — don't reuse it, and don't call `FreeXL_Close` on it again (a second close call will get `FREEXL_NULL_HANDLE` back, since the plugin's own handle table no longer has an entry for it).

### Example
From both of the plugin's test methods:
```4d
//close
$error:=FreeXL_Close($ref)
```

---

## FreeXL_Get_info

### Syntax
```4d
FreeXL_Get_info ( fileRef ; infoType ; infoValue ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) or [`FreeXL_Open_info`](#freexl_open_info) |
| `infoType` | Longint | Which piece of information to query — see the table below |
| `infoValue` | Longint | Receives the requested value |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

`infoType` must be one of:

| Constant | Value | `infoValue` returns |
|---|---|---|
| `FREEXL_CFBF_VERSION` | 32001 | `3` or `4` (compound-file-binary-format version) |
| `FREEXL_CFBF_SECTOR_SIZE` | 32002 | `512` or `4096` |
| `FREEXL_CFBF_FAT_COUNT` | 32003 | Total count of FAT entries in the file |
| `FREEXL_BIFF_VERSION` | 32005 | `2`, `3`, `4`, `5`, or `8` (BIFF version) |
| `FREEXL_BIFF_MAX_RECSIZE` | 32006 | `2080` or `8224` |
| `FREEXL_BIFF_DATEMODE` | 32007 | `1900` or `1904` (workbook's date epoch) |
| `FREEXL_BIFF_PASSWORD` | 32008 | `3003` (password-protected) or `3004` (plain) |
| `FREEXL_BIFF_CODEPAGE` | 32009 | Code-page constant — ASCII, one of the `CPnnn` codes, UTF-16LE, or Mac Roman |
| `FREEXL_BIFF_SHEET_COUNT` | 32010 | Total number of worksheets |
| `FREEXL_BIFF_STRING_COUNT` | 32011 | Total number of Single String Table (SST) entries |
| `FREEXL_BIFF_FORMAT_COUNT` | 32012 | Total number of format entries |
| `FREEXL_BIFF_XF_COUNT` | 32013 | Number of extended format entries |

These constants aren't predefined in 4D — you'll need to declare them yourself (e.g. as 4D constants or method-local variables) since they come from the underlying C library's header, not from 4D.

### Description
`infoValue` is set to `0` if the requested information isn't available or doesn't apply to this file's format — that's not itself an error; the command result will still be `0` (`FREEXL_OK`). Only a genuine failure (e.g. an invalid `fileRef`, or an unrecognized `infoType`) produces a non-zero result.

### Example
From the plugin's own test method (`Get_info.4dm`), which queries every available `infoType` in one pass:
```4d
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
```

---

## FreeXL_Get_worksheet_name

### Syntax
```4d
FreeXL_Get_worksheet_name ( fileRef ; sheetIndex ; sheetName ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) or [`FreeXL_Open_info`](#freexl_open_info) |
| `sheetIndex` | Longint | Worksheet number, 1-based |
| `sheetName` | Text | Receives the worksheet's name |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
`sheetName` is only written on success; on failure (invalid `fileRef` or `sheetIndex` out of range) it's left untouched, so clear it yourself beforehand if you're looping over indices and checking each result.

### Example
From the plugin's own test method (`Get_info.4dm`), reading every worksheet name into an array:
```4d
//the total number of worksheets
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_SHEET_COUNT; $sheetCount)
//names of each worksheet
ARRAY TEXT:C222($names; $sheetCount)
For ($i; 1; $sheetCount)
  //start from 1
  $error:=FreeXL_Get_worksheet_name($ref; $i; $names{$i})
End for 
```

---

## FreeXL_Set_active_worksheet

### Syntax
```4d
FreeXL_Set_active_worksheet ( fileRef ; sheetIndex ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) or [`FreeXL_Open_info`](#freexl_open_info) |
| `sheetIndex` | Longint | Worksheet number to activate, 1-based |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
Only one worksheet can be active at a time per `fileRef`. [`FreeXL_Worksheet_dimensions`](#freexl_worksheet_dimensions) and [`FreeXL_Get_cell_value`](#freexl_get_cell_value) both implicitly operate on whichever worksheet was most recently activated with this command — there's no per-call worksheet parameter on either of them.

### Example
From the plugin's own test method (`Get_cell_data.4dm`):
```4d
$error:=FreeXL_Set_active_worksheet($ref; 1)
```

---

## FreeXL_Get_active_worksheet

### Syntax
```4d
FreeXL_Get_active_worksheet ( fileRef ; sheetIndex ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) or [`FreeXL_Open_info`](#freexl_open_info) |
| `sheetIndex` | Longint | Receives the 1-based index of the currently active worksheet |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
Companion getter for [`FreeXL_Set_active_worksheet`](#freexl_set_active_worksheet). Useful if you're passing a `fileRef` between methods and need to confirm/restore which worksheet is selected before reading cells.

### Example
```4d
$error:=FreeXL_Set_active_worksheet($ref; 2)
$error:=FreeXL_Get_active_worksheet($ref; $current)
 //$current is now 2
```

---

## FreeXL_Worksheet_dimensions

### Syntax
```4d
FreeXL_Worksheet_dimensions ( fileRef ; rows ; columns ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) or [`FreeXL_Open_info`](#freexl_open_info) |
| `rows` | Longint | Receives the total row count of the active worksheet |
| `columns` | Longint | Receives the total column count of the active worksheet |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

### Description
Operates on whichever worksheet was last selected with [`FreeXL_Set_active_worksheet`](#freexl_set_active_worksheet). `rows`/`columns` are returned as plain counts (e.g. a sheet with data in rows 1-2 and columns 1-4 returns `rows=2`, `columns=4`) — you can use them directly as `For` loop bounds starting at 1, as in the example below, without any further adjustment.

### Example
From the plugin's own test method (`Get_cell_data.4dm`):
```4d
$error:=FreeXL_Worksheet_dimensions($ref; $rows; $columns)
```

---

## FreeXL_Get_cell_value

### Syntax
```4d
FreeXL_Get_cell_value ( fileRef ; row ; column ; intValue ; realValue ; textValue ; valueType ) → Long
```

| Parameter | Type | Description |
|---|---|---|
| `fileRef` | Longint | Handle previously returned by [`FreeXL_Open`](#freexl_open) — **not** [`FreeXL_Open_info`](#freexl_open_info), see below |
| `row` | Longint | Row number, 1-based |
| `column` | Longint | Column number, 1-based |
| `intValue` | Longint | Receives the cell's value if `valueType` is `102` (integer) |
| `realValue` | Real | Receives the cell's value if `valueType` is `103` (floating point) |
| `textValue` | Text | Receives the cell's value if `valueType` is `104`, `105`, `106`, `107`, or `108` (any text/date/time form) |
| `valueType` | Longint | Receives a code identifying which of the three value parameters above actually holds the result |
| Result | Longint | `0` (`FREEXL_OK`) on success, otherwise a FreeXL error code |

`valueType` will be one of:

| Value | Meaning | Where the value is |
|---|---|---|
| `101` | Empty cell | (none — cell has no value) |
| `102` | Integer | `intValue` |
| `103` | Floating point | `realValue` |
| `104` | Text | `textValue` |
| `105` | Text (from the Single String Table, BIFF8 only) | `textValue` |
| `106` | Date, formatted `YYYY-MM-DD` | `textValue` |
| `107` | Date and time, formatted `YYYY-MM-DD HH:MM:SS` | `textValue` |
| `108` | Time, formatted `HH:MM:SS` | `textValue` |

### Description
This command requires a handle opened with [`FreeXL_Open`](#freexl_open); a handle from `FreeXL_Open_info` will fail here because that command's abbreviated parse doesn't retain the data this needs. It operates on whichever worksheet was last selected with [`FreeXL_Set_active_worksheet`](#freexl_set_active_worksheet) — there's no worksheet parameter here.

Only the output parameter indicated by `valueType` is meaningful for a given call; the other two are left at their default (empty/zero) value. Dates and times are never returned as native 4D dates/times — they come back pre-formatted as text in `textValue`, so convert them yourself (e.g. with `Date` or a string-parsing method) if you need a real 4D date. Cell rows/columns that are outside the worksheet's actual data range, or a worksheet that was never selected with `FreeXL_Set_active_worksheet`, will come back as a non-zero result rather than an empty cell — check the result code, don't rely on `valueType` alone to detect an out-of-range read.

### Example
From the plugin's own test method (`Get_cell_data.4dm`), reading every cell in the active worksheet:
```4d
For ($r; 1; $rows)
  For ($c; 1; $columns)
    $error:=FreeXL_Get_cell_value($ref; $r; $c; \
      $intValue; \
      $realValue; \
      $textValue; \
      $valueType)
  End for 
End for 
```

A version that branches on `valueType` to build a single display value:
```4d
$error:=FreeXL_Get_cell_value($ref; $r; $c; $intValue; $realValue; $textValue; $valueType)
Case of 
  : ($valueType=102)
    $display:=String($intValue)
  : ($valueType=103)
    $display:=String($realValue)
  : (($valueType>=104) & ($valueType<=108))
    $display:=$textValue
  Else 
    $display:=""  //empty cell (101), or the call failed
End case 
```

---

## Error handling & troubleshooting

- **A non-zero result is always a FreeXL error code, not a 4D error** — none of these commands raise a 4D interpreted error; check the returned Long explicitly after every call. The most common codes you'll see:

  | Code | Constant | Meaning |
  |---|---|---|
  | `-1` | `FREEXL_FILE_NOT_FOUND` | The `.xls` path doesn't exist or isn't readable |
  | `-2` | `FREEXL_NULL_HANDLE` | `fileRef` is `0`/unset, or refers to a handle that was already closed |
  | `-3` | `FREEXL_INVALID_HANDLE` | `fileRef` doesn't correspond to any open handle |
  | `-4` | `FREEXL_INSUFFICIENT_MEMORY` | Memory allocation failure inside the library |
  | `-6` | `FREEXL_INVALID_INFO_ARG` | `infoType` passed to [`FreeXL_Get_info`](#freexl_get_info) isn't one of the documented constants |
  | `-18` | `FREEXL_BIFF_ILLEGAL_SHEET_INDEX` | `sheetIndex` is out of range for the workbook |
  | `-19` | `FREEXL_BIFF_UNSELECTED_SHEET` | No worksheet has been activated yet — call [`FreeXL_Set_active_worksheet`](#freexl_set_active_worksheet) first |
  | `-22` | `FREEXL_ILLEGAL_CELL_ROW_COL` | `row`/`column` passed to [`FreeXL_Get_cell_value`](#freexl_get_cell_value) is outside the worksheet's range |

  Several other codes (`-7` through `-25`) indicate a corrupt or malformed `.xls` file rather than a usage mistake on the calling side — if you see one of those on a file that opens fine in Excel, it's worth trying `FreeXL_Open` again on a re-saved copy of the file before assuming a plugin bug.

- **`FreeXL_Get_cell_value` returning `FREEXL_BIFF_UNSELECTED_SHEET` (`-19`) even right after `FreeXL_Open`:** you must call [`FreeXL_Set_active_worksheet`](#freexl_set_active_worksheet) at least once before reading cells — opening a workbook doesn't select a worksheet automatically.

- **`FreeXL_Get_cell_value` always failing on a handle that works fine for `FreeXL_Get_info`/`FreeXL_Get_worksheet_name`:** that handle was almost certainly opened with [`FreeXL_Open_info`](#freexl_open_info) rather than [`FreeXL_Open`](#freexl_open) — re-open the file with `FreeXL_Open` if you need cell values.

- **A `fileRef` stops working partway through a method with no obvious cause:** check whether another process/method closed the same `fileRef`, or whether you're holding onto a handle number after calling `FreeXL_Close` on it — handle numbers get reused for the next file opened after a close.

- **Worksheet names or cell text come back empty on a call that otherwise reports success (result `0`):** unlikely, but if it happens, treat it as a signal the underlying `.xls` file's internal string table is malformed rather than a calling mistake — the plugin passes through exactly what FreeXL decodes.

---

## Quick reference

```4d
//open + list worksheets
$error:=FreeXL_Open_info($path; $ref)
$error:=FreeXL_Get_info($ref; FREEXL_BIFF_SHEET_COUNT; $sheetCount)
ARRAY TEXT:C222($names; $sheetCount)
For ($i; 1; $sheetCount)
  $error:=FreeXL_Get_worksheet_name($ref; $i; $names{$i})
End for 
$error:=FreeXL_Close($ref)

//open + read every cell of worksheet 1
$error:=FreeXL_Open($path; $ref)
$error:=FreeXL_Set_active_worksheet($ref; 1)
$error:=FreeXL_Worksheet_dimensions($ref; $rows; $columns)
For ($r; 1; $rows)
  For ($c; 1; $columns)
    $error:=FreeXL_Get_cell_value($ref; $r; $c; $intValue; $realValue; $textValue; $valueType)
  End for 
End for 
$error:=FreeXL_Close($ref)
```
