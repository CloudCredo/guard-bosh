module Guard
  class Bosh
    # Determines the impact of a code change to enable a subset of files to be
    # re-evaluated.
    class ChangeAssessor
      def initialize(deployment_manifest)
        @deployment_manifest = deployment_manifest
      end

      def determine_scope(raw_paths)
        paths = raw_paths.map { |p| Pathname.new(p) }
        return :all if paths.include?(@deployment_manifest)

        jobs = paths.select { |p| spec_path?(p) }.map do |p|
          p.dirname.basename.to_s
        end

        spec_scope = scope(jobs, :all_templates_for_job)
        return spec_scope if spec_scope

        jobs = paths.select { |p| template_path?(p) }.map do |t|
          template_job(t)
        end
        template_scope = scope(jobs, :single_template)
        return template_scope if template_scope

        :none
      end

      private

      def spec_path?(path)
        path.basename.to_s == 'spec'
      end

      def template_path?(path)
        path.descend { |p| break true if p.basename.to_s == 'templates' }
      end

      def template_job(template_path)
        template_path.ascend do |p|
          break p.dirname.basename.to_s if p.basename.to_s == 'templates'
        end
      end

      def scope(jobs, value)
        if jobs.size > 1
          :all
        elsif jobs.any?
          [value, jobs.first]
        end
      end
    end
  end
end
