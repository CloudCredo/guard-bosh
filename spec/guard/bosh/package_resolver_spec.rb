require 'guard/bosh/package_resolver'

require 'pathname'

describe Guard::Bosh::PackageResolver do
  subject do
    Guard::Bosh::PackageResolver.new(Pathname.new('/path/to/release/dir/'))
  end

  it 'resolves the package associated with the specified job' do
    expect(YAML).to receive(:load_file).with(
      Pathname.new('/path/to/release/dir/jobs/redis/spec')
    ).and_return('packages' => ['redis'])
    expect(subject.resolve('redis')).to eq(['redis'])
  end

  it 'raises if the job spec cannot be loaded' do
    expect(YAML).to receive(:load_file)
    expect do
      subject.resolve('redis')
    end.to raise_error
  end
end
