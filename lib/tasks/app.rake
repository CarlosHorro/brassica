namespace :app do
  desc "Prepare DB and ES from zero to production-ready state"
  task :bootstrap => :environment do
    unless ask_for_confirmation
      puts "Exiting."
      next
    end
    puts " - dropping old DB and creating a new one"
    recreate_db
    puts " - loading cropstore DB dump data"
    restore_cropstore_dump
    puts " - run further migrations"
    silence_stdout do
      migrate_db
    end
    puts " - building ES indices"
    build_elasticsearch_indices
    puts " - DONE"
  end

  def ask_for_confirmation
    print "This will drop and recreate database resulting in potential data loss.\n"
    print "Are you sure? (y/n): "
    $stdin.getc.downcase == 'y'
  end

  def recreate_db
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
  end

  def restore_cropstore_dump
    db_config = Rails.application.config_for(:database)
    env = { "PGUSER" => db_config["username"], "PGPASSWORD" => db_config["password"] }
    cmd = "pg_restore -O -d #{db_config["database"]} db/cropstore_web_20160616_1214.dump"
    unless system(env, cmd)
      raise "Cropstore dump restoration failed: #{$?}"
    end
  end

  def migrate_db
    Rake::Task['db:migrate'].invoke
  end

  def build_elasticsearch_indices
    Rake::Task['elasticsearch:import:all'].invoke
  end

  def silence_stdout
    $stdout = File.new( '/dev/null', 'w' )
    yield
  ensure
    $stdout = STDOUT
  end
end
