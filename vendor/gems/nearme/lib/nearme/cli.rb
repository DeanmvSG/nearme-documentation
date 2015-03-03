require 'thor'
require 'nearme'

module NearMe
  class CLI < Thor
    include Thor::Actions

    desc "info", "currect opsworks stack info"
    long_desc <<DESC
    get info about the current opsworks stacks
    for example:

    nearme info

    will show you the current stacks and some assorted info
DESC

    def info
      puts "Retrieving opsworks stack info..."
      result = NearMe::Info.new(options).status
    end

    desc "deploy", "deploy NearMe application to AWS OpsWorks"
    long_desc <<DESC
    deploy NearMe application to AWS OpsWorks

    for example:

    nearme deploy -r my-little-staging -e nm-staging --comment "deploy pls"

    will deploy branch my-little-staging to nm-staging AWS OpsWorks stack
DESC
    method_option "branch", required: true, type: :string,
                  aliases: :r, desc: "git branch to deploy"
    method_option "stack", required: true, type: :string,
                  aliases: :e, desc: "AWS OpsWorks stack name"
    method_option "environment", required: false, type: :string,
                  aliases: :v, desc: "Rails environtment"
    method_option "migrate", required: false, type: :boolean,
                  default: true, desc: "Trigger migration"
    method_option "assets", required: false, type: :boolean,
                  default: true, desc: "Sync assets"
    method_option "bucket", required: false, type: :string,
                  aliases: :b, desc: "S3 bucket name"
    method_option "comment", required: false, type: :string,
                  desc: "deploy comment"
    method_option "watch", required: false, type: :boolean,
                  default: true, desc: "wait until deploy is finished and print report"

    def deploy
      deployment_check

      if options[:assets]
        puts "Assets sync..."
        result = NearMe::SyncAssets.new(options).start!
        puts "Assets sync done."
      end

      puts "Deploying..."
      deploy = NearMe::Deploy.new(options)
      result = deploy.start!
      deployment_id = result.data[:deployment_id]
      puts "Deploy started with ID: #{deployment_id}"
      if options[:watch]
        puts "Waiting until deploy is done."
        deploy.watch!(deployment_id)
      end
    end

    desc "sync_assets", "synchronize assets with S3 bucket"
    long_desc <<DESC
    sync NearMe application assets to S3
    for example:

    nearme sync_assets -r my-branch -b near-me-assets-staging-2
    nearme sync_assets -r my-branch -e nm-staging-2

    will compile assets and sync it to S3 bucket
DESC
    method_option "branch", required: true, type: :string,
                  aliases: :r, desc: "git branch to synch"
    method_option "bucket", required: false, type: :string,
                  aliases: :b, desc: "S3 bucket name"
    method_option "stack", required: true, type: :string,
                  aliases: :e, desc: "AWS OpsWorks stack name"
    method_option "environment", required: false, type: :string,
                  aliases: :v, desc: "Rails environtment"

    def sync_assets
      deployment_check

      puts "Assets sync..."
      result = NearMe::SyncAssets.new(options).start!
      puts "Assets sync done."
    end

    desc "capture", "capture db dump to S3"
    long_desc <<DESC
    dump stack database to S3
    for example:

    nearme capture -e nm-production

    will dump the qa-1 stack db and store it in S3
DESC
    method_option "stack", required: true, type: :string,
                  aliases: :e, default: 'nm-production', desc: "AWS OpsWorks stack name"
    method_option "host", required: false, type: :string,
                  aliases: :h, desc: "AWS OpsWorks host name"
    method_option "environment", required: false, type: :string,
                  aliases: :v, desc: "Rails environtment"

    def capture
      puts "Capturing db to S3..."
      result = NearMe::Backup.new(options).capture!
      puts "Capture done."
    end

    desc "restore", "restore db from S3"
    long_desc <<DESC
    restore stack database from S3
    for example:

    nearme restore -e nm-qa-1

    will restore the qa-1 stack db from the captured dump in S3
DESC
    method_option "stack", required: true, type: :string,
                  aliases: :e, desc: "AWS OpsWorks stack name"
    method_option "host", required: false, type: :string,
                  aliases: :h, desc: "AWS OpsWorks host name"
    method_option "environment", required: false, type: :string,
                  aliases: :v, desc: "Rails environtment"

    def restore
      deployment_check

      puts "Restoring db from S3..."
      result = NearMe::Backup.new(options).restore!
      puts "Restore done."
    end

    no_commands do

      def deployment_check
        stack = options[:stack]
        environment = options[:environment].to_s

        return true unless stack.include?('production')

        if !environment.empty? && environment != 'production'
          puts 'ERROR: You cannot use this environment for production stack'
          exit 1
        end

        banner = <<'BANNER'
                           _            _   _
                          | |          | | (_)
       _ __  _ __ ___   __| |_   _  ___| |_ _  ___  _ __
      | '_ \| '__/ _ \ / _` | | | |/ __| __| |/ _ \| '_ \
      | |_) | | | (_) | (_| | |_| | (__| |_| | (_) | | | |
      | .__/|_|  \___/ \__,_|\__,_|\___|\__|_|\___/|_| |_|
      | |
      |_|

BANNER

        info = ''
        info << "Branch: #{options[:branch]}\n" if options.has_key?('branch')
        info << "Environment: #{options[:environment]}\n" if options.has_key?('environment')
        info << "Migrate: #{options[:migrate]}\n" if options.has_key?('migrate')
        info << "Assets: #{options[:assets]}\n" if options.has_key?('assets')
        info << "Bucket: #{options[:bucket]}\n" if options.has_key?('bucket')
        info << "Watch: #{options[:watch]}\n" if options.has_key?('watch')
        info << "Host: #{options[:host]}\n" if options.has_key?('host')
        info << "Comment: #{options[:comment]}\n" if options.has_key?('comment')

        banner << info

        banner.each_line do |line|
          line.each_char do |ch|
            print ch
            sleep 0.002
          end
        end

        answer = ask "\nAre you sure you want to perform this action on production? Type 'production' if so:"

        if answer != 'production'
          puts 'Nope!'
          exit 1
        end
      end
    end
  end
end
