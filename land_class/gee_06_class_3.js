// 1. Define training polygons as a FeatureCollection with a 'class' property.
// (Alternatively, draw polygons in the Code Editor and set a 'class' property.)
var polygons = ee.FeatureCollection([
  ee.Feature(
    ee.Geometry.Polygon([[[-3.21, 55.94], [-3.20, 55.94], [-3.20, 55.93], [-3.21, 55.93]]]),
    {'class': 0} // e.g., Non-forest / Urban
  ),
  ee.Feature(
    ee.Geometry.Polygon([[[-3.25, 55.95], [-3.24, 55.95], [-3.24, 55.94], [-3.25, 55.94]]]),
    {'class': 1} // e.g., Vegetation / Forest
  )
]);

// 2. Load Sentinel-2 surface reflectance imagery and create a median composite.
var bands = ['B2', 'B3', 'B4', 'B8'];
var image = ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
  .filterBounds(polygons.geometry().bounds())
  .filterDate('2024-05-01', '2024-08-31')
  .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20))
  .select(bands)
  .median();

// 3. Extract pixel values inside the training polygons at 10m scale.
var training = image.sampleRegions({
  collection: polygons,
  properties: ['class'],
  scale: 10
});

// 4. Train a Random Forest classifier and classify the image.
var classifier = ee.Classifier.smileRandomForest(50)
  .train({
    features: training,
    classProperty: 'class',
    inputProperties: bands
  });

var classified = image.classify(classifier);

// 5. Display results on the map.
Map.centerObject(polygons, 12);
Map.addLayer(image, {bands: ['B4', 'B3', 'B2'], min: 200, max: 3000}, 'RGB Composite');
Map.addLayer(polygons, {color: 'yellow'}, 'Training Polygons');
Map.addLayer(classified, {min: 0, max: 1, palette: ['gray', 'green']}, 'Classified Map');
