Dir[File.join(Rails.root, *%w[lib ext *.rb])].each {|f| require f}
