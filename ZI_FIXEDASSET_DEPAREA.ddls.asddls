@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Fixed Asset Depreciation Areas - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #TRANSACTIONAL
}
define view entity ZI_FIXEDASSET_DEPAREA
  as select from anlb
  
  association to parent ZI_FIXEDASSET as _FixedAsset
    on  $projection.CompanyCode     = _FixedAsset.CompanyCode
    and $projection.AssetMainNumber = _FixedAsset.AssetMainNumber
    and $projection.AssetSubNumber  = _FixedAsset.AssetSubNumber
    
  association [0..1] to I_DepreciationArea as _DepreciationAreaText
    on $projection.DepreciationArea = _DepreciationAreaText.DepreciationArea
    
{
  key cast(concat(concat(concat(concat(bukrs, anln1), anln2), afaber), '') as sysuuid_x16) as DepAreaUUID,
  key bukrs                                                                                  as CompanyCode,
  key anln1                                                                                  as AssetMainNumber,
  key anln2                                                                                  as AssetSubNumber,
  key afaber                                                                                 as DepreciationArea,
  
  // Useful life information
      ndjar                                                                                  as UsefulLifeYears,
      ndper                                                                                  as UsefulLifePeriods,
      
  // Depreciation key
      afasl                                                                                  as DepreciationKey,
      
  // Scrap value
      answt                                                                                  as ScrapValue,
      
  // Capitalization date
      aktiv                                                                                  as AssetCapitalizationDate,
      
  // Shutdown date
      deakt                                                                                  as AssetShutdownDate,
      
  // Investment support
      invnr                                                                                  as InvestmentSupport,
      
  // Interest calculation
      zinsz                                                                                  as InterestCalculationIndicator,
      
  // Depreciation start date
      afabg                                                                                  as DepreciationStartDate,
      
  // Technical fields
      @Semantics.systemDateTime.lastChangedAt: true
      cast('00000000000000' as abp_lastchange_tstmpl)                                        as LocalLastChangedAt,
  
  // Association
  _FixedAsset,
  _DepreciationAreaText
}