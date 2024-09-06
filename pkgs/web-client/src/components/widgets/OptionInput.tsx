import { ChangeEvent, useEffect, useState } from 'react'
import { useAuthState } from '../contexts/User'
import { Option, OptionDefault, OptionsMap } from '../../types/options'
import { API_URI } from '../../config'

type HTMLModalElement = HTMLElement & {
  showModal(): void;
  close(): void;
}

const genKey = (option: Option) => `$${option.loc.slice(1).map((str) => {
  if (str.indexOf('-') > -1) {
    return `["${str}"]`;
  }
  return `.${str}`;
}).join('')}`;

const OptionInputDefault = (value: OptionDefault) => {
  if (value.text.indexOf('"') == 0 && value.text.lastIndexOf('"') == value.text.length - 1) {
    return value.text.substring(1, value.text.length - 1);
  }

  if (value.text == 'true') return true;
  if (value.text == 'false') return false;
  return null;
};

const OptionInputString = ({ option }: { option: Option }) => {
  const { auth } = useAuthState();

  const defaultValue = (option.default != null ? OptionInputDefault(option.default) : null) ?? '';
  const [value, setValue] = useState(defaultValue);
  const key = genKey(option);

  useEffect(() => {
    fetch(`${API_URI}/settings/get?key=${encodeURIComponent(key)}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    }).then((resp) => resp.json())
      .then((value) => {
        setValue(value ?? defaultValue);
      });
  }, [ auth, defaultValue, key ]);

  const handleChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const resp = await fetch(`${API_URI}/settings/set?key=${encodeURIComponent(key)}&value=${encodeURIComponent(JSON.stringify(e.target.value))}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    });

    const value = await resp.json();
    setValue(value ?? defaultValue);
  };

  return (
    <div className="card bg-neutral text-neutral-content shadow-xl">
      <div className="card-body">
        <label className="form-control w-full max-w-xs">
          <div className="label">
            <span className="label-text">{option.description}</span>
          </div>
          <input type="text" className="input input-bordered w-full max-w-xs" value={value as string} onChange={handleChange} />
        </label>
      </div>
    </div>
  );
};

const OptionInputBoolean = ({ option }: { option: Option }) => {
  const { auth } = useAuthState();

  const defaultValue = (option.default != null ? OptionInputDefault(option.default) == true : null) ?? false;
  const [value, setValue] = useState(defaultValue);
  const key = genKey(option);

  useEffect(() => {
    fetch(`${API_URI}/settings/get?key=${encodeURIComponent(key)}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        'Content-Type': 'application/json',
      },
    }).then((resp) => resp.json())
      .then((value) => {
        setValue(value ?? defaultValue);
      });
  }, [ auth, defaultValue, key ]);

  const handleChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const resp = await fetch(`${API_URI}/settings/set?key=${encodeURIComponent(key)}&value=${encodeURIComponent(JSON.stringify(e.target.checked))}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        'Content-Type': 'application/json',
      },
    });

    const value = await resp.json();
    setValue(value ?? defaultValue);
  };

  return (
    <div className="card bg-neutral text-neutral-content shadow-xl">
      <div className="card-body">
        <div className="form-control">
          <label className="label cursor-pointer">
            <span className="label-text">{option.description}</span>
            <input type="checkbox" className="toggle" checked={value} onChange={handleChange} />
          </label>
        </div>
      </div>
    </div>
  );
};

const OptionInputList = ({ option }: { option: Option }) => {
  const { auth } = useAuthState();

  const defaultValue = ((option.default != null ? OptionInputDefault(option.default) : null) ?? []) as Record<string, string | null>[];
  const [value, setValue] = useState(defaultValue);
  const [newOption, setNewOption] = useState({} as Record<string, string | null>);
  const key = genKey(option);

  useEffect(() => {
    fetch(`${API_URI}/settings/get?key=${encodeURIComponent(key)}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        'Content-Type': 'application/json',
      },
    }).then((resp) => resp.json())
      .then((value) => {
        setValue(value);
      });
  }, [ auth, defaultValue, key ]);

  const handleAdd = async () => {
    const temp = value.concat([ newOption ]);

    const resp = await fetch(`${API_URI}/settings/set?key=${encodeURIComponent(key)}&value=${encodeURIComponent(JSON.stringify(temp))}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    });

    const newValue = await resp.json();
    setValue(newValue ?? defaultValue);

    setNewOption({});
  };

  const handleDelete = async (i: number) => {
    const temp = value;
    temp.splice(i, 1);

    const resp = await fetch(`${API_URI}/settings/set?key=${encodeURIComponent(key)}&value=${encodeURIComponent(JSON.stringify(temp))}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    });

    const newValue = await resp.json();
    setValue(newValue ?? defaultValue);
  };

  return (
    <div className="card bg-neutral text-neutral-content shadow-xl">
      <div className="card-body">
        <div className="overflow-x-auto">
          <dialog id={`${key.substring(2)}-new-dialog`} className="modal">
            <div className="modal-box">
              <div className="space-y-2">
                {Object.entries(option.children ?? {} as OptionsMap).map(([ key, subOption ]) => (
                  <div className="card bg-neutral text-neutral-content shadow-xl" key={key}>
                    <div className="card-body">
                      <label className="form-control w-full max-w-xs">
                        <div className="label">
                          <span className="label-text">{subOption.description}</span>
                        </div>
                        <input type="text" className="input input-bordered w-full max-w-xs" value={newOption[key] ?? ''} onChange={(e) => setNewOption({
                          ...newOption,
                          [key]: e.target.value,
                        })} />
                      </label>
                    </div>
                  </div>
                ))}
              </div>
              <div className="modal-action">
                <form method="dialog">
                  <button className="btn">Close</button>
                  <button className="btn" onClick={handleAdd}>Add</button>
                </form>
              </div>
            </div>
          </dialog>
          <table className="table">
            <thead>
              <tr>
                <th>
                  <div className="join">
                    <button className="btn join-item" onClick={() => (document.getElementById(`${key.substring(2)}-new-dialog`) as HTMLModalElement).showModal()}>Add</button>
                  </div>
                </th>
                {Object.entries(option.children ?? {} as OptionsMap).map(([ key, value ]) => (
                  <th key={key}>{value.label}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {value.map((entry, i) => (
                <tr key={i.toString()}>
                  <th>
                    <div className="join">
                      <button className="btn join-item" onClick={() => handleDelete(i)}>Delete</button>
                    </div>
                  </th>
                  {Object.keys(option.children ?? {}).map((key, i) => (
                    <th key={i.toString()}>{(entry[key] || '').toString()}</th>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

const OptionInput = ({ key, option }: { key: string, option: Option }) => {
  const type = option.type.split(';')[0];
  //const isNullable = (type.match(/^null or/g) ?? []).length > 0;
  const isString = (type.match(/string/g) ?? []).length > 0;
  const isBoolean = (type.match(/boolean/g) ?? []).length > 0;
  //const isUtf16 = (type.match(/16 bit unsigned integer/g) ?? []).length > 0;
  const isList = (type.match(/^list of/g) ?? []).length > 0;

  if (isString) {
    return <OptionInputString option={option} />;
  }

  if (isBoolean) {
    return <OptionInputBoolean option={option} />;
  }

  if (isList) {
    return <OptionInputList option={option} />;
  }

  console.log(option);
  return (<div key={key}></div>);
};

export default OptionInput;
