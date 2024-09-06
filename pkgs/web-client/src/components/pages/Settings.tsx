import { useLoaderData } from 'react-router-dom'
import { OptionsMap } from '../../types/options'
import OptionInput from '../widgets/OptionInput'

const SettingsPage = () => {
  const data = useLoaderData() as OptionsMap;
  const toplevel = Object.fromEntries(Object.entries(data).filter((entries) => entries[1].isToplevel).map(([ key, value ]) => [
    key,
    {
      ...value,
      children: Object.fromEntries(Object.entries(data).filter((entries) => entries[1].childOf == value.loc.join('.')).map(([ skey, svalue ]) => [
        skey.replace(`${key}.*.`, ''),
        svalue,
      ])),
    },
  ]));

  return (
    <div className="space-y-2 p-2">
      {Object.entries(toplevel).map(([ key, opt ]) => <OptionInput key={key} option={opt} />)}
    </div>
  );
};

export default SettingsPage
