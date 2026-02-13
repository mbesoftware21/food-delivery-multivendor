import { useState } from 'react';
import OrdersSuperAdminHeader from '@/lib/ui/screen-components/protected/super-admin/order/header/screen-header';
import OrderSuperAdminMain from '@/lib/ui/screen-components/protected/super-admin/order/main';

const OrderSuperAdminScreen = () => {
  const [isNewOrderModalVisible, setIsNewOrderModalVisible] = useState(false);

  return (
    <div className="screen-container">
      <OrdersSuperAdminHeader onNewOrder={() => setIsNewOrderModalVisible(true)} />
      <OrderSuperAdminMain
        isNewOrderModalVisible={isNewOrderModalVisible}
        onNewOrderModalHide={() => setIsNewOrderModalVisible(false)}
      />
    </div>
  );
};

export default OrderSuperAdminScreen;
