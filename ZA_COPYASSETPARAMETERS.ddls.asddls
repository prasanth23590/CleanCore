@EndUserText.label: 'Copy Asset Parameters'
define abstract entity ZA_CopyAssetParameters
{
  @EndUserText.label: 'Reference Company Code'
  ReferenceCompanyCode : bukrs;
  
  @EndUserText.label: 'Reference Asset Main Number'
  ReferenceAssetMainNumber : anln1;
  
  @EndUserText.label: 'Reference Asset Sub Number'
  ReferenceAssetSubNumber : anln2;
  
  @EndUserText.label: 'Copy Depreciation Areas'
  CopyDepreciationAreas : abap_boolean;
  
  @EndUserText.label: 'Copy Time-Dependent Data'
  CopyTimeDependentData : abap_boolean;
}