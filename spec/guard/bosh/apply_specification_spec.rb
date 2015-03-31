require 'guard/bosh/apply_specification'

describe Guard::Bosh::ApplySpecification do
  let(:package_resolver) { double }
  subject do
    Guard::Bosh::ApplySpecification.new(
      deployment_manifest: manifest_stub,
      package_resolver: package_resolver
    )
  end

  let(:manifest_stub) do
    {
      'name' => 'redis-deployment',
      'jobs' => [{
        'instances' => 1,
        'name' => 'redis_leader_z1',
        'networks' => [{ 'name' => 'redis1', 'static_ips' => ['203.0.113.2'] }],
        'persistent_disk' => 0,
        'resource_pool' => 'small_z1',
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
      ],
      'resource_pools' => [
        {
          'cloud_properties' => { 'name' => 'random' },
          'name' => 'small_z1',
          'network' => 'redis1',
          'size' => 3,
          'stemcell' => {
            'name' => 'bosh-warden-boshlite-ubuntu-trusty-go_agent',
            'version' => '389'
          }
        }
      ]
    }
  end

  before do
    allow(package_resolver).to receive(:resolve).with('redis').and_return(['redis'])
  end

  it 'includes the effective properties provided' do
    effective_properties = {
      'redis' => {
        'master' => '203.0.113.2'
      }
    }
    apply_spec = subject.generate(
      properties: effective_properties, job_name: 'redis_leader_z1')
    expect(apply_spec['properties']).to include(effective_properties)
  end

  it 'includes a job index' do
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['index']).to eq(0)
  end

  it 'includes the job details' do
    expected_job = {
      'name' => 'redis_leader_z1',
      'template' => 'redis',
      'version' => '1',
      'sha1' => 'c7f277de5b283e5ceffe55674dc56fad2257ecab',
      'blobstore_id' => '8a66ab45-4831-4ce3-aa8f-313fe33a9891',
      'templates' => [
        {
          'name' => 'redis',
          'version' => '1',
          'sha1' => '88d6ea417857efda58916f9cb9bd5dd3a0f76f00',
          'blobstore_id' => '2356dff1-18fd-4314-a9bd-199b9d6c5c45'
        }
      ]
    }
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['job']).to eq(expected_job)
  end

  it 'includes the package details' do
    expected_packages = {
      'redis' => {
        'name' => 'redis',
        'version' => '1.0',
        'sha1' => 'b945ce51b3635bb0ebfb2207323514381bcee824',
        'blobstore_id' => '608c41bc-d491-4773-9812-8f24276eace1'
      }
    }
    expect(package_resolver).to receive(:resolve).with('redis').and_return(['redis'])
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['packages']).to eq(expected_packages)
  end

  it 'includes a dummy configuration hash' do
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['configuration_hash']).to_not be_empty
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
      apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
      expect(apply_spec['networks']).to eq(expected_networks)
    end
  end

  context 'when the job has a dynamic ip' do
    let(:manifest_stub_without_static_ip) do
      manifest_stub.tap do |stub|
        stub['jobs'].first['networks'].first.delete('static_ips')
      end
    end

    subject do
      Guard::Bosh::ApplySpecification.new(
        deployment_manifest: manifest_stub_without_static_ip,
        package_resolver: package_resolver
      )
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
      apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
      expect(apply_spec['networks']).to eq(expected_networks)
    end
  end

  it 'includes the resource pool' do
    resource_pool = {
      'cloud_properties' => {
        'name' => 'random'
      },
      'name' => 'small_z1',
      'stemcell' => {
        'name' => 'bosh-warden-boshlite-ubuntu-trusty-go_agent',
        'version' => '389'
      }
    }
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['resource_pool']).to eq(resource_pool)
  end

  it 'includes the deployment name' do
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['deployment']).to eq('redis-deployment')
  end

  it 'includes the persistent disk' do
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['persistent_disk']).to eq(0)
  end

  it 'includes a dummy rendered templates archive' do
    apply_spec = subject.generate(properties: {}, job_name: 'redis_leader_z1')
    expect(apply_spec['rendered_templates_archive']).to eq(
      'sha1' => 'c299ead74faf9ee9b47b3548e5df427e3e9a2c70',
      'blobstore_id' => '72fb06ef-0f40-4280-85e8-b5930e672308'
    )
  end
end
