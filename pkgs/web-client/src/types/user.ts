import { API_URI } from '../config'

class User {
  id: number;
  name: string;
  createdAt: Date;
  displayName?: string;
  authKey?: string;

  constructor({ id, name, createdAt, displayName, authKey }: {
    id: number,
    name: string,
    createdAt: Date,
    displayName?: string,
    authKey?: string,
  }) {
    this.id = id;
    this.name = name;
    this.createdAt = createdAt;
    this.displayName = displayName;
    this.authKey = authKey;
  }

  static async login(name: string, password: string): Promise<User> {
    const authKey = btoa(`${name}:${password}`);

    const resp = await fetch(`${API_URI}/user/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${authKey}`,
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
      authKey,
    });
  }
}

export default User
