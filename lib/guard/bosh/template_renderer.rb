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
          error(template, "missing property: #{e.name}", line(e))
        rescue NoMethodError, NameError => e
          error(template, remove_bosh_template(e.message), line(e))
        rescue SyntaxError => e
          context = find_erb_error(e.message)
          error(template, context['message'], context['line'].to_i)
        end
      end

      private

      def error(template, message, line)
        {
          template: template,
          status: :failure,
          detail: message,
          line: line
        }
      end

      def line(error)
        erb_error = find_erb_error(error.backtrace)
        if erb_error.nil?
          :unknown
        else
          erb_error['line'].to_i
        end
      end

      ERB_LINE_PATTERN = /^\(erb\):(?<line>[0-9]+): ?(?<message>.*)/

      def find_erb_error(error_lines)
        # '(erb):4: syntax error, unexpected keyword_do_block'
        Array(error_lines).lazy.grep(ERB_LINE_PATTERN) do |error_line|
          ERB_LINE_PATTERN.match(error_line)
        end.first
      end

      def remove_bosh_template(message)
        # ' for #<Bosh::Template::EvaluationContext:0x00000000000000>'
        message.sub(/ for #<Bosh::Template::[^>]+>$/, '')
      end
    end
  end
end
