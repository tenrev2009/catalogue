# bci_catalog.rb
require 'sketchup.rb'
require 'extensions.rb'

module BCI
  module Catalog
    VERSION = "1.0.0"
    
    ext = SketchupExtension.new("BCI Catalog Generator", File.join("bci_catalog", "main"))
    ext.description = "Génère un catalogue LayOut automatique depuis les composants SketchUp."
    ext.version = VERSION
    ext.copyright = "BCI © 2025"
    ext.creator = "Toi"
    
    Sketchup.register_extension(ext, true)
  end
end