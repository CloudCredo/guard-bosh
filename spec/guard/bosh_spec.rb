require 'pathname'
require 'guard/compat/test/helper'

require 'guard/bosh/change_assessor'
require 'guard/bosh/job_repository'
require 'guard/bosh/template_checker'
require 'guard/bosh/notifier'

describe Guard::Bosh do
  let(:change_assessor) { instance_double(Guard::Bosh::ChangeAssessor) }
  let(:job_repository) { instance_double(Guard::Bosh::JobRepository) }
  let(:template_checker) { instance_double(Guard::Bosh::TemplateChecker) }
  let(:notifier) { instance_double(Guard::Bosh::Notifier) }
  let(:deployment_manifest_path) { '/path/to/manifest.yml' }

  subject do
    Guard::Bosh.new(
      deployment_manifest: deployment_manifest_path,
      change_assessor: change_assessor,
      job_repository: job_repository,
      template_checker: template_checker,
      notifier: notifier
    )
  end

  context 'when a deployment manifest is not specified' do
    it 'raises an error' do
      expect { Guard::Bosh.new }.to raise_error(
        'Please specify the deployment_manifest in your Guardfile')
    end
  end

  context 'when a template is modified' do
    before do
      expect(change_assessor).to receive(:determine_scope).with(
        ['jobs/redis/templates/redis.conf.erb']).and_return(
          [:single_template, 'redis'])
      expect(job_repository).to receive(:find_by_template).with(
        'redis').and_return(%w(redis_leader_z1 redis_slave_z2))
    end
    context 'when there are no errors' do
      it 'checks the template for errors' do
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_leader_z1',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis.conf.erb'
        ).and_return([])
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_slave_z2',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis.conf.erb'
        ).and_return([])
        expect(notifier).to receive(:notify).with([]).once
        subject.run_on_modifications(['jobs/redis/templates/redis.conf.erb'])
      end
    end
    context 'when there are errors' do
      it 'reports the errors' do
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_leader_z1',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis.conf.erb'
        ).and_return([{
                       template: 'config.erb',
                       status: :failure,
                       detail: 'Missing property: redis.port'
                     }])
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_slave_z2',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis.conf.erb'
        ).and_return([{
                       template: 'config.erb',
                       status: :failure,
                       detail: 'Missing property: redis.port'
                     }])
        expect(notifier).to receive(:notify).with([
          {
            template: 'config.erb',
            status: :failure,
            detail: 'Missing property: redis.port'
          },
          {
            template: 'config.erb',
            status: :failure,
            detail: 'Missing property: redis.port'
          }
        ]).once
        expect(subject).to receive(:throw).with(:task_has_failed)
        subject.run_on_modifications(['jobs/redis/templates/redis.conf.erb'])
      end
    end
  end

  context 'when a job specification is modified' do
    before do
      expect(change_assessor).to receive(:determine_scope).with(
        ['jobs/redis/spec']).and_return([:all_templates_for_job, 'redis'])

      expect(job_repository).to receive(:find_by_template).with(
        'redis').and_return(%w(redis_leader_z1 redis_slave_z2))

      expect(job_repository).to receive(:template_paths).with('redis').and_return([
        'jobs/redis/templates/redis_ctl.sh.erb',
        'jobs/redis/templates/redis.conf.erb'
      ])
    end
    context 'when there are no errors' do
      it 'checks the template for errors' do
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_leader_z1',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis_ctl.sh.erb'
        ).and_return([])
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_leader_z1',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis.conf.erb'
        ).and_return([])
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_slave_z2',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis_ctl.sh.erb'
        ).and_return([])
        expect(template_checker).to receive(:check).with(
          manifest_job_name: 'redis_slave_z2',
          job_name: 'redis',
          template: 'jobs/redis/templates/redis.conf.erb'
        ).and_return([])
        expect(notifier).to receive(:notify).with([]).once
        subject.run_on_modifications(['jobs/redis/spec'])
      end
    end
  end

  shared_context 'expect a complete check of all templates' do
    before do
      expect(job_repository).to receive(:job_templates).and_return(
        %w(postgresql redis))
      expect(job_repository).to receive(:template_paths).with('postgresql').and_return([
        'jobs/postgresql/templates/pg_hba.conf.erb'
      ])
      expect(job_repository).to receive(:template_paths).with('redis').and_return([
        'jobs/redis/templates/redis_ctl.sh.erb',
        'jobs/redis/templates/redis.conf.erb'
      ])
      expect(template_checker).to receive(:check).with(
        manifest_job_name: 'redis_slave_z2',
        job_name: 'redis',
        template: 'jobs/redis/templates/redis.conf.erb'
      ).and_return([])
      expect(job_repository).to receive(:find_by_template).with(
      'redis').and_return(%w(redis_leader_z1 redis_slave_z2))
      expect(job_repository).to receive(:find_by_template).with(
        'postgresql').and_return(['postgresql_z1'])
      expect(template_checker).to receive(:check).with(
        manifest_job_name: 'redis_leader_z1',
        job_name: 'redis',
        template: 'jobs/redis/templates/redis_ctl.sh.erb'
      ).and_return([])
      expect(template_checker).to receive(:check).with(
        manifest_job_name: 'redis_leader_z1',
        job_name: 'redis',
        template: 'jobs/redis/templates/redis.conf.erb'
      ).and_return([])
      expect(template_checker).to receive(:check).with(
        manifest_job_name: 'redis_slave_z2',
        job_name: 'redis',
        template: 'jobs/redis/templates/redis_ctl.sh.erb'
      ).and_return([])
      expect(template_checker).to receive(:check).with(
        manifest_job_name: 'postgresql_z1',
        job_name: 'postgresql',
        template: 'jobs/postgresql/templates/pg_hba.conf.erb'
      ).and_return([])
      expect(notifier).to receive(:notify).with([]).once
    end
  end

  context 'when the manifest is modified' do
    include_context 'expect a complete check of all templates'
    it 'checks all jobs and templates for errors' do
      allow(subject).to receive(:reload_deployment_manifest)
      expect(change_assessor).to receive(:determine_scope).with(
        [deployment_manifest_path]).and_return([:all])
      subject.run_on_modifications([deployment_manifest_path])
    end
    it 'reloads the manifest' do
      allow(change_assessor).to receive(:determine_scope).with(
        [deployment_manifest_path]).and_return([:all])
      expect(subject).to receive(:reload_deployment_manifest)
      subject.run_on_modifications([deployment_manifest_path])
    end
  end

  context 'when the user requests that all templates are checked' do
    include_context 'expect a complete check of all templates'
    it 'checks all jobs and templates for errors' do
      subject.run_all
    end
  end
end
