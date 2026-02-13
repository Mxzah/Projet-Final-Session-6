module Api
  class MenuController < ApplicationController
    before_action :authenticate_user!

    # GET /api/menu
    def index
      categories = [
        { id: 1, name: 'Assiettes', position: 0 },
        { id: 2, name: 'Trios', position: 1 },
        { id: 3, name: 'Poutines', position: 2 },
        { id: 4, name: 'Sandwich', position: 3 },
        { id: 5, name: 'Familiale', position: 4 },
        { id: 6, name: 'Entrée', position: 5 },
        { id: 7, name: 'Dessert', position: 6 },
        { id: 8, name: 'Extras', position: 7 }
      ]

      items = [
        # Assiettes
        { id: 1, name: 'Assiette Shish Taouk', description: 'Poulet mariné', price: 20.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Shish+Taouk', category_id: 1, deleted_at: nil },
        { id: 2, name: 'Assiette Mixte', description: 'Poulet mariné et bœuf mariné', price: 21.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Assiette+Mixte', category_id: 1, deleted_at: nil },
        { id: 3, name: 'Assiette Shawarma', description: 'Bœuf mariné', price: 20.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Shawarma', category_id: 1, deleted_at: nil },
        { id: 4, name: 'Brochettes de Crevettes (8 mcx)', description: 'Crevettes marinées et grillées', price: 26.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Crevettes', category_id: 1, deleted_at: nil },
        { id: 5, name: '3 Brochettes Mixtes Grillées', description: 'Poulet, filet mignon et kafta (viande hachée libanaise)', price: 29.49, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Brochettes+Mixtes', category_id: 1, deleted_at: nil },
        { id: 6, name: 'Merguez (4 mcx)', description: 'Saucisses merguez épicées grillées', price: 22.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Merguez', category_id: 1, deleted_at: nil },

        # Trios
        { id: 7, name: 'Trio Shish Taouk', description: 'Sandwich shish taouk, frites et boisson', price: 14.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Trio+Taouk', category_id: 2, deleted_at: nil },
        { id: 8, name: 'Trio Shawarma', description: 'Sandwich shawarma bœuf, frites et boisson', price: 15.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Trio+Shawarma', category_id: 2, deleted_at: nil },

        # Poutines
        { id: 9, name: 'Poutine Classique', description: 'Frites, fromage en grains et sauce brune maison', price: 10.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Poutine', category_id: 3, deleted_at: nil },
        { id: 10, name: 'Poutine Shawarma', description: "Poutine garnie de shawarma de bœuf et sauce à l'ail", price: 15.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Poutine+Shawarma', category_id: 3, deleted_at: nil },

        # Sandwich
        { id: 11, name: 'Sandwich Shish Taouk', description: 'Poulet grillé, cornichons, ail et légumes frais dans un pain pita', price: 11.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Sand.+Taouk', category_id: 4, deleted_at: nil },
        { id: 12, name: 'Sandwich Kafta', description: 'Viande hachée assaisonnée, persil, oignons dans un pain pita', price: 11.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Sand.+Kafta', category_id: 4, deleted_at: nil },

        # Familiale
        { id: 13, name: 'Plateau Familial', description: 'Assiette pour 4 personnes avec shish taouk, kafta, shawarma, riz et salades', price: 59.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Familial', category_id: 5, deleted_at: nil },

        # Entrée
        { id: 14, name: 'Hummus', description: "Purée de pois chiches crémeuse avec huile d'olive et épices", price: 7.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Hummus', category_id: 6, deleted_at: nil },
        { id: 15, name: 'Fattoush', description: 'Salade libanaise avec légumes frais, pain pita croustillant et vinaigrette', price: 8.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Fattoush', category_id: 6, deleted_at: nil },

        # Dessert
        { id: 16, name: 'Baklava', description: 'Pâtisserie feuilletée aux noix et sirop de miel', price: 6.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Baklava', category_id: 7, deleted_at: nil },

        # Extras
        { id: 17, name: 'Pain Pita (3)', description: 'Trois pains pita frais et chauds', price: 2.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Pita', category_id: 8, deleted_at: nil },
        { id: 18, name: "Sauce à l'ail", description: "Sauce à l'ail maison crémeuse", price: 1.99, image_url: 'https://placehold.co/400x300/f3ede4/1b1a17?text=Sauce+Ail', category_id: 8, deleted_at: nil }
      ]

      render json: {
        success: true,
        data: { categories: categories, items: items },
        errors: []
      }, status: :ok
    end
  end
end
