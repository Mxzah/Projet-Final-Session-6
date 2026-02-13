export interface Category {
  id: number;
  name: string;
  position: number;
}

export interface Item {
  id: number;
  name: string;
  description: string;
  price: number;
  image_url: string;
  category_id: number;
  deleted_at: string | null;
}

export interface MenuData {
  categories: Category[];
  items: Item[];
}
