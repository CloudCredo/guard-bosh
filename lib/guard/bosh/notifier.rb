require 'guard/compat'

module Guard
  class Bosh
    class Notifier
      def notify(errors)
        if errors.empty?
          Guard::Compat::UI.notify(
            'Succeeded', title: 'BOSH', image: :success, priority: -2)
        else
          Guard::Compat::UI.error(error_line(errors))
          Guard::Compat::UI.notify(
            'Failed', title: 'BOSH', image: :failed, priority: 2)
        end
      end

      private

      def error_line(errors)
        error = errors.first
        [
          error[:template],
          error[:line] == :unknown ? '?' : error[:line],
          " #{error[:detail]}"
        ].join(':')
      end
    end
  end
end
