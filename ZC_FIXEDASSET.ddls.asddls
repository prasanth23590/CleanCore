@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Fixed Asset - Consumption View'
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: {
  typeName: 'Fixed Asset',
  typeNamePlural: 'Fixed Assets',
  title: { type: #STANDARD, value: 'AssetDescription' },
  description: { value: 'AssetMainNumber' }
}
define root view entity ZC_FIXEDASSET
  provider contract transactional_query
  as projection on ZI_FIXEDASSET
{
  // UUID
  key AssetUUID,
  
  // Key fields with UI annotations
  @UI.selectionField: [{ position: 10 }]
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'I_CompanyCode', element: 'CompanyCode' }
  }]
  @Search.defaultSearchElement: true
  @Search.ranking: #HIGH
  CompanyCode,
  
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  @Search.defaultSearchElement: true
  @Search.ranking: #HIGH
  AssetMainNumber,
  
  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  @UI.identification: [{ position: 20 }]
  AssetSubNumber,
  
  // General data with UI annotations
  @UI.selectionField: [{ position: 20 }]
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'I_AssetClass', element: 'AssetClass' }
  }]
  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  @UI.identification: [{ position: 30 }]
  @Search.defaultSearchElement: true
  @Search.ranking: #MEDIUM
  AssetClass,
  
  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  @UI.identification: [{ position: 40 }]
  @Search.defaultSearchElement: true
  @Search.fuzzinessThreshold: 0.8
  AssetDescription,
  
  @UI.identification: [{ position: 50 }]
  AssetLongText,
  
  // Organizational data
  @UI.identification: [{ position: 60 }]
  BusinessArea,
  
  @UI.selectionField: [{ position: 30 }]
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'I_Plant', element: 'Plant' }
  }]
  @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
  @UI.identification: [{ position: 70 }]
  Plant,
  
  // Quantity information
  @UI.identification: [{ position: 80 }]
  Quantity,
  
  @UI.identification: [{ position: 90 }]
  UnitOfMeasure,
  
  // Inventory information
  @UI.identification: [{ position: 100 }]
  InventoryNumber,
  
  @UI.identification: [{ position: 110 }]
  LastInventoryDate,
  
  // Status fields
  @UI.identification: [{ position: 120 }]
  AssetIsGroup,
  
  @UI.identification: [{ position: 130 }]
  AssetIsLowValueAsset,
  
  @UI.identification: [{ position: 140 }]
  AssetIsComplete,
  
  // Acquisition information
  @UI.lineItem: [{ position: 60, importance: #MEDIUM }]
  @UI.identification: [{ position: 150 }]
  AcquisitionDate,
  
  // Origin information
  @UI.identification: [{ position: 160 }]
  Manufacturer,
  
  @UI.identification: [{ position: 170 }]
  CountryOfOrigin,
  
  @UI.identification: [{ position: 180 }]
  TypeDesignation,
  
  // Leasing information
  @UI.identification: [{ position: 190 }]
  LeasingStartYear,
  
  @UI.identification: [{ position: 200 }]
  LeasingStartPeriod,
  
  // Insurance information
  @UI.identification: [{ position: 210 }]
  InsuranceType,
  
  // Real estate information
  @UI.identification: [{ position: 220 }]
  LandParcelNumber,
  
  // Administrative fields
  @UI.lineItem: [{ position: 70, importance: #LOW }]
  @UI.identification: [{ position: 230 }]
  CreationDate,
  
  @UI.identification: [{ position: 240 }]
  CreatedBy,
  
  @UI.identification: [{ position: 250 }]
  LastChangedDate,
  
  @UI.identification: [{ position: 260 }]
  LastChangedBy,
  
  LocalLastChangedAt,
  
  // Associations
  _CompanyCode,
  _AssetClass,
  _Plant,
  _BusinessArea,
  _DepreciationAreas : redirected to composition child ZC_FIXEDASSET_DEPAREA,
  _TimeDependentData : redirected to composition child ZC_FIXEDASSET_TIMEDEPA
}