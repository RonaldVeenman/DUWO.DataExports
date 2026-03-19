# DUWO Data Exports

**Publisher:** VBS
**Version:** 27.3.260319.0
**Runtime:** 16.0 | **Platform:** 1.0.0.0 | **Application:** 27.0.0.0
**ID Range:** 60300–60310

## Overview

This Business Central extension allows users to configure and export data from any table in the system as CSV files, uploading them directly to Azure Blob Storage. It is designed for DUWO to facilitate bulk data extraction for external reporting or data lake scenarios.

## Components

### Tables

| Object | Name | Purpose |
|--------|------|---------|
| 60300 | Data Export Table Setup | Stores which BC tables are configured for export, with an enabled flag and description. |
| 60301 | Data Export Field Setup | Stores which fields per table are included in the export, capturing field metadata (name, caption, type, FlowField indicator). |

### Pages

| Object | Name | Type | Purpose |
|--------|------|------|---------|
| 60300 | Data Export Table List | List | Main administration page listing all configured export tables. Entry point for the extension (Usage Category: Administration). |
| 60301 | Data Export Table Card | Card | Detail page for a single table setup, showing general info and an embedded field subpage. |
| 60302 | Data Export Field Subpage | ListPart | Editable list of fields belonging to a table export setup. Embedded in the Table Card. |

### Codeunit

| Object | Name | Purpose |
|--------|------|---------|
| 60300 | DUWO Azure Blob Storage Mgt. | Core engine handling Azure Blob Storage connectivity and the CSV export logic. |

### Report

| Object | Name | Purpose |
|--------|------|---------|
| 60300 | DUWO Export Tables | Processing-only report that serves as the user-facing entry point for running exports, collecting Azure connection parameters via a request page. |

## Functionality

### 1. Table & Field Configuration

Users configure which tables and fields to export through the **Data Export Table Setup** pages:

- **Add tables manually** — Select any BC table by number; the table name is resolved automatically.
- **Add HBVG tables in bulk** — An action scans all tables whose name contains "HBVG", adds those that contain data, and auto-populates all their fields.
- **Add all fields** — For any configured table, a single action adds every enabled, non-obsolete field.
- **Enable/Disable** — Tables and fields can be individually or bulk-enabled/disabled to control what is included in exports.
- **Delete** — Selected table configurations (and their associated fields) can be removed.

### 2. CSV Export

The export process (driven by `ExportAllTables` / `ExportTable`) works as follows:

1. **Obsolete-field filtering** — Before exporting, any fields marked as `Removed` or `Pending` obsolete are automatically disabled.
2. **Header row** — A semicolon-delimited header line is written using field captions.
3. **Data rows** — Each record in the table is iterated via `RecordRef`. FlowFields are calculated on the fly. Values are formatted and CSV-escaped (double quotes around values containing `"`, `;`, or newlines).
4. **Progress dialog** — A dialog window shows the current table number, name, and a progress bar during export.
5. **Blob naming** — The resulting CSV is named with a timestamp, company name, table number, and table name (e.g., `20260319_143025.DUWO_18_Customer.csv`), with spaces replaced by underscores.
6. **Upload** — The CSV is uploaded to the configured Azure Blob Storage container.

### 3. Azure Blob Storage Integration

The `DUWO Azure Blob Storage Mgt.` codeunit provides a full Azure Blob Storage client:

| Method | Description |
|--------|-------------|
| `Initialize` | Authenticates using a Storage Account name, SAS token, and container name. Optionally accepts a custom base URL (e.g., for Data Lake Storage `dfs.core.windows.net`). |
| `UploadBlob` | Uploads a stream as a block blob. |
| `DownloadBlob` | Downloads a blob as a stream. |
| `ListBlobs` | Lists all blobs in the configured container. |
| `DeleteBlob` | Deletes a blob by name. |
| `TestConnection` | Tests connectivity by listing containers or blobs and reports the result. |
| `CreateAndUploadTestFile` | Creates and uploads a small test text file to verify the upload pipeline. |

### 4. Running an Export

The **DUWO Export Tables** report (60300) is the main entry point:

1. User opens the report (or clicks **Export All Tables** from the Table List page).
2. A request page collects Azure Blob Storage parameters:
   - **Storage Account Name**
   - **Base URL** (supports `%1` placeholder for the account name; defaults to `https://%1.blob.core.windows.net`)
   - **SAS Token** (masked input)
   - **Container Name**
3. On confirmation, the extension initializes the Azure client and exports all enabled tables sequentially, uploading each as a CSV file.

## Data Flow

```
BC Table Data
    ↓
[RecordRef iteration + FlowField calculation]
    ↓
CSV (semicolon-delimited, UTF-8)
    ↓
Azure Blob Storage (block blob upload via SAS authentication)
```

## Key Design Decisions

- **Dynamic table access** — Uses `RecordRef` / `FieldRef` to export any table without compile-time dependencies.
- **SAS authentication** — Uses Shared Access Signature tokens rather than account keys for scoped, time-limited access.
- **Semicolon delimiter** — CSV files use `;` as the delimiter (common in European/Dutch locale contexts).
- **Automatic obsolete-field handling** — Fields that become obsolete between configuration and export time are gracefully excluded.
- **FlowField support** — FlowFields are explicitly calculated during export to ensure computed values are included.
