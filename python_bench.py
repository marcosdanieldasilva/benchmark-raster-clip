# ==============================================================================
# IMPORTS
# ==============================================================================

import sys
import time
from pathlib import Path

import geopandas as gpd
import rasterio
from rasterio.mask import mask
from shapely.geometry import box

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================

# Resolve repository root based on script location
REPO_ROOT = Path(__file__).resolve().parent
DATA_DIR = REPO_ROOT / "data"

VECTOR_FILE = DATA_DIR / "poly.gpkg"
RASTER_FILE = DATA_DIR / "img.tif"

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

if not VECTOR_FILE.exists():
    sys.exit(f"Vector file not found: {VECTOR_FILE}")

if not RASTER_FILE.exists():
    sys.exit(
        "Raster file not found: mini_ortho.tif\n"
        "Please download it from Google Drive and place it in:\n"
        f"{RASTER_FILE}"
    )

# ==============================================================================
# PREPARATION (NOT PART OF BENCHMARK)
# ==============================================================================

print("\n--- Preparation (not timed) ---")

# Load vector data
print("Loading vector data...")
gdf = gpd.read_file(VECTOR_FILE)

# Open raster dataset
print("Opening raster...")
src = rasterio.open(RASTER_FILE)

# Cache raster metadata
ras_crs = src.crs
ras_bounds = src.bounds
ras_nodata = src.nodata

# Ensure CRS alignment (outside benchmark)
if gdf.crs != ras_crs:
    print(f"Reprojecting vector from {gdf.crs} to {ras_crs}...")
    gdf = gdf.to_crs(ras_crs)
else:
    print("CRS already aligned.")

# ==============================================================================
# TEST 1: SPATIAL INDEX SELECTION (R-TREE)
# ==============================================================================

print("\n" + "=" * 60)
print("TEST 1: Spatial index selection (bounding box intersection)")
print("=" * 60)

# Create raster bounding box geometry
raster_box = box(*ras_bounds)

start_idx = time.perf_counter()

# GeoPandas uses STRtree internally for spatial predicates
gdf_subset = gdf[gdf.intersects(raster_box)]

end_idx = time.perf_counter()
time_idx = end_idx - start_idx

print(f"Selection time:        {time_idx:.4f} seconds")
print(f"Total polygons:        {len(gdf)}")
print(f"Selected polygons:     {len(gdf_subset)}")

# ==============================================================================
# TEST 2: RASTER CLIP (GDAL CUTLINE EQUIVALENT)
# ==============================================================================

print("\n" + "=" * 60)
print("TEST 2: Raster clip (GDAL / QGIS cutline equivalent)")
print("=" * 60)

if len(gdf_subset) == 0:
    print("No polygons intersect raster. Clip skipped.")
else:
    # Rasterio expects a list of geometries (GeoJSON-like)
    shapes = list(gdf_subset.geometry)

    start_clip = time.perf_counter()

    out_image, out_transform = mask(
        src,
        shapes,
        crop=True,            # Equivalent to -crop_to_cutline
        all_touched=False,    # QGIS/GDAL default: center-of-pixel rule
        filled=True,
        nodata=ras_nodata
    )

    end_clip = time.perf_counter()
    time_clip = end_clip - start_clip

    print(f"Clip time:             {time_clip:.4f} seconds")
    print(f"Output array shape:    {out_image.shape}")

    print("-" * 60)
    print(f"TOTAL TIME (Index + Clip): {time_idx + time_clip:.4f} seconds")

# ==============================================================================
# CLEANUP
# ==============================================================================

src.close()
print("\nBenchmark finished.")
