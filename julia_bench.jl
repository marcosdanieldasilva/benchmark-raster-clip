# ==============================================================================
# USING PACKAGES
# ==============================================================================
using BenchmarkTools
using GeoIO
using GeoStats
using Rasters
using ArchGDAL

# ==============================================================================
# PATH CONFIGURATION
# ==============================================================================

DATADIR = "data"
TIFFPATH = joinpath(DATADIR, "img.tif")
GPKGPATH = joinpath(DATADIR, "poly.gpkg")

isfile(TIFFPATH) || error("Raster file not found: $TIFFPATH")
isfile(GPKGPATH) || error("Vector file not found: $GPKGPATH")
println("Repository root: ", @__DIR__)
println("Data directory:  ", DATADIR)

# ==============================================================================
# GEOSTATS.JL APPROACH (geometry-driven, view-based)
# ==============================================================================

println("\n==================================================")
println("GeoStats.jl benchmark")
println("==================================================")

println("Loading raster grid with GeoIO...")
tiff = GeoIO.load(TIFFPATH)

println("Loading polygon with GeoIO...")
gpkg = GeoIO.load(GPKGPATH)

# Extract geometry objects
poly = gpkg.geometry[1]
grid = tiff.geometry

println("\nIndex search (grid vs polygon):")
@btime indices($grid, $poly);

println("\nSubsetting grid (view creation):")
@btime $tiff[$poly, :];

# ==============================================================================
# RASTERS.JL APPROACH (grid-based masking)
# ==============================================================================

println("\n==================================================")
println("Rasters.jl benchmark")
println("==================================================")

println("Loading polygon with ArchGDAL...")
ag_poly = ArchGDAL.read(GPKGPATH) do ds
  layer = ArchGDAL.getlayer(ds, 0)
  feat = first(layer)
  ArchGDAL.clone(ArchGDAL.getgeom(feat))
end

println("\nLazy raster masking:")
raster_lazy = Raster(TIFFPATH; lazy=true)
@btime mask(crop($raster_lazy; to=$ag_poly); with=$ag_poly)

println("\nEager raster masking:")
raster_eager = Raster(TIFFPATH; lazy=false)
@btime mask(crop($raster_eager; to=$ag_poly); with=$ag_poly)
