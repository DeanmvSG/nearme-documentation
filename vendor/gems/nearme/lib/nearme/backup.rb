require 'pp'
require 'aws'

module NearMe
  class Backup

    def initialize(options = {})
      @stack_name = options[:stack]
      @host_name = options[:host] || stack_to_host_mapping[@stack_name]
      @environment = options[:environment] || stack_to_env_mapping[@stack_name]

      if ENV['AWS_PEM_FILE_PATH'].nil?
        puts "You must set the AWS_PEM_FILE_PATH enviroment variable for AWS."
        exit 1
      end

      if ENV['AWS_USER'].nil?
        puts "You must set the AWS_USER enviroment variable for AWS."
        exit 1
      end

      if ENV['AWS_ACCESS_KEY_ID'].nil?
        puts "You must set the AWS_ACCESS_KEY_ID enviroment variable for AWS."
        exit 1
      end

      if ENV['AWS_SECRET_ACCESS_KEY'].nil?
        puts "You must set the AWS_SECRET_ACCESS_KEY enviroment variable for AWS."
        exit 1
      end

      if not stack_id.nil?
        puts "Stack id: #{stack_id} (#{@stack_name})"
      else
        puts "Cannot find stack by name #{@stack_name}"
        exit 1
      end

      if not instance.empty?
        puts "Instance found for host #{@host_name}"
      else
        puts "Cannot find instance for host #{@host_name}"
        exit 1
      end

      if not public_dns.empty?
        puts "Public dns (#{public_dns}) found for host #{@host_name}"
      else
        puts "Cannot find public dns for host #{@host_name}"
        exit 1
      end
    end

    # This maps the default host (ec2 instance) we want the scripts to run on for a stack
    def stack_to_host_mapping
      {
        'nm-production' => 'utility1',
        'nm-staging' => 'rails-app-1',
        'nm-qa-1' => 'rails-qa-1',
        'nm-qa-2' => 'rails-qa-2'
      }
    end

    # This maps the default rails env we want the scripts to run in for a stack
    def stack_to_env_mapping
      {
        'nm-production' => 'production',
        'nm-staging' => 'staging',
        'nm-qa-1' => 'staging',
        'nm-qa-2' => 'staging'
      }
    end

    def opsworks_client
      @opsworks_client ||= AWS.ops_works.client
    end

    def stacks
      @stacks ||= opsworks_client.describe_stacks.data.fetch(:stacks, {})
    end

    def stack
      @stack ||= stacks.find(-> {{}}) {|stack| stack[:name] == @stack_name}
    end

    def stack_id
      @stack_id ||= stack.fetch(:stack_id, nil)
    end

    def instances
      @instances ||= opsworks_client.describe_instances(stack_id: stack_id).data.fetch(:instances, {})
    end

    def instance
      @instance ||= instances.find(-> {{}}) {|instance| instance[:hostname] == @host_name}
    end

    def public_dns
      @public_dns ||= instance.fetch(:public_dns, {})
    end

    def capture!
      puts "Creating remote db dump..."
      remote_command = "sudo -H -u deploy bash -c 'cd /srv/www/nearme/current && AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']} RAILS_ENV=#{@environment} bundle exec rake backup:capture'"
      run_remote_command(remote_command)
    end

    def restore!
      if @stack_name == 'nm-production'
        puts "[Error] This tool is not meant to restore to the production db."
        exit 1
      end

      puts "Restoring remote db dump..."
      remote_command = "sudo -H -u deploy bash -c 'cd /srv/www/nearme/current && AWS_ACCESS_KEY_ID=#{ENV['AWS_ACCESS_KEY_ID']} AWS_SECRET_ACCESS_KEY=#{ENV['AWS_SECRET_ACCESS_KEY']} RAILS_ENV=#{@environment} bundle exec rake backup:restore'"
      run_remote_command(remote_command)
    end

    private

    def run_remote_command(remote_command)
      if not Kernel.system("ssh -i #{ENV['AWS_PEM_FILE_PATH']} #{ENV['AWS_USER']}@#{public_dns} \"#{remote_command}\"")
        puts "Remote command failed."
        exit 1
      end
    end

  end
end
