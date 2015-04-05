require 'guard/bosh/network_generator'

describe Guard::Bosh::NetworkGenerator do
  let(:manifest_stub) do
    {
      'name' => 'redis-deployment',
      'jobs' => [{
        'name' => 'redis_leader_z1',
        'networks' => [{ 'name' => 'redis1', 'static_ips' => ['203.0.113.2'] }],
        'templates' => [{ 'name' => 'redis', 'release' => 'redis' }]
      }],
      'networks' => [
        {
          'name' => 'redis1',
          'subnets' =>  [{
            'cloud_properties' => { 'name' => 'iaas_network_name' },
            'range' => '203.0.113.2/24',
            'static' => ['10.244.2.2']
          }]
        }
      ]
    }
  end

  context 'when the job has a static ip' do
    it 'includes the network config' do
      expected_networks = {
        'redis1' =>  {
          'cloud_properties' => { 'name' => 'iaas_network_name' },
          'dns_record_name' => '0.redis-leader-z1.redis1.redis-deployment.bosh',
          'ip' => '203.0.113.2',
          'netmask' => '255.255.255.0',
          'default' => %w(dns gateway)
        }
      }
      generated_networks = subject.generate(
        deployment_manifest: manifest_stub, job_name: 'redis_leader_z1')
      expect(generated_networks).to eq(expected_networks)
    end
  end

  context 'when the job has a dynamic ip' do
    let(:manifest_stub_without_static_ip) do
      manifest_stub.tap do |stub|
        stub['jobs'].first['networks'].first.delete('static_ips')
      end
    end

    it 'includes the network config' do
      expected_networks = {
        'redis1' =>  {
          'cloud_properties' => { 'name' => 'iaas_network_name' },
          'dns_record_name' => '0.redis-leader-z1.redis1.redis-deployment.bosh',
          'ip' => '203.0.113.2',
          'netmask' => '255.255.255.0',
          'default' => %w(dns gateway)
        }
      }
      generated_networks = subject.generate(
        deployment_manifest: manifest_stub_without_static_ip,
        job_name: 'redis_leader_z1')
      expect(generated_networks).to eq(expected_networks)
    end
  end
end
