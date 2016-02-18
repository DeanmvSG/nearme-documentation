node[:deploy].each do |application, deploy|

  file "Create shared/config/application.yml"  do
    path    "#{::File.join(deploy[:deploy_to], 'shared', 'config', 'application.yml')}"
    group   deploy[:group]
    owner   deploy[:user]
    mode    "0660"
    content YAML.dump(deploy['environment'].to_hash.merge((deploy['custom_env'] || {}).to_hash.merge({'GIT_VERSION' => `cd #{deploy[:deploy_to]}; git describe`})))
  end

  directory "Create shared/node_modules" do
    path  "#{::File.join(deploy[:deploy_to], 'shared', 'node_modules')}"
    mode  "0770"
    group deploy[:group]
    owner deploy[:user]
  end

end

