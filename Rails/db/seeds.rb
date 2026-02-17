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

# Create items
puts "\nCreating items..."

items_data = [
  # Entrées
  { name: 'Tartare de Saumon', description: 'Saumon frais coupé au couteau, avocat, câpres, huile de sésame et chips de won-ton', price: 24.99, category: 'Entrées' },
  { name: 'Carpaccio de Bœuf', description: 'Fines tranches de filet de bœuf AAA, roquette, copeaux de parmesan, huile de truffe', price: 22.99, category: 'Entrées' },
  { name: 'Foie Gras Poêlé', description: 'Foie gras de canard poêlé, chutney de figues, brioche dorée et fleur de sel', price: 32.99, category: 'Entrées' },
  { name: 'Velouté de Homard', description: 'Bisque de homard onctueuse, crème fraîche, ciboulette et huile de homard', price: 19.99, category: 'Entrées' },
  { name: 'Burrata & Tomates Anciennes', description: 'Burrata crémeuse, tomates heirloom, basilic frais, réduction de balsamique', price: 21.99, category: 'Entrées' },

  # Poissons & Fruits de mer
  { name: 'Filet de Bar Grillé', description: 'Bar européen grillé, purée de céleri-rave, beurre blanc au citron et asperges', price: 45.99, category: 'Poissons & Fruits de mer' },
  { name: 'Homard Thermidor', description: 'Demi-homard gratiné, sauce Mornay au cognac, gruyère fondu et riz sauvage', price: 62.99, category: 'Poissons & Fruits de mer' },
  { name: 'Pavé de Saumon Laqué', description: 'Saumon laqué au miso et érable, bok choy sauté, sésame noir', price: 38.99, category: 'Poissons & Fruits de mer' },
  { name: 'Pétoncles Poêlés', description: 'Pétoncles géants, purée de panais, pancetta croustillante et noisettes torréfiées', price: 42.99, category: 'Poissons & Fruits de mer' },

  # Viandes
  { name: 'Filet Mignon AAA', description: 'Filet mignon 8oz, sauce au poivre vert, pommes dauphines et légumes de saison', price: 56.99, category: 'Viandes' },
  { name: 'Carré d\'Agneau', description: 'Carré d\'agneau en croûte d\'herbes, jus au romarin, ratatouille provençale', price: 52.99, category: 'Viandes' },
  { name: 'Magret de Canard', description: 'Magret de canard rôti, sauce aux cerises et porto, purée de patates douces', price: 44.99, category: 'Viandes' },
  { name: 'Côte de Veau', description: 'Côte de veau de lait, jus corsé aux morilles, gnocchis au beurre', price: 58.99, category: 'Viandes' },
  { name: 'Tartare de Bison', description: 'Bison haché au couteau, jaune d\'œuf, condiments classiques, frites allumettes', price: 34.99, category: 'Viandes' },

  # Pâtes & Risottos
  { name: 'Risotto aux Truffes', description: 'Risotto crémeux au parmesan, copeaux de truffe noire et huile de truffe', price: 36.99, category: 'Pâtes & Risottos' },
  { name: 'Linguine au Homard', description: 'Linguine fraîches, chair de homard, tomates cerises, bisque légère et estragon', price: 44.99, category: 'Pâtes & Risottos' },
  { name: 'Gnocchis à la Parisienne', description: 'Gnocchis maison, crème de gorgonzola, noix de Grenoble caramélisées et sauge', price: 29.99, category: 'Pâtes & Risottos' },

  # Accompagnements
  { name: 'Purée de Pommes de Terre Truffée', description: 'Pommes de terre Yukon Gold, beurre, crème et huile de truffe blanche', price: 14.99, category: 'Accompagnements' },
  { name: 'Asperges Grillées', description: 'Asperges vertes grillées, hollandaise légère et copeaux de parmesan', price: 13.99, category: 'Accompagnements' },
  { name: 'Légumes de Saison Rôtis', description: 'Sélection de légumes du marché, rôtis au four avec herbes et fleur de sel', price: 12.99, category: 'Accompagnements' },
  { name: 'Frites Truffées', description: 'Frites allumettes croustillantes, huile de truffe, parmesan râpé et persil', price: 15.99, category: 'Accompagnements' },

  # Fromages
  { name: 'Plateau de Fromages Fins', description: 'Sélection de 5 fromages affinés québécois et français, confiture, noix et pain', price: 28.99, category: 'Fromages' },
  { name: 'Brie Fondant au Four', description: 'Brie double crème rôti au four, miel de lavande, noix de Grenoble et crostinis', price: 22.99, category: 'Fromages' },

  # Desserts
  { name: 'Crème Brûlée à la Vanille', description: 'Crème brûlée classique, gousse de vanille de Madagascar et caramel craquant', price: 16.99, category: 'Desserts' },
  { name: 'Fondant au Chocolat', description: 'Fondant au chocolat noir Valrhona 70%, cœur coulant, glace vanille et tuile dentelle', price: 18.99, category: 'Desserts' },
  { name: 'Tarte Tatin', description: 'Tarte aux pommes caramélisées, pâte feuilletée dorée, crème fraîche et caramel beurre salé', price: 17.99, category: 'Desserts' },
  { name: 'Assiette de Mignardises', description: 'Sélection de petits fours: macaron, truffe au chocolat, pâte de fruit et financier', price: 14.99, category: 'Desserts' },

  # Boissons
  { name: 'Eau Minérale San Pellegrino', description: 'Eau minérale gazeuse italienne, 750ml', price: 8.99, category: 'Boissons' },
  { name: 'Espresso Double', description: 'Espresso double, grains torréfiés artisanalement', price: 5.99, category: 'Boissons' },
  { name: 'Thé des Jardins', description: 'Sélection de thés fins: Earl Grey, Jasmin, Sencha ou Camomille', price: 6.99, category: 'Boissons' },
  { name: 'Limonade Maison au Basilic', description: 'Limonade fraîche pressée, basilic frais, miel et eau pétillante', price: 9.99, category: 'Boissons' }
]

items_data.each do |id|
  Item.find_or_create_by!(name: id[:name], category: categories[id[:category]]) do |i|
    i.description = id[:description]
    i.price = id[:price]
  end
  puts "- #{id[:name]} (#{id[:category]}) — CA$#{id[:price]}"
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

# Order 1 — client1, table 3, server marie
order1 = Order.find_or_create_by!(client_id: client1.id, ended_at: nil) do |o|
  o.table    = table3
  o.nb_people = 3
  o.server   = marie
  o.note     = 'Allergie aux arachides'
end

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

# Order 2 — client2, table 5, server jean
order2 = Order.find_or_create_by!(client_id: client2.id, ended_at: nil) do |o|
  o.table    = table5
  o.nb_people = 2
  o.server   = jean
end

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

# Order 3 — client3, table 7, no server
order3 = Order.find_or_create_by!(client_id: client3.id, ended_at: nil) do |o|
  o.table    = table7
  o.nb_people = 4
end

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
