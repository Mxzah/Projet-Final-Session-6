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

Waiter.find_or_create_by!(email: 'marie@restoqr.ca') do |user|
  user.first_name = 'Marie'
  user.last_name = 'Dupont'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Waiter.find_or_create_by!(email: 'jean@restoqr.ca') do |user|
  user.first_name = 'Jean'
  user.last_name = 'Tremblay'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Cook.find_or_create_by!(email: 'cook@restoqr.ca') do |user|
  user.first_name = 'Chef'
  user.last_name = 'Cuisine'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Client.find_or_create_by!(email: 'alice@restoqr.ca') do |user|
  user.first_name = 'Alice'
  user.last_name = 'Martin'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Client.find_or_create_by!(email: 'bob@restoqr.ca') do |user|
  user.first_name = 'Bob'
  user.last_name = 'Gagnon'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

Client.find_or_create_by!(email: 'demo@restoqr.ca') do |user|
  user.first_name = 'Demo'
  user.last_name = 'Client'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.status = 'active'
end

puts "Users created!"
puts "- Administrator: admin@restoqr.ca"
puts "- Client: client@restoqr.ca"
puts "- Client: alice@restoqr.ca"
puts "- Client: bob@restoqr.ca"
puts "- Client: demo@restoqr.ca (utilisé pour les commandes demo)"
puts "- Waiter: waiter@restoqr.ca"
puts "- Waiter: marie@restoqr.ca"
puts "- Waiter: jean@restoqr.ca"
puts "- Cook: cook@restoqr.ca"
puts "Password for all: password123"

# Create restaurant tables
puts "\nCreating tables..."

tables_data = [
  { number: 1, nb_seats: 2 },
  { number: 2, nb_seats: 2 },
  { number: 3, nb_seats: 4 },
  { number: 4, nb_seats: 4 },
  { number: 5, nb_seats: 4 },
  { number: 6, nb_seats: 6 },
  { number: 7, nb_seats: 6 },
  { number: 8, nb_seats: 8 },
  { number: 9, nb_seats: 8 },
  { number: 10, nb_seats: 10 }
]

tables_data.each do |td|
  table = Table.unscoped.find_or_initialize_by(number: td[:number])
  table.nb_seats = td[:nb_seats]
  table.deleted_at = nil
  table.temporary_code ||= SecureRandom.hex(16)
  table.save!
  puts "- Table ##{td[:number]} (#{td[:nb_seats]} places)"
end

# Create categories
puts "\nCreating categories..."

categories_data = [
  { name: 'Entrées', position: 0 },
  { name: 'Poissons & Fruits de mer', position: 1 },
  { name: 'Viandes', position: 2 },
  { name: 'Pâtes & Risottos', position: 3 }
]

categories = {}
categories_data.each do |cd|
  cat = Category.find_or_create_by!(name: cd[:name]) do |c|
    c.position = cd[:position]
  end
  categories[cd[:name]] = cat
  puts "- #{cat.name} (position: #{cat.position})"
end

# Create items
puts "\nCreating items..."

images_dir = Rails.root.join('db', 'images')

items_data = [
  # Entrées
  { name: 'Tartare de Saumon', description: 'Saumon frais coupé au couteau, avocat, câpres, huile de sésame et chips de won-ton', price: 24.99, category: 'Entrées', image: 'TartareDeSaumon.jpeg' },
  { name: 'Carpaccio de Bœuf', description: 'Fines tranches de filet de bœuf AAA, roquette, copeaux de parmesan, huile de truffe', price: 22.99, category: 'Entrées', image: 'CarpaccioDeBœufjpg.jpg' },

  # Poissons & Fruits de mer
  { name: 'Filet de Bar Grillé', description: 'Bar européen grillé, purée de céleri-rave, beurre blanc au citron et asperges', price: 45.99, category: 'Poissons & Fruits de mer', image: 'FiletdeBarGrille.jpg' },
  { name: 'Pétoncles Poêlés', description: 'Pétoncles géants, purée de panais, pancetta croustillante et noisettes torréfiées', price: 42.99, category: 'Poissons & Fruits de mer', image: 'PetonclesPoeles.jpg' },

  # Viandes
  { name: 'Filet Mignon AAA', description: 'Filet mignon 8oz, sauce au poivre vert, pommes dauphines et légumes de saison', price: 56.99, category: 'Viandes', image: 'FiletMignonAAA.jpg' },
  { name: 'Magret de Canard', description: 'Magret de canard rôti, sauce aux cerises et porto, purée de patates douces', price: 44.99, category: 'Viandes', image: 'MagretDeCanard.jpg' },

  # Pâtes & Risottos
  { name: 'Risotto aux Truffes', description: 'Risotto crémeux au parmesan, copeaux de truffe noire et huile de truffe', price: 36.99, category: 'Pâtes & Risottos', image: 'RisottoAuxTruffes.jpg' },
  { name: 'Linguine au Homard', description: 'Linguine fraîches, chair de homard, tomates cerises, bisque légère et estragon', price: 44.99, category: 'Pâtes & Risottos', image: 'LinguineAuHomard.jpg' },
]

created_items = []

items_data.each do |id|
  item = Item.find_or_initialize_by(name: id[:name], category: categories[id[:category]])
  item.description = id[:description]
  item.price = id[:price]
  unless item.image.attached?
    image_path = images_dir.join(id[:image])
    content_type = id[:image].end_with?('.png') ? 'image/png' : 'image/jpeg'
    item.image.attach(
      io: File.open(image_path),
      filename: id[:image],
      content_type: content_type
    )
  end
  item.save!
  created_items << item
  puts "- #{id[:name]} (#{id[:category]}) — CA$#{id[:price]}"
end

# Tous les items reçoivent une availability permanente pour l'instant
# (l'archivage et la suppression des availabilities se font à la fin,
#  après la création des orders et du combo)
puts "\nCreating default availabilities..."
created_items.each do |item|
  next unless item.id.present?
  unless Availability.exists?(available_type: 'Item', available_id: item.id)
    Availability.create!(
      available_type: 'Item',
      available_id:   item.id,
      start_at:       Time.current.beginning_of_minute,
      end_at:         nil,
      description:    nil
    )
    puts "- Disponibilité ajoutée : #{item.name}"
  end
end

# ── Vibes ──────────────────────────────────────────────────────────────────
puts "\nCreating vibes..."

vibes_data = [
  { name: 'Fête',  color: '#FFB347' },
  { name: 'Date',  color: '#FF6B9D' },
  { name: 'Mort',  color: '#2C3E50' }
]

vibes = {}
vibes_data.each do |vd|
  vibe = Vibe.find_or_create_by!(name: vd[:name]) do |v|
    v.color = vd[:color]
  end
  vibes[vd[:name]] = vibe
  puts "- #{vibe.name} (#{vibe.color})"
end

# ── Demo orders for kitchen dashboard ──────────────────────────────────────
puts "\nCreating demo orders..."

marie   = Waiter.find_by(email: 'marie@restoqr.ca')
jean    = Waiter.find_by(email: 'jean@restoqr.ca')
client1 = Client.find_by(email: 'demo@restoqr.ca')
client2 = Client.find_by(email: 'alice@restoqr.ca')
client3 = Client.find_by(email: 'bob@restoqr.ca')
table3  = Table.find_by(number: 3)
table5  = Table.find_by(number: 5)
table7  = Table.find_by(number: 7)

tartare  = Item.find_by(name: 'Tartare de Saumon')
risotto  = Item.find_by(name: 'Risotto aux Truffes')
filet    = Item.find_by(name: 'Filet Mignon AAA')
petoncle = Item.find_by(name: 'Pétoncles Poêlés')

unless tartare && risotto && filet && petoncle
  puts "Skipping demo orders — some items not found"
  puts "\nAll seeds created!"
  return
end

# Order 1 — client1, table 3, server marie, vibe Fête
order1 = Order.find_or_create_by!(client_id: client1.id, ended_at: nil) do |o|
  o.table     = table3
  o.nb_people = 3
  o.server    = marie
  o.note      = 'Allergie aux arachides'
  o.vibe      = vibes['Fête']
end
order1.update!(vibe: vibes['Fête']) if order1.vibe.nil?

OrderLine.find_or_create_by!(order_id: order1.id, orderable_type: 'Item', orderable_id: tartare.id) do |l|
  l.quantity   = 2
  l.unit_price = tartare.price
  l.status     = 'sent'
  l.note       = 'Sans câpres'
end

OrderLine.find_or_create_by!(order_id: order1.id, orderable_type: 'Item', orderable_id: risotto.id) do |l|
  l.quantity   = 1
  l.unit_price = risotto.price
  l.status     = 'in_preparation'
end

order1.update_column(:created_at, 2.hours.ago)
puts "- Order ##{order1.id} (Table #{table3.number}, #{marie.first_name}) — il y a 2h"

# Order 2 — client2, table 5, server jean, vibe Date + note + tip
order2 = Order.find_or_create_by!(client_id: client2.id, ended_at: nil) do |o|
  o.table     = table5
  o.nb_people = 2
  o.server    = jean
  o.vibe      = vibes['Date']
  o.note      = 'gros date'
  o.tip       = 15.00
end
order2.update!(vibe: vibes['Date']) if order2.vibe.nil?

OrderLine.find_or_create_by!(order_id: order2.id, orderable_type: 'Item', orderable_id: filet.id) do |l|
  l.quantity   = 1
  l.unit_price = filet.price
  l.status     = 'ready'
  l.note       = 'Saignant, sans sauce'
end

OrderLine.find_or_create_by!(order_id: order2.id, orderable_type: 'Item', orderable_id: risotto.id) do |l|
  l.quantity   = 2
  l.unit_price = risotto.price
  l.status     = 'sent'
end

order2.update_column(:created_at, 45.minutes.ago)
puts "- Order ##{order2.id} (Table #{table5.number}, #{jean.first_name}, tip: $15.00) — il y a 45min"

# Order 3 — client3, table 7, no server, vibe Mort + tip
order3 = Order.find_or_create_by!(client_id: client3.id, ended_at: nil) do |o|
  o.table     = table7
  o.nb_people = 4
  o.vibe      = vibes['Mort']
  o.tip       = 5.50
end
order3.update!(vibe: vibes['Mort']) if order3.vibe.nil?

OrderLine.find_or_create_by!(order_id: order3.id, orderable_type: 'Item', orderable_id: petoncle.id) do |l|
  l.quantity   = 3
  l.unit_price = petoncle.price
  l.status     = 'in_preparation'
  l.note       = 'Sans sel'
end

OrderLine.find_or_create_by!(order_id: order3.id, orderable_type: 'Item', orderable_id: tartare.id) do |l|
  l.quantity   = 4
  l.unit_price = tartare.price
  l.status     = 'sent'
end

order3.update_column(:created_at, 10.minutes.ago)
puts "- Order ##{order3.id} (Table #{table7.number}, no server, tip: $5.50) — il y a 10min"

# ── Demo combo (pour tester in_use via combo_items) ────────────────────────
puts "\nCreating demo combo..."

magret   = Item.find_by(name: 'Magret de Canard')
linguine = Item.find_by(name: 'Linguine au Homard')

if magret && linguine
  combo = Combo.find_or_create_by!(name: 'Duo Terre & Mer') do |c|
    c.description = 'Magret de canard et linguine au homard — le meilleur des deux mondes'
    c.price       = 79.99
  end

  ComboItem.find_or_create_by!(combo: combo, item: magret) do |ci|
    ci.quantity = 1
  end

  ComboItem.find_or_create_by!(combo: combo, item: linguine) do |ci|
    ci.quantity = 1
  end

  puts "- Combo '#{combo.name}' créé avec Magret de Canard + Linguine au Homard"
else
  puts "- Skipping combo — items not found"
end

# ── Archivage et indisponibilité ───────────────────────────────────────────
# Fait en dernier pour ne pas bloquer les validations des orders/combos

puts "\nArchiving Linguine au Homard..."
linguine_id = Item.unscoped.find_by(name: 'Linguine au Homard')&.id
if linguine_id
  now = Time.current
  Item.unscoped.where(id: linguine_id).update_all(deleted_at: now)
  Availability.where(available_type: 'Item', available_id: linguine_id)
              .where("start_at > ?", now)
              .delete_all
  Availability.where(available_type: 'Item', available_id: linguine_id)
              .where("start_at <= ? AND (end_at IS NULL OR end_at > ?)", now, now)
              .update_all(end_at: now)
  puts "- Archivé : Linguine au Homard"
end

puts "Removing availability from Risotto aux Truffes (indisponible)..."
risotto_id = Item.unscoped.find_by(name: 'Risotto aux Truffes')&.id
if risotto_id
  Availability.where(available_type: 'Item', available_id: risotto_id).delete_all
  puts "- Indisponible : Risotto aux Truffes"
end

puts "\nAll seeds created!"
