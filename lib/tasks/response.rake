namespace :response do
  desc "Fetch data"
  task :fetch_data => :environment do
    Response.fetch_data
  end
end