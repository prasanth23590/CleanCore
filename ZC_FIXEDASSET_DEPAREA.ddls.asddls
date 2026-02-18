@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Fixed Asset Depreciation Areas - Consumption View'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Depreciation Area',
  typeNamePlural: 'Depreciation Areas'
}
define view entity ZC_FIXEDASSET_DEPAREA
  as projection on ZI_FIXEDASSET_DEPAREA
{
  key DepAreaUUID,
  key CompanyCode,
  key AssetMainNumber,
  key AssetSubNumber,
  
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'I_DepreciationArea', element: 'DepreciationArea' }
  }]
  key DepreciationArea,
  
  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  @UI.identification: [{ position: 20 }]
  UsefulLifeYears,
  
  @UI.lineItem: [{ position: 30, importance: #MEDIUM }]
  @UI.identification: [{ position: 30 }]
  UsefulLifePeriods,
  
  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  @UI.identification: [{ position: 40 }]
  DepreciationKey,
  
  @UI.identification: [{ position: 50 }]
  ScrapValue,
  
  @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
  @UI.identification: [{ position: 60 }]
  AssetCapitalizationDate,
  
  @UI.identification: [{ position: 70 }]
  AssetShutdownDate,
  
  @UI.identification: [{ position: 80 }]
  InvestmentSupport,
  
  @UI.identification: [{ position: 90 }]
  InterestCalculationIndicator,
  
  @UI.identification: [{ position: 100 }]
  DepreciationStartDate,
  
  LocalLastChangedAt,
  
  // Association
  _FixedAsset : redirected to parent ZC_FIXEDASSET,
  _DepreciationAreaText
}