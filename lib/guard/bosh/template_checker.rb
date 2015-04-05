require 'guard/bosh/apply_specification'
require 'guard/bosh/effective_properties_calculator'
require 'guard/bosh/global_properties_loader'
require 'guard/bosh/job_default_properties_loader'
require 'guard/bosh/job_properties_loader'
require 'guard/bosh/network_generator'
require 'guard/bosh/package_resolver'
require 'guard/bosh/template_renderer'

module Guard
  class Bosh
    # Encapsulates building the apply spec, and rendering job templates against
    # it to identify errors.
    class TemplateChecker
      def initialize(deployment_manifest:,
                     properties_calculator:,
                     apply_specification:,
                     template_renderer:)
        @deployment_manifest = deployment_manifest
        @properties_calculator = properties_calculator
        @apply_specification = apply_specification
        @template_renderer = template_renderer
      end

      def check(manifest_job_name:, job_name:, template:)
        properties = @properties_calculator.calculate_effective_properties(
          manifest_job_name: manifest_job_name, job_name: job_name)
        apply_spec = @apply_specification.generate(
          properties: properties,
          job_name: manifest_job_name
        )
        @template_renderer.render(context: apply_spec, template: template)
      end

      def self.build(deployment_manifest:, release_dir:)
        new(
          deployment_manifest: deployment_manifest,
          properties_calculator:
            properties_calculator(deployment_manifest, release_dir),
          apply_specification:
            apply_specification(deployment_manifest, release_dir),
          template_renderer: TemplateRenderer.new
        )
      end

      def self.properties_calculator(deployment_manifest, release_dir)
        EffectivePropertiesCalculator.new(loaders: [
          JobDefaultPropertiesLoader.new(release_dir: release_dir),
          GlobalPropertiesLoader.new(deployment_manifest: deployment_manifest),
          JobPropertiesLoader.new(deployment_manifest: deployment_manifest)
        ])
      end

      def self.apply_specification(deployment_manifest, release_dir)
        ApplySpecification.new(
          deployment_manifest: deployment_manifest,
          network_generator: NetworkGenerator.new,
          package_resolver: PackageResolver.new(release_dir)
        )
      end
    end
  end
end
