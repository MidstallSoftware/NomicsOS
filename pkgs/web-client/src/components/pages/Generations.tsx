import { useEffect, useState } from 'react'
import { useAuthState } from '../contexts/User'
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
  const [ updateError, setUpdateError ] = useState<Error | null>(null);
  const [ nixLog, setNixLog ] = useState<NixLog[]>([]);
  const [ nixUpdateDone, setNixUpdateDone ] = useState<boolean>(false);

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
    setUpdateError(null);
    setNixLog([]);
    setNixUpdateDone(false);

    (document.getElementById('flake-update') as HTMLModalElement).showModal();

    const authKey = 'user' in auth ? atob(auth.user.authKey ?? '').split(':') : [];

    const url = new URL(`${API_URI}/gen/update`);
    url.username = authKey[0];
    url.password = authKey[1];

    const ws = new WebSocket(url);

    const log: NixLog[] = [];

    ws.onerror = () => {
      setUpdateError(new Error('Unexpected WebSocket error'));
    };

    ws.onmessage = (msg) => {
      log.push(JSON.parse(msg.data) as NixLog);
      setNixLog(log);
    };

    ws.onclose = () => {
      setNixUpdateDone(true);
    };
  };

  return (
    <div className="p-2 space-2 gap-2 flex">
      <dialog id="flake-update" className="modal">
        <div className="modal-box">
          <h3 className="font-bold text-lg pb-2">Update Flake</h3>
          {updateError !== null ? (
            <div className="card bg-error shadow-xl text-error-content">
              <div className="card-body">
                <h2 className="card-title">{updateError.name}</h2>
                <p>{updateError.message}</p>
              </div>
            </div>
          ) : null}
          <div className="mockup-code">
            {nixLog.filter((log) => log.action == 'msg').map((log, i) => (
              <pre key={i} className="text-warning"><code>{log.msg}</code></pre>
            ))}
          </div>
          {nixUpdateDone ? (
            <div className="modal-action">
              <button className="btn justify-end" onClick={() => (document.getElementById('flake-update') as HTMLModalElement).close()}>
                Close
              </button>
            </div>
          ) : null}
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
                <button className="btn join-item" onClick={handleUpdate}>Update</button>
                <button className="btn join-item" disabled={genInfo != null ? genInfo.isClean : true}>Commit</button>
                <button className="btn join-item" disabled={genInfo != null ? !genInfo.isClean : true}>Apply</button>
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
