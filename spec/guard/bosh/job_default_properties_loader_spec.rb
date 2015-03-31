require 'guard/bosh/job_default_properties_loader'

require 'pathname'
require 'yaml'

describe Guard::Bosh::JobDefaultPropertiesLoader do
  let(:release_dir) { Pathname.new('/path/to/a/release') }
  let(:job_spec_excerpt) do
    {
      'properties' =>
      {
        'redis.port' => {
          'description' => 'Port to listen for requests to redis server',
          'default' => 6379
        },
        'redis.password' => {
          'description' => 'Password to access redis server',
          'default' => 'password'
        },
        'redis.master' => {
          'description' => 'IP address or hostname of the Redis master node'
        },
        'redis.compression.rdb' => {
          'description' => 'Compress when dumping databases?',
          'default' => true
        },
        'redis.blazingly.fast' => {
          'description' => 'Empty hash should be created for parent key'
        }
      }
    }
  end
  subject do
    Guard::Bosh::JobDefaultPropertiesLoader.new(
      release_dir: release_dir
    )
  end

  it 'returns the properties that have defaults in the job spec' do
    expect(YAML).to receive(:load_file).with(
      Pathname.new('/path/to/a/release/jobs/job-name/spec')).and_return(job_spec_excerpt)
    job_defaults = subject.load_properties(job_name: 'job-name')
    expect(job_defaults).to include(
      'redis' => {
        'blazingly' => {},
        'port' => 6379,
        'password' => 'password',
        'compression' => {
          'rdb' => true
        }
      }
    )
  end

  it 'ignores properties that do not have defaults defined' do
    expect(YAML).to receive(:load_file).with(
      Pathname.new('/path/to/a/release/jobs/job-name/spec')).and_return(job_spec_excerpt)
    job_defaults = subject.load_properties(job_name: 'job-name')
    expect(job_defaults['redis'].keys).not_to include('master')
  end

  it 'includes an empty hash for intermediate keys' do
    expect(YAML).to receive(:load_file).with(
      Pathname.new('/path/to/a/release/jobs/job-name/spec')).and_return(job_spec_excerpt)
    job_defaults = subject.load_properties(job_name: 'job-name')
    expect(job_defaults['redis'].keys).to include('blazingly')
    expect(job_defaults['redis']['blazingly']).to be_empty
  end
end
