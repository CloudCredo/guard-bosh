require 'json'
require 'bosh/template/renderer'
require 'bosh/template/unknown_property'

module Guard
  class Bosh
    class TemplateRenderer
      def render(context:, template:)
        renderer = ::Bosh::Template::Renderer.new(
          context: JSON.generate(context))
        begin
          renderer.render(template)
          { template: template, status: :success, detail: '' }
        rescue ::Bosh::Template::UnknownProperty => e
          {
            template: template,
            status: :failure,
            detail: "Missing property: #{e.name}"
          }
        end
      end
    end
  end
end
