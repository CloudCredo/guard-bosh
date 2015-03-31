module Guard
  class Bosh
    class GlobalPropertiesLoader
      def initialize(deployment_manifest:)
        @deployment_manifest = deployment_manifest
      end

      def load_properties(_)
        global_properties = @deployment_manifest['properties']
        if global_properties.nil?
          {}
        else
          global_properties
        end
      end
    end
  end
end
