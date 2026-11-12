// A script to view a single Sentinel-1 scene

// Open the Sentinel-1 collection and filter for VH and VV
var imgVH = ee.ImageCollection('COPERNICUS/S1_GRD')
        .filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VH'))
        .filter(ee.Filter.eq('instrumentMode', 'IW'))
        .select('VH');
var imgVV = ee.ImageCollection('COPERNICUS/S1_GRD')
        .filter(ee.Filter.listContains('transmitterReceiverPolarisation', 'VV'))
        .filter(ee.Filter.eq('instrumentMode', 'IW'))
        .select('VV');

// separate ascending and descending orbits, for consistent geometry
var ascVH = imgVH.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING'));
var ascVV = imgVV.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING'));
var descVH = imgVH.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING'));
var descVV = imgVV.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING'));


// Select a two month window
var dates = ee.Filter.date('2026-09-25', '2026-11-25');

// take the mean backscatter for the time window. This is despeckling in time
var scatterVHasc = ascVH.filter(dates).mean();
var scatterVHdesc = descVH.filter(dates).mean();
var scatterVVasc = ascVV.filter(dates).mean();
var scatterVVdesc = descVV.filter(dates).mean();


// make the map
Map.setCenter( -3.9 ,56.8, 9.5); // Center on Scotland
Map.addLayer(scatterVHasc, {min: -25, max: 5}, 'VH Ascending', true);
Map.addLayer(scatterVVasc, {min: -25, max: 5}, 'VV Ascending', true);
Map.addLayer(scatterVHdesc, {min: -25, max: 5}, 'VH Descending', true);
Map.addLayer(scatterVVdesc, {min: -25, max: 5}, 'VV Descending', true);


