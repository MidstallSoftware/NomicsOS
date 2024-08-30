import { Option } from '../../types/options'

const OptionInput = ({ key, option }: { key: string, option: Option }) => {
  const type = option.type.split(';')[0];
  //const isNullable = (type.match(/^null or/g) ?? []).length > 0;
  const isString = (type.match(/string/g) ?? []).length > 0;
  const isBoolean = (type.match(/boolean/g) ?? []).length > 0;
  //const isUtf16 = (type.match(/16 bit unsigned integer/g) ?? []).length > 0;
  //const isList = (type.match(/^list of/g) ?? []).length > 0;

  if (isString) {
    return (
      <div className="card" key={key}>
        <div className="card-body">
          <label className="form-control w-full max-w-xs">
            <div className="label">
              <span className="label-text">{option.description}</span>
            </div>
            <input type="text" className="input input-bordered w-full max-w-xs" />
          </label>
        </div>
      </div>
    );
  }

  if (isBoolean) {
    return (
      <div className="card" key={key}>
        <div className="card-body">
          <div className="form-control">
            <label className="label cursor-pointer">
              <span className="label-text">{option.description}</span>
              <input type="checkbox" className="toggle" checked={option.default != null ? option.default.text == 'true' : false} />
            </label>
          </div>
        </div>
      </div>
    );
  }
  return (<div key={key}></div>);
};

export default OptionInput;
