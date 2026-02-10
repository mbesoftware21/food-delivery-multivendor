import { gql } from '@apollo/client';

export const OWNER_LOGIN = gql`
  mutation ownerLogin($email: String!, $password: String!) {
    ownerLogin(args: {email: $email, password: $password}) {
      userId
      token
      email
      userType
      permissions
      userTypeId
      image
      name
      isActive
    }
  }
`;
