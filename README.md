# guard-bosh

Guard BOSH is a [Guard](http://guardgem.org/) plugin to make it easier to
develop [BOSH](https://github.com/cloudfoundry/bosh) releases.

Currently it will monitor your templates and a deployment manifest for any
changes and report missing BOSH properties or template errors.

## Example setup

```
$ git clone https://github.com/pivotal-cf/cf-rabbitmq-release.git
$ cd cf-rabbitmq-release

# Create a Gemfile, or add guard and guard-bosh to your existing Gemfile
$ if [ ! -f 'Gemfile' ]; then echo "source 'https://rubygems.org'" > Gemfile; fi
$ echo "gem 'guard'" >> Gemfile
$ echo "gem 'guard-bosh'" >> Gemfile
$ bundle

# Generate a Guardfile you can then customise
$ bundle exec guard init
```

Guard BOSH requires a manifest to work. Update the references to the manifest
in the generated Guardfile:

```
$ gsed -i 's|path/to/manifest.yml|manifests/cf-rabbitmq-lite.yml|' Guardfile

# For Rabbit we need to tell it to monitor the manifests directory
# rather than the templates directory.
$ gsed -i 's|%w(jobs templates)|%w(jobs manifests)|' Guardfile
```

Now we can start Guard:

```
$ bundle exec guard
```

## Backlog

You can review the
[backlog for Guard BOSH](https://www.pivotaltracker.com/n/projects/1302220) on
the public Pivotal Tracker project.
