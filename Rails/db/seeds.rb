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
