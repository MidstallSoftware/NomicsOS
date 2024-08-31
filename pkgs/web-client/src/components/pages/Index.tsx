import { useState, useEffect } from 'react'
import { useAuthState } from '../contexts/User'
import CpuGague from '../widgets/CpuGague.tsx'
import Graph from '../widgets/Graph.tsx'
import { SystemStats } from '../../types/stats.ts'
import { API_URI } from '../../config.ts'

const IndexPage = () => {
  const { auth } = useAuthState();
  const [state, setState] = useState<SystemStats[]>([]);

  useEffect(() => {
    const int = setInterval(() => {
      fetch(`${API_URI}/system/status`, {
        headers: {
          'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        },
      }).then(async (r) => await r.json() as SystemStats).then((data) => {
        const newState = state.splice(0, 5).concat([ data ]);
        setState(newState.map((st, i) => ({
          ...st,
          net: st.net.map((netdev, x) => {
            const prev = i > 0 ? newState[i - 1].net[x].stats : { rx: 0, tx: 0 };
            return {
              ...netdev,
              stats: {
                rx: Math.abs(netdev.stats.rx - prev.rx),
                tx: Math.abs(netdev.stats.tx - prev.tx),
              },
            };
          }),
        })));
      });
    }, 1000);

    return () => clearInterval(int);
  });

  return (
    <div className="p-2 space-2 gap-2 grid grid-cols-2">
      <div className="card bg-neutral text-neutral-content shadow-xl">
        <div className="card-body">
         <h2 className="card-title">CPU Usage</h2>
          <div className="grid grid-cols-5 justify-evenly">
            {state.length > 1 ? new Array(state[state.length - 1].cpu.length).fill(0)
              .map((_, i) => <CpuGague last={state[state.length - 2].cpu[i]} curr={state[state.length - 1].cpu[i]} />) : <div className="skeleton h-96 w-96"></div>}
          </div>
        </div>
      </div>
      <div className="card bg-neutral text-neutral-content shadow-xl">
        <div className="card-body">
         <h2 className="card-title">Memory Usage</h2>
         <div className="flex justify-evenly w-full">
           {state.length > 1 ? (
             <Graph
               options={{
                  scales: {
                    x: {
                      display: false,
                    },
                    y: {
                      display: true,
                      max: state.map((st) => st.mem.MemTotal)[state.length - 1],
                      ticks: {
                        stepSize: 1024 * 1024 * 1024,
                        callback: (_, i) => `${i} GB`,
                      },
                    },
                  },
                }}
                data={{
                  datasets: [
                    {
                      fill: true,
                      data: state.map((st) => st.mem.MemAvailable),
                      label: 'Available',
                      backgroundColor: '#65a30d40',
                    },
                    {
                      fill: true,
                      data: state.map((st) => st.mem.Cached),
                      label: 'Cached',
                      backgroundColor: '#57534e40',
                    },
                    {
                      fill: true,
                      data: state.map((st) => st.mem.MemTotal - st.mem.MemAvailable),
                      label: 'Used',
                      backgroundColor: '#dc262640',
                    }
                  ],
                  labels: new Array(state.length).fill(0)
                    .map((_, i) => `${state.length - i} second${(state.length - i) > 1 ? 's' : ''} ago`),
                }}
              />
            ) : <div className="skeleton h-96 w-96"></div>}
          </div>
        </div>
      </div>
      {state.length > 0 ? state[state.length - 1].net.map((netdev, i) => (
        <div className="card bg-neutral text-neutral-content shadow-xl">
          <div className="card-body">
             <h2 className="card-title">Network Usage: {netdev.name}</h2>
             <div className="flex justify-evenly w-full">
              <Graph
                options={{
                  scales: {
                    x: {
                      display: false,
                    },
                    y: {
                      display: true,
                      ticks: {
                        stepSize: 1024 * 1024,
                        callback: (_, i) => `${i} MB`,
                      },
                    },
                  },
                }}
                data={{
                  datasets: [
                    {
                      fill: true,
                      data: state.map((st) => st.net[i].stats.rx),
                      label: 'RX',
                      backgroundColor: '#65a30d40',
                    },
                    {
                      fill: true,
                      data: state.map((st) => st.net[i].stats.tx),
                      label: 'TX',
                      backgroundColor: '#dc262640',
                    }
                  ],
                  labels: new Array(state.length).fill(0)
                    .map((_, i) => `${state.length - i} second${(state.length - i) > 1 ? 's' : ''} ago`),
                }}
              />
             </div>
          </div>
        </div>
      )) : <div className="skeleton h-96 w-96"></div>}
    </div>
  );
};

export default IndexPage
