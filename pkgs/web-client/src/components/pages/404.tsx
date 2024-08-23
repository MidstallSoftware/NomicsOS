const E404Page = () =>
  (
    <div className="flex justify-center pt-3">
      <div className="card bg-base-300 w-96 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">404 Page Not Found</h2>
          <p>The requested page could not be found.</p>
          <div className="card-actions justify-end">
            <a className="btn btn-primary" href="/">Return Home</a>
          </div>
        </div>
      </div>
    </div>
  );

export default E404Page
