import { useEffect, useState } from 'react'
import { useAuthState } from '../contexts/User'
import { API_URI } from '../../config.ts'
import { Generation } from '../../types/gen.ts'

const GenerationsPage = () => {
  const { auth } = useAuthState();
  const [ gens, setGens ] = useState<Map<string, Generation>>({});

  useEffect(() => {
    fetch(`${API_URI}/gen/list`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    }).then((resp) => resp.json())
      .then((value) => {
        setGens(value);
      });
  }, [auth, gens]);

  return (
    <div className="p-2 space-2 gap-2 flex">
      <div className="card bg-neutral text-neutral-content shadow-xl flex-1">
        <div className="card-body">
          <h2 className="card-title">Generations</h2>
          <ul className="space-y-2">
            {Object.entries(gens).length > 0 ? (
              Object.entries(gens).map(([ sha, gen ]) => (
                <li key={sha}>
                  <div className="card bg-slate-950 shadow-xl">
                    <div className="card-body">
                      <h2>{sha}</h2>
                      <h2 className="card-title">{gen.message.split('\n')[0]}</h2>

                      <div className="card-actions justify-end">
                        <button className="btn btn-error">Rollback</button>
                      </div>
                    </div>
                  </div>
                </li>
              ))
            ) : <div className="skeleton h-32 w-96"></div>}
          </ul>
        </div>
      </div>
      <div className="card bg-neutral text-neutral-content shadow-xl">
        <div className="card-body">
          <h2 className="card-title">Staging Generation</h2>
          <div>
            <div className="join pb-2">
              <button className="btn join-item">Update</button>
              <button className="btn join-item">Commit</button>
              <button className="btn join-item">Apply</button>
            </div>
            <p>Nix: v</p>
            <p>Branch: main</p>
          </div>
          <h2 className="text-neutral-content font-bold text-lg">Flake Inputs</h2>
          <ul>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default GenerationsPage
