// Components
import HeaderText from '@/lib/ui/useable-components/header-text';
import CustomButton from '@/lib/ui/useable-components/button';

// Hooks
import { useTranslations } from 'next-intl';

const OrdersSuperAdminHeader = ({ onNewOrder }: { onNewOrder: () => void }) => {
  // Hooks
  const t = useTranslations();

  return (
    <div className="sticky top-0 z-10 w-full flex-shrink-0 bg-white dark:bg-dark-950 p-3 shadow-sm">
      <div className="flex w-full justify-between items-center">
        <HeaderText text={t('Orders')} />
        <CustomButton
          label={t('New Order')}
          icon="pi pi-plus"
          onClick={onNewOrder}
          className="bg-primary text-white"
        />
      </div>
    </div>
  );
};

export default OrdersSuperAdminHeader;
