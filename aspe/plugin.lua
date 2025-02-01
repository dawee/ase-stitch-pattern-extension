local exporter = require('aspe.exporter')

function init(plugin)
  plugin:newCommand{
    id="ExportStichPatterns",
    title="Export stitch patterns",
    group="file_export",
    onclick=function()
      exporter.run()
    end
  }
end