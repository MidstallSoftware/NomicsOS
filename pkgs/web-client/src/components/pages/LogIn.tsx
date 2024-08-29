import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useSignIn } from '../contexts/User'
import User from '../../types/user'

const LogInPage = () => {
  const [ error, setError ] = useState<Error | null>(null);
  const [ name, setName ] = useState('');
  const [ password, setPassword ] = useState('');
  const { signIn } = useSignIn();
  const nav = useNavigate();

  const handleSubmit = (ev) => {
    ev.preventDefault();
    setError(null);

    User.login(name, password).then((user) => {
      signIn(user);
      nav('/');
    }).catch((err) => {
      setError(err);
    });
  };

  return (
    <div className="flex justify-center pt-3">
      <div className="card bg-base-300 w-96 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">Log In</h2>
          {error !== null ? (
            <div className="card bg-error shadow-xl text-error-content">
              <div className="card-body">
                <h2 className="card-title">{error.name}</h2>
                <p>{error.message}</p>
              </div>
            </div>
          ) : null}
          <form onSubmit={handleSubmit}>
            <input type="text" placeholder="User Name" value={name} onChange={e => setName(e.target.value)} className="input w-full max-w-xs m-2" />
            <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} className="input w-full max-w-xs m-2" />
            <div className="card-actions justify-end">
              <button className="btn btn-primary">Log in</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default LogInPage
