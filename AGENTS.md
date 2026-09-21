# Build file syncing

After changing `Builld Ideas/Spark - comet/spark-comet.build`, validate the JSON and run `.\sync-build.ps1` from the repository root to update the local Path of Exile 2 BuildPlanner copy.

For another `.build` file, pass its path with `.\sync-build.ps1 -SourcePath '<path>'`.

Run the script manually after edits. Do not create watchers, background tasks, or scheduled tasks. Report sync failures explicitly; do not claim the game copy is current unless the script succeeds.
