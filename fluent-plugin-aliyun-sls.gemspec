# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-aliyun-sls"
  gem.description = "Aliyun SLS output plugin for Fluentd event collector"
  gem.license     = "MIT"
  gem.homepage    = "https://github.com/Arvintian/fluent-plugin-aliyun-sls"
  gem.summary     = gem.description
  gem.version     = File.read("VERSION").strip
  gem.authors     = ["Arvin"]
  gem.email       = "arvintian8@163.com"
  gem.has_rdoc    = false
  gem.files       = `git ls-files | grep -v ext | grep -v package`.split("\n")
  gem.require_paths = ['lib']

  gem.add_dependency "aliyun_sls_sdk", [">= 0.0.9"]
end