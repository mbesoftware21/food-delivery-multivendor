import { gql } from '@apollo/client';

export const PLACE_MANUAL_ORDER = gql`
  mutation PlaceManualOrder(
    $arg_user_id: uuid!
    $arg_restaurant_id: uuid!
    $arg_items: jsonb!
    $arg_delivery_address: jsonb!
    $arg_payment_method: String!
    $arg_delivery_charges: numeric!
    $arg_tax_amount: numeric!
    $arg_total_amount: numeric!
    $arg_order_amount: numeric!
    $arg_special_instructions: String
  ) {
    place_manual_order(
      args: {
        arg_user_id: $arg_user_id
        arg_restaurant_id: $arg_restaurant_id
        arg_items: $arg_items
        arg_delivery_address: $arg_delivery_address
        arg_payment_method: $arg_payment_method
        arg_delivery_charges: $arg_delivery_charges
        arg_tax_amount: $arg_tax_amount
        arg_total_amount: $arg_total_amount
        arg_order_amount: $arg_order_amount
        arg_special_instructions: $arg_special_instructions
      }
    ) {
      _id
      order_id
      status
    }
  }
`;
