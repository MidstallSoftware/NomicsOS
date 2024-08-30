import { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuthState } from '../contexts/User.tsx'
import NavBar from '../widgets/NavBar.tsx'

const DefaultLayout = ({ children }: { children: ReactNode }) => {
  const { auth } = useAuthState();
  const nav = useNavigate();

  return auth.state == 'SIGNED_IN' ? (
    <div className="drawer lg:drawer-open">
      <input id="drawer" type="checkbox" className="drawer-toggle" />
      <div className="drawer-content">
        <NavBar />
        {children}
      </div>
      <div className="drawer-side">
        <label htmlFor="drawer" aria-label="close sidebar" className="drawer-overlay"></label>
        <ul className="menu bg-base-200 text-base-content min-h-full w-80 p-4">
          <li><button onClick={() => nav('/')}>Dashboard</button></li>
          <li>
            <h2 className="menu-title">Settings</h2>
            <ul>
              <li><button onClick={() => nav('/settings/general')}>General</button></li>
              <li><button onClick={() => nav('/settings/users')}>Users</button></li>
            </ul>
          </li>
        </ul>
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
