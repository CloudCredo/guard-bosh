require 'json'
require 'bosh/template/renderer'
require 'bosh/template/unknown_property'

module Guard
  class Bosh
    # Render a template with the provided context and report any errors.
    class TemplateRenderer
      def render(context:, template:)
        renderer = ::Bosh::Template::Renderer.new(
          context: JSON.generate(context))

        begin
          renderer.render(template)
          { template: template, status: :success, detail: '' }
        rescue StandardError, SyntaxError => e
          generate_user_facing_error(template, e)
        end
      end

      private

      def generate_user_facing_error(template, ex)
        case ex
        when ::Bosh::Template::UnknownProperty
          error(template, "missing property: #{ex.name}", line(ex))
        when NoMethodError, NameError
          error(template, remove_bosh_template(ex.message), line(ex))
        when SyntaxError
          context = find_erb_error(ex.message)
          error(template, context['message'], context['line'].to_i)
        end
      end

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
