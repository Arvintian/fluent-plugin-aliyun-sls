project = fluent-plugin-aliyun-sls
version = 0.1.0

build:
	gem build $(project).gemspec

install: build
	gem uninstall $(project)
	gem install $(project)-$(version).gem

clean:
	gem uninstall $(project)
	rm -vf $(project)-$(version).gem