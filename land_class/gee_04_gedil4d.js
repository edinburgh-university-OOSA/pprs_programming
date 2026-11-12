// A script to view the GEDI L4D data, which is derived from Landsat

// Open the L4D collection
var dataset = ee.ImageCollection('LARSE/GEDI/GEDI04_D_002');

var height = {
  bands: ['rh98'],
    palette: [
    'darkred',
    'red',
    'orange',
    'green',
    'darkgreen',
  ]
};

var cov = {
  bands: ['cover_z_000']
};

Map.setCenter(-3.9, 50.5, 8);
Map.addLayer(dataset, height, 'Height');
Map.addLayer(dataset, cov, 'Cover');

