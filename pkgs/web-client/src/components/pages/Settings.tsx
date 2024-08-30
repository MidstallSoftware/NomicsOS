import { useLoaderData } from 'react-router-dom'
import { OptionsMap } from '../../types/options'

const SettingsPage = () => {
  const data = useLoaderData() as OptionsMap;
  const toplevel = Object.fromEntries(Object.entries(data).filter((entries) => entries[1].isToplevel));

  return (
    <div className="flex justify-center p-3">
      <div className="mockup-code">
        {JSON.stringify(toplevel, null, 2)}
      </div>
    </div>
  );
};

export default SettingsPage
