import { lazy, Suspense } from 'react';
import { RouteObject, useRoutes, BrowserRouter } from 'react-router-dom'
import DefaultLayout from './components/layouts/Default.tsx'
import LoadingPage from './components/pages/Loading.tsx'
import { AuthProvider } from './components/contexts/User.tsx'
import './App.css'

const IndexPage = lazy(() => import('./components/pages/Index.tsx'));
const LogInPage = lazy(() => import('./components/pages/LogIn.tsx'));
const E404Page = lazy(() => import('./components/pages/404.tsx'));

const Router = () =>
  (
    <BrowserRouter>
      <InnerRouter />
    </BrowserRouter>
  );

function InnerRouter() {
  const routes: RouteObject[] = [
    {
      path: '/',
      element: <DefaultLayout />,
      children: [
        {
          index: true,
          element: <IndexPage />,
        },
        {
          path: '/login',
          element: <LogInPage />,
        },
        {
          path: '*',
          element: <E404Page />,
        },
      ],
    },
  ];

  const element = useRoutes(routes);
  return (
    <div>
      <Suspense fallback={<LoadingPage />}>{element}</Suspense>
    </div>
  );
}

const App = () =>
  (
    <AuthProvider>
      <Router />
    </AuthProvider>
  );

export default App
