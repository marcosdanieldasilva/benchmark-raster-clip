# Raster Clip Benchmark (Polygon Mask)

This repository benchmarks **raster clipping by polygon** using different geospatial stacks, focusing on **algorithmic behavior, performance, and geometric fidelity**.

The comparison includes:

- QGIS / GDAL (`gdalwarp -cutline`)
- Python (`rasterio.mask`)
- Julia:
  - GeoStats.jl (geometry-driven, domain views)
  - Rasters.jl (grid-based masking, lazy vs eager)

The goal is to understand differences between **geometry-based** and **raster-based** clipping approaches.

---

## Repository structure

```

benchmark-raster-clip/
├── data/
│   ├── poly.gpkg
│   └── img.tif
│
├── python_bench.py
├── julia_bench.jl
└── README.md

````

---

## Data

### Polygon

- `data/poly.gpkg`
- Single irregular polygon
- Lightweight and included in the repository

### Raster

The raster file is not versioned due to size.

Download it from:

https://drive.google.com/file/d/1MXkcL9r3XoT19Oeo2UY8Ww9zzT6y8l6u/view?usp=sharing

After downloading:

1. Rename the file to `img.tif`
2. Place it in the `data/` directory

---

## Python benchmark

### Requirements

- Python ≥ 3.9
- geopandas
- rasterio
- shapely

### Run

```bash
python python_bench.py
````

The script:

* loads the polygon
* aligns CRS if needed
* performs spatial index filtering
* clips the raster using `rasterio.mask`

This corresponds to the GDAL operation:

```
gdalwarp -cutline -crop_to_cutline
```

---

## Julia benchmark

### Requirements

* Julia ≥ 1.9
* ArchGDAL
* GeoIO
* GeoStats
* Rasters
* BenchmarkTools

### Run

```bash
julia julia_bench.jl
```

For a clean benchmark environment:

```julia
using Pkg
Pkg.activate(; temp=true)
Pkg.add([
    "ArchGDAL",
    "BenchmarkTools",
    "GeoIO",
    "GeoStats",
    "Rasters"
])
include("julia_bench.jl")
```

The Julia benchmark evaluates:

* geometry-domain indexing and subsetting (GeoStats.jl)
* raster masking with lazy and eager loading (Rasters.jl)

---

## Notes

* QGIS / GDAL rasterizes the polygon internally and applies a pixel-wise mask
* Python follows the same GDAL-based logic
* GeoStats.jl operates on geometry-domain intersections
* Rasters.jl applies grid masking after bounding-box cropping

Differences in extent, performance, and memory usage are expected.

---
