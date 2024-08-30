import { useState, useEffect, ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthState } from '../contexts/User.tsx'
import NavBar from '../widgets/NavBar.tsx'
import { API_URI } from '../../config.ts'

type NavMenuItem = {
  displayName: string;
  id: string;
}

const NavMenu = () => {
  const [settingsItems, setSettingsItems] = useState([] as NavMenuItem[]);
  const nav = useNavigate();

  useEffect(() => {
    fetch(`${API_URI}/option-pages.json`)
      .then((resp) => resp.json())
      .then((items) => {
        setSettingsItems(items);
      });
  }, []);

  return (
    <ul className="menu bg-base-200 text-base-content min-h-full w-80 p-4">
      <li><button onClick={() => nav('/')}>Dashboard</button></li>
      <li>
        <h2 className="menu-title">Settings</h2>
        <ul>
          {settingsItems.map(({ displayName, id }) => (
            <li key={id}><button onClick={() => nav(`/settings/${id}`)}>{displayName}</button></li>
          ))}
        </ul>
      </li>
    </ul>
  );
};

const DefaultLayout = ({ children }: { children: ReactNode }) => {
  const { auth } = useAuthState();

  return auth.state == 'SIGNED_IN' ? (
    <div className="drawer lg:drawer-open">
      <input id="drawer" type="checkbox" className="drawer-toggle" />
      <div className="drawer-content">
        <NavBar />
        {children}
      </div>
      <div className="drawer-side">
        <label htmlFor="drawer" aria-label="close sidebar" className="drawer-overlay"></label>
        <NavMenu />
      </div>
    </div>
  ) : (
    <div>
      <NavBar />
      {children}
    </div>
  );
};

export default DefaultLayout
