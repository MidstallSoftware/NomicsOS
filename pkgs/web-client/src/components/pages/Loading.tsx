const LoadingPage = () =>
  (
    <div className="flex justify-center pt-3">
      <div className="card bg-base-300 w-96 shadow-xl">
        <div className="card-body">
          <h2 className="card-title text-center">Page is loading</h2>
          <progress className="progress w-56"></progress>
        </div>
      </div>
    </div>
  );

export default LoadingPage
