require 'guard/bosh/job_repository'

describe Guard::Bosh::JobRepository do
  let(:manifest) do
    {
      'jobs' => [
        {
          'name' => 'redis_leader_z1',
          'templates' => [{ 'name' => 'redis', 'release' => 'redis' }]
        },
        {
          'name' => 'postgresql_z1',
          'template' => 'postgresql',
          'properties' => {}
        },
        {
          'name' => 'redis_slave_z2',
          'templates' => [{ 'name' => 'redis', 'release' => 'redis' }]
        }
      ]
    }
  end

  subject do
    Guard::Bosh::JobRepository.new(manifest)
  end

  describe '#job_templates' do
    it 'returns all job templates' do
      expect(subject.job_templates).to eq(%w(postgresql redis))
    end
  end

  describe '#find_by_template' do
    context 'when there are multiple jobs that use a job template' do
      it 'returns all jobs that use that template' do
        expect(subject.find_by_template('redis')).to eq(%w(redis_leader_z1 redis_slave_z2))
      end
    end
  end

  describe '#template_paths' do
    it 'looks up the template paths from the job specification' do
      expect(YAML).to receive(:load_file).with(Pathname.new('jobs/redis/spec')).and_return(
        'templates' => {
          'redis_ctl.sh.erb' => 'bin/redis_ctl.sh',
          'redis.conf.erb' => 'config/redis.conf'
        }
      )
      expect(subject.template_paths('redis')).to eq([
        Pathname.new('jobs/redis/templates/redis_ctl.sh.erb'),
        Pathname.new('jobs/redis/templates/redis.conf.erb')
      ])
    end
  end
end
