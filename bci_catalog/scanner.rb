# bci_catalog/scanner.rb
module BCI
  module Catalog
    
    # Structure de données interne
    CatalogItem = Struct.new(:entity, :definition, :meta, :scene_names)

    class Scanner
      DICT = 'bci_catalog'.freeze

      def self.scan(model, selection_only: false)
        items = []
        entities = selection_only ? model.selection : model.entities

        entities.each do |ent|
          # On ne traite que les instances de composants pour le MVP
          next unless ent.is_a?(Sketchup::ComponentInstance)
          
          # Filtrage optionnel : ignorer les objets cachés
          next unless ent.visible?

          items << build_item(ent)
        end
        
        # Déduplication (Mode B : Par définition) - Optionnel
        # items = items.uniq { |i| i.definition.persistent_id } 
        
        items
      end

      def self.build_item(entity)
        definition = entity.definition
        
        # Récupération des attributs (Cascade: Instance > Def > Nom)
        meta = {
          ref: get_attr(entity, definition, 'reference', definition.name),
          name: get_attr(entity, definition, 'designation', definition.name),
          dims: "#{entity.bounds.width.to_l} x #{entity.bounds.depth.to_l} x #{entity.bounds.height.to_l}",
          uuid: entity.persistent_id.to_s # Clé unique pour lier aux scènes
        }

        CatalogItem.new(entity, definition, meta, {})
      end

      def self.get_attr(ent, defn, key, fallback)
        val = ent.get_attribute(DICT, key)
        val = defn.get_attribute(DICT, key) if val.nil? || val.to_s.empty?
        val = fallback if val.nil? || val.to_s.empty?
        val
      end
    end
  end
end