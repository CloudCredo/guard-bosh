require 'guard/bosh/job_properties_loader'

describe Guard::Bosh::JobPropertiesLoader do
  let(:deployment_manifest) do
    {
      'jobs' => [
        {
          'instances' => 1,
          'name' => 'redis_leader_z1',
          'networks' => [
            { 'name' => 'redis1', 'static_ips' => ['10.244.2.6'] }
          ],
          'persistent_disk' => 0,
          'properties' => { 'network' => 'redis1', 'redis' => nil },
          'resource_pool' => 'small_z1',
          'templates' => [{ 'name' => 'redis', 'release' => 'redis' }]
        },
        {
          'instances' => 2,
          'name' => 'redis_z1',
          'networks' => [
            {
              'name' => 'redis1',
              'static_ips' => ['10.244.2.10', '10.244.2.14']
            }
          ],
          'persistent_disk' => 0,
          'properties' => {
            'network' => 'redis1',
            'redis' => { 'master' => '10.244.2.6' }
          },
          'resource_pool' => 'small_z1',
          'templates' => [{ 'name' => 'redis', 'release' => 'redis' }],
          'update' => { 'canaries' => 10 }
        }
      ]
    }
  end
  subject do
    Guard::Bosh::JobPropertiesLoader.new(
      deployment_manifest: deployment_manifest
    )
  end

  context 'when the job exists within the deployment manifest' do
    it 'returns the properties defined at the job level' do
      job_properties = subject.load_properties(manifest_job_name: 'redis_z1')
      expect(job_properties).to eq(
        'network' => 'redis1', 'redis' => { 'master' => '10.244.2.6' }
      )
    end
  end

  context 'when the job does not exist in the deployment manifest' do
    it 'returns an empty' do
      job_properties = subject.load_properties(manifest_job_name: 'missing_job')
      expect(job_properties).to be_empty
    end
  end
end
