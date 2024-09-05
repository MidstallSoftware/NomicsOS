import { ChangeEvent, useEffect, useState } from 'react'
import { useAuthState } from '../contexts/User'
import { Option, OptionDefault } from '../../types/options'
import { API_URI } from '../../config'

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
    const resp = await fetch(`${API_URI}/settings/set?key=${encodeURIComponent(key)}&value=${encodeURIComponent(e.target.value)}`, {
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
      },
    });

    const value = await resp.json();
    setValue(value ?? defaultValue);
  };

  return (
    <div className="card">
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
    fetch(`${API_URI}/settings/get`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ key }),
    }).then((resp) => resp.json())
      .then((value) => {
        setValue(value ?? defaultValue);
      });
  }, [ auth, defaultValue, key ]);

  const handleChange = async (e: ChangeEvent<HTMLInputElement>) => {
    const resp = await fetch(`${API_URI}/settings/set`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${'user' in auth ? auth.user.authKey : null}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        key,
        value: e.target.checked,
      }),
    });

    const value = await resp.json();
    setValue(value ?? defaultValue);
  };

  return (
    <div className="card">
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

const OptionInput = ({ key, option }: { key: string, option: Option }) => {
  const type = option.type.split(';')[0];
  //const isNullable = (type.match(/^null or/g) ?? []).length > 0;
  const isString = (type.match(/string/g) ?? []).length > 0;
  const isBoolean = (type.match(/boolean/g) ?? []).length > 0;
  //const isUtf16 = (type.match(/16 bit unsigned integer/g) ?? []).length > 0;
  //const isList = (type.match(/^list of/g) ?? []).length > 0;

  if (isString) {
    return <OptionInputString option={option} />;
  }

  if (isBoolean) {
    return <OptionInputBoolean option={option} />;
  }
  return (<div key={key}></div>);
};

export default OptionInput;
