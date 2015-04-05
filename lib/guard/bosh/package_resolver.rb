module Guard
  class Bosh
    # Packages for a given BOSH job
    class PackageResolver
      def initialize(release_dir)
        @release_dir = release_dir
      end

      def resolve(job)
        job_spec = @release_dir + 'jobs' + job + 'spec'
        YAML.load_file(job_spec)['packages']
      end
    end
  end
end
