require 'guard/bosh/change_assessor'

require 'pathname'

describe Guard::Bosh::ChangeAssessor do
  subject do
    Guard::Bosh::ChangeAssessor.new(Pathname.new('templates/manifest.yml'))
  end

  context 'when a final.yml has been modified' do
    it 'reports a scope that means the change can be ignored' do
      change_scope, _ = subject.determine_scope(['config/final.yml'])
      expect(change_scope).to eq(:none)
    end
  end

  context 'when the deployment manifest has been modified' do
    it 'reports a scope that means all jobs and templates must be re-evaluated' do
      change_scope, _ = subject.determine_scope(['templates/manifest.yml'])
      expect(change_scope).to eq(:all)
    end
  end

  context 'when a job spec has been modified' do
    it 'reports a scope that means all templates must be evaluated for a single job' do
      change_scope, _ = subject.determine_scope(['jobs/redis/spec'])
      expect(change_scope).to eq(:all_templates_for_job)
    end
    it 'reports the correct job name' do
      _, job_name = subject.determine_scope(['jobs/redis/spec'])
      expect(job_name).to eq('redis')
    end
  end

  context 'when a job template has been modified' do
    it 'reports a scope that means a single template must be evaluated for a single job' do
      change_scope, _ = subject.determine_scope(['jobs/redis/templates/config/redis.conf.erb'])
      expect(change_scope).to eq(:single_template)
    end
    it 'reports the correct job name' do
      _, job_name = subject.determine_scope(['jobs/redis/templates/config/redis.conf.erb'])
      expect(job_name).to eq('redis')
    end
  end

  context 'when multiple job specs have been modified across jobs' do
    it 'reports a scope that means all jobs and templates must be re-evaluated' do
      change_scope, _ = subject.determine_scope([
        'jobs/redis/spec',
        'jobs/postgresql/spec'
      ])
      expect(change_scope).to eq(:all)
    end
  end

  context 'when multiple templates have been modified across jobs' do
    it 'reports a scope that means all jobs and templates must be re-evaluated' do
      change_scope, _ = subject.determine_scope([
        'jobs/redis/templates/config/redis.conf.erb',
        'jobs/postgresql/templates/config/pg_hba.conf.erb'
      ])
      expect(change_scope).to eq(:all)
    end
  end
end
