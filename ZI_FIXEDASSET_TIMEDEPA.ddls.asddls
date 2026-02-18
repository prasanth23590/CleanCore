@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Fixed Asset Time-Dependent Data - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #TRANSACTIONAL
}
define view entity ZI_FIXEDASSET_TIMEDEPA
  as select from anlz
  
  association to parent ZI_FIXEDASSET as _FixedAsset
    on  $projection.CompanyCode     = _FixedAsset.CompanyCode
    and $projection.AssetMainNumber = _FixedAsset.AssetMainNumber
    and $projection.AssetSubNumber  = _FixedAsset.AssetSubNumber
    
  association [0..1] to I_CostCenter   as _CostCenter
    on $projection.CostCenter = _CostCenter.CostCenter
    
  association [0..1] to I_ProfitCenter as _ProfitCenter
    on $projection.ProfitCenter = _ProfitCenter.ProfitCenter
    
{
  key cast(concat(concat(concat(concat(bukrs, anln1), anln2), bdatu), '') as sysuuid_x16) as TimeDependentUUID,
  key bukrs                                                                                 as CompanyCode,
  key anln1                                                                                 as AssetMainNumber,
  key anln2                                                                                 as AssetSubNumber,
  key bdatu                                                                                 as ValidityStartDate,
  
  // Validity period
      adatu                                                                                 as ValidityEndDate,
  
  // Allocation data
      kostl                                                                                 as CostCenter,
      prctr                                                                                 as ProfitCenter,
      ps_psp_pnr                                                                            as WBSElement,
      aufnr                                                                                 as InternalOrder,
      
  // Location data
      stort                                                                                 as AssetLocation,
      raumn                                                                                 as RoomNumber,
      
  // Responsible person
      answt_drc                                                                             as PersonResponsible,
      
  // Segment
      segment                                                                               as Segment,
      
  // Functional area
      fkber                                                                                 as FunctionalArea,
      
  // Technical fields
      @Semantics.systemDateTime.lastChangedAt: true
      cast('00000000000000' as abp_lastchange_tstmpl)                                       as LocalLastChangedAt,
  
  // Associations
  _FixedAsset,
  _CostCenter,
  _ProfitCenter
}