# ==============================================================================
# USING PACKAGES
# ==============================================================================
using ArchGDAL
using BenchmarkTools
using GeoIO
using GeoStats
using Rasters

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================

# Repository root = directory where this script is located
REPO_ROOT = @__DIR__
DATA_DIR = joinpath(REPO_ROOT, "data")

TIF_PATH = joinpath(DATA_DIR, "img.tif")
GPKG_PATH = joinpath(DATA_DIR, "poly.gpkg")

isfile(TIF_PATH) || error("Raster file not found: $TIF_PATH")
isfile(GPKG_PATH) || error("Vector file not found: $GPKG_PATH")

println("Repository root: ", REPO_ROOT)
println("Data directory:  ", DATA_DIR)

# ==============================================================================
# GEOSTATS.JL APPROACH (geometry-driven, view-based)
# ==============================================================================

println("\n==================================================")
println("GeoStats.jl benchmark")
println("==================================================")

println("Loading raster grid with GeoIO...")
geostats_grid = GeoIO.load(TIF_PATH)

println("Loading polygon with GeoIO...")
geostats_poly_table = GeoIO.load(GPKG_PATH)

# Extract geometry objects
geo_poly = geostats_poly_table.geometry[1]
grid_geom = geostats_grid.geometry

println("\nIndex search (grid vs polygon):")
@btime indices(grid_geom, geo_poly)

println("\nSubsetting grid (view creation):")
@btime geostats_grid[geo_poly, :]

# ==============================================================================
# RASTERS.JL APPROACH (grid-based masking)
# ==============================================================================

println("\n==================================================")
println("Rasters.jl benchmark")
println("==================================================")

println("Loading polygon with ArchGDAL...")
ag_poly = ArchGDAL.read(GPKG_PATH) do ds
  layer = ArchGDAL.getlayer(ds, 0)
  feat = first(layer)
  ArchGDAL.clone(ArchGDAL.getgeom(feat))
end

println("\nLazy raster masking:")
raster_lazy = Raster(TIF_PATH; lazy=true)
@btime mask(crop(raster_lazy; to=ag_poly); with=ag_poly)

println("\nEager raster masking:")
raster_eager = Raster(TIF_PATH; lazy=false)
@btime mask(crop(raster_eager; to=ag_poly); with=ag_poly)
