# Fixed Asset RAP Business Object - Deployment Guide

## Overview
This guide provides step-by-step instructions for deploying the Fixed Asset RAP Business Object that replaces the legacy BAPI_FIXEDASSET_CREATE1 function module.

---

## Prerequisites

### System Requirements
- S/4HANA Public Cloud or Private Cloud (2023 or later)
- ABAP Development Tools (ADT) Eclipse plugin
- Developer user with necessary authorizations
- Access to development, quality, and production systems

### Required Authorizations
- S_DEVELOP: ABAP development authorization
- S_TABU_DIS: Table maintenance authorization for draft tables
- F_ANLA_BUK: Asset authorization for company codes
- Transport management authorization

---

## Deployment Steps

### Phase 1: Create Draft Tables (Prerequisites)

Before activating the behavior definition, create the required draft tables:

```sql
-- Draft table for root entity
CREATE TABLE zfixedasset_d (
  client TYPE mandt NOT NULL,
  assetuuid TYPE sysuuid_x16 NOT NULL,
  companycode TYPE bukrs,
  assetmainnumber TYPE anln1,
  assetsubnumber TYPE anln2,
  assetclass TYPE anlkl,
  assetdescription TYPE txt50_anlt,
  -- ... other fields from ANLA
  "%admin" TYPE sych_bdl_draft_admin_inc,
  "%is_draft" TYPE  abp_behv_flag,
  PRIMARY KEY client assetuuid
);

-- Draft table for depreciation areas
CREATE TABLE zfixedasset_da_d (
  client TYPE mandt NOT NULL,
  depareauuid TYPE sysuuid_x16 NOT NULL,
  companycode TYPE bukrs,
  assetmainnumber TYPE anln1,
  assetsubnumber TYPE anln2,
  depreciationarea TYPE afaber,
  -- ... other fields from ANLB
  "%admin" TYPE sych_bdl_draft_admin_inc,
  "%is_draft" TYPE abp_behv_flag,
  PRIMARY KEY client depareauuid
);

-- Draft table for time-dependent data
CREATE TABLE zfixedasset_td_d (
  client TYPE mandt NOT NULL,
  timedependentuuid TYPE sysuuid_x16 NOT NULL,
  companycode TYPE bukrs,
  assetmainnumber TYPE anln1,
  assetsubnumber TYPE anln2,
  validitystartdate TYPE bdatu,
  -- ... other fields from ANLZ
  "%admin" TYPE sych_bdl_draft_admin_inc,
  "%is_draft" TYPE abp_behv_flag,
  PRIMARY KEY client timedependentuuid
);
```

### Phase 2: Activate CDS Views (Sequence Matters!)

Activate in this specific order:

1. **Interface Views First:**
   ```
   ZI_FIXEDASSET.ddls.asddls
   ZI_FIXEDASSET_DEPAREA.ddls.asddls
   ZI_FIXEDASSET_TIMEDEPA.ddls.asddls
   ```

2. **Abstract Entity for Actions:**
   ```
   ZA_COPYASSETPARAMETERS.ddls.asddls
   ```

3. **Consumption Views:**
   ```
   ZC_FIXEDASSET.ddls.asddls
   ZC_FIXEDASSET_DEPAREA.ddls.asddls
   ZC_FIXEDASSET_TIMEDEPA.ddls.asddls
   ```

4. **Metadata Extension:**
   ```
   ZC_FIXEDASSET.ddlx.asddlxs
   ```

### Phase 3: Activate Behavior Definition

```
ZBD_I_FIXEDASSET.bdef.asbdef
```

**Common Activation Issues:**
- Ensure draft tables exist
- Verify all field mappings match database table structures
- Check that all validations reference existing methods

### Phase 4: Activate Behavior Implementation

1. **Main Class:**
   ```
   ZCL_BP_I_FIXEDASSET.clas.abap
   ```

2. **Local Implementation:**
   ```
   ZCL_BP_I_FIXEDASSET.clas.locals_imp.abap
   ```

**Testing After Activation:**
```abap
" Test EML in ABAP console
DATA: rap_asset TYPE STRUCTURE FOR CREATE zi_fixedasset.

rap_asset-%cid = 'TEST001'.
rap_asset-companycode = '1000'.
rap_asset-assetclass = '3000'.
rap_asset-assetdescription = 'Test Asset'.

MODIFY ENTITIES OF zi_fixedasset
  ENTITY fixedasset
    CREATE FIELDS ( companycode assetclass assetdescription )
    WITH VALUE #( ( rap_asset ) )
  MAPPED DATA(mapped)
  FAILED DATA(failed)
  REPORTED DATA(reported).

IF failed IS INITIAL.
  COMMIT ENTITIES.
  WRITE: / 'Success:', mapped-fixedasset[ 1 ]-assetmainnumber.
ELSE.
  WRITE: / 'Failed - Check reported table'.
ENDIF.
```

### Phase 5: Activate Service Definition and Binding

1. **Service Definition:**
   ```
   Z_FIXEDASSET_UI.srvd.srvdsrv
   ```

2. **Create Service Binding:**
   - Right-click on Service Definition
   - Select "New Service Binding"
   - Name: `Z_FIXEDASSET_UI_O4`
   - Binding Type: `OData V4 - UI`
   - Click "Publish"

### Phase 6: Activate Authorization (DCL)

```
ZI_FIXEDASSET.dcls.asdcls
```

**Test Authorization:**
```abap
" Test with user having limited company code access
" Verify data restriction works correctly
```

### Phase 7: Deploy Wrapper BAPI (Optional)

For backward compatibility:

```
Z_BAPI_FIXEDASSET_CREATE1.abap
```

**Create Function Module:**
1. SE37 → Create Function Module
2. Copy interface from original BAPI
3. Paste implementation code
4. Activate

**Test Wrapper:**
```abap
DATA: ls_key TYPE bapi1022_key,
      ls_generaldata TYPE bapi1022_feglg001,
      lv_asset TYPE bapi1022_1-assetmaino,
      ls_return TYPE bapiret2.

ls_key-companycode = '1000'.
ls_generaldata-assetclass = '3000'.
ls_generaldata-descript = 'Test via Wrapper'.

CALL FUNCTION 'Z_BAPI_FIXEDASSET_CREATE1'
  EXPORTING
    key          = ls_key
    generaldata  = ls_generaldata
  IMPORTING
    asset        = lv_asset
    return       = ls_return.

WRITE: / 'Asset:', lv_asset, 'Type:', ls_return-type.
```

---

## Post-Deployment Configuration

### 1. IAM App Configuration

Create IAM Business Catalog in Fiori Launchpad:

```
Business Catalog ID: Z_FIXEDASSET_BC
Description: Fixed Asset Creation and Maintenance
Apps:
  - Z_FIXEDASSET_APP (OData Service: Z_FIXEDASSET_UI_O4)
Authorization Objects:
  - F_ANLA_BUK (Company Code)
  - F_ANLA_ART (Asset Class)
  - S_TABU_DIS (Table Authorization)
```

### 2. Assign to Business Roles

```
Business Role: Asset Accountant
Catalogs: Z_FIXEDASSET_BC
Restrictions:
  - Company Code: 1000, 2000 (as per user authorization)
  - Plant: * (all plants authorized for user)
```

### 3. Configure Tile in Fiori Launchpad

```
Tile Configuration:
Title: Create Fixed Asset
Subtitle: Asset Accounting
Icon: sap-icon://product
Target Mapping: Z_FIXEDASSET_APP
```

---

## Testing Strategy

### 1. Unit Tests

Execute ABAP Unit tests:

```
Class: ZCL_BP_I_FIXEDASSET_TEST
Methods:
  - test_create_asset_success
  - test_validate_company_code
  - test_validate_asset_class
  - test_early_numbering
  - test_composition_dep_areas
```

### 2. Integration Tests

| Test Scenario | Steps | Expected Result |
|---------------|-------|-----------------|
| Create Simple Asset | 1. Open Fiori app<br>2. Enter company code, asset class, description<br>3. Save | Asset created with generated number |
| Create with Dep Areas | 1. Create asset<br>2. Add depreciation areas<br>3. Activate | Asset with dep areas created |
| Authorization Test | 1. Login as restricted user<br>2. Try to create asset in unauthorized company code | Error message displayed |
| Draft Functionality | 1. Create asset<br>2. Save as draft<br>3. Resume draft<br>4. Modify<br>5. Activate | Draft workflow works correctly |
| Wrapper BAPI Test | 1. Call Z_BAPI_FIXEDASSET_CREATE1<br>2. Verify asset created via RAP BO | Asset created successfully |

### 3. Performance Tests

```abap
" Test bulk creation performance
DATA: lt_assets TYPE TABLE FOR CREATE zi_fixedasset.

" Create 100 test assets
DO 100 TIMES.
  APPEND VALUE #(
    %cid = |TEST{ sy-index }|
    companycode = '1000'
    assetclass = '3000'
    assetdescription = |Performance Test { sy-index }|
  ) TO lt_assets.
ENDDO.

GET RUN TIME FIELD DATA(lv_start_time).

MODIFY ENTITIES OF zi_fixedasset
  ENTITY fixedasset
    CREATE FIELDS ( companycode assetclass assetdescription )
    WITH lt_assets
  MAPPED DATA(mapped)
  FAILED DATA(failed).

COMMIT ENTITIES.

GET RUN TIME FIELD DATA(lv_end_time).

WRITE: / 'Time:', ( lv_end_time - lv_start_time ) / 1000000, 'seconds'.
WRITE: / 'Created:', lines( mapped-fixedasset ), 'assets'.
WRITE: / 'Failed:', lines( failed-fixedasset ), 'assets'.
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Draft Table Not Found
**Error:** `Draft table ZFIXEDASSET_D does not exist`
**Solution:** Create draft tables before activating behavior definition (see Phase 1)

#### Issue 2: Number Range Not Configured
**Error:** `Number range object ANLN1 not maintained`
**Solution:** 
```
Transaction: SNRO
Object: ANLN1
Subobject: <Company Code>
Configure number range: 100000 - 999999
```

#### Issue 3: Authorization Check Failed
**Error:** `No authorization for company code 1000`
**Solution:** 
- Assign authorization object F_ANLA_BUK to user
- Values: BUKRS = 1000, ACTVT = 01 (Create)

#### Issue 4: CDS View Activation Failed
**Error:** `Field ASSET_UUID not found in database table ANLA`
**Solution:** Modify CDS view to use CONCAT for UUID generation instead of table field

#### Issue 5: Service Binding Not Working
**Error:** `Service cannot be published`
**Solution:**
- Ensure all CDS views are activated
- Check that behavior implementation is active
- Verify service definition syntax

#### Issue 6: Wrapper BAPI Not Creating Assets
**Error:** `Assets not created via wrapper`
**Solution:**
- Check COMMIT ENTITIES is called
- Verify EML syntax
- Enable EML debugging: `SET UPDATE TASK LOCAL`

---

## Migration from Original BAPI

### Phase 1: Parallel Run (Week 1-2)

```abap
" Feature toggle approach
IF sy-uname IN lt_test_users.
  " Use new RAP BO
  MODIFY ENTITIES OF zi_fixedasset ...
ELSE.
  " Use original BAPI
  CALL FUNCTION 'BAPI_FIXEDASSET_CREATE1' ...
ENDIF.
```

### Phase 2: Gradual Migration (Week 3-8)

1. **Week 3-4:** Migrate non-critical programs (reports, interfaces)
2. **Week 5-6:** Migrate medium-priority programs (batch jobs)
3. **Week 7-8:** Migrate critical programs (online transactions)

### Phase 3: Deprecation (Week 9-12)

1. **Week 9:** Switch feature toggle to RAP BO for all users
2. **Week 10-11:** Monitor for issues, provide support
3. **Week 12:** Mark original BAPI as obsolete

### Phase 4: Removal (After 6 months)

1. Remove original BAPI from system
2. Clean up wrapper function module
3. Update documentation

---

## Monitoring and Support

### Key Performance Indicators

```sql
-- Monitor asset creation performance
SELECT 
  COUNT(*) as total_assets,
  AVG( DATS_DAYS_BETWEEN( erdat, current_date ) ) as avg_days_old
FROM anla
WHERE erdat >= @current_date - 30;

-- Monitor draft cleanup
SELECT COUNT(*) as draft_count
FROM zfixedasset_d
WHERE "%is_draft" = 'X';
```

### Support Contacts

| Area | Contact | Email |
|------|---------|-------|
| Technical Issues | ABAP Development Team | dev-team@company.com |
| Functional Issues | Asset Accounting Team | asset-accounting@company.com |
| Authorization | Security Team | security@company.com |
| Performance | Basis Team | basis@company.com |

---

## Rollback Plan

### Emergency Rollback Procedure

If critical issues are discovered:

1. **Immediate Action:**
   ```abap
   " Deactivate service binding
   " Switch feature toggle to original BAPI
   ```

2. **Communicate to Users:**
   - Send notification about rollback
   - Provide timeline for fix

3. **Root Cause Analysis:**
   - Review error logs
   - Analyze failed transactions
   - Identify missing functionality

4. **Fix and Redeploy:**
   - Implement fixes
   - Re-test thoroughly
   - Deploy with monitoring

---

## Success Criteria

### Technical Metrics
- ✅ All CDS views activated without errors
- ✅ Behavior implementation passes all unit tests
- ✅ Service binding published successfully
- ✅ Authorization working correctly
- ✅ Performance within acceptable limits (< 2 seconds per asset)

### Business Metrics
- ✅ 100% functional parity with original BAPI
- ✅ Zero data loss incidents
- ✅ User acceptance rate > 90%
- ✅ Support ticket volume < 5 per week
- ✅ System availability > 99.5%

---

## Appendix

### A. Object Naming Conventions

```
Interface Views: ZI_<BusinessObject>
Consumption Views: ZC_<BusinessObject>
Behavior Definition: ZBD_I_<BusinessObject>
Behavior Implementation: ZCL_BP_I_<BusinessObject>
Service Definition: Z_<BusinessObject>_UI
Service Binding: Z_<BusinessObject>_UI_O4
DCL: ZI_<BusinessObject>.dcls
```

### B. Transport Checklist

```
□ Draft tables created
□ Interface CDS views
□ Consumption CDS views
□ Metadata extensions
□ Behavior definition
□ Behavior implementation class
□ Service definition
□ Service binding configuration
□ DCL authorization file
□ Wrapper BAPI (if needed)
□ Test classes
□ Documentation
```

### C. Go-Live Checklist

```
□ All objects activated in production
□ Service binding published
□ IAM apps configured
□ Business roles assigned
□ Fiori tiles configured
□ Number ranges maintained
□ Authorization objects assigned
□ User training completed
□ Documentation updated
□ Support team briefed
□ Monitoring dashboards configured
□ Backup and rollback plan ready
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-18  
**Next Review:** 2026-03-18