require 'guard/bosh/template_renderer'

require 'pathname'

describe Guard::Bosh::TemplateRenderer do
  subject do
    Guard::Bosh::TemplateRenderer.new
  end

  let(:bosh_renderer) { instance_double(::Bosh::Template::Renderer) }
  before do
    expect(::Bosh::Template::Renderer).to receive(:new).with(
      context: '{}').and_return(bosh_renderer)
  end

  context 'when the template contains no errors' do
    it 'reports that no error occurred' do
      expect(bosh_renderer).to receive(:render).with('config.erb')
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(template: 'config.erb', status: :success, detail: '')
    end
  end

  context 'when the template refers to an unknown property' do
    it 'reports the missing property' do
      expect(bosh_renderer).to receive(:render).with('config.erb').and_raise(
        ::Bosh::Template::UnknownProperty.new('redis.port'))
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(
        template: 'config.erb',
        status: :failure,
        detail: 'missing property: redis.port'
      )
    end
  end

  context 'when the template calls a misnamed helper method' do
    it 'reports the missing helper method' do
      expect(bosh_renderer).to receive(:render).with('config.erb').and_raise(
        NoMethodError.new("undefined method `o' for #<Bosh::Template::EvaluationContext:0x00000000000000>"))
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(
        template: 'config.erb',
        status: :failure,
        detail: "undefined method `o'"
      )
    end
  end

  context 'when the template references a missing name' do
    it 'reports the missing name' do
      expect(bosh_renderer).to receive(:render).with('config.erb').and_raise(
        NameError.new("undefined local variable or method `missing' for #<Bosh::Template::EvaluationContext:0x00000000000000>"))
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(
        template: 'config.erb',
        status: :failure,
        detail: "undefined local variable or method `missing'"
      )
    end
  end

  context 'when the template is not well-formed' do
    it 'reports the template error' do
      expect(bosh_renderer).to receive(:render).with('config.erb').and_raise(
        SyntaxError.new("(erb):7: syntax error, unexpected end-of-input, expecting keyword_end\n; _erbout.force_encoding(__ENCODING__)"))
      result = subject.render(context: {}, template: 'config.erb')
      expect(result).to eq(
        template: 'config.erb',
        status: :failure,
        detail: 'syntax error, unexpected end-of-input, expecting keyword_end'
      )
    end
  end
end
