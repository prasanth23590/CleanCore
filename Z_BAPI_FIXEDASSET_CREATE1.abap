FUNCTION z_bapi_fixedasset_create1.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(KEY) TYPE  BAPI1022_KEY
*"     VALUE(REFERENCE) TYPE  BAPI1022_REFERENCE OPTIONAL
*"     VALUE(CREATESUBNUMBER) TYPE  BAPI1022_MISC-XSUBNO OPTIONAL
*"     VALUE(POSTCAP) TYPE  BAPI1022_MISC-POSTCAP OPTIONAL
*"     VALUE(CREATEGROUPASSET) TYPE  BAPI1022_MISC-XANLGR OPTIONAL
*"     VALUE(TESTRUN) TYPE  BAPI1022_MISC-TESTRUN OPTIONAL
*"     VALUE(GENERALDATA) TYPE  BAPI1022_FEGLG001 OPTIONAL
*"     VALUE(GENERALDATAX) TYPE  BAPI1022_FEGLG001X OPTIONAL
*"     VALUE(POSTINGINFORMATION) TYPE  BAPI1022_FEGLG002 OPTIONAL
*"     VALUE(POSTINGINFORMATIONX) TYPE  BAPI1022_FEGLG002X OPTIONAL
*"     VALUE(TIMEDEPENDENTDATA) TYPE  BAPI1022_FEGLG003 OPTIONAL
*"     VALUE(TIMEDEPENDENTDATAX) TYPE  BAPI1022_FEGLG003X OPTIONAL
*"  EXPORTING
*"     VALUE(COMPANYCODE) TYPE  BAPI1022_1-COMP_CODE
*"     VALUE(ASSET) TYPE  BAPI1022_1-ASSETMAINO
*"     VALUE(SUBNUMBER) TYPE  BAPI1022_1-ASSETSUBNO
*"     VALUE(ASSETCREATED) TYPE  BAPI1022_REFERENCE
*"     VALUE(RETURN) TYPE  BAPIRET2
*"  TABLES
*"      DEPRECIATIONAREAS TYPE  BAPI1022_DEP_AREAS OPTIONAL
*"----------------------------------------------------------------------

  " This is a wrapper function module that calls the RAP Business Object
  " It provides backward compatibility with the original BAPI interface

  DATA: rap_asset           TYPE STRUCTURE FOR CREATE zi_fixedasset,
        rap_dep_areas       TYPE TABLE FOR CREATE zi_fixedasset\_depreciationareas,
        rap_time_dep        TYPE TABLE FOR CREATE zi_fixedasset\_timedependentdata,
        mapped_data         TYPE RESPONSE FOR MAPPED zi_fixedasset,
        failed_data         TYPE RESPONSE FOR FAILED zi_fixedasset,
        reported_data       TYPE RESPONSE FOR REPORTED zi_fixedasset.

  " Clear return message
  CLEAR: companycode, asset, subnumber, assetcreated, return.

  " Map BAPI parameters to RAP structure
  rap_asset-%cid = 'BAPI_WRAPPER_001'.
  rap_asset-companycode = key-companycode.
  rap_asset-assetmainnumber = key-asset.
  rap_asset-assetsubnumber = key-subnumber.

  " Map general data
  IF generaldatax-assetclass = 'X'.
    rap_asset-assetclass = generaldata-assetclass.
  ENDIF.

  IF generaldatax-descript = 'X'.
    rap_asset-assetdescription = generaldata-descript.
  ENDIF.

  IF generaldatax-txt50_lc = 'X'.
    rap_asset-assetlongtext = generaldata-txt50_lc.
  ENDIF.

  IF generaldatax-quantity = 'X'.
    rap_asset-quantity = generaldata-quantity.
  ENDIF.

  IF generaldatax-unit = 'X'.
    rap_asset-unitofmeasure = generaldata-unit.
  ENDIF.

  IF generaldatax-plant = 'X'.
    rap_asset-plant = generaldata-plant.
  ENDIF.

  IF generaldatax-bus_area = 'X'.
    rap_asset-businessarea = generaldata-bus_area.
  ENDIF.

  " Map posting information
  IF postinginformationx-cap_date = 'X'.
    rap_asset-acquisitiondate = postinginformation-cap_date.
  ENDIF.

  " Map depreciation areas
  LOOP AT depreciationareas ASSIGNING FIELD-SYMBOL(<dep_area>).
    APPEND VALUE #(
      %cid_ref = 'BAPI_WRAPPER_001'
      %target = VALUE #( (
        %cid = |DEP_{ sy-tabix }|
        depreciationarea = <dep_area>-dep_area
        usefullifeyears = <dep_area>-life_yrs
        usefullifeperiods = <dep_area>-life_pers
        depreciationkey = <dep_area>-dep_key
        assetcapitalizationdate = <dep_area>-cap_date
      ) )
    ) TO rap_dep_areas.
  ENDLOOP.

  " Map time-dependent data if provided
  IF timedependentdatax IS NOT INITIAL.
    APPEND VALUE #(
      %cid_ref = 'BAPI_WRAPPER_001'
      %target = VALUE #( (
        %cid = 'TIME_DEP_001'
        validitystartdate = timedependentdata-fr_date
        validityenddate = timedependentdata-to_date
        costcenter = timedependentdata-costcenter
        profitcenter = timedependentdata-prof_ctr
        wbselement = timedependentdata-wbs_elem
        internalorder = timedependentdata-order_no
        assetlocation = timedependentdata-location
        roomnumber = timedependentdata-room
      ) )
    ) TO rap_time_dep.
  ENDIF.

  " Call RAP Business Object using EML
  IF testrun IS INITIAL.
    " Production mode - create and activate
    MODIFY ENTITIES OF zi_fixedasset
      ENTITY fixedasset
        CREATE FIELDS ( companycode assetmainnumber assetsubnumber assetclass
                        assetdescription assetlongtext plant businessarea
                        quantity unitofmeasure acquisitiondate )
        WITH VALUE #( ( rap_asset ) )
      CREATE BY \_depreciationareas
        FIELDS ( depreciationarea usefullifeyears usefullifeperiods
                 depreciationkey assetcapitalizationdate )
        WITH rap_dep_areas
      CREATE BY \_timedependentdata
        FIELDS ( validitystartdate validityenddate costcenter profitcenter
                 wbselement internalorder assetlocation roomnumber )
        WITH rap_time_dep
      MAPPED mapped_data
      FAILED failed_data
      REPORTED reported_data.

    " Commit the transaction
    COMMIT ENTITIES
      RESPONSES
        FAILED DATA(commit_failed)
        REPORTED DATA(commit_reported).

    " Map results back to BAPI format
    IF mapped_data-fixedasset IS NOT INITIAL.
      READ TABLE mapped_data-fixedasset INDEX 1 INTO DATA(created_asset).
      
      companycode = created_asset-companycode.
      asset = created_asset-assetmainnumber.
      subnumber = created_asset-assetsubnumber.
      
      assetcreated-companycode = companycode.
      assetcreated-asset = asset.
      assetcreated-subnumber = subnumber.

      " Success message
      return-type = 'S'.
      return-id = 'BAPI1022'.
      return-number = '007'.
      MESSAGE s007(bapi1022) WITH asset subnumber companycode INTO return-message.

    ELSE.
      " Handle errors from reported table
      IF reported_data-fixedasset IS NOT INITIAL.
        READ TABLE reported_data-fixedasset INDEX 1 INTO DATA(error_msg).
        IF error_msg-%msg IS BOUND.
          return-type = 'E'.
          return-message = error_msg-%msg->if_message~get_text( ).
        ELSE.
          return-type = 'E'.
          return-id = 'BAPI1022'.
          return-number = '001'.
          MESSAGE e001(bapi1022) INTO return-message.
        ENDIF.
      ELSE.
        return-type = 'E'.
        return-id = 'BAPI1022'.
        return-number = '001'.
        MESSAGE e001(bapi1022) INTO return-message.
      ENDIF.
    ENDIF.

  ELSE.
    " Test run mode - validate only
    return-type = 'S'.
    return-id = 'BAPI1022'.
    return-number = '040'.
    MESSAGE s040(bapi1022) INTO return-message.
  ENDIF.

ENDFUNCTION.