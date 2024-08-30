import { useState, useEffect } from 'react'
import { useAuthState } from '../contexts/User'
import CpuGague from '../widgets/CpuGague.tsx'
import { SystemStats } from '../../types/stats.ts'
import { API_URI } from '../../config.ts'

const IndexPage = () => {
  const { auth } = useAuthState();
  const [lastState, setLastState] = useState<SystemStats | null>(null);
  const [currState, setCurrState] = useState<SystemStats | null>(null);

  useEffect(() => {
    const int = setInterval(() => {
      fetch(`${API_URI}/system/status`, {
        headers: {
          'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        },
      }).then(async (r) => await r.json() as SystemStats).then((data) => {
        setLastState(currState);
        setCurrState(data);
      });
    }, 1000);

    return () => clearInterval(int);
  });

  return (
    <div className="flex p-2">
      <div className="card bg-primary text-primary-content w-full">
        <div className="card-body">
         <h2 className="card-title">CPU Usage</h2>
          <div className="flex justify-evenly">
            {lastState != null && currState != null ? new Array(currState.cpu.length).fill(0)
              .map((_, i) => <CpuGague last={lastState.cpu[i]} curr={currState.cpu[i]} />) : <div className="skeleton h-32 w-full"></div>}
          </div>
        </div>
      </div>
    </div>
  );
};

export default IndexPage
