import { useState } from 'react'
import { API_URI } from '../../config'

const LogInPage = () => {
  const [data, setData] = useState<null | object>(null);

  const fetchData = () => {
    fetch(API_URI, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json; charset=utf-8'
      },
    }).then(r => r.json()).then(r => {
      setData(r);
    }).catch(console.log);
  };

  return (
    <div>
      <p>Hello, world</p>
      <p>API URI: {API_URI}</p>
      <p>{JSON.stringify(data)}</p>
      <button className="btn btn-primary" onClick={() => fetchData()}>Fetch from API</button>
    </div>
  );
};

export default LogInPage
