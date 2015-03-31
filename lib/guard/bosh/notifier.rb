require 'guard/compat'

module Guard
  class Bosh
    class Notifier
      def notify(errors)
        if errors.empty?
          Guard::Compat::UI.notify(
            'Succeeded', title: 'BOSH', image: :success, priority: -2)
        else
          Guard::Compat::UI.error(
            '%s: %s' % [errors.first[:template], errors.first[:detail]])
          Guard::Compat::UI.notify(
            'Failed', title: 'BOSH', image: :failed, priority: 2)
        end
      end
    end
  end
end
