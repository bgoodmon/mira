#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Tufts::Application.load_tasks

# Get rid of the default task (was spec)
task :default => []; Rake::Task[:default].clear

task :default => [:ci]

require 'resque/tasks'

task "resque:setup" => :environment
