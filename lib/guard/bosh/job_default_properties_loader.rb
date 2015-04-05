require 'yaml'

module Guard
  class Bosh
    # The property defaults (if any) defined for a BOSH job in the job spec.
    class JobDefaultPropertiesLoader
      def initialize(release_dir:)
        @release_dir = release_dir
      end

      def load_properties(job)
        properties = job_spec(job[:job_name]).fetch('properties')
        expand(
          intermediate_properties(properties).merge(
            default_properties(properties)
          )
        )
      end

      private

      def default_properties(properties)
        defaults_only = properties.map do |property, config|
          [property, config['default']]
        end
        Hash[defaults_only].reject { |_k, v| v.nil? }
      end

      def intermediate_properties(properties)
        intermediates = properties.keys.map do |key|
          key.split('.')[0..-2].join('.')
        end.sort.uniq
        Hash[intermediates.zip(intermediates.map { |_t| {} })]
      end

      def job_spec(job_name)
        YAML.load_file(@release_dir + 'jobs' + job_name + 'spec')
      end

      def expand(properties)
        properties.each_with_object({}) do |property, expanded|
          key, value = property
          current = expanded
          each_parent(key) do |parent|
            current[parent] = {} unless current.key?(parent)
            current = current[parent]
          end
          current[leaf(key)] = value
        end
      end

      def each_parent(key)
        path = key.split('.')
        path[0...-1].each do |parent|
          yield parent
        end
      end

      def leaf(key)
        key.split('.').last
      end
    end
  end
end
