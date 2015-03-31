require 'guard/bosh/template_renderer'

require 'pathname'

describe Guard::Bosh::TemplateRenderer do
  subject do
    Guard::Bosh::TemplateRenderer.new
  end

  context 'when the template contains no errors' do
    it 'reports that no error occurred' do
      bosh_renderer = instance_double(::Bosh::Template::Renderer)
      expect(::Bosh::Template::Renderer).to receive(:new).with(context: '{}').and_return(bosh_renderer)
      expect(bosh_renderer).to receive(:render).with('config.erb')
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(template: 'config.erb', status: :success, detail: '')
    end
  end

  context 'when the template refers to an unknown property' do
    it 'reports the missing property' do
      bosh_renderer = instance_double(::Bosh::Template::Renderer)
      expect(::Bosh::Template::Renderer).to receive(:new).with(context: '{}').and_return(bosh_renderer)
      expect(bosh_renderer).to receive(:render).with('config.erb').and_raise(::Bosh::Template::UnknownProperty.new('redis.port'))
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(template: 'config.erb', status: :failure, detail: 'Missing property: redis.port')
    end
  end
end
