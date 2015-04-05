require 'ipaddr'

module Guard
  class Bosh
    class ApplySpecification
      def initialize(deployment_manifest:, package_resolver:)
        @manifest = deployment_manifest
        @package_resolver = package_resolver
      end

      def generate(properties:, job_name:)
        {
          'deployment' => @manifest['name'],
          'configuration_hash' => '24292bab7264f00ada207768efa7018e2a2226fc',
          'job' => job(job_name),
          'packages' => packages(job_name),
          'resource_pool' => resource_pool(job_name),
          'networks' => network(job_name),
          'index' => 0,
          'properties' => properties,
          'persistent_disk' => persistent_disk(job_name),
          'rendered_templates_archive' => rendered_templates_archive
        }
      end

      private

      def job(job_name)
        manifest_job = manifest_job_with_name(job_name)
        {
          'name' => job_name,
          'template' => manifest_job['template'] ||
            manifest_job['templates'].first['name'],
          'version' => '1',
          'sha1' => 'c7f277de5b283e5ceffe55674dc56fad2257ecab',
          'blobstore_id' => '8a66ab45-4831-4ce3-aa8f-313fe33a9891',
          'templates' => templates(manifest_job)
        }
      end

      def packages(job_name)
        manifest_job = manifest_job_with_name(job_name)
        all_packages = template_names(manifest_job).flat_map do |template|
          @package_resolver.resolve(template)
        end
        all_packages.inject({}) do |result, package|
          result.merge(

            package => {
              'name' => package,
              'version' => '1.0',
              'sha1' => 'b945ce51b3635bb0ebfb2207323514381bcee824',
              'blobstore_id' => '608c41bc-d491-4773-9812-8f24276eace1'
            }

          )
        end
      end

      def templates(manifest_job)
        template_names(manifest_job).map { |t| template(t) }
      end

      def template_names(manifest_job)
        if manifest_job.key?('template')
          Array(manifest_job['template'])
        else
          manifest_job['templates'].map { |t| t['name'] }
        end
      end

      def template(name)
        {
          'name' => name,
          'version' => '1',
          'sha1' => '88d6ea417857efda58916f9cb9bd5dd3a0f76f00',
          'blobstore_id' => '2356dff1-18fd-4314-a9bd-199b9d6c5c45'
        }
      end

      def network(job_name)
        manifest_job = manifest_job_with_name(job_name)
        job_network = manifest_job['networks'].first
        network_definition = @manifest['networks'].find do |n|
          n['name'] == job_network['name']
        end
        {
          job_network['name'] => {
            'cloud_properties' => network_definition['subnets'].first[
              'cloud_properties'],
            'dns_record_name' => dns_record_name(
              job_name, job_network['name'], @manifest['name']),
            'ip' => ip_address(job_network, network_definition),
            'netmask' => netmask(network_definition['subnets'].first['range']),
            'default' => %w(dns gateway)
          }
        }
      end

      def ip_address(job_network, network_definition)
        if job_network.key?('static_ips') &&
           Array(job_network['static_ips']).any?
          job_network['static_ips'].first
        else
          # We could be better here and calculate the dynamic address properly
          network_definition['subnets'].first['range'].split('/').first
        end
      end

      def dns_record_name(job, network, deployment)
        "0.#{job}.#{network}.#{deployment}.bosh".gsub('_', '-')
      end

      def netmask(range)
        cidr = range.split('/').last
        IPAddr.new('255.255.255.255').mask(cidr).to_s
      end

      def resource_pool(job_name)
        manifest_job = manifest_job_with_name(job_name)
        job_pool = @manifest['resource_pools'].find do |pool|
          pool['name'] == manifest_job['resource_pool']
        end
        job_pool.delete_if do |k, _|
          ! %w(cloud_properties name stemcell).include?(k)
        end
      end

      def persistent_disk(job_name)
        manifest_job = manifest_job_with_name(job_name)
        manifest_job['persistent_disk']
      end

      def rendered_templates_archive
        {
          'sha1' => 'c299ead74faf9ee9b47b3548e5df427e3e9a2c70',
          'blobstore_id' => '72fb06ef-0f40-4280-85e8-b5930e672308'
        }
      end

      def manifest_job_with_name(name)
        @manifest['jobs'].find { |j| j['name'] == name }
      end
    end
  end
end
