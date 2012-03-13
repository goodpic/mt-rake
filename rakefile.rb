# You can write your configuration in config.rb or here
begin
  load "./config.rb"
  puts "config.rb was found."
rescue LoadError
  puts "config.rb was not found."
  REPO_REMOTE = "git@github.com:movabletype/movabletype.git"
  REPO_LOCAL  = ""
  DEPLOY_DIR  = ""
  MYUSER = ""
  MYPASS = ""
end

directory DEPLOY_DIR
directory REPO_LOCAL

namespace :mt do
  desc "Update your movable type from the github"
  task :pull => REPO_LOCAL do |t, args|
    puts "Trying to git pull #{REPO_LOCAL}"

    cd "#{REPO_LOCAL}" do
      sh %{make clean}
      sh %{git pull}
    end
    Rake::Task['mt:deploy'].invoke
  end

  desc "Checkout movable type from the github repository with specifying the branch to ARG[1]"
  task :co,[:branch] => REPO_LOCAL do |t, args|
    puts "Trying to git pull #{REPO_LOCAL}"

    cd "#{REPO_LOCAL}" do
      sh %{make clean}
      sh %{git checkout #{args.branch}}
    end
    Rake::Task['mysql:create'].invoke("mt_" << args.branch)
    Rake::Task['mt:deploy'].invoke
  end

  desc "Deploy the latest code"
  task :deploy => [REPO_LOCAL,DEPLOY_DIR] do
    cd "#{REPO_LOCAL}" do
      sh %{git archive --format=tar HEAD | tar -x -C #{DEPLOY_DIR}}
    end
    cd "#{DEPLOY_DIR}" do
      sh %{make me}
    end
    puts "Deployed to #{DEPLOY_DIR}"
  end

end


namespace :mysql do
  desc "create database, specify dbname by ARG[1]"
  task :create,[:dbname] => REPO_LOCAL do |t, args|
    args.with_defaults(:dbname => "test")
    sh "mysql -u #{MYUSER} -p#{MYPASS} -e \"create database IF NOT EXISTS #{args.dbname}\""
  end
end


desc "The default task"
task :my_task do
  puts "This is a default task."
  puts "REPO_LOCAL is #{REPO_LOCAL}"
end

task :default => ["my_task"]

