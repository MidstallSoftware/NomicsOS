import { ReactNode } from 'react'
import { useAuthState } from '../contexts/User.tsx'

const AuthRequired = ({ children }: { children: ReactNode }) => {
  const { auth } = useAuthState();

  if (auth.state == 'SIGNED_IN') return children;

  return (
    <div className="flex justify-center pt-3">
      <div className="card bg-base-300 w-96 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">401 Unauthorized</h2>
          <p>The requested page cannot be accessed without authorization.</p>
          <div className="card-actions justify-end">
            <a className="btn btn-primary" href="/login">Log In</a>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuthRequired
