export interface Category {
  id: number;
  name: string;
  position: number;
}

export interface AvailabilityEntry {
  id?: number;
  start_at: string;
  end_at?: string | null;
  description?: string | null;
}

export interface Item {
  id: number;
  name: string;
  description: string;
  price: number;
  image_url: string;
  category_id: number;
  category_name?: string;
  deleted_at: string | null;
  in_use: boolean;
  availabilities: AvailabilityEntry[];
}
