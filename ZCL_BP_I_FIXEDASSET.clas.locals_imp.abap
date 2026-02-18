***********************************************************************
* Behavior Implementation for Fixed Asset Creation
***********************************************************************
CLASS lhc_fixedasset DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE fixedasset.

    METHODS validatecompanycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR fixedasset~validatecompanycode.

    METHODS validateassetclass FOR VALIDATE ON SAVE
      IMPORTING keys FOR fixedasset~validateassetclass.

    METHODS validateplant FOR VALIDATE ON SAVE
      IMPORTING keys FOR fixedasset~validateplant.

    METHODS validateassetdescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR fixedasset~validateassetdescription.

    METHODS determineassetnumber FOR DETERMINE ON MODIFY
      IMPORTING keys FOR fixedasset~determineassetnumber.

    METHODS determinedefaultvalues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR fixedasset~determinedefaultvalues.

    METHODS calculateuuid FOR DETERMINE ON SAVE
      IMPORTING keys FOR fixedasset~calculateuuid.

    METHODS copyfromreference FOR MODIFY
      IMPORTING keys FOR ACTION fixedasset~copyfromreference RESULT result.

    METHODS postcapitalization FOR MODIFY
      IMPORTING keys FOR ACTION fixedasset~postcapitalization RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR fixedasset RESULT result.

ENDCLASS.

CLASS lhc_fixedasset IMPLEMENTATION.

  METHOD earlynumbering_create.
    " Generate asset main numbers for new assets
    
    DATA: number_range_key TYPE cl_numberrange_runtime=>nr_key,
          next_number      TYPE anln1.

    " Read entities that need numbering
    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( CompanyCode AssetMainNumber ) WITH CORRESPONDING #( entities )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>) WHERE AssetMainNumber IS INITIAL.

      TRY.
          " Get next asset number from number range
          number_range_key = VALUE #(
            object    = 'ANLN1'
            subobject = <asset>-CompanyCode
          ).

          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_key = number_range_key
            IMPORTING
              number       = next_number
          ).

          " Update the entity with the new number
          APPEND VALUE #(
            %cid            = <asset>-%cid
            assetmainnumber = next_number
          ) TO mapped-fixedasset.

        CATCH cx_number_ranges INTO DATA(number_range_error).
          " Report error
          APPEND VALUE #(
            %cid = <asset>-%cid
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = |Number range error: { number_range_error->get_text( ) }|
            )
          ) TO reported-fixedasset.

          APPEND VALUE #( %cid = <asset>-%cid ) TO failed-fixedasset.
      ENDTRY.

    ENDLOOP.

  ENDMETHOD.

  METHOD validatecompanycode.
    " Validate company code exists using released API

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( CompanyCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>).

      " Check if company code exists in I_CompanyCode
      SELECT SINGLE FROM i_companycode
        FIELDS companycode
        WHERE companycode = @<asset>-CompanyCode
        INTO @DATA(company_code_check).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <asset>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Company code { <asset>-CompanyCode } does not exist or is not active|
          )
          %element-companycode = if_abap_behv=>mk-on
        ) TO reported-fixedasset.

        APPEND VALUE #( %tky = <asset>-%tky ) TO failed-fixedasset.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateassetclass.
    " Validate asset class exists and is valid for the company code

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( CompanyCode AssetClass ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>) WHERE AssetClass IS NOT INITIAL.

      " Check if asset class exists in I_AssetClass
      SELECT SINGLE FROM i_assetclass
        FIELDS assetclass
        WHERE assetclass = @<asset>-AssetClass
        INTO @DATA(asset_class_check).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <asset>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Asset class { <asset>-AssetClass } does not exist|
          )
          %element-assetclass = if_abap_behv=>mk-on
        ) TO reported-fixedasset.

        APPEND VALUE #( %tky = <asset>-%tky ) TO failed-fixedasset.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateplant.
    " Validate plant if specified

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( Plant CompanyCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>) WHERE Plant IS NOT INITIAL.

      " Check if plant exists in I_Plant
      SELECT SINGLE FROM i_plant
        FIELDS plant
        WHERE plant = @<asset>-Plant
        INTO @DATA(plant_check).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <asset>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Plant { <asset>-Plant } does not exist|
          )
          %element-plant = if_abap_behv=>mk-on
        ) TO reported-fixedasset.

        APPEND VALUE #( %tky = <asset>-%tky ) TO failed-fixedasset.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateassetdescription.
    " Validate asset description is not empty

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( AssetDescription ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>) WHERE AssetDescription IS INITIAL.

      APPEND VALUE #(
        %tky = <asset>-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Asset description is required'
        )
        %element-assetdescription = if_abap_behv=>mk-on
      ) TO reported-fixedasset.

      APPEND VALUE #( %tky = <asset>-%tky ) TO failed-fixedasset.

    ENDLOOP.

  ENDMETHOD.

  METHOD determineassetnumber.
    " Already handled in early numbering
    " This method can be used for additional number determination logic
  ENDMETHOD.

  METHOD determinedefaultvalues.
    " Determine default values from asset class master data

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( AssetClass ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    " Read asset class configuration to populate defaults
    " This could include default depreciation areas, useful life, etc.
    " Implementation depends on available released APIs

  ENDMETHOD.

  METHOD calculateuuid.
    " Calculate UUID based on key fields

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( CompanyCode AssetMainNumber AssetSubNumber ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    MODIFY ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        UPDATE FIELDS ( AssetUUID )
        WITH VALUE #( FOR asset IN assets (
          %tky     = asset-%tky
          AssetUUID = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        ) ).

  ENDMETHOD.

  METHOD copyfromreference.
    " Copy asset data from reference asset
    " This implements the reference parameter logic from original BAPI

    DATA: reference_asset TYPE STRUCTURE FOR READ IMPORT zi_fixedasset.

    " Read the action parameters
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      
      " Read reference asset data (would need parameter structure definition)
      " Copy relevant fields to new asset
      " Implementation depends on specific business requirements
      
    ENDLOOP.

  ENDMETHOD.

  METHOD postcapitalization.
    " Post asset capitalization
    " This implements the postcap logic from original BAPI

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>).
      
      " Implement capitalization posting logic
      " This would typically:
      " 1. Check if capitalization is allowed
      " 2. Update asset status
      " 3. Create accounting document (via released API)
      " 4. Update depreciation start dates
      
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_authorizations.
    " Implement authorization checks

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY fixedasset
        FIELDS ( CompanyCode AssetClass ) WITH CORRESPONDING #( keys )
      RESULT DATA(assets).

    LOOP AT assets ASSIGNING FIELD-SYMBOL(<asset>).
      
      " Check authorization for company code
      AUTHORITY-CHECK OBJECT 'F_ANLA_BUK'
        ID 'BUKRS' FIELD <asset>-CompanyCode
        ID 'ACTVT' FIELD '01'. " Create

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <asset>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |No authorization for company code { <asset>-CompanyCode }|
          )
        ) TO reported-fixedasset.

        APPEND VALUE #( %tky = <asset>-%tky ) TO failed-fixedasset.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

***********************************************************************
* Behavior Implementation for Depreciation Areas
***********************************************************************
CLASS lhc_depreciationarea DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validatedepreciationarea FOR VALIDATE ON SAVE
      IMPORTING keys FOR depreciationarea~validatedepreciationarea.

    METHODS validateusefullife FOR VALIDATE ON SAVE
      IMPORTING keys FOR depreciationarea~validateusefullife.

    METHODS validatecapitalizationdate FOR VALIDATE ON SAVE
      IMPORTING keys FOR depreciationarea~validatecapitalizationdate.

    METHODS calculatedepareauuid FOR DETERMINE ON SAVE
      IMPORTING keys FOR depreciationarea~calculatedepareauuid.

ENDCLASS.

CLASS lhc_depreciationarea IMPLEMENTATION.

  METHOD validatedepreciationarea.
    " Validate depreciation area exists

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY depreciationarea
        FIELDS ( DepreciationArea ) WITH CORRESPONDING #( keys )
      RESULT DATA(dep_areas).

    LOOP AT dep_areas ASSIGNING FIELD-SYMBOL(<dep_area>).

      SELECT SINGLE FROM i_depreciationarea
        FIELDS depreciationarea
        WHERE depreciationarea = @<dep_area>-DepreciationArea
        INTO @DATA(dep_area_check).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <dep_area>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Depreciation area { <dep_area>-DepreciationArea } does not exist|
          )
          %element-depreciationarea = if_abap_behv=>mk-on
        ) TO reported-depreciationarea.

        APPEND VALUE #( %tky = <dep_area>-%tky ) TO failed-depreciationarea.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateusefullife.
    " Validate useful life values

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY depreciationarea
        FIELDS ( UsefulLifeYears UsefulLifePeriods ) WITH CORRESPONDING #( keys )
      RESULT DATA(dep_areas).

    LOOP AT dep_areas ASSIGNING FIELD-SYMBOL(<dep_area>).

      IF <dep_area>-UsefulLifeYears <= 0 AND <dep_area>-UsefulLifePeriods <= 0.
        APPEND VALUE #(
          %tky = <dep_area>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Useful life must be greater than zero'
          )
          %element-usefullifeyears = if_abap_behv=>mk-on
        ) TO reported-depreciationarea.

        APPEND VALUE #( %tky = <dep_area>-%tky ) TO failed-depreciationarea.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validatecapitalizationdate.
    " Validate capitalization date is valid

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY depreciationarea
        FIELDS ( AssetCapitalizationDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(dep_areas).

    LOOP AT dep_areas ASSIGNING FIELD-SYMBOL(<dep_area>)
      WHERE AssetCapitalizationDate IS NOT INITIAL.

      " Check date plausibility
      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date   = <dep_area>-AssetCapitalizationDate
        EXCEPTIONS
          OTHERS = 1.

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <dep_area>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Invalid capitalization date: { <dep_area>-AssetCapitalizationDate }|
          )
          %element-assetcapitalizationdate = if_abap_behv=>mk-on
        ) TO reported-depreciationarea.

        APPEND VALUE #( %tky = <dep_area>-%tky ) TO failed-depreciationarea.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD calculatedepareauuid.
    " Calculate UUID for depreciation area

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY depreciationarea
        FIELDS ( CompanyCode AssetMainNumber AssetSubNumber DepreciationArea )
        WITH CORRESPONDING #( keys )
      RESULT DATA(dep_areas).

    MODIFY ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY depreciationarea
        UPDATE FIELDS ( DepAreaUUID )
        WITH VALUE #( FOR dep_area IN dep_areas (
          %tky       = dep_area-%tky
          DepAreaUUID = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        ) ).

  ENDMETHOD.

ENDCLASS.

***********************************************************************
* Behavior Implementation for Time-Dependent Data
***********************************************************************
CLASS lhc_timedependentdata DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validatevalidityperiod FOR VALIDATE ON SAVE
      IMPORTING keys FOR timedependentdata~validatevalidityperiod.

    METHODS validatecostcenter FOR VALIDATE ON SAVE
      IMPORTING keys FOR timedependentdata~validatecostcenter.

    METHODS calculatetimedependentuuid FOR DETERMINE ON SAVE
      IMPORTING keys FOR timedependentdata~calculatetimedependentuuid.

ENDCLASS.

CLASS lhc_timedependentdata IMPLEMENTATION.

  METHOD validatevalidityperiod.
    " Validate validity period logic

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY timedependentdata
        FIELDS ( ValidityStartDate ValidityEndDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(time_dep_data).

    LOOP AT time_dep_data ASSIGNING FIELD-SYMBOL(<time_dep>)
      WHERE ValidityEndDate IS NOT INITIAL.

      IF <time_dep>-ValidityEndDate < <time_dep>-ValidityStartDate.
        APPEND VALUE #(
          %tky = <time_dep>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'End date cannot be before start date'
          )
          %element-validityenddate = if_abap_behv=>mk-on
        ) TO reported-timedependentdata.

        APPEND VALUE #( %tky = <time_dep>-%tky ) TO failed-timedependentdata.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validatecostcenter.
    " Validate cost center if specified

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY timedependentdata
        FIELDS ( CostCenter ) WITH CORRESPONDING #( keys )
      RESULT DATA(time_dep_data).

    LOOP AT time_dep_data ASSIGNING FIELD-SYMBOL(<time_dep>)
      WHERE CostCenter IS NOT INITIAL.

      SELECT SINGLE FROM i_costcenter
        FIELDS costcenter
        WHERE costcenter = @<time_dep>-CostCenter
        INTO @DATA(cost_center_check).

      IF sy-subrc <> 0.
        APPEND VALUE #(
          %tky = <time_dep>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Cost center { <time_dep>-CostCenter } does not exist|
          )
          %element-costcenter = if_abap_behv=>mk-on
        ) TO reported-timedependentdata.

        APPEND VALUE #( %tky = <time_dep>-%tky ) TO failed-timedependentdata.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD calculatetimedependentuuid.
    " Calculate UUID for time-dependent data

    READ ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY timedependentdata
        FIELDS ( CompanyCode AssetMainNumber AssetSubNumber ValidityStartDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(time_dep_data).

    MODIFY ENTITIES OF zi_fixedasset IN LOCAL MODE
      ENTITY timedependentdata
        UPDATE FIELDS ( TimeDependentUUID )
        WITH VALUE #( FOR time_dep IN time_dep_data (
          %tky             = time_dep-%tky
          TimeDependentUUID = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( )
        ) ).

  ENDMETHOD.

ENDCLASS.