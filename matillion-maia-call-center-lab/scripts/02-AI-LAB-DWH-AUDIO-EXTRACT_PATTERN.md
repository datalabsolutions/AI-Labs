# Snowflake Stage File Discovery Pattern

## Overview
This pattern is used for extracting file metadata from Snowflake internal stages using the DIRECTORY() function. Ideal for audio files, documents, or any file-based data discovery.

## When to Use
- Discovering files in Snowflake internal stages
- Need file metadata (size, path, extension)
- Filtering files by type/extension
- Building file catalogs for processing

## Architecture Pattern

```yaml
# Component 1: Create Target Table
type: "create-table-v2"
parameters:
  createMethod: "Create If Not Exists"
  # Schema should match DIRECTORY() output + transformations
  columns:
    - ["PRIMARY_KEY", "VARCHAR", "", "", "", "Yes", "No", "", ""]
    - ["RELATIVE_PATH", "VARCHAR", "", "", "", "No", "No", "", ""]
    - ["FILE_CONTENT", "VARIANT", "", "", "", "No", "No", "", ""]  # TO_FILE() result
    - ["FILE_URL", "VARCHAR", "", "", "", "No", "No", "", ""]        # BUILD_STAGE_FILE_URL() result
    - ["SIZE", "NUMBER", "", "", "", "No", "No", "", ""]            # From DIRECTORY()
    - ["FILE_EXTENSION", "VARCHAR", "", "", "", "No", "No", "", ""]  # SPLIT_PART() result

# Component 2: Extract with DIRECTORY()
type: "sql-executor"
parameters:
  sqlScript: |
    TRUNCATE TABLE {target_table};
    
    INSERT INTO {target_table} (
        {primary_key},
        RELATIVE_PATH,
        {file_content_column},
        FILE_URL,
        SIZE,
        FILE_EXTENSION
    )
    SELECT 
        {primary_key_logic} AS {primary_key},
        RELATIVE_PATH,
        TO_FILE('@{stage_name}', RELATIVE_PATH) AS {file_content_column},
        BUILD_STAGE_FILE_URL('@{stage_name}', RELATIVE_PATH) AS FILE_URL,
        SIZE,
        SPLIT_PART(RELATIVE_PATH, '.', -1) AS FILE_EXTENSION
    FROM 
        DIRECTORY('@{stage_name}')
    WHERE 
        {file_filter_conditions};
```

## Template Variables
- `{target_table}`: Full table name (e.g., CALL_CENTER_DB.RAW.AUDIO_FILES)
- `{stage_name}`: Snowflake stage reference (e.g., CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW)
- `{primary_key}`: Primary key column name
- `{primary_key_logic}`: Logic to derive PK (e.g., REPLACE(RELATIVE_PATH, '.mp3', ''))
- `{file_content_column}`: Column name for file content
- `{file_filter_conditions}`: WHERE conditions (e.g., RELATIVE_PATH ILIKE '%.mp3' OR RELATIVE_PATH ILIKE '%.wav')

## Example Implementation
```sql
-- Audio Files Example
TRUNCATE TABLE CALL_CENTER_DB.RAW.AUDIO_FILES;

INSERT INTO CALL_CENTER_DB.RAW.AUDIO_FILES (
    TRANSCRIPT_ID,
    RELATIVE_PATH,
    AUDIO_FILE,
    FILE_URL,
    SIZE,
    FILE_EXTENSION
)
SELECT 
    REPLACE(RELATIVE_PATH, '.mp3', '') AS TRANSCRIPT_ID,
    RELATIVE_PATH,
    TO_FILE('@CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW', RELATIVE_PATH) AS AUDIO_FILE,
    BUILD_STAGE_FILE_URL('@CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW', RELATIVE_PATH) AS FILE_URL,
    SIZE,
    SPLIT_PART(RELATIVE_PATH, '.', -1) AS FILE_EXTENSION
FROM 
    DIRECTORY('@CALL_CENTER_DB.RAW.INT_STAGE_DOC_RAW')
WHERE 
    RELATIVE_PATH ILIKE '%.mp3' 
    OR RELATIVE_PATH ILIKE '%.wav';
```

## Benefits
- **Idempotent**: TRUNCATE + INSERT pattern
- **Efficient**: Single query handles discovery + transformation
- **Snowflake Native**: Uses DIRECTORY(), TO_FILE(), BUILD_STAGE_FILE_URL()
- **Flexible**: Easy to filter by file type/pattern
- **Metadata Rich**: Captures size, path, extension automatically

## Best Practices
- Always use TRUNCATE before INSERT for idempotent operations
- Filter files early in WHERE clause for performance
- Use meaningful primary keys derived from filenames
- Document stage permissions and access requirements
- Test with sample files before full implementation

## When NOT to Use
- External stages (use S3 Load, Azure Blob Load instead)
- Simple file loading without metadata needs
- When files need complex multi-step transformations before cataloging
