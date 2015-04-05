require 'guard/compat/plugin'
require 'pathname'
require 'yaml'

module Guard
  # Guard BOSH Plugin
  class Bosh < Plugin
    require 'pathname'

    require 'guard/bosh/apply_specification'
    require 'guard/bosh/change_assessor'
    require 'guard/bosh/effective_properties_calculator'
    require 'guard/bosh/global_properties_loader'
    require 'guard/bosh/job_default_properties_loader'
    require 'guard/bosh/job_properties_loader'
    require 'guard/bosh/job_repository'
    require 'guard/bosh/notifier'
    require 'guard/bosh/package_resolver'
    require 'guard/bosh/template_checker'
    require 'guard/bosh/template_renderer'

    def initialize(options = {})
      super

      unless options.key?(:deployment_manifest)
        fail 'Please specify the deployment_manifest in your Guardfile'
      end

      @deployment_manifest = Pathname.new(options[:deployment_manifest])
      @change_assessor = options[:change_assessor]
      @job_repository = options[:job_repository]
      @template_checker = options[:template_checker]
      @notifier = options[:notifier]
    end

    def start
      reload_deployment_manifest
      @notifier = Notifier.new
    end

    def run_all
      errors = render_all_job_templates
      notify_errors(errors)
    end

    # rubocop:disable Metrics/MethodLength
    def run_on_modifications(paths)
      change_scope, job_name = @change_assessor.determine_scope(paths)
      errors = case change_scope
               when :all
                 reload_deployment_manifest
                 render_all_job_templates
               when :all_templates_for_job
                 render_templates_for_job(
                   job_name, @job_repository.template_paths(job_name))
               when :single_template
                 render_templates_for_job(job_name, paths)
               end
      notify_errors(errors)
    end

    private

    def reload_deployment_manifest
      manifest = YAML.load_file(@deployment_manifest)
      @change_assessor = ChangeAssessor.new(@deployment_manifest)
      @job_repository = JobRepository.new(manifest)
      @template_checker = TemplateChecker.build(
        deployment_manifest: manifest,
        release_dir: Pathname.new('.')
      )
    end

    def notify_errors(errors)
      @notifier.notify(errors)
      throw :task_has_failed unless errors.empty?
    end

    def render_all_job_templates
      @job_repository.job_templates.flat_map do |job_name|
        render_templates_for_job(job_name,
                                 @job_repository.template_paths(job_name))
      end
    end

    def render_templates_for_job(job_name, templates)
      manifest_jobs = @job_repository.find_by_template(job_name)
      template_results = manifest_jobs.product(
        templates).flat_map do |manifest_job, template|
        @template_checker.check(
          manifest_job_name: manifest_job,
          job_name: job_name,
          template: template)
      end
      template_results.select { |tr| tr[:status] == :failure }
    end
  end
end
