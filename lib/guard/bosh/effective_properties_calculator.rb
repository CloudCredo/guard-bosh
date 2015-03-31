require 'deep_merge'

module Guard
  class Bosh
    class EffectivePropertiesCalculator
      def initialize(loaders:)
        @loaders = loaders
      end

      def calculate_effective_properties(job)
        @loaders.inject({}) do |result, loader|
          result.deep_merge!(loader.load_properties(job))
        end
      end
    end
  end
end
