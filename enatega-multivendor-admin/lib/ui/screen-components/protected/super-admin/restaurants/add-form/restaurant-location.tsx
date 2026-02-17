'use client';

// Core
import { Form, Formik } from 'formik';
import { useContext, useState } from 'react';
import { useMutation } from '@apollo/client';

// Interface and Types
import {
  IRestaurantsRestaurantLocationComponentProps,
  IVendorForm,
  IUpdateRestaurantDeliveryZoneVariables,
} from '@/lib/utils/interfaces';

// Context
import { RestaurantsContext } from '@/lib/context/super-admin/restaurants.context';
import { ToastContext } from '@/lib/context/global/toast.context';

// API and GraphQL
import { UPDATE_DELIVERY_BOUNDS_AND_LOCATION } from '@/lib/api/graphql';

// Custom Components
import CustomTextField from '@/lib/ui/useable-components/input-field';
import CustomNumberField from '@/lib/ui/useable-components/number-input-field';
import CustomButton from '@/lib/ui/useable-components/button';
import { useTranslations } from 'next-intl';

const initialValues: IVendorForm = {
  name: '',
  email: '',
  password: '',
  confirmPassword: '',
};

export default function RestaurantLocation({
  stepperProps,
}: IRestaurantsRestaurantLocationComponentProps) {
  const t = useTranslations();
  const { onStepChange, order } = stepperProps ?? {
    onStepChange: () => { },
    order: 0,
  };

  // Contexts
  const { restaurantsContextData } = useContext(RestaurantsContext);
  const { showToast } = useContext(ToastContext);

  // States
  const [address, setAddress] = useState(restaurantsContextData?.restaurant?.autoCompleteAddress || '');
  const [lat, setLat] = useState<number>(0);
  const [lng, setLng] = useState<number>(0);
  const [radius, setRadius] = useState<number>(1);

  // API
  const [updateRestaurantDeliveryZone, { loading }] = useMutation(
    UPDATE_DELIVERY_BOUNDS_AND_LOCATION,
    {
      onCompleted: () => {
        showToast({
          type: 'success',
          title: t('Location & Zone'),
          message: t('Store Location & Zone has been updated successfully'),
        });
        if (onStepChange) onStepChange(order + 1);
      },
      onError: (error) => {
        showToast({
          type: 'error',
          title: t('Location & Zone'),
          message: error.message || t('Store Location & Zone update failed'),
        });
      },
    }
  );

  const handleSubmit = async () => {
    if (!restaurantsContextData?.restaurant?._id?.code) {
      showToast({
        type: 'error',
        title: t('Location & Zone'),
        message: t('No restaurant is selected'),
      });
      return;
    }

    // Generate hexagonal polygon points based on center and radius (mocked bounds)
    const points = 6;
    const polygon = [];
    for (let i = 0; i < points; i++) {
      const angle = (i * 2 * Math.PI) / points;
      const pLat = lat + (radius / 111.32) * Math.cos(angle);
      const pLng = lng + (radius / (111.32 * Math.cos((lat * Math.PI) / 180))) * Math.sin(angle);
      polygon.push([pLng, pLat]);
    }
    polygon.push(polygon[0]);

    const variables: IUpdateRestaurantDeliveryZoneVariables = {
      id: restaurantsContextData.restaurant._id.code,
      location: { latitude: lat, longitude: lng },
      boundType: 'radius',
      address: address,
      bounds: [polygon],
      circleBounds: {
        radius: radius,
      },
    };

    console.log('DEBUG: updateRestaurantDeliveryZone variables:', JSON.stringify(variables, null, 2));

    await updateRestaurantDeliveryZone({ variables });
  };

  return (
    <div className="flex h-full w-full items-center justify-start dark:text-white dark:bg-dark-950 p-4" >
      <div className="h-full w-full space-y-6">
        <h3 className="text-xl font-semibold mb-4">{t('Store Location (Mocked)')}</h3>

        <div className="grid grid-cols-1 gap-4">
          <CustomTextField
            label={t('Address')}
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder={t('Enter address manually')}
          />

          <div className="grid grid-cols-2 gap-4">
            <CustomNumberField
              label={t('Latitude')}
              value={lat}
              onChange={(_, val) => setLat(val as number || 0)}
              minFractionDigits={6}
            />
            <CustomNumberField
              label={t('Longitude')}
              value={lng}
              onChange={(_, val) => setLng(val as number || 0)}
              minFractionDigits={6}
            />
          </div>

          <CustomNumberField
            label={`${t('Delivery Radius')} (km)`}
            value={radius}
            onChange={(_, val) => setRadius(val as number || 1)}
            min={0.1}
            max={50}
            step={0.5}
          />
        </div>

        <div className="flex justify-between mt-8">
          <CustomButton
            className="h-10 w-fit border border-gray-300 dark:hover:bg-dark-600 dark:border-dark-600 bg-black px-8 text-white"
            label={t('Back')}
            onClick={() => onStepChange(order - 1)}
          />

          <CustomButton
            className="h-10 w-fit border border-gray-300 dark:hover:bg-dark-600 dark:border-dark-600 bg-black px-8 text-white"
            label={t('Save & Next')}
            loading={loading}
            onClick={handleSubmit}
          />
        </div>
      </div>
    </div>
  );
}
