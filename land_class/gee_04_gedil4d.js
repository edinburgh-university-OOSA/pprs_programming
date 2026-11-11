// A script to view the GEDI L4D data, which is derived from Landsat

// Open the L4D collection
var dataset = ee.ImageCollection('LARSE/GEDI/GEDI04_D_002');

var visualization = {
  bands: ['rh98'],
    palette: [
    'darkred',
    'red',
    'orange',
    'green',
    'darkgreen',
  ]
};

Map.setCenter(-3.9, 50.5, 8);
Map.addLayer(dataset, visualization, 'Height');

