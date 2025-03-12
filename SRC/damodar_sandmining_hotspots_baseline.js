// Load the Damodar River shapefile
var damodarRiver = ee.FeatureCollection("projects/ed-sayandasgupta97/assets/mrb_rivnets_Q09_10");

// Create a simple buffer around the river instead of generating individual points
var riverBuffer = damodarRiver.geometry().buffer(1000); // 1km buffer around the entire river network

// Load relevant datasets for sandmining hotspot detection
// 1. Landsat imagery for spectral analysis
var startDate = '2023-01-01';
var endDate = '2023-12-31';
var landsat = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
  .filterDate(startDate, endDate)
  .filterBounds(riverBuffer)
  .map(function(image) {
    // Apply scaling factors for Landsat Collection 2
    var opticalBands = image.select(['SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B6', 'SR_B7'])
      .multiply(0.0000275).add(-0.2);
    var thermalBands = image.select(['ST_B10']).multiply(0.00341802).add(149.0);
    return opticalBands.addBands(thermalBands)
      .copyProperties(image, ['system:time_start']);
  });

// 2. Create a cloud-free composite
var composite = landsat.median();

// 3. Calculate indices useful for sandmining detection
var ndwi = composite.normalizedDifference(['SR_B3', 'SR_B5']).rename('NDWI'); // Water Index
var ndvi = composite.normalizedDifference(['SR_B5', 'SR_B4']).rename('NDVI'); // Vegetation Index
var mndwi = composite.normalizedDifference(['SR_B3', 'SR_B6']).rename('MNDWI'); // Modified Water Index
var bsi = composite.expression(
  '((SR_B6 + SR_B4) - (SR_B5 + SR_B2)) / ((SR_B6 + SR_B4) + (SR_B5 + SR_B2))',
  {
    'SR_B2': composite.select('SR_B2'),
    'SR_B4': composite.select('SR_B4'),
    'SR_B5': composite.select('SR_B5'),
    'SR_B6': composite.select('SR_B6')
  }
).rename('BSI'); // Bare Soil Index

// 4. Merge the indices
var indices = ee.Image.cat([ndwi, ndvi, mndwi, bsi]);

// 5. Create a probability model for sandmining detection
// Sand mining typically has: high BSI, low NDVI, moderate-high MNDWI, variable NDWI
var sandminingProbability = ee.Image(1)
  .where(bsi.gt(0.1), 2)  // Higher BSI increases probability
  .where(ndvi.lt(0.2), 3)  // Lower NDVI increases probability
  .where(mndwi.gt(-0.3).and(mndwi.lt(0.3)), 2)  // Moderate MNDWI increases probability
  .where(bsi.gt(0.2).and(ndvi.lt(0.1)), 4)  // Very likely when high BSI and very low NDVI
  .divide(4)  // Normalize to 0-1 range
  .rename('sandmining_probability');

// 6. Clip to river buffer zone
var clippedProbability = sandminingProbability.clip(riverBuffer);

// 7. Create a temporal analysis to detect changes (optional)
// If you have access to historical imagery:
var historicalLandsat = ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
  .filterDate('2018-01-01', '2018-12-31')
  .filterBounds(riverBuffer)
  .map(function(image) {
    var opticalBands = image.select(['SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B6', 'SR_B7'])
      .multiply(0.0000275).add(-0.2);
    return opticalBands.copyProperties(image, ['system:time_start']);
  });

var historicalComposite = historicalLandsat.median();
var historicalBSI = historicalComposite.expression(
  '((SR_B6 + SR_B4) - (SR_B5 + SR_B2)) / ((SR_B6 + SR_B4) + (SR_B5 + SR_B2))',
  {
    'SR_B2': historicalComposite.select('SR_B2'),
    'SR_B4': historicalComposite.select('SR_B4'),
    'SR_B5': historicalComposite.select('SR_B5'),
    'SR_B6': historicalComposite.select('SR_B6')
  }
).rename('historical_BSI');

// Calculate BSI change over time
var bsiChange = bsi.subtract(historicalBSI).rename('BSI_change');
var changeMask = bsiChange.gt(0.1);  // Areas with significant increase in bare soil

// Apply change mask to increase probability where change is detected
var finalProbability = clippedProbability.where(changeMask, clippedProbability.multiply(1.5).clamp(0, 1));

// 8. Find hotspots (areas with highest probability)
var hotspots = finalProbability.gt(0.7);  // Adjust threshold as needed

// Add visualization layers
Map.centerObject(damodarRiver, 8);
Map.addLayer(damodarRiver, {color: 'blue'}, "Damodar River");
Map.addLayer(riverBuffer, {color: 'red', opacity: 0.3}, "River Buffer (1km)");

// Add a false color composite for visual reference
Map.addLayer(
  composite.select(['SR_B5', 'SR_B4', 'SR_B3']),
  {min: 0, max: 0.3, gamma: 1.4},
  'Landsat False Color'
);

// Add probability layer with a color gradient
Map.addLayer(
  finalProbability,
  {
    min: 0,
    max: 1,
    palette: ['green', 'yellow', 'orange', 'red']
  },
  'Sandmining Probability'
);

// Add hotspots layer
Map.addLayer(
  hotspots.updateMask(hotspots),
  {palette: ['FF0000']},
  'Sandmining Hotspots'
);

// Create a legend for the probability map
var legend = ui.Panel({
  style: {
    position: 'bottom-left',
    padding: '8px 15px'
  }
});

var legendTitle = ui.Label({
  value: 'Sandmining Probability',
  style: {
    fontWeight: 'bold',
    fontSize: '16px',
    margin: '0 0 4px 0',
    padding: '0'
  }
});
legend.add(legendTitle);

var makeRow = function(color, name) {
  var colorBox = ui.Label({
    style: {
      backgroundColor: color,
      padding: '8px',
      margin: '0 0 4px 0'
    }
  });
  var description = ui.Label({
    value: name,
    style: {margin: '0 0 4px 6px'}
  });
  return ui.Panel({
    widgets: [colorBox, description],
    layout: ui.Panel.Layout.Flow('horizontal')
  });
};

legend.add(makeRow('green', 'Low (0 - 0.25)'));
legend.add(makeRow('yellow', 'Medium (0.25 - 0.5)'));
legend.add(makeRow('orange', 'High (0.5 - 0.75)'));
legend.add(makeRow('red', 'Very High (0.75 - 1.0)'));

Map.add(legend);

// Export the results
Export.image.toDrive({
  image: finalProbability,
  description: 'Damodar_Sandmining_Probability',
  scale: 30,
  region: riverBuffer,
  maxPixels: 1e9
});

// Export hotspots as vectors for easier sharing
var vectorHotspots = hotspots.updateMask(hotspots).reduceToVectors({
  geometry: riverBuffer,
  scale: 30,
  geometryType: 'polygon',
  eightConnected: true,
  maxPixels: 1e9,
  reducer: ee.Reducer.countEvery()
});

Export.table.toDrive({
  collection: vectorHotspots,
  description: 'Damodar_Sandmining_Hotspots',
  fileFormat: 'SHP'
});