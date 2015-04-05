require 'guard/bosh/notifier'

describe Guard::Bosh::Notifier do
  before do
    allow(Guard::Compat::UI).to receive(:notify)
    allow(Guard::Compat::UI).to receive(:error)
  end

  context 'when there are no errors' do
    it 'reports success' do
      expect(Guard::Compat::UI).to receive(:notify).with(
        'Succeeded',
        title: 'BOSH',
        image: :success,
        priority: -2
      )
      subject.notify([])
    end
  end

  context 'when there are errors' do
    it 'reports failure' do
      expect(Guard::Compat::UI).to receive(:notify).with(
        'Failed',
        title: 'BOSH',
        image: :failed,
        priority: 2
      )
      subject.notify([
        { template: 'config.erb', status: :failure, detail: 'Missing property: redis.port' }
      ])
    end
    it 'outputs the template the error occurred in and the detail' do
      expect(Guard::Compat::UI).to receive(:error).with('config.erb:10: missing property: redis.port')
      subject.notify([
        { template: 'config.erb', status: :failure, detail: 'missing property: redis.port', line: 10 }
      ])
    end
    context 'when the line number is not known' do
      it 'outputs the template the error occurred in and the detail' do
        expect(Guard::Compat::UI).to receive(:error).with('config.erb:?: missing property: redis.port')
        subject.notify([
          { template: 'config.erb', status: :failure, detail: 'missing property: redis.port', line: :unknown }
        ])
      end
    end
  end
end
