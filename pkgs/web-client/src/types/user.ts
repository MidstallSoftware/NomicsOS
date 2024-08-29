import { API_URI } from '../config'

class User {
  id: number;
  name: string;
  createdAt: Date;
  displayName?: string;

  constructor({ id, name, createdAt, displayName }: {
    id: number,
    name: string,
    createdAt: Date,
    displayName?: string,
  }) {
    this.id = id;
    this.name = name;
    this.createdAt = createdAt;
    this.displayName = displayName;
  }

  static async login(name: string, password: string): Promise<User> {
    const resp = await fetch(`${API_URI}/user/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${btoa(`${name}:${password}`)}`,
      },
    });

    const data = await resp.json();

    if (resp.status == 401) {
      throw new Error(`${data.error}: ${data.message}`);
    }

    return new User({
      id: data['id'],
      name: data['name'],
      createdAt: new Date(data['createdAt']),
      displayName: data['displayName'],
    });
  }
}

export default User
