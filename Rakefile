def clean
  Dir['redis-roc-*.gem'].each{|f| File.unlink(f)}
end

def build
  `gem build roc.gemspec`
end

def publish_local
  dir = '~/Development/Gems/'
  `cp redis-roc-*.gem #{dir}/gems/`
  `gem generate_index --update --modern -d #{dir}`
end

def publish_remote
  `gem push redis-roc-*.gem`
end

def uninstall
  `sudo gem uninstall redis-roc`
end

def install_local
  do_install('http://localhost/Gems/')
end

def install_remote
  do_install
end

def do_install(source=nil)
  cmd = 'sudo gem install redis-roc'
  if !source.nil?
    cmd << " --source #{source}"
  end
  `#{cmd}`
end

def run_tests
  puts `test/all gem`
end

def test
  clean
  uninstall
  build
  publish_local
  install_local
  run_tests
end

namespace :gem do 
  task(:clean){clean}
  task(:build){build}
  task(:uninstall){uninstall}
  task(:install_local){install_local}
  task(:install_remote){install_remote}
  task(:publish_local){publish_local}
  task(:publish_remote){publish_remote}
  task(:test){test}
end
