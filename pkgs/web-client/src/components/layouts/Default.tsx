import { Outlet } from 'react-router-dom'
import NavBar from '../widgets/NavBar.tsx'

const DefaultLayout = () =>
  (
    <div>
      <NavBar />
      <Outlet />
    </div>
  );

export default DefaultLayout
