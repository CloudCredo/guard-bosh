directories %w(lib spec)
clearing :on

guard :rspec, cmd: 'NO_COVERAGE=true rspec' do
  watch(/^spec\/.+_spec\.rb$/)
  watch(/^lib\/(.+)\.rb$/)     { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec' }
end

notification :tmux,
             display_message: true,
             timeout: 5,
             default_message_format: '%s >> %s',
             line_separator: ' > ',
             color_location: 'status-left-bg',
             default_message_color: 'black',
             success: 'colour150',
             failure: 'colour174',
             pending: 'colour179',
             display_on_all_clients: false
