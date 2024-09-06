import { useEffect, useState } from 'react'
import { useAuthState } from '../contexts/User'
import Terminal from '../widgets/Terminal.tsx'
import { API_URI } from '../../config.ts'
import { FlakeLockNodeInput, FlakeLockNodeRoot, Generation, GenerationInfo } from '../../types/gen.ts'

type HTMLModalElement = HTMLElement & {
  showModal(): void;
  close(): void;
}

type NixLog = {
  action: 'msg',
  level: number,
  msg: string,
} | {
  action: 'start',
  fields: string[],
  id: number,
  level: number,
  parent: number,
  text: string,
} | {
  action: 'result',
  field: string[],
  id: number,
  type: number,
} | {
  action: 'stop',
  id: number,
}

const GenerationsPage = () => {
  const { auth } = useAuthState();
  const [ gens, setGens ] = useState({} as Map<string, Generation>);
  const [ genInfo, setGenInfo ] = useState<GenerationInfo | null>(null);
  const [ error, setError ] = useState<Error | null>(null);
  const [ nixLog, setNixLog ] = useState<NixLog[]>([]);
  const [ nixDone, setNixDone ] = useState<boolean>(false);
  const [ commitTitle, setCommitTitle ] = useState<string>('');

  const fmtTime = (date: Date) => `${date.getFullYear()}-${date.getMonth()}-${date.getDate()} ${date.getHours()}:${date.getMinutes()}`;

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

  const handleUpdate = () => {
    setError(null);
    setNixLog([]);
    setNixDone(false);

    (document.getElementById('terminal') as HTMLModalElement).showModal();

    const authKey = 'user' in auth ? atob(auth.user.authKey ?? '').split(':') : [];

    const url = new URL(`${API_URI.indexOf('/') == 0 ? window.location.origin + API_URI : API_URI}/gen/update`);
    url.username = authKey[0];
    url.password = authKey[1];

    const ws = new WebSocket(url);

    const log: NixLog[] = [];

    ws.onerror = () => {
      setError(new Error('Unexpected WebSocket error'));
    };

    ws.onmessage = (msg) => {
      log.push(JSON.parse(msg.data) as NixLog);
      setNixLog(log);
    };

    ws.onclose = () => {
      setNixDone(true);
    };
  };

  const handleApply = (commitHash?: string) => {
    setError(null);
    setNixLog([]);
    setNixDone(false);

    (document.getElementById('terminal') as HTMLModalElement).showModal();

    const authKey = 'user' in auth ? atob(auth.user.authKey ?? '').split(':') : [];

    const url = new URL(`${API_URI.indexOf('/') == 0 ? window.location.origin + API_URI : API_URI}/gen/apply`);
    url.username = authKey[0];
    url.password = authKey[1];

    if (commitHash !== null) {
      url.searchParams.set('commit', commitHash as string);
    }

    const ws = new WebSocket(url);

    const log: NixLog[] = [];

    ws.onerror = () => {
      setError(new Error('Unexpected WebSocket error'));
    };

    ws.onmessage = (msg) => {
      log.push(JSON.parse(msg.data) as NixLog);
      setNixLog(log);
    };

    ws.onclose = () => {
      setNixDone(true);
    };
  };

  const handleCommit = () => {
    fetch(`${API_URI}/gen/commit?title=${encodeURIComponent(commitTitle)}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    }).then((resp) => resp.text())
      .then(() => {
        setCommitTitle('');
        (document.getElementById('commit') as HTMLModalElement).close();
      });
  };

  return (
    <div className="p-2 space-2 gap-2 flex">
      <dialog id="terminal" className="modal">
        <div className="modal-box max-w-[64em]">
          {error !== null ? (
            <div className="card bg-error shadow-xl text-error-content">
              <div className="card-body">
                <h2 className="card-title">{error.name}</h2>
                <p>{error.message}</p>
              </div>
            </div>
          ) : null}
          <Terminal input={nixLog.filter((log) => log.action == 'msg').map((log) => log.msg).join('\n')} />
          {nixDone ? (
            <div className="modal-action">
              <button className="btn justify-end" onClick={() => (document.getElementById('terminal') as HTMLModalElement).close()}>
                Close
              </button>
            </div>
          ) : null}
        </div>
      </dialog>
      <dialog id="commit" className="modal">
        <div className="modal-box">
          <label className="form-control w-full max-w-xs">
            <div className="label">
              <span className="label-text">Commit title</span>
            </div>
            <input type="text" className="input input-bordered w-full max-w-xs" value={commitTitle} onChange={(e) => setCommitTitle(e.target.value)} />
            <div className="modal-action">
              <button className="btn justify-end" onClick={handleCommit}>
                Commit
              </button>
            </div>
          </label>
        </div>
      </dialog>
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
                      <p><span className="font-bold">Author</span>: {gen.author.substring(0, gen.author.indexOf('<') - 1)}</p>
                      <p><span className="font-bold">Committed</span>: {fmtTime(new Date(gen.authorDate))}</p>
                      <div className="card-actions justify-end">
                        <button className="btn btn-error" onClick={() => handleApply(sha)}>Rollback</button>
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
                <button className="btn join-item" onClick={handleUpdate}>Update</button>
                <button className="btn join-item"
                  onClick={() => (document.getElementById('commit') as HTMLModalElement).showModal()}
                  disabled={genInfo != null ? genInfo.isClean : true}>Commit</button>
                <button className="btn join-item" onClick={() => handleApply()} disabled={genInfo != null ? !genInfo.isClean : true}>Apply</button>
              </div>
              <p><span className="font-bold">Nix</span>: {genInfo.nixVersion}</p>
              <p><span className="font-bold">Branch</span>: {genInfo.branch}</p>
              <p><span className="font-bold">Config Name</span>: {genInfo.configName}</p>
              <h2 className="text-neutral-content font-bold text-lg pt-2">Flake Inputs</h2>
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
