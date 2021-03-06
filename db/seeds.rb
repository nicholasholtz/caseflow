# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'database_cleaner'

class SeedDB
  def initialize
    @appeals, @tasks, @users = [], [], []
  end

  def create_appeals(number)
    appeals = number.times.map do |i|
      Appeal.create(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}"
        )
    end
    @appeals.push(*appeals)
  end

  def create_users(number, deterministic = true)
    users = number.times.map do |i|
      length = VACOLS::RegionalOffice::STATIONS.length
      station_index = deterministic ? (i % length) : (rand(length))
      User.create(
        station_id: VACOLS::RegionalOffice::STATIONS.keys[station_index],
        css_id: "css_#{i}",
        full_name: "name_#{i}",
        email: "test#{i}@example.com"
        )
    end

    @users.push(*users)
  end

  def create_tasks(number)
    num_appeals = @appeals.length
    num_users = @users.length

    tasks = number.times.map do |i|
      establish_claim = EstablishClaim.create(
        appeal: @appeals[i % num_appeals]
        )
      establish_claim.prepare!
      establish_claim
    end

    # Give each user a task in a different state
    tasks[0].assign!(@users[0])

    tasks[1].assign!(@users[1])
    tasks[1].start!

    tasks[2].assign!(@users[2])
    tasks[2].start!
    tasks[2].review!
    tasks[2].complete!(status: 0)

    # Create one task with no decision documents
    EstablishClaim.create(
      appeal: tasks[2].appeal
    )

    @tasks.push(*tasks)
  end

  def create_default_users
    @users.push(User.create(css_id: "Invalid Role", station_id: "283", full_name: "Cave Johnson"))
    @users.push(User.create(css_id: "Establish Claim", station_id: "283", full_name: "Jane Smith"))
    @users.push(User.create(css_id: "Establish Claim", station_id: "284", full_name: "Bob Contoso"))
    @users.push(User.create(css_id: "Establish Claim", station_id: "285", full_name: "Carole Johnson"))
    @users.push(User.create(css_id: "Manage Claim Establishment", station_id: "283", full_name: "John Doe"))
    @users.push(User.create(css_id: "Certify Appeal", station_id: "283", full_name: "John Smith"))
    @users.push(User.create(css_id: "System Admin", station_id: "283", full_name: "Angelina Smith"))
  end

  def clean_db
    DatabaseCleaner.clean_with(:truncation)
  end

  def seed
    clean_db
    create_default_users
    create_appeals(50)
    create_users(3)
    create_tasks(50)
  end
end


SeedDB.new.seed
