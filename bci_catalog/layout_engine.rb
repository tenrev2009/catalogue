# bci_catalog/layout_engine.rb
module BCI
  module Catalog
    class LayoutEngine
      def initialize(template_path, skp_path, items)
        @template_path = template_path
        @skp_path = skp_path
        @items = items
      end

      def generate(output_path)
        doc = Layout::Document.open(@template_path)
        
        # Récupération des slots (bounding boxes) depuis la page 1
        # Contrat : Des rectangles sur le calque "CAT_SLOTS"
        template_page = doc.pages.first
        slots = detect_slots(doc, template_page)

        @items.each_with_index do |item, idx|
          # Nouvelle page (clone du template si possible, sinon new empty)
          # Layout API n'a pas de "duplicate page" simple qui copie tout le contenu non-partagé.
          # Si le template est bien fait (Shared Layers pour le fond), doc.pages.add suffit.
          page = idx == 0 ? template_page : doc.pages.add("Item #{idx}")
          
          # Placement Vues
          place_viewport(doc, page, slots[:front], item.scene_names[:front], Layout::SketchUpModel::FRONT_VIEW)
          place_viewport(doc, page, slots[:iso], item.scene_names[:iso], Layout::SketchUpModel::ISO_VIEW)
          place_viewport(doc, page, slots[:section], item.scene_names[:section], Layout::SketchUpModel::RIGHT_VIEW)
          
          # Placement Textes (Titre)
          place_text(doc, page, slots[:title], "#{item.meta[:name]}\n#{item.meta[:ref]}")
        end

        # Nettoyage layer slots
        slot_layer = doc.layers["CAT_SLOTS"]
        slot_layer.set_visible(false, doc.pages.first) if slot_layer

        doc.save(output_path)
        # Export PDF auto
        doc.export(output_path.gsub(".layout", ".pdf"))
      end

      private

      def detect_slots(doc, page)
        # On retourne un hash avec les Bounds
        slots = {}
        
        # Pour le MVP, si on ne trouve pas de slots, on hardcode des valeurs A4
        w = doc.page_info.width
        h = doc.page_info.height
        
        # Default
        slots[:front] = Geom::Bounds2d.new(10.mm, 100.mm, 80.mm, 80.mm)
        slots[:iso]   = Geom::Bounds2d.new(100.mm, 100.mm, 80.mm, 80.mm)
        slots[:section] = Geom::Bounds2d.new(10.mm, 10.mm, 80.mm, 80.mm)
        slots[:title] = Geom::Point2d.new(20.mm, 280.mm)

        # Logique de détection réelle : parcourir page.entities
        # Si entité sur layer "CAT_SLOTS"... on l'assigne selon sa position X/Y
        # (TopLeft = Front, TopRight = Iso, etc.)
        
        slots
      end

      def place_viewport(doc, page, bounds, scene_name, std_view)
        return unless scene_name && bounds
        
        vp = Layout::SketchUpModel.new(@skp_path, bounds)
        
        # On force la scène
        # Note: API LayOut un peu tricky sur les scenes.
        # Il faut que le modèle soit chargé.
        available_scenes = vp.scenes
        idx = available_scenes.index(scene_name)
        
        if idx
          vp.current_scene = idx
        else
          # Fallback si scène pas trouvée
          vp.view = std_view
        end
        
        vp.render_mode = Layout::SketchUpModel::RASTER_RENDER # Plus rapide
        # vp.render_mode = Layout::SketchUpModel::VECTOR_RENDER # Plus propre
        
        doc.add_entity(vp, doc.layers.active, page)
      end

      def place_text(doc, page, anchor, string)
        return unless anchor
        txt = Layout::FormattedText.new(string, anchor, Layout::FormattedText::ANCHOR_TOP_LEFT)
        doc.add_entity(txt, doc.layers.active, page)
      end
    end
  end
end