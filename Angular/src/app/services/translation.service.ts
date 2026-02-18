import { Injectable, signal } from '@angular/core';

export type Lang = 'fr' | 'en';

const TRANSLATIONS: Record<string, Record<Lang, string>> = {
  // Header
  'header.logout': { fr: 'Déconnexion', en: 'Logout' },
  'header.login': { fr: 'Connexion', en: 'Login' },

  // Menu page
  'menu.categories': { fr: 'Catégories', en: 'Categories' },
  'menu.search': { fr: 'Rechercher un item...', en: 'Search an item...' },
  'menu.priceMin': { fr: 'Prix min', en: 'Min price' },
  'menu.priceMax': { fr: 'Prix max', en: 'Max price' },
  'menu.sortByPrice': { fr: 'Trier par prix', en: 'Sort by price' },
  'menu.priceAsc': { fr: 'Prix croissant', en: 'Price ascending' },
  'menu.priceDesc': { fr: 'Prix décroissant', en: 'Price descending' },
  'menu.category': { fr: 'Catégorie', en: 'Category' },
  'menu.noResults': { fr: 'Aucun item trouvé.', en: 'No items found.' },
  'menu.noItems': { fr: 'Aucun item dans cette catégorie.', en: 'No items in this category.' },
  'menu.subtotal': { fr: 'Sous-total', en: 'Subtotal' },
  'menu.yourOrder': { fr: 'Votre commande', en: 'Your order' },
  'menu.cartEmpty': { fr: 'Votre panier est vide.', en: 'Your cart is empty.' },
  'menu.modify': { fr: 'Modifier', en: 'Edit' },
  'menu.remove': { fr: 'Retirer', en: 'Remove' },
  'menu.continue': { fr: 'Continuer', en: 'Continue' },
  'menu.fromPrice': { fr: 'À PARTIR DE', en: 'STARTING AT' },
  'menu.priceNote': { fr: 'Le prix peut varier selon les options.', en: 'Price may vary depending on options.' },
  'menu.specialInstructions': { fr: 'Instructions spéciales (optionnel)', en: 'Special instructions (optional)' },
  'menu.specialPlaceholder': { fr: 'Ex: Sans oignon, extra sauce, bien cuit...', en: 'E.g.: No onion, extra sauce, well done...' },
  'menu.addToCart': { fr: 'Ajouter au panier', en: 'Add to cart' },
  'menu.item': { fr: 'item(s)', en: 'item(s)' },
  'menu.unit': { fr: '/ unit', en: '/ unit' },
  'menu.portion': { fr: 'portion', en: 'portion' },
  'menu.portions': { fr: 'portions', en: 'portions' },
  'menu.loadError': { fr: 'Erreur lors du chargement du menu', en: 'Error loading the menu' },

  // Admin items
  'admin.itemsTitle': { fr: 'Gestion des items', en: 'Items management' },
  'admin.itemsSubtitle': { fr: 'Consultez les plats et boissons du restaurant.', en: 'Browse the restaurant dishes and drinks.' },
  'admin.noItems': { fr: 'Aucun item.', en: 'No items.' },
  'admin.addItem': { fr: 'Ajouter un item', en: 'Add an item' },
  'admin.editItem': { fr: "Modifier l'item", en: 'Edit item' },
  'admin.deleteItem': { fr: "Supprimer l'item", en: 'Delete item' },
  'admin.deleteConfirm': { fr: 'Voulez-vous vraiment supprimer', en: 'Are you sure you want to delete' },
  'admin.cancel': { fr: 'Annuler', en: 'Cancel' },
  'admin.delete': { fr: 'Supprimer', en: 'Delete' },
  'admin.name': { fr: 'Nom', en: 'Name' },
  'admin.description': { fr: 'Description', en: 'Description' },
  'admin.price': { fr: 'Prix ($)', en: 'Price ($)' },
  'admin.category': { fr: 'Catégorie', en: 'Category' },
  'admin.image': { fr: 'Image', en: 'Image' },
  'admin.save': { fr: 'Enregistrer', en: 'Save' },
  'admin.saving': { fr: 'Enregistrement...', en: 'Saving...' },
  'admin.add': { fr: 'Ajouter', en: 'Add' },
  'admin.nameRequired': { fr: 'Le nom est requis.', en: 'Name is required.' },
  'admin.nameMaxLength': { fr: 'Le nom ne doit pas dépasser 100 caractères.', en: 'Name must not exceed 100 characters.' },
  'admin.nameWhitespace': { fr: "Le nom ne peut pas être composé uniquement d'espaces.", en: 'Name cannot be only whitespace.' },
  'admin.descMaxLength': { fr: 'La description ne doit pas dépasser 255 caractères.', en: 'Description must not exceed 255 characters.' },
  'admin.descWhitespace': { fr: "La description ne peut pas être composée uniquement d'espaces.", en: 'Description cannot be only whitespace.' },
  'admin.priceRequired': { fr: 'Le prix est requis.', en: 'Price is required.' },
  'admin.priceMin': { fr: 'Le prix doit être supérieur ou égal à 0.', en: 'Price must be greater than or equal to 0.' },
  'admin.priceMax': { fr: 'Le prix ne doit pas dépasser 9999.99 $.', en: 'Price must not exceed $9999.99.' },
  'admin.categoryRequired': { fr: 'La catégorie est requise.', en: 'Category is required.' },
  'admin.createError': { fr: 'Erreur lors de la création', en: 'Error during creation' },
  'admin.editError': { fr: 'Erreur lors de la modification', en: 'Error during modification' },
  'admin.editBtn': { fr: 'Modifier', en: 'Edit' },
  'admin.deleteBtn': { fr: 'Supprimer', en: 'Delete' },
};

@Injectable({ providedIn: 'root' })
export class TranslationService {
  lang = signal<Lang>((localStorage.getItem('lang') as Lang) || 'fr');

  t(key: string): string {
    const entry = TRANSLATIONS[key];
    if (!entry) return key;
    return entry[this.lang()] ?? entry['fr'] ?? key;
  }

  setLang(lang: Lang): void {
    this.lang.set(lang);
    localStorage.setItem('lang', lang);
  }
}
