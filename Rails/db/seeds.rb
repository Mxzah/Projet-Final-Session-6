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

unavailable_table_number = 5

tables_data.each do |td|
  table = Table.unscoped.find_or_initialize_by(number: td[:number])
  table.nb_seats = td[:nb_seats]
  table.deleted_at = nil
  table.temporary_code ||= SecureRandom.hex(16)
  table.save!
  puts "- Table ##{td[:number]} (#{td[:nb_seats]} places)"

  next if td[:number] == unavailable_table_number
  unless Availability.exists?(available_type: 'Table', available_id: table.id)
    a = Availability.new(
      available_type: 'Table',
      available_id:   table.id,
      start_at:       1.day.ago,
      end_at:         6.months.from_now,
      description:    "Table #{td[:number]} disponible"
    )
    a.save(validate: false)
  end
end

puts "- Table ##{unavailable_table_number} laissée sans disponibilité (unavailable)"

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

  unless combo.image.attached?
    combo.image.attach(
      io:           File.open(Rails.root.join('db', 'images', 'DuoTerreMer.jpg')),
      filename:     'DuoTerreMer.jpg',
      content_type: 'image/jpeg'
    )
  end

  ComboItem.find_or_create_by!(combo: combo, item: magret) do |ci|
    ci.quantity = 1
  end

  ComboItem.find_or_create_by!(combo: combo, item: linguine) do |ci|
    ci.quantity = 1
  end

  # Availability expirée → combo unavailable (save validate: false pour contourner la validation start_at_not_in_past)
  unless Availability.exists?(available_type: 'Combo', available_id: combo.id)
    a = Availability.new(
      available_type: 'Combo',
      available_id:   combo.id,
      start_at:       2.days.ago,
      end_at:         1.day.ago,
      description:    'Disponible le week-end seulement'
    )
    a.save(validate: false)
    puts "- Availability expirée ajoutée au combo '#{combo.name}' (unavailable)"
  end

  puts "- Combo '#{combo.name}' créé avec Magret de Canard + Linguine au Homard"
else
  puts "- Skipping combo — items not found"
end

# ── Combos disponibles ──────────────────────────────────────────────────────
puts "\nCreating available combos..."

filet_mignon = Item.find_by(name: 'Filet Mignon AAA')
petoncles    = Item.find_by(name: 'Pétoncles Poêlés')
tartare      = Item.find_by(name: 'Tartare de Saumon')
carpaccio    = Item.find_by(name: 'Carpaccio de Bœuf')
bar_grille   = Item.find_by(name: 'Filet de Bar Grillé')
risotto      = Item.find_by(name: 'Risotto aux Truffes')

if filet_mignon && petoncles
  surf_turf = Combo.find_or_create_by!(name: 'Surf & Turf Premium') do |c|
    c.description = 'Filet mignon AAA et pétoncles poêlés — une alliance terre et mer d\'exception'
    c.price       = 89.99
  end

  unless surf_turf.image.attached?
    surf_turf.image.attach(
      io:           File.open(Rails.root.join('db', 'images', 'SurfTurfPremium.jpg')),
      filename:     'SurfTurfPremium.jpg',
      content_type: 'image/jpeg'
    )
  end

  ComboItem.find_or_create_by!(combo: surf_turf, item: filet_mignon) { |ci| ci.quantity = 1 }
  ComboItem.find_or_create_by!(combo: surf_turf, item: petoncles)    { |ci| ci.quantity = 1 }
  unless Availability.exists?(available_type: 'Combo', available_id: surf_turf.id)
    a = Availability.new(available_type: 'Combo', available_id: surf_turf.id,
                         start_at: 1.day.ago, end_at: 6.months.from_now,
                         description: 'Disponible tous les soirs')
    a.save(validate: false)
  end
  puts "- Combo '#{surf_turf.name}' créé (disponible)"
end

if tartare && bar_grille
  menu_mer = Combo.find_or_create_by!(name: 'Menu Fruits de Mer') do |c|
    c.description = 'Tartare de saumon en entrée suivi d\'un filet de bar grillé — le meilleur de la mer'
    c.price       = 64.99
  end

  unless menu_mer.image.attached?
    menu_mer.image.attach(
      io:           File.open(Rails.root.join('db', 'images', 'MenuFruitsDeMer.jpg')),
      filename:     'MenuFruitsDeMer.jpg',
      content_type: 'image/jpeg'
    )
  end

  ComboItem.find_or_create_by!(combo: menu_mer, item: tartare)   { |ci| ci.quantity = 1 }
  ComboItem.find_or_create_by!(combo: menu_mer, item: bar_grille) { |ci| ci.quantity = 1 }
  unless Availability.exists?(available_type: 'Combo', available_id: menu_mer.id)
    a = Availability.new(available_type: 'Combo', available_id: menu_mer.id,
                         start_at: 1.day.ago, end_at: 6.months.from_now,
                         description: 'Disponible du mardi au dimanche')
    a.save(validate: false)
  end
  puts "- Combo '#{menu_mer.name}' créé (disponible)"
end

if carpaccio && risotto
  menu_prestige = Combo.find_or_create_by!(name: 'Menu Prestige') do |c|
    c.description = 'Carpaccio de bœuf et risotto aux truffes — l\'élégance italienne dans votre assiette'
    c.price       = 54.99
  end

  unless menu_prestige.image.attached?
    menu_prestige.image.attach(
      io:           File.open(Rails.root.join('db', 'images', 'MenuPrestige.jpg')),
      filename:     'MenuPrestige.jpg',
      content_type: 'image/jpeg'
    )
  end

  ComboItem.find_or_create_by!(combo: menu_prestige, item: carpaccio) { |ci| ci.quantity = 1 }
  ComboItem.find_or_create_by!(combo: menu_prestige, item: risotto)   { |ci| ci.quantity = 1 }
  unless Availability.exists?(available_type: 'Combo', available_id: menu_prestige.id)
    a = Availability.new(available_type: 'Combo', available_id: menu_prestige.id,
                         start_at: 1.day.ago, end_at: 6.months.from_now,
                         description: 'Menu du chef — disponible tous les soirs')
    a.save(validate: false)
  end
  puts "- Combo '#{menu_prestige.name}' créé (disponible)"
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

# ── Combos et ComboItems supprimés (soft delete) ───────────────────────────
puts "\nCreating deleted combos for testing..."

# Utiliser des items existants
carpaccio_item = Item.find_by(name: 'Carpaccio de Bœuf')
bar_item       = Item.find_by(name: 'Filet de Bar Grillé')
petoncles_item = Item.find_by(name: 'Pétoncles Poêlés')
magret_item    = Item.find_by(name: 'Magret de Canard')
tartare_item   = Item.find_by(name: 'Tartare de Saumon')

if carpaccio_item && bar_item
  # Combo supprimé
  deleted_combo = Combo.unscoped.find_or_create_by!(name: 'Menu Ancien') do |c|
    c.description = 'Ancien menu promotionnel - retiré du catalogue'
    c.price       = 55.99
    c.deleted_at  = 3.days.ago
  end
  
  # ComboItems pour le combo supprimé  
  ComboItem.unscoped.find_or_create_by!(combo: deleted_combo, item: carpaccio_item) do |ci|
    ci.quantity = 1
  end
  
  ComboItem.unscoped.find_or_create_by!(combo: deleted_combo, item: bar_item) do |ci|
    ci.quantity = 1
  end
  
  puts "- Combo supprimé 'Menu Ancien' créé"
end

# ComboItem supprimé dans un combo actif
surf_turf = Combo.find_by(name: 'Surf & Turf Premium')

if surf_turf && tartare_item
  deleted_ci = ComboItem.unscoped.find_or_create_by!(combo: surf_turf, item: tartare_item) do |ci|
    ci.quantity   = 1
    ci.deleted_at = 2.days.ago
  end
  puts "- ComboItem supprimé (Tartare de Saumon dans Surf & Turf Premium) créé"
end

# Un autre combo supprimé
if petoncles_item && magret_item
  deleted_combo2 = Combo.unscoped.find_or_create_by!(name: 'Duo Spécial Printemps') do |c|
    c.description = 'Offre promotionnelle de printemps - terminée'
    c.price       = 69.99
    c.deleted_at  = 1.week.ago
  end
  
  ComboItem.unscoped.find_or_create_by!(combo: deleted_combo2, item: petoncles_item) do |ci|
    ci.quantity = 1
  end
  
  ComboItem.unscoped.find_or_create_by!(combo: deleted_combo2, item: magret_item) do |ci|
    ci.quantity = 1
  end
  
  puts "- Combo supprimé 'Duo Spécial Printemps' créé"
end

# ── Closed orders + Reviews ──────────────────────────────────────────────────
puts "\nCreating closed orders for reviews..."

client_test = Client.find_by(email: 'client@restoqr.ca')
alice       = Client.find_by(email: 'alice@restoqr.ca')
marie       = Waiter.find_by(email: 'marie@restoqr.ca')
jean        = Waiter.find_by(email: 'jean@restoqr.ca')
waiter_test = Waiter.find_by(email: 'waiter@restoqr.ca')
table1      = Table.find_by(number: 1)
table2      = Table.find_by(number: 2)
table4      = Table.find_by(number: 4)

tartare_item    = Item.find_by(name: 'Tartare de Saumon')
filet_item      = Item.find_by(name: 'Filet Mignon AAA')
petoncles_item  = Item.find_by(name: 'Pétoncles Poêlés')
carpaccio_item  = Item.find_by(name: 'Carpaccio de Bœuf')
bar_item        = Item.find_by(name: 'Filet de Bar Grillé')
magret_item     = Item.find_by(name: 'Magret de Canard')
surf_turf_combo = Combo.find_by(name: 'Surf & Turf Premium')
menu_mer_combo  = Combo.find_by(name: 'Menu Fruits de Mer')

if client_test && alice && marie && jean && tartare_item && filet_item

  # Helper: create a closed order bypassing the "one open order" validation
  # (these are historical orders, already ended)
  seed_closed_order = ->(attrs) {
    existing = Order.unscoped.find_by(
      client_id: attrs[:client_id],
      table_id:  attrs[:table]&.id,
      ended_at:  attrs[:ended_at]
    )
    next existing if existing

    order = Order.new(attrs.except(:created_at))
    order.save(validate: false)
    order.update_columns(created_at: attrs[:created_at], ended_at: attrs[:ended_at])
    order
  }

  # ── Closed order 1: client@restoqr.ca, served by Marie, 3 days ago ──
  closed1 = seed_closed_order.call(
    client_id: client_test.id, table: table1, server: marie,
    nb_people: 2, tip: 12.00, note: 'Anniversaire de mariage',
    created_at: 3.days.ago, ended_at: 3.days.ago + 2.hours
  )

  OrderLine.find_or_create_by!(order: closed1, orderable: tartare_item) do |l|
    l.quantity   = 1
    l.unit_price = tartare_item.price
    l.status     = 'served'
  end
  OrderLine.find_or_create_by!(order: closed1, orderable: filet_item) do |l|
    l.quantity   = 1
    l.unit_price = filet_item.price
    l.status     = 'served'
  end
  if surf_turf_combo
    OrderLine.find_or_create_by!(order: closed1, orderable: surf_turf_combo) do |l|
      l.quantity   = 1
      l.unit_price = surf_turf_combo.price
      l.status     = 'served'
    end
  end

  puts "- Closed order ##{closed1.id} (client@, Table 1, Marie, 3 days ago)"

  # ── Closed order 2: client@restoqr.ca, served by Jean, 1 week ago ──
  closed2 = seed_closed_order.call(
    client_id: client_test.id, table: table2, server: jean,
    nb_people: 2, tip: 8.00,
    created_at: 1.week.ago, ended_at: 1.week.ago + 1.5.hours
  )

  if petoncles_item
    OrderLine.find_or_create_by!(order: closed2, orderable: petoncles_item) do |l|
      l.quantity   = 2
      l.unit_price = petoncles_item.price
      l.status     = 'served'
    end
  end
  if carpaccio_item
    OrderLine.find_or_create_by!(order: closed2, orderable: carpaccio_item) do |l|
      l.quantity   = 1
      l.unit_price = carpaccio_item.price
      l.status     = 'served'
    end
  end
  if menu_mer_combo
    OrderLine.find_or_create_by!(order: closed2, orderable: menu_mer_combo) do |l|
      l.quantity   = 1
      l.unit_price = menu_mer_combo.price
      l.status     = 'served'
    end
  end

  puts "- Closed order ##{closed2.id} (client@, Table 2, Jean, 1 week ago)"

  # ── Closed order 3: alice@restoqr.ca, served by Marie, 2 days ago ──
  closed3 = seed_closed_order.call(
    client_id: alice.id, table: table4, server: marie,
    nb_people: 4, tip: 20.00, note: 'Souper entre amis',
    created_at: 2.days.ago, ended_at: 2.days.ago + 1.hour
  )

  if bar_item
    OrderLine.find_or_create_by!(order: closed3, orderable: bar_item) do |l|
      l.quantity   = 2
      l.unit_price = bar_item.price
      l.status     = 'served'
    end
  end
  if magret_item
    OrderLine.find_or_create_by!(order: closed3, orderable: magret_item) do |l|
      l.quantity   = 2
      l.unit_price = magret_item.price
      l.status     = 'served'
    end
  end
  OrderLine.find_or_create_by!(order: closed3, orderable: filet_item) do |l|
    l.quantity   = 1
    l.unit_price = filet_item.price
    l.status     = 'served'
  end

  puts "- Closed order ##{closed3.id} (alice@, Table 4, Marie, 2 days ago)"

  # ── Closed order 4: alice@restoqr.ca, served by Serveur Test, 5 days ago ──
  closed4 = seed_closed_order.call(
    client_id: alice.id, table: table1, server: waiter_test,
    nb_people: 2, tip: 6.00,
    created_at: 5.days.ago, ended_at: 5.days.ago + 1.hour
  )

  OrderLine.find_or_create_by!(order: closed4, orderable: tartare_item) do |l|
    l.quantity   = 1
    l.unit_price = tartare_item.price
    l.status     = 'served'
  end

  puts "- Closed order ##{closed4.id} (alice@, Table 1, Serveur Test, 5 days ago)"

  # ── Reviews ──────────────────────────────────────────────────────────────
  puts "\nCreating reviews..."

  reviews_data = [
    # client@restoqr.ca — from closed order 1 (Marie, 3 days ago)
    { user: client_test, reviewable: tartare_item,    rating: 5,
      comment: "Incroyablement frais, le meilleur tartare que j'ai mangé! Les chips de won-ton ajoutent une texture parfaite.",
      ago: 3.days.ago },
    { user: client_test, reviewable: filet_item,      rating: 4,
      comment: "Très tendre et bien assaisonné, cuisson parfaite. La sauce au poivre vert est un délice.",
      ago: 3.days.ago },
    { user: client_test, reviewable: marie,           rating: 5,
      comment: "Service impeccable! Marie est toujours souriante et attentionnée, elle a rendu notre soirée d'anniversaire spéciale.",
      ago: 2.days.ago },

    # client@restoqr.ca — from closed order 2 (Jean, 1 week ago)
    { user: client_test, reviewable: petoncles_item,  rating: 3,
      comment: "Bons mais un peu trop cuits à mon goût. La purée de panais était cependant excellente.",
      ago: 6.days.ago },
    { user: client_test, reviewable: carpaccio_item,  rating: 4,
      comment: "Présentation magnifique, l'huile de truffe relève parfaitement le plat. À recommander!",
      ago: 6.days.ago },
    { user: client_test, reviewable: jean,            rating: 4,
      comment: "Très professionnel, bonnes recommandations de vins. Service rapide et courtois.",
      ago: 6.days.ago },

    # alice@restoqr.ca — from closed order 3 (Marie, 2 days ago)
    { user: alice, reviewable: bar_item,     rating: 5,
      comment: "Le bar était cuit à la perfection, un vrai délice! Le beurre blanc au citron est sublime.",
      ago: 1.day.ago },
    { user: alice, reviewable: magret_item,  rating: 4,
      comment: "Sauce aux cerises et porto incroyable. Le canard était un peu plus rosé que demandé mais excellent quand même.",
      ago: 1.day.ago },
    { user: alice, reviewable: filet_item,   rating: 5,
      comment: "Meilleur filet mignon en ville! Fondant comme du beurre, les pommes dauphines sont addictives.",
      ago: 1.day.ago },
    { user: alice, reviewable: marie,        rating: 5,
      comment: "Marie nous a fait sentir comme des VIP! Toujours de bonne humeur, elle connaît le menu par cœur.",
      ago: 1.day.ago },

    # alice@restoqr.ca — from closed order 4 (Serveur Test, 5 days ago)
    { user: alice, reviewable: tartare_item, rating: 4,
      comment: "Très bon tartare, portion généreuse. L'huile de sésame apporte une belle originalité.",
      ago: 4.days.ago },
    { user: alice, reviewable: waiter_test,  rating: 3,
      comment: "Service correct mais un peu lent ce soir-là. Les plats ont mis du temps à arriver.",
      ago: 4.days.ago },
  ]

  # Combo reviews (if combos exist)
  if surf_turf_combo
    reviews_data << { user: client_test, reviewable: surf_turf_combo, rating: 5,
      comment: "Combinaison terre et mer extraordinaire! Le filet mignon et les pétoncles se complètent à merveille.",
      ago: 2.days.ago }
  end
  if menu_mer_combo
    reviews_data << { user: client_test, reviewable: menu_mer_combo, rating: 4,
      comment: "Excellent rapport qualité-prix pour ce menu. Le tartare en entrée suivi du bar grillé, parfait!",
      ago: 5.days.ago }
  end

  reviews_data.each do |rd|
    existing = Review.find_by(user: rd[:user], reviewable: rd[:reviewable])
    next if existing

    review = Review.new(
      user:       rd[:user],
      reviewable: rd[:reviewable],
      rating:     rd[:rating],
      comment:    rd[:comment]
    )
    if review.save
      review.update_columns(created_at: rd[:ago], updated_at: rd[:ago])
      label = rd[:reviewable].is_a?(User) ? rd[:reviewable].first_name : rd[:reviewable].name
      puts "- #{rd[:user].first_name}: #{rd[:rating]}★ #{rd[:reviewable].class.name} '#{label}'"
    else
      puts "- SKIPPED #{rd[:reviewable].class.name}: #{review.errors.full_messages.join(', ')}"
    end
  end

  puts "\n#{Review.count} reviews total!"
else
  puts "Skipping reviews — required users or items not found"
end

puts "\nAll seeds created!"
