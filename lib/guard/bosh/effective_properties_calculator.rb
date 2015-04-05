require 'deep_merge'

module Guard
  class Bosh
    # The effective set of properties is the union of:
    # * The default properties declared in the job spec
    # * The properties declared at the top-level of the manifest
    # * The properties declared at the job-level of the manifest
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
