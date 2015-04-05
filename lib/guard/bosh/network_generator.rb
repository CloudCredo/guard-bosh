require 'ipaddr'

module Guard
  class Bosh
    # Generates a simulated network section for the apply spec
    class NetworkGenerator
      # rubocop:disable Metrics/MethodLength
      def generate(deployment_manifest:, job_name:)
        job_network, network_definition =
          manifest_sections(deployment_manifest, job_name)
        {
          job_network['name'] => {
            'cloud_properties' => network_definition['subnets'].first[
              'cloud_properties'],
            'dns_record_name' => dns_record_name(
              job_name, job_network['name'], deployment_manifest['name']),
            'ip' => ip_address(job_network, network_definition),
            'netmask' => netmask(network_definition['subnets'].first['range']),
            'default' => %w(dns gateway)
          }
        }
      end

      private

      def manifest_sections(deployment_manifest, job_name)
        manifest_job = deployment_manifest['jobs'].find do |job|
          job['name'] == job_name
        end
        job_network = manifest_job['networks'].first
        network_definition = deployment_manifest['networks'].find do |n|
          n['name'] == job_network['name']
        end
        [job_network, network_definition]
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
    end
  end
end
