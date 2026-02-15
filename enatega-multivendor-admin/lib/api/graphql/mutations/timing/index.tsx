import { gql } from '@apollo/client';

export const UPDATE_TIMINGS = gql`
  mutation UpdateTimings($restaurantInput: RestaurantInputCustom!) {
    updateTimings: editStore(restaurant: $restaurantInput) {
      success
      message
    }
  }
`;
