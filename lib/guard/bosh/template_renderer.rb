require 'json'
require 'bosh/template/renderer'
require 'bosh/template/unknown_property'

module Guard
  class Bosh
    class TemplateRenderer
      def render(context:, template:)
        renderer = ::Bosh::Template::Renderer.new(
          context: JSON.generate(context))

        # The re-writing of messages we do here is intended to make the output
        # more readable, but may not be wise.
        begin
          renderer.render(template)
          { template: template, status: :success, detail: '' }
        rescue ::Bosh::Template::UnknownProperty => e
          error(template, "missing property: #{e.name}")
        rescue NoMethodError => e
          error(template, e.message.sub(/ for #<[^>]+>$/, ''))
        rescue NameError => e
          error(template, e.message.sub(/ for #<[^>]+>$/, ''))
        rescue SyntaxError => e
          error(template, e.message.split("\n").first.sub(
            /^\(erb\):[0-9]+: /, ''))
        end
      end

      private

      def error(template, message)
        {
          template: template,
          status: :failure,
          detail: message
        }
      end
    end
  end
end
