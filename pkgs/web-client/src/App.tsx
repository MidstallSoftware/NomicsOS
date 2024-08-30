import { lazy, Suspense } from 'react';
import { createBrowserRouter, Outlet, RouterProvider } from 'react-router-dom'
import DefaultLayout from './components/layouts/Default.tsx'
import LoadingPage from './components/pages/Loading.tsx'
import { AuthProvider } from './components/contexts/User.tsx'
import AuthRequired from './components/widgets/AuthRequired.tsx'
import { API_URI } from './config.ts'
import { OptionsMap } from './types/options.ts'
import './App.css'

const IndexPage = lazy(() => import('./components/pages/Index.tsx'));
const LogInPage = lazy(() => import('./components/pages/LogIn.tsx'));
const SettingsPage = lazy(() => import('./components/pages/Settings.tsx'));
const E404Page = lazy(() => import('./components/pages/404.tsx'));

const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <DefaultLayout>
        <Outlet />
      </DefaultLayout>
    ),
    children: [
      {
        index: true,
        element: (
          <AuthRequired>
            <IndexPage />
          </AuthRequired>
        ),
      },
      {
        path: '/settings/:pageId',
        loader: ({ params }) =>
          fetch(`${API_URI}/options.json`)
            .then(r => r.json())
            .then((opts) => Object.fromEntries(Object.entries(opts as OptionsMap).filter((entry) => entry[1].pageId == params.pageId))),
        element: (
          <AuthRequired>
            <SettingsPage />
          </AuthRequired>
        ),
      },
    ],
  },
  {
    path: '/login',
    element: (
      <DefaultLayout>
        <LogInPage />
      </DefaultLayout>
    ),
  },
  {
    path: '/*',
    element: (
      <DefaultLayout>
        <E404Page />
      </DefaultLayout>
    ),
  },
]);

const App = () =>
  (
    <AuthProvider>
      <Suspense fallback={<LoadingPage />}>
        <RouterProvider router={router} />
      </Suspense>
    </AuthProvider>
  );

export default App
