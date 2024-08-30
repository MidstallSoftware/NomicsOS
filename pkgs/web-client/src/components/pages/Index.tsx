import { useState, useEffect } from 'react'
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler } from 'chart.js'
import { Line } from 'react-chartjs-2'
import { useAuthState } from '../contexts/User'
import CpuGague from '../widgets/CpuGague.tsx'
import { SystemStats } from '../../types/stats.ts'
import { API_URI } from '../../config.ts'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler);

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
        setState(state.splice(0, 5).concat([ data ]));
      });
    }, 1000);

    return () => clearInterval(int);
  });

  return (
    <div className="p-2 space-y-2">
      <div className="flex space-x-2">
        <div className="card bg-neutral text-neutral-content w-full shadow-xl">
          <div className="card-body">
           <h2 className="card-title">CPU Usage</h2>
            <div className="grid grid-cols-5 justify-evenly">
              {state.length > 1 ? new Array(state[state.length - 1].cpu.length).fill(0)
                .map((_, i) => <CpuGague last={state[state.length - 2].cpu[i]} curr={state[state.length - 1].cpu[i]} />) : <div className="skeleton h-96 w-96"></div>}
            </div>
          </div>
        </div>
        <div className="card bg-neutral text-neutral-content w-full shadow-xl">
          <div className="card-body">
           <h2 className="card-title">Memory Usage</h2>
            <div className="flex justify-evenly w-full">
              {state.length > 1 ? (
                <Line
                  className="border-3 rounded text-white"
                  options={{
                    responsive: true,
                    scales: {
                      x: {
                        display: false,
                      },
                      y: {
                        display: true,
                        max: state.map((st) => st.mem.MemTotal)[state.length - 1],
                        ticks: {
                          color: '#ffffff',
                          stepSize: 1024 * 1024 * 1024,
                          callback: (_, i) => `${i} GB`,
                        },
                      },
                    },
                    color: '#ffffff',
                  }}
                  redraw={false}
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
      </div>
    </div>
  );
};

export default IndexPage
