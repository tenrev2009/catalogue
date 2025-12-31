# bci_catalog/staging.rb
module BCI
  module Catalog
    class StagingEngine
      def initialize(model, items)
        @model = model
        @items = items
        @view = @model.active_view
      end

      def generate(output_path)
        # On démarre une opération qu'on annulera à la fin
        @model.start_operation('BCI Temp Staging', true)
        
        begin
          # 1. Préparer l'environnement "Studio Photo"
          # On crée un calque dédié pour isoler nos objets
          studio_layer = @model.layers.add("BCI_CATALOG_STUDIO")
          
          # On va masquer tous les autres calques dans les nouvelles scènes
          # (Simplification: dans SketchUp, on gère ça via les Scene updates)

          @items.each do |item|
            process_item(item, studio_layer)
          end

          # 2. Sauvegarder le modèle "Source" qui contient les scènes
          @model.save_copy(output_path)
          puts "Fichier source sauvegardé : #{output_path}"

        rescue => e
          puts "Erreur Staging: #{e.message}"
          puts e.backtrace
        ensure
          # 3. Annuler toutes les modifications (Clean exit)
          @model.abort_operation
        end
      end

      private

      def process_item(item, layer)
        # Pour une isolation parfaite sans toucher aux objets existants complexe:
        # On place une NOUVELLE instance de la définition à l'origine [0,0,0]
        # sur le calque Studio.
        
        defn = item.definition
        # Placer à l'origine
        instance = @model.entities.add_instance(defn, Geom::Transformation.new)
        instance.layer = layer
        
        # On s'assure que l'instance est visible
        instance.hidden = false
        
        # --- SCENE FACE ---
        scene_name_front = "CAT_#{item.meta[:uuid]}_FRONT"
        page = @model.pages.add(scene_name_front)
        setup_camera(instance, Geom::Vector3d.new(0, -1, 0)) # Vue de face (Y-)
        isolate_layer(page, layer)
        item.scene_names[:front] = scene_name_front # Stocker le nom pour LayOut

        # --- SCENE ISO ---
        scene_name_iso = "CAT_#{item.meta[:uuid]}_ISO"
        page = @model.pages.add(scene_name_iso)
        setup_camera(instance, Geom::Vector3d.new(1, -1, 0.5)) # Iso
        isolate_layer(page, layer)
        item.scene_names[:iso] = scene_name_iso

        # --- SCENE SECTION (Coupe) ---
        # MVP: Pour l'instant une vue de gauche
        scene_name_side = "CAT_#{item.meta[:uuid]}_SIDE"
        page = @model.pages.add(scene_name_side)
        setup_camera(instance, Geom::Vector3d.new(1, 0, 0)) # Vue droite (X+)
        isolate_layer(page, layer)
        item.scene_names[:section] = scene_name_side

        # Nettoyage : On supprime l'instance temporaire ? 
        # NON, car les scènes en ont besoin pour le fichier sauvegardé.
        # Mais comme on fera un abort_operation, tout disparaitra du modèle actif.
        # Par contre, pour le fichier suivant dans la boucle, il faut masquer 
        # l'instance précédente.
        instance.hidden = true 
        # Note: SketchUp Scenes stockent l'état caché par entité si on met à jour le flag.
        # Astuce : Pour éviter les conflits, on supprime l'instance après création des scènes ?
        # Non, la scène serait vide.
        # Solution simple MVP : On met chaque item sur un layer unique ? Trop lourd.
        # Solution "Undo" : On ne peut pas faire de Undo partiel.
        
        # CORRECTION LOGIQUE STAGING :
        # Pour que chaque scène ne voie QUE son objet, il faut gérer la visibilité.
        # La méthode simple : `instance.visible = false` sur les scènes précédentes ? Difficile par code.
        # Méthode robuste "Explosion" : On place les instances loin les unes des autres (x += 100m).
        # Et on zoome dessus.
        # Ici j'ai utilisé l'instance unique à [0,0,0], mais il faut gérer le "hide".
        # Hack pour MVP : On assume que l'utilisateur veut 1 item par page.
        # On va utiliser "Entities.erase" de l'instance PRÉCÉDENTE avant de passer au suivant ?
        # Non, car la scène 1 serait vide.
        
        # RECTIFICATION : On place TOUS les objets alignés sur l'axe X (espacés de 10m).
        # La caméra zoome (Fit) sur l'objet concerné.
        # Comme on est en Zoom Extents sur objet, si l'écart est assez grand, on ne voit pas les voisins.
        vec_offset = Geom::Vector3d.new(0, 0, 0) # Pas d'offset, on gère la visibilité via Layer c'est mieux
        
        # Pour ce script MVP, on laisse l'instance visible. Si le zoom est serré, c'est OK.
        # Pour la prod : Il faut créer un Layer par Item ("CAT_ITEM_01") et configurer les pages.
        item_layer = @model.layers.add("CAT_ITEM_#{item.meta[:uuid]}")
        instance.layer = item_layer
        
        # Update des pages créées pour ne montrer QUE ce layer
        [scene_name_front, scene_name_iso, scene_name_side].each do |s_name|
           p = @model.pages[s_name]
           @model.layers.each { |l| p.set_visibility(l, false) } # Tout off
           p.set_visibility(item_layer, true) # Item on
           p.update(1|16) # Camera + Layers
        end
      end

      def setup_camera(instance, dir_vec)
        cam = @model.active_view.camera
        bb = instance.bounds
        target = bb.center
        
        # Positionnement
        dist = bb.diagonal * 2.0
        eye = target + transform_dir(dir_vec, dist)
        
        cam.set(eye, target, Z_AXIS)
        cam.perspective = false # Ortho pour catalogue technique
        
        # Zoom fit manuel (Approximation)
        # view.zoom(instance) ne marche pas bien hors contexte UI parfois.
        # On laisse le `cam.set` faire le gros du travail et on ajuste le FOV/Height
        cam.height = bb.height * 1.5
        
        # Mise à jour vue
        @view.camera = cam
      end

      def transform_dir(vec, dist)
        vec.normalize!
        output = Geom::Vector3d.new(vec.x * dist, vec.y * dist, vec.z * dist)
        output
      end
      
      def isolate_layer(page, layer)
         # Géré dans process_item
      end
    end
  end
end