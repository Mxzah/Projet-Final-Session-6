# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default users
Administrator.find_or_create_by!(email: 'admin@restoqr.ca') do |user|
  user.first_name = 'Admin'
  user.last_name = 'RestoQR'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Client.find_or_create_by!(email: 'client@restoqr.ca') do |user|
  user.first_name = 'Client'
  user.last_name = 'Test'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Waiter.find_or_create_by!(email: 'waiter@restoqr.ca') do |user|
  user.first_name = 'Serveur'
  user.last_name = 'Test'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

puts "Seeds created successfully!"
puts "- Administrator: admin@restoqr.ca"
puts "- Client: client@restoqr.ca"
puts "- Waiter: waiter@restoqr.ca"
puts "Password for all: password123"

# Create restaurant tables
puts "\nCreating tables..."

tables_data = [
  { number: 1, capacity: 2 },
  { number: 2, capacity: 2 },
  { number: 3, capacity: 4 },
  { number: 4, capacity: 4 },
  { number: 5, capacity: 4 },
  { number: 6, capacity: 6 },
  { number: 7, capacity: 6 },
  { number: 8, capacity: 8 },
  { number: 9, capacity: 8 },
  { number: 10, capacity: 10 }
]

tables_data.each do |td|
  table = Table.find_or_create_by!(number: td[:number]) do |t|
    t.capacity = td[:capacity]
  end
  puts "- Table ##{table.number} (#{table.capacity} places) — Token: #{table.qr_token}"
end

puts "\nAll seeds created!"
