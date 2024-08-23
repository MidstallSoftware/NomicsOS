import AuthRequired from '../widgets/AuthRequired.tsx'

const IndexPage = () =>
  (
    <AuthRequired>
      <p>Hello, world</p>
    </AuthRequired>
  );

export default IndexPage
