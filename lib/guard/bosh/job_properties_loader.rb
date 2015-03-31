module Guard
  class Bosh
    class JobPropertiesLoader
      def initialize(deployment_manifest:)
        @manifest = deployment_manifest
      end

      def load_properties(job)
        manifest_job = @manifest['jobs'].find do |j|
          j['name'] == job[:manifest_job_name]
        end
        if manifest_job
          manifest_job['properties']
        else
          {}
        end
      end
    end
  end
end
