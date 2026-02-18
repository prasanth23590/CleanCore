@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Fixed Asset - Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #TRANSACTIONAL
}
define root view entity ZI_FIXEDASSET
  as select from anla
  
  // Associations for navigation and value helps
  association [0..1] to I_CompanyCode          as _CompanyCode
    on $projection.CompanyCode = _CompanyCode.CompanyCode
    
  association [0..1] to I_AssetClass           as _AssetClass
    on $projection.AssetClass = _AssetClass.AssetClass
    
  association [0..1] to I_Plant                as _Plant
    on $projection.Plant = _Plant.Plant
    
  association [0..1] to I_BusinessArea         as _BusinessArea
    on $projection.BusinessArea = _BusinessArea.BusinessArea
    
  // Composition: Child entities
  composition [0..*] of ZI_FIXEDASSET_DEPAREA  as _DepreciationAreas
  composition [0..*] of ZI_FIXEDASSET_TIMEDEPA as _TimeDependentData
  
{
  // UUID for draft handling and unique identification
  key cast(concat(concat(bukrs, anln1), anln2) as sysuuid_x16) as AssetUUID,
  
  // Key fields
      bukrs                                                      as CompanyCode,
      anln1                                                      as AssetMainNumber,
      anln2                                                      as AssetSubNumber,
  
  // General master data
      anlkl                                                      as AssetClass,
      txt50                                                      as AssetDescription,
      txt50_lc                                                   as AssetLongText,
      
  // Organizational data
      gsber                                                      as BusinessArea,
      werks                                                      as Plant,
      
  // Quantity information
      menge                                                      as Quantity,
      meins                                                      as UnitOfMeasure,
      
  // Inventory information
      invnr                                                      as InventoryNumber,
      invzu                                                      as LastInventoryDate,
      
  // Status and control fields
      ord41                                                      as AssetIsGroup,
      ord42                                                      as AssetIsLowValueAsset,
      ord43                                                      as AssetIsComplete,
      
  // Acquisition information  
      zugdt                                                      as AcquisitionDate,
      
  // Origin information
      herst                                                      as Manufacturer,
      herld                                                      as CountryOfOrigin,
      typbz                                                      as TypeDesignation,
      
  // Leasing information
      urjah                                                      as LeasingStartYear,
      urpeh                                                      as LeasingStartPeriod,
      
  // Insurance information
      vers                                                       as InsuranceType,
      
  // Real estate information
      eaufn                                                      as LandParcelNumber,
      
  // Administrative fields
      @Semantics.systemDate.createdAt: true
      erdat                                                      as CreationDate,
      @Semantics.user.createdBy: true
      ernam                                                      as CreatedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      aedat                                                      as LastChangedDate,
      @Semantics.user.lastChangedBy: true
      aenam                                                      as LastChangedBy,
      
  // Technical fields for optimistic locking
      @Semantics.systemDateTime.lastChangedAt: true
      cast('00000000000000' as abp_lastchange_tstmpl)            as LocalLastChangedAt,
  
  // Associations
  _CompanyCode,
  _AssetClass,
  _Plant,
  _BusinessArea,
  _DepreciationAreas,
  _TimeDependentData
}