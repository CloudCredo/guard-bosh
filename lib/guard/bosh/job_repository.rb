require 'pathname'

module Guard
  class Bosh
    # Wraps access to manifest jobs and templates
    class JobRepository
      def initialize(deployment_manifest)
        @manifest = deployment_manifest
      end

      def job_templates
        @manifest['jobs'].flat_map { |j| template_names(j) }.sort.uniq
      end

      def find_by_template(job)
        jobs_using_template = @manifest['jobs'].select do |manifest_job|
          template_names(manifest_job).include?(job)
        end
        jobs_using_template.map { |j| j['name'] }
      end

      def template_paths(job)
        job_dir = Pathname.new('jobs') + job
        YAML.load_file(job_dir + 'spec')['templates'].keys.map do |template|
          job_dir + 'templates' + template
        end
      end

      private

      def template_names(manifest_job)
        if manifest_job.key?('templates')
          manifest_job['templates'].map { |t| t['name'] }
        else
          Array(manifest_job['template'])
        end
      end
    end
  end
end
