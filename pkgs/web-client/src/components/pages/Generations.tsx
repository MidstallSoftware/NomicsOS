import { useEffect, useState } from 'react'
import { useAuthState } from '../contexts/User'
import { API_URI } from '../../config.ts'
import { FlakeLockNodeInput, FlakeLockNodeRoot, Generation, GenerationInfo } from '../../types/gen.ts'

const GenerationsPage = () => {
  const { auth } = useAuthState();
  const [ gens, setGens ] = useState({} as Map<string, Generation>);
  const [ genInfo, setGenInfo ] = useState<GenerationInfo | null>(null);

  useEffect(() => {
    fetch(`${API_URI}/gen/list`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    }).then((resp) => resp.json())
      .then((value) => {
        setGens(value);
      });

    fetch(`${API_URI}/gen/info`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    }).then((resp) => resp.json())
      .then((value) => {
        setGenInfo(value);
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
      <div className="card bg-neutral text-neutral-content shadow-xl h-min">
        <div className="card-body">
          <h2 className="card-title">Staging Generation</h2>
          {genInfo != null ? (
            <div>
              <div className="join pb-2">
                <button className="btn join-item">Update</button>
                <button className="btn join-item">Commit</button>
                <button className="btn join-item">Apply</button>
              </div>
              <p>Nix: {genInfo.nixVersion}</p>
              <p>Branch: {genInfo.branch}</p>
              <h2 className="text-neutral-content font-bold text-lg">Flake Inputs</h2>
              <ul>
                {Object.entries((genInfo.metadata.locks.nodes[genInfo.metadata.locks.root] as FlakeLockNodeRoot).inputs).map(([ input, key ]) => {
                  const node = genInfo.metadata.locks.nodes[key] as FlakeLockNodeInput;
                  return (
                    <li key={input} className="space-x-1">
                      <span className="font-bold">{input}</span>
                      {node.original.type == "github" ? (
                        <a target="_blank"
                          className="link"
                          href={`https://github.com/${node.original.owner}/${node.original.repo}${node.original.ref != null ? `/commit/${node.original.ref}` : ''}`}>
                          github:{node.original.owner}/{node.original.repo}{node.original.ref != null ? `/${node.original.ref}` : ''}
                        </a>
                      ) : null}
                    </li>
                  );
                })}
              </ul>
            </div>
          ) : <div className="skeleton h-32 w-32"></div>}
        </div>
      </div>
    </div>
  );
};

export default GenerationsPage
