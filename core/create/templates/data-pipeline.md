---
type: data-pipeline
name: {{PIPELINE_NAME}}
version: {{VERSION}}
author: {{AUTHOR}}
description: {{DESCRIPTION}}
sources:
  - {{SOURCE_1}}
  - {{SOURCE_2}}
destinations:
  - {{DESTINATION_1}}
  - {{DESTINATION_2}}
schedule: {{SCHEDULE}}
---

# {{PIPELINE_NAME}}

{{DESCRIPTION}}

## Pipeline Flow

```
┌─────────┐     ┌───────────┐     ┌──────────┐     ┌────────┐
│ EXTRACT │────▶│ TRANSFORM │────▶│ VALIDATE │────▶│  LOAD  │
└─────────┘     └───────────┘     └──────────┐     └────────┘
      │                                      │
      │                                      │
      ▼                                      ▼
{{SOURCE_1}}                          Error Handling
{{SOURCE_2}}                          & Recovery
```

## EXTRACT Mode

### Input Sources
- **Source 1**: {{SOURCE_1}}
  - Format: {{SOURCE_1_FORMAT}}
  - Connection: {{SOURCE_1_CONNECTION}}
  - Authentication: {{SOURCE_1_AUTH}}
  
- **Source 2**: {{SOURCE_2}}
  - Format: {{SOURCE_2_FORMAT}}
  - Connection: {{SOURCE_2_CONNECTION}}
  - Authentication: {{SOURCE_2_AUTH}}

### Extraction Logic
```python
# {{EXTRACT_SCRIPT_PATH}}
def extract_from_{{SOURCE_1_NAME}}():
    """Extract data from {{SOURCE_1}}"""
    {{EXTRACT_LOGIC_1}}

def extract_from_{{SOURCE_2_NAME}}():
    """Extract data from {{SOURCE_2}}"""
    {{EXTRACT_LOGIC_2}}
```

### Extraction Configuration
```yaml
extract:
  batch_size: {{BATCH_SIZE}}
  timeout_seconds: {{EXTRACT_TIMEOUT}}
  retry_attempts: {{RETRY_ATTEMPTS}}
  retry_delay: {{RETRY_DELAY}}
  parallel_extract: {{PARALLEL_EXTRACT}}
```

## TRANSFORM Mode

### Transformation Steps
1. **{{TRANSFORM_STEP_1}}**
   - Purpose: {{TRANSFORM_STEP_1_PURPOSE}}
   - Logic: {{TRANSFORM_STEP_1_LOGIC}}

2. **{{TRANSFORM_STEP_2}}**
   - Purpose: {{TRANSFORM_STEP_2_PURPOSE}}
   - Logic: {{TRANSFORM_STEP_2_LOGIC}}

3. **{{TRANSFORM_STEP_3}}**
   - Purpose: {{TRANSFORM_STEP_3_PURPOSE}}
   - Logic: {{TRANSFORM_STEP_3_LOGIC}}

### Transformation Logic
```python
# {{TRANSFORM_SCRIPT_PATH}}
def transform_{{DATA_ENTITY}}(raw_data):
    """Transform raw data to target format"""
    {{TRANSFORM_LOGIC}}
    return transformed_data
```

### Data Mappings
| Source Field | Target Field | Transformation | Data Type |
|--------------|--------------|----------------|-----------|
| {{SRC_FIELD_1}} | {{TGT_FIELD_1}} | {{XFORM_1}} | {{TYPE_1}} |
| {{SRC_FIELD_2}} | {{TGT_FIELD_2}} | {{XFORM_2}} | {{TYPE_2}} |
| {{SRC_FIELD_3}} | {{TGT_FIELD_3}} | {{XFORM_3}} | {{TYPE_3}} |

## VALIDATE Mode

### Schema Validation
```json
{
  "type": "object",
  "required": [{{REQUIRED_FIELDS}}],
  "properties": {
    "{{FIELD_1}}": {
      "type": "{{FIELD_1_TYPE}}",
      "pattern": "{{FIELD_1_PATTERN}}"
    },
    "{{FIELD_2}}": {
      "type": "{{FIELD_2_TYPE}}",
      "minimum": {{FIELD_2_MIN}},
      "maximum": {{FIELD_2_MAX}}
    }
  }
}
```

### Validation Rules
- **Rule 1**: {{VALIDATION_RULE_1}}
  - Severity: {{RULE_1_SEVERITY}}
  - Action on failure: {{RULE_1_ACTION}}

- **Rule 2**: {{VALIDATION_RULE_2}}
  - Severity: {{RULE_2_SEVERITY}}
  - Action on failure: {{RULE_2_ACTION}}

- **Rule 3**: {{VALIDATION_RULE_3}}
  - Severity: {{RULE_3_SEVERITY}}
  - Action on failure: {{RULE_3_ACTION}}

### Validation Results
```python
validation_summary = {
    "total_records": {{TOTAL_RECORDS}},
    "passed": {{PASSED_COUNT}},
    "failed": {{FAILED_COUNT}},
    "pass_rate": {{PASS_RATE}},
    "errors": [{{VALIDATION_ERRORS}}]
}
```

## LOAD Mode

### Output Destinations
- **Destination 1**: {{DESTINATION_1}}
  - Format: {{DEST_1_FORMAT}}
  - Connection: {{DEST_1_CONNECTION}}
  - Write Mode: {{DEST_1_WRITE_MODE}}
  
- **Destination 2**: {{DESTINATION_2}}
  - Format: {{DEST_2_FORMAT}}
  - Connection: {{DEST_2_CONNECTION}}
  - Write Mode: {{DEST_2_WRITE_MODE}}

### Loading Logic
```python
# {{LOAD_SCRIPT_PATH}}
def load_to_{{DEST_1_NAME}}(validated_data):
    """Load data to {{DESTINATION_1}}"""
    {{LOAD_LOGIC_1}}

def load_to_{{DEST_2_NAME}}(validated_data):
    """Load data to {{DESTINATION_2}}"""
    {{LOAD_LOGIC_2}}
```

### Load Configuration
```yaml
load:
  batch_size: {{LOAD_BATCH_SIZE}}
  write_mode: {{WRITE_MODE}}  # append, overwrite, merge
  partition_by: [{{PARTITION_COLUMNS}}]
  sort_by: [{{SORT_COLUMNS}}]
  timeout_seconds: {{LOAD_TIMEOUT}}
```

## Quality Gates

### Data Quality Metrics
| Metric | Threshold | Current | Status |
|--------|-----------|---------|--------|
| Completeness | {{COMPLETENESS_THRESHOLD}}% | {{COMPLETENESS_CURRENT}}% | {{COMPLETENESS_STATUS}} |
| Accuracy | {{ACCURACY_THRESHOLD}}% | {{ACCURACY_CURRENT}}% | {{ACCURACY_STATUS}} |
| Consistency | {{CONSISTENCY_THRESHOLD}}% | {{CONSISTENCY_CURRENT}}% | {{CONSISTENCY_STATUS}} |
| Timeliness | {{TIMELINESS_THRESHOLD}} min | {{TIMELINESS_CURRENT}} min | {{TIMELINESS_STATUS}} |

### Processing Speed Metrics
| Metric | SLA | Current | Status |
|--------|-----|---------|--------|
| Records/Second | {{RPS_SLA}} | {{RPS_CURRENT}} | {{RPS_STATUS}} |
| Total Duration | {{DURATION_SLA}} min | {{DURATION_CURRENT}} min | {{DURATION_STATUS}} |
| Latency (p95) | {{LATENCY_SLA}} ms | {{LATENCY_CURRENT}} ms | {{LATENCY_STATUS}} |

### Error Rate Metrics
| Metric | Threshold | Current | Status |
|--------|-----------|---------|--------|
| Extraction Errors | {{EXTRACT_ERROR_THRESHOLD}}% | {{EXTRACT_ERROR_CURRENT}}% | {{EXTRACT_ERROR_STATUS}} |
| Transformation Errors | {{TRANSFORM_ERROR_THRESHOLD}}% | {{TRANSFORM_ERROR_CURRENT}}% | {{TRANSFORM_ERROR_STATUS}} |
| Validation Failures | {{VALIDATION_THRESHOLD}}% | {{VALIDATION_CURRENT}}% | {{VALIDATION_STATUS}} |
| Load Errors | {{LOAD_ERROR_THRESHOLD}}% | {{LOAD_ERROR_CURRENT}}% | {{LOAD_ERROR_STATUS}} |

### Quality Gate Actions
- **PASS**: {{PASS_ACTION}}
- **WARNING**: {{WARNING_ACTION}}
- **FAIL**: {{FAIL_ACTION}}

## Security Baseline

### Data Protection
- **PII Handling**: No PII is logged to plaintext logs
  - PII fields identified: [{{PII_FIELDS}}]
  - Masking strategy: {{PII_MASKING_STRATEGY}}
  - Encryption at rest: {{ENCRYPTION_AT_REST}}
  - Encryption in transit: {{ENCRYPTION_IN_TRANSIT}}

- **Data Classification**: {{DATA_CLASSIFICATION}}
  - Access controls: {{ACCESS_CONTROLS}}
  - Retention policy: {{RETENTION_POLICY}}

### Data Integrity
- **Checksums**: {{CHECKSUM_ALGORITHM}} for data validation
- **Audit Trail**: All transformations logged to {{AUDIT_LOG_DESTINATION}}
- **Lineage Tracking**: Data lineage tracked from source to destination
- **Rollback Capability**: Can rollback to {{ROLLBACK_POINT}}

### Security Checklist
- [ ] No hardcoded credentials in code
- [ ] Secrets stored in {{SECRET_STORE}}
- [ ] Database credentials use {{CREDENTIAL_ROTATION_POLICY}}
- [ ] Network access restricted to {{ALLOWED_NETWORKS}}
- [ ] Data encrypted using {{ENCRYPTION_STANDARD}}
- [ ] Access logs sent to {{SECURITY_MONITORING}}

## Error Handling

### Error Types
| Error Code | Description | Action | Retry |
|------------|-------------|--------|-------|
| E001 | {{ERROR_1_DESC}} | {{ERROR_1_ACTION}} | {{ERROR_1_RETRY}} |
| E002 | {{ERROR_2_DESC}} | {{ERROR_2_ACTION}} | {{ERROR_2_RETRY}} |
| E003 | {{ERROR_3_DESC}} | {{ERROR_3_ACTION}} | {{ERROR_3_RETRY}} |

### Recovery Procedures
1. **Partial Failure**: {{PARTIAL_FAILURE_RECOVERY}}
2. **Complete Failure**: {{COMPLETE_FAILURE_RECOVERY}}
3. **Data Corruption**: {{DATA_CORRUPTION_RECOVERY}}

## Monitoring & Alerting

### Metrics to Track
- {{METRIC_1}}
- {{METRIC_2}}
- {{METRIC_3}}

### Alerts
| Condition | Severity | Notification | Escalation |
|-----------|----------|--------------|------------|
| {{ALERT_1_CONDITION}} | {{ALERT_1_SEVERITY}} | {{ALERT_1_NOTIFY}} | {{ALERT_1_ESCALATION}} |
| {{ALERT_2_CONDITION}} | {{ALERT_2_SEVERITY}} | {{ALERT_2_NOTIFY}} | {{ALERT_2_ESCALATION}} |

## Configuration

### Environment Variables
```bash
export {{ENV_VAR_1}}={{ENV_VAR_1_VALUE}}
export {{ENV_VAR_2}}={{ENV_VAR_2_VALUE}}
export {{ENV_VAR_3}}={{ENV_VAR_3_VALUE}}
```

### Pipeline Parameters
```yaml
pipeline:
  name: {{PIPELINE_NAME}}
  schedule: {{SCHEDULE}}
  timeout: {{PIPELINE_TIMEOUT}}
  max_retries: {{MAX_RETRIES}}
  
resources:
  cpu: {{CPU_LIMIT}}
  memory: {{MEMORY_LIMIT}}
  storage: {{STORAGE_LIMIT}}
```

## Dependencies

### External Systems
- {{DEPENDENCY_1}}
- {{DEPENDENCY_2}}
- {{DEPENDENCY_3}}

### Internal Dependencies
- {{INTERNAL_DEP_1}}
- {{INTERNAL_DEP_2}}

## Testing

### Unit Tests
```bash
{{UNIT_TEST_COMMAND}}
```

### Integration Tests
```bash
{{INTEGRATION_TEST_COMMAND}}
```

### Data Quality Tests
```bash
{{DATA_QUALITY_TEST_COMMAND}}
```

## Deployment

### Deployment Steps
1. {{DEPLOY_STEP_1}}
2. {{DEPLOY_STEP_2}}
3. {{DEPLOY_STEP_3}}

### Rollback Procedure
{{ROLLBACK_PROCEDURE}}

## Runbook

### Manual Execution
```bash
{{MANUAL_RUN_COMMAND}}
```

### Troubleshooting
- **Issue**: {{COMMON_ISSUE_1}}
  - **Symptoms**: {{ISSUE_1_SYMPTOMS}}
  - **Resolution**: {{ISSUE_1_RESOLUTION}}

- **Issue**: {{COMMON_ISSUE_2}}
  - **Symptoms**: {{ISSUE_2_SYMPTOMS}}
  - **Resolution**: {{ISSUE_2_RESOLUTION}}

## Changelog

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| {{VERSION}} | {{DATE}} | {{CHANGES}} | {{AUTHOR}} |
