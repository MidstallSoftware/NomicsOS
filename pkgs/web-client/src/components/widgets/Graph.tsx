import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler, ChartData, ChartOptions } from 'chart.js'
import { Line } from 'react-chartjs-2'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler);

const Graph = ({ data, options }: { data: ChartData<'line'>, options: ChartOptions<'line'> }) => (
  <Line
    className="border-3 rounded text-white"
    data={data}
    redraw={false}
    options={{
      ...(options ?? {}),
      responsive: true,
      scales: Object.fromEntries(Object.entries(options.scales ?? {}).map(([ key, scale ]) => [
        key,
        {
          ...(scale ?? {}),
          ticks: {
            ...((scale ?? {}).ticks ?? {}),
            color: '#ffffff',
          },
        },
      ])),
      color: '#ffffff',
    }}
    />
);

export default Graph
