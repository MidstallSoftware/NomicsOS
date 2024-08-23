import { createContext, ReactNode, useContext, useReducer } from 'react'

type AuthAction = {
  type: 'SIGN_IN'
} | {
  type: 'SIGN_OUT'
}

type AuthState = {
  state: 'SIGNED_IN'
} | {
  state: 'SIGNED_OUT'
} | {
  state: 'UNKNOWN'
}

const AuthReducer = (_: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case 'SIGN_IN':
      return {
        state: 'SIGNED_IN'
      };
    case 'SIGN_OUT':
      return {
        state: 'SIGNED_OUT'
      }
  }
};

type AuthContextProps = {
  state: AuthState
  dispatch: (value: AuthAction) => void
}

export const AuthContext = createContext<AuthContextProps>({
  state: {
    state: 'UNKNOWN'
  },
  dispatch: () => {},
});

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [state, dispatch] = useReducer(AuthReducer, { state: 'UNKNOWN' })

  return (
    <AuthContext.Provider value={{ state, dispatch }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuthState = () => {
  const { state } = useContext(AuthContext);
  return { auth: state };
};

export const useSignIn = () => {
  const {dispatch} = useContext(AuthContext)
  return {
    signIn: () => {
      dispatch({
        type: 'SIGN_IN'
      })
    }
  }
}

export const useSignOut = () => {
  const {dispatch} = useContext(AuthContext)
  return {
    signOut: () => {
      dispatch({type: "SIGN_OUT"})
    }
  }
}
