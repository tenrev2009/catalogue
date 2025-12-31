require 'fileutils'

module BCI
  module Catalog
    class Main
      def self.run
        Sketchup.active_model.start_operation('BCI Trace', true)
        puts "--- DÉBUT DU DEBUG ---"

        # 1. SETUP
        model = Sketchup.active_model
        if model.path.empty?
          # Fallback si le fichier n'est pas enregistré
          base_path = ENV['TEMP']
        else
          base_path = File.dirname(model.path)
        end
        
        output_dir = File.join(base_path, "Catalog_Output")
        FileUtils.mkdir_p(output_dir)
        puts "Dossier sortie : #{output_dir}"

        skp_path = File.join(output_dir, "source_catalog.skp")
        layout_path = File.join(output_dir, "catalogue.layout")

        # 2. SELECTION DU TEMPLATE
        template_path = UI.openpanel("Choisir le Template LayOut", "", "LayOut Files|*.layout;||")
        if template_path.nil?
          puts "Annulé par l'utilisateur."
          return
        end
        puts "Template choisi : #{template_path}"

        # 3. SCAN
        puts "Lancement du Scan..."
        # Vérification de sécurité sur la classe Scanner
        unless defined?(Scanner)
           UI.messagebox("Erreur CRITIQUE : Le fichier scanner.rb n'est pas chargé.")
           return
        end

        items = Scanner.scan(model, selection_only: true)
        
        if items.empty?
          UI.messagebox("STOP : Aucun COMPOSANT n'est sélectionné.\nSélectionnez un composant et réessayez.")
          return
        end
        puts "Items trouvés : #{items.size}"

        # 4. STAGING
        puts "Lancement du Staging..."
        begin
          StagingEngine.new(model, items).generate(skp_path)
          puts "Staging terminé. Fichier SKP : #{skp_path}"
        rescue => e
          UI.messagebox("ERREUR CRITIQUE STAGING :\n" + e.message + "\n" + e.backtrace[0..2].join("\n"))
          return
        end

        # 5. LAYOUT
        puts "Lancement de LayOut..."
        begin
          LayoutEngine.new(template_path, skp_path, items).generate(layout_path)
          puts "Génération LayOut terminée."
        rescue => e
          UI.messagebox("ERREUR CRITIQUE LAYOUT :\n" + e.message + "\n" + e.backtrace[0..2].join("\n"))
          return
        end

        # FIN
        UI.messagebox("SUCCÈS !\nFichier généré :\n" + layout_path)
        UI.openURL("file:///" + output_dir)
        
        Sketchup.active_model.abort_operation # Juste pour nettoyer l'undo stack du debug
      end
    end
    
    # Menu
    unless file_loaded?(__FILE__)
      menu = UI.menu('Extensions').add_submenu('BCI Catalog')
      menu.add_item('Générer Catalogue (Debug)') { Main.run }
      file_loaded(__FILE__)
    end
  end
end
