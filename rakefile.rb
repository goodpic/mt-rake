# -*- coding: utf-8 -*-
# You can write your configuration in config.rb or here
begin
  load "./config.rb"
  puts "config.rb was found."
rescue LoadError
  puts "config.rb was not found."
  
  # Git information
  REPO_REMOTE = "git@github.com:movabletype/movabletype.git"
  REPO_LOCAL  = ""
  DEPLOY_DIR  = ""
  
  # Your MT settings in mt-config.cgi
  MT_CONFIG = <<EOS
CGIPath         /
StaticWebPath   /mt-static/
StaticFilePath  /PATH/TO/mt-static
ObjectDriver    DBI::mysql
DBHost          localhost
DBPort          8889
DBSocket        /Applications/MAMP/tmp/mysql/mysql.sock
Database        YOUR_DB_NAME
DBUser          YOUR_DB_USER_NAME
DBPassword      YOUR_DB_PASSWORD
ImageDriver     Imager
SendMailPath    /usr/sbin/sendmail
DefaultLanguage ja
EOS
end

# Parse MT_CONFIG as a hash
params = {}
MT_CONFIG.each_line {|line|
  param = line.split(" ")
  params[param[0]] = param[1]
}

# Create a mysql command to create/backup database
db_options  = ""
params.each_pair {|key,value|
  if key =~ /^DB(.*)/
    if $1 == "Password"
      db_options << "-p#{value} "
    else
      db_options << "--#{$1.downcase}=#{value} "
    end
  end
}

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
  desc "Create database, specify dbname by ARG[1]"
  task :create,[:dbname] => REPO_LOCAL do |t, args|
    args.with_defaults(:dbname => "test")
    params['Database'] = "mt_" << args.dbname unless params['Database']
    sh "mysql " << db_options << "-e \"create database IF NOT EXISTS #{params['Database']}\""
  end

  desc "Backup your current database specified by Database attribute in mt-config.cgi"
  task :backup do |t, arg|
    if params['Database']
      sh "mysqldump -a --default-character-set=binary " << db_options << " #{params['Database']} > #{params['Database']}." << Time.now.strftime("%Y-%m-%d-%H-%M-%S.sql") 
    end
  end
end

desc "The default task"
task :my_task do
  puts "This is a default task."
  puts "REPO_LOCAL is #{REPO_LOCAL}"
end

task :default => ["my_task"]

