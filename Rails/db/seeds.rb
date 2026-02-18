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

puts "Users created!"
puts "- Administrator: admin@restoqr.ca"
puts "- Client: client@restoqr.ca"
puts "- Client: alice@restoqr.ca"
puts "- Client: bob@restoqr.ca"
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
  Table.find_or_create_by!(number: td[:number]) do |t|
    t.nb_seats = td[:nb_seats]
    t.temporary_code = SecureRandom.hex(16)
  end
  puts "- Table ##{td[:number]} (#{td[:nb_seats]} places)"
end

# Create categories
puts "\nCreating categories..."

categories_data = [
  { name: 'Entrées', position: 0 },
  { name: 'Poissons & Fruits de mer', position: 1 },
  { name: 'Viandes', position: 2 },
  { name: 'Pâtes & Risottos', position: 3 },
  { name: 'Accompagnements', position: 4 },
  { name: 'Fromages', position: 5 },
  { name: 'Desserts', position: 6 },
  { name: 'Boissons', position: 7 }
]

categories = {}
categories_data.each do |cd|
  cat = Category.find_or_create_by!(name: cd[:name]) do |c|
    c.position = cd[:position]
  end
  categories[cd[:name]] = cat
  puts "- #{cat.name} (position: #{cat.position})"
end

# Create a placeholder image for seeding
placeholder_path = Rails.root.join('db', 'placeholder.jpg')
unless File.exist?(placeholder_path)
  # Create a minimal valid JPEG file
  File.open(placeholder_path, 'wb') do |f|
    f.write([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
      0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
      0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
      0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
      0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
      0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
      0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
      0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
      0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
      0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
      0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
      0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
      0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
      0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
      0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
      0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
      0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
      0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
      0x00, 0x00, 0x3F, 0x00, 0x7B, 0x94, 0x11, 0x00, 0x00, 0x00, 0x00, 0xFF,
      0xD9
    ].pack('C*'))
  end
end

# Create items
puts "\nCreating items..."

items_data = [
  # Entrées
  { name: 'Tartare de Saumon', description: 'Saumon frais coupé au couteau, avocat, câpres, huile de sésame et chips de won-ton', price: 24.99, category: 'Entrées' },
  { name: 'Carpaccio de Bœuf', description: 'Fines tranches de filet de bœuf AAA, roquette, copeaux de parmesan, huile de truffe', price: 22.99, category: 'Entrées' },

  # Poissons & Fruits de mer
  { name: 'Filet de Bar Grillé', description: 'Bar européen grillé, purée de céleri-rave, beurre blanc au citron et asperges', price: 45.99, category: 'Poissons & Fruits de mer' },
  { name: 'Pétoncles Poêlés', description: 'Pétoncles géants, purée de panais, pancetta croustillante et noisettes torréfiées', price: 42.99, category: 'Poissons & Fruits de mer' },

  # Viandes
  { name: 'Filet Mignon AAA', description: 'Filet mignon 8oz, sauce au poivre vert, pommes dauphines et légumes de saison', price: 56.99, category: 'Viandes' },
  { name: 'Magret de Canard', description: 'Magret de canard rôti, sauce aux cerises et porto, purée de patates douces', price: 44.99, category: 'Viandes' },

  # Pâtes & Risottos
  { name: 'Risotto aux Truffes', description: 'Risotto crémeux au parmesan, copeaux de truffe noire et huile de truffe', price: 36.99, category: 'Pâtes & Risottos' },
  { name: 'Linguine au Homard', description: 'Linguine fraîches, chair de homard, tomates cerises, bisque légère et estragon', price: 44.99, category: 'Pâtes & Risottos' },

  # Accompagnements
  { name: 'Purée de Pommes de Terre Truffée', description: 'Pommes de terre Yukon Gold, beurre, crème et huile de truffe blanche', price: 14.99, category: 'Accompagnements' },
  { name: 'Frites Truffées', description: 'Frites allumettes croustillantes, huile de truffe, parmesan râpé et persil', price: 15.99, category: 'Accompagnements' },

  # Fromages
  { name: 'Plateau de Fromages Fins', description: 'Sélection de 5 fromages affinés québécois et français, confiture, noix et pain', price: 28.99, category: 'Fromages' },
  { name: 'Brie Fondant au Four', description: 'Brie double crème rôti au four, miel de lavande, noix de Grenoble et crostinis', price: 22.99, category: 'Fromages' },

  # Desserts
  { name: 'Crème Brûlée à la Vanille', description: 'Crème brûlée classique, gousse de vanille de Madagascar et caramel craquant', price: 16.99, category: 'Desserts' },
  { name: 'Fondant au Chocolat', description: 'Fondant au chocolat noir Valrhona 70%, cœur coulant, glace vanille et tuile dentelle', price: 18.99, category: 'Desserts' },

  # Boissons
  { name: 'Espresso Double', description: 'Espresso double, grains torréfiés artisanalement', price: 5.99, category: 'Boissons' },
  { name: 'Limonade Maison au Basilic', description: 'Limonade fraîche pressée, basilic frais, miel et eau pétillante', price: 9.99, category: 'Boissons' }
]

items_data.each do |id|
  item = Item.find_or_initialize_by(name: id[:name], category: categories[id[:category]])
  item.description = id[:description]
  item.price = id[:price]
  unless item.image.attached?
    item.image.attach(
      io: File.open(placeholder_path),
      filename: 'placeholder.jpg',
      content_type: 'image/jpeg'
    )
  end
  item.save!
  puts "- #{id[:name]} (#{id[:category]}) — CA$#{id[:price]}"
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
client1 = Client.find_by(email: 'client@restoqr.ca')
client2 = Client.find_by(email: 'alice@restoqr.ca')
client3 = Client.find_by(email: 'bob@restoqr.ca')
table3  = Table.find_by(number: 3)
table5  = Table.find_by(number: 5)
table7  = Table.find_by(number: 7)

tartare  = Item.find_by(name: 'Tartare de Saumon')
risotto  = Item.find_by(name: 'Risotto aux Truffes')
filet    = Item.find_by(name: 'Filet Mignon AAA')
fondant  = Item.find_by(name: 'Fondant au Chocolat')
petoncle = Item.find_by(name: 'Pétoncles Poêlés')
brulee   = Item.find_by(name: 'Crème Brûlée à la Vanille')

unless tartare && risotto && filet && fondant && petoncle && brulee
  puts "Skipping demo orders — some items not found"
  puts "\nAll seeds created!"
  return
end

# Order 1 — client1, table 3, server marie, vibe Fête
order1 = Order.find_or_create_by!(client_id: client1.id, ended_at: nil) do |o|
  o.table    = table3
  o.nb_people = 3
  o.server   = marie
  o.note     = 'Allergie aux arachides'
  o.vibe     = vibes['Fête']
end
order1.update!(vibe: vibes['Fête']) if order1.vibe.nil?

OrderLine.find_or_create_by!(order_id: order1.id, orderable_type: 'Item', orderable_id: tartare.id) do |l|
  l.quantity   = 2
  l.unit_price = tartare.price
  l.status     = 'sent'
end

OrderLine.find_or_create_by!(order_id: order1.id, orderable_type: 'Item', orderable_id: risotto.id) do |l|
  l.quantity   = 1
  l.unit_price = risotto.price
  l.status     = 'in_preparation'
end

puts "- Order ##{order1.id} (Table #{table3.number}, #{marie.first_name})"

# Order 2 — client2, table 5, server jean, vibe Date
order2 = Order.find_or_create_by!(client_id: client2.id, ended_at: nil) do |o|
  o.table    = table5
  o.nb_people = 2
  o.server   = jean
  o.vibe     = vibes['Date']
end
order2.update!(vibe: vibes['Date']) if order2.vibe.nil?

OrderLine.find_or_create_by!(order_id: order2.id, orderable_type: 'Item', orderable_id: filet.id) do |l|
  l.quantity   = 1
  l.unit_price = filet.price
  l.status     = 'ready'
end

OrderLine.find_or_create_by!(order_id: order2.id, orderable_type: 'Item', orderable_id: fondant.id) do |l|
  l.quantity   = 2
  l.unit_price = fondant.price
  l.status     = 'sent'
end

puts "- Order ##{order2.id} (Table #{table5.number}, #{jean.first_name})"

# Order 3 — client3, table 7, no server, vibe Mort
order3 = Order.find_or_create_by!(client_id: client3.id, ended_at: nil) do |o|
  o.table    = table7
  o.nb_people = 4
  o.vibe     = vibes['Mort']
end
order3.update!(vibe: vibes['Mort']) if order3.vibe.nil?

OrderLine.find_or_create_by!(order_id: order3.id, orderable_type: 'Item', orderable_id: petoncle.id) do |l|
  l.quantity   = 3
  l.unit_price = petoncle.price
  l.status     = 'in_preparation'
end

OrderLine.find_or_create_by!(order_id: order3.id, orderable_type: 'Item', orderable_id: brulee.id) do |l|
  l.quantity   = 4
  l.unit_price = brulee.price
  l.status     = 'sent'
end

puts "- Order ##{order3.id} (Table #{table7.number}, no server)"

puts "\nAll seeds created!"
