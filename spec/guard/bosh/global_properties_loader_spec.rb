require 'guard/bosh/global_properties_loader'

describe Guard::Bosh::GlobalPropertiesLoader do
  let(:deployment_manifest) do
    {
      'jobs' => %w(some jobs),
      'networks' => %w(some networks),
      'properties' => {
        'global' => 'property'
      }
    }
  end
  let(:deployment_manifest_without_global_properties) do
    deployment_manifest.tap do |manifest|
      manifest.delete('properties')
    end
  end
  subject do
    Guard::Bosh::GlobalPropertiesLoader.new(
      deployment_manifest: deployment_manifest)
  end

  context 'when the manifest contains global properties section' do
    it 'returns them' do
      expect(subject.load_properties('ignored')).to eq('global' => 'property')
    end
  end

  context 'when the manifest does not contain a global properties section' do
    subject do
      Guard::Bosh::GlobalPropertiesLoader.new(
        deployment_manifest: deployment_manifest_without_global_properties)
    end
    it 'returns an empty' do
      expect(subject.load_properties('ignored')).to be_empty
    end
  end
end
