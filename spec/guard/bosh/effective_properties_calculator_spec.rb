require 'guard/bosh/job_properties_loader'
require 'guard/bosh/job_default_properties_loader'
require 'guard/bosh/global_properties_loader'
require 'guard/bosh/effective_properties_calculator'

describe Guard::Bosh::EffectivePropertiesCalculator do
  let(:job_defaults_loader) do
    instance_double(Guard::Bosh::JobDefaultPropertiesLoader)
  end

  let(:global_properties_loader) do
    instance_double(Guard::Bosh::GlobalPropertiesLoader)
  end

  let(:job_properties_loader) do
    instance_double(Guard::Bosh::JobPropertiesLoader)
  end

  subject do
    Guard::Bosh::EffectivePropertiesCalculator.new(loaders: [
      job_defaults_loader,
      global_properties_loader,
      job_properties_loader
    ])
  end

  it 'merges the properties' do
    expect(job_defaults_loader).to receive(:load_properties).and_return(

        'redis' => {
          'password' => 'password',
          'port' => 6379
        }

    )
    expect(global_properties_loader).to receive(:load_properties).and_return(

        'redis' => {
          'password' => 'secure-password',
          'slaves' => ['203.0.113.3', '203.0.113.4']
        },
        'network' => 'redis1'

    )
    expect(job_properties_loader).to receive(:load_properties).and_return(

        'redis' => {
          'master' => '203.0.113.2'
        }

    )

    properties = subject.calculate_effective_properties(manifest_job_name: 'redis_z1')
    expect(properties).to eq(
      'redis' => {
        'password' => 'secure-password',
        'port' => 6379,
        'master' => '203.0.113.2',
        'slaves' => ['203.0.113.3', '203.0.113.4']
      },
      'network' => 'redis1'
    )
  end
end
