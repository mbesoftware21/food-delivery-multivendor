'use client';

import React, { useState, useContext, useMemo } from 'react';
import { Dialog } from 'primereact/dialog';
import { useQueryGQL } from '@/lib/hooks/useQueryQL';
import { useMutation } from '@apollo/client';
import { GET_USERS, GET_RESTAURANTS_DROPDOWN, GET_FOODS_BY_RESTAURANT_ID } from '@/lib/api/graphql';
import { PLACE_MANUAL_ORDER } from '@/lib/api/graphql/mutations/order';
import CustomDropdown from '../custom-dropdown';
import CustomButton from '../button';
import { useTranslations } from 'next-intl';
import { ToastContext } from '@/lib/context/global/toast.context';
import { IQueryResult, IItem } from '@/lib/utils/interfaces';

interface NewOrderModalProps {
    visible: boolean;
    onHide: () => void;
}

interface CartItem {
    food_id: string;
    title: string;
    quantity: number;
    unit_price: number;
    total_price: number;
    variation_id: string;
    variation_title: string;
}

export default function NewOrderModal({ visible, onHide }: NewOrderModalProps) {
    const t = useTranslations();
    const { showToast } = useContext(ToastContext);

    // Form States
    const [selectedUser, setSelectedUser] = useState<any>(null);
    const [selectedRestaurantId, setSelectedRestaurantId] = useState<string | null>(null);
    const [cart, setCart] = useState<CartItem[]>([]);
    const [selectedAddress, setSelectedAddress] = useState<any>(null);

    // Queries
    const { data: usersData, loading: usersLoading } = useQueryGQL(GET_USERS, {}, { enabled: visible });
    const { data: restaurantsData, loading: restaurantsLoading } = useQueryGQL(GET_RESTAURANTS_DROPDOWN, {}, { enabled: visible });
    const { data: foodData, loading: foodsLoading } = useQueryGQL(
        GET_FOODS_BY_RESTAURANT_ID,
        { id: selectedRestaurantId },
        { enabled: !!selectedRestaurantId }
    );

    // Mutation
    const [placeOrderMutation, { loading: isPlacing }] = useMutation(PLACE_MANUAL_ORDER, {
        onCompleted: () => {
            showToast({
                type: 'success',
                title: t('Order Created'),
                message: t('Manual order placed successfully (Hasura Synced)'),
            });
            onHide();
            setCart([]);
            setSelectedUser(null);
            setSelectedRestaurantId(null);
        },
        onError: (error) => {
            showToast({
                type: 'error',
                title: t('Error'),
                message: error.message,
            });
        },
    });

    // Mappings for Dropdowns
    const userOptions = useMemo(() =>
        (usersData as any)?.users?.map((u: any) => ({ label: `${u.name} (${u.phone || u.email})`, value: u })) || [],
        [usersData]
    );

    const restaurantOptions = useMemo(() =>
        (restaurantsData as any)?.restaurants?.map((r: any) => ({ label: r.name, value: r._id })) || [],
        [restaurantsData]
    );

    const addressOptions = useMemo(() =>
        selectedUser?.addresses?.map((a: any) => ({ label: a.deliveryAddress, value: a })) || [],
        [selectedUser]
    );

    // Handlers
    const addToCart = (food: any) => {
        const variation = food.variations[0]; // Simplification for MVP: take first variation
        const existingIndex = cart.findIndex(item => item.food_id === food._id && item.variation_id === variation._id);

        if (existingIndex > -1) {
            const newCart = [...cart];
            newCart[existingIndex].quantity += 1;
            newCart[existingIndex].total_price = newCart[existingIndex].quantity * newCart[existingIndex].unit_price;
            setCart(newCart);
        } else {
            setCart([...cart, {
                food_id: food._id,
                title: food.title,
                quantity: 1,
                unit_price: variation.price,
                total_price: variation.price,
                variation_id: variation._id,
                variation_title: variation.title
            }]);
        }
    };

    const removeFromCart = (index: number) => {
        const newCart = [...cart];
        if (newCart[index].quantity > 1) {
            newCart[index].quantity -= 1;
            newCart[index].total_price = newCart[index].quantity * newCart[index].unit_price;
            setCart(newCart);
        } else {
            newCart.splice(index, 1);
            setCart(newCart);
        }
    };

    const subtotal = useMemo(() => cart.reduce((acc, item) => acc + item.total_price, 0), [cart]);

    const handlePlaceOrder = () => {
        if (!selectedUser || !selectedRestaurantId || cart.length === 0 || !selectedAddress) {
            showToast({ type: 'error', title: t('Error'), message: t('Please fill all required fields') });
            return;
        }

        const orderInput = cart.map(item => ({
            food_id: item.food_id,
            title: item.title,
            quantity: item.quantity,
            unit_price: item.unit_price,
            total_price: item.total_price,
            addons: [] // MVP: No addons for manual creation yet
        }));

        placeOrderMutation({
            variables: {
                arg_user_id: selectedUser._id,
                arg_restaurant_id: selectedRestaurantId,
                arg_items: orderInput,
                arg_delivery_address: {
                    deliveryAddress: selectedAddress.deliveryAddress,
                    details: selectedAddress.details || '',
                    location: selectedAddress.location
                },
                arg_payment_method: 'CASH',
                arg_delivery_charges: 0,
                arg_tax_amount: 0,
                arg_total_amount: subtotal,
                arg_order_amount: subtotal,
                arg_special_instructions: ''
            }
        });
    };

    return (
        <Dialog
            visible={visible}
            onHide={onHide}
            header={t('New Manual Order')}
            style={{ width: '60vw' }}
            className="dark:bg-dark-950 dark:text-white"
        >
            <div className="flex flex-col gap-4 p-2">
                {/* Step 1: User & Restaurant */}
                <div className="grid grid-cols-2 gap-4">
                    <CustomDropdown
                        name="customer"
                        placeholder={t('Select Customer')}
                        options={userOptions}
                        selectedItem={selectedUser}
                        setSelectedItem={(_, val) => {
                            setSelectedUser(val);
                            setSelectedAddress((val as any)?.addresses?.[0] || null);
                        }}
                        isLoading={usersLoading}
                        showLabel
                    />
                    <CustomDropdown
                        name="restaurant"
                        placeholder={t('Select Restaurant')}
                        options={restaurantOptions}
                        selectedItem={selectedRestaurantId as any}
                        setSelectedItem={(_, val) => {
                            if ((val as any) !== selectedRestaurantId) setCart([]);
                            setSelectedRestaurantId(val as any);
                        }}
                        isLoading={restaurantsLoading}
                        showLabel
                    />
                </div>

                {selectedUser && (
                    <CustomDropdown
                        name="address"
                        placeholder={t('Select Delivery Address')}
                        options={addressOptions}
                        selectedItem={selectedAddress}
                        setSelectedItem={(_, val) => setSelectedAddress(val)}
                        showLabel
                    />
                )}

                {/* Step 2: Catalog browser */}
                {selectedRestaurantId && (
                    <div className="border rounded p-3 dark:border-dark-700">
                        <h3 className="font-bold mb-2">{t('Menu Catalog')}</h3>
                        <div className="max-h-60 overflow-y-auto grid grid-cols-2 gap-2">
                            {(foodData as any)?.restaurant?.categories?.map((cat: any) => (
                                cat.foods.map((food: any) => (
                                    <div key={food._id} className="flex justify-between items-center p-2 border rounded dark:border-dark-800">
                                        <div>
                                            <div className="font-semibold text-sm">{food.title}</div>
                                            <div className="text-xs text-gray-500">${food.variations[0]?.price}</div>
                                        </div>
                                        <CustomButton
                                            label=""
                                            icon="pi pi-plus"
                                            className="p-button-sm p-button-outlined"
                                            onClick={() => addToCart(food)}
                                        />
                                    </div>
                                ))
                            ))}
                            {foodsLoading && <p>{t('Loading foods...')}</p>}
                        </div>
                    </div>
                )}

                {/* Step 3: Cart Summary */}
                {cart.length > 0 && (
                    <div className="border rounded p-3 bg-gray-50 dark:bg-dark-900 dark:border-dark-700">
                        <h3 className="font-bold mb-2">{t('Order Summary')}</h3>
                        <div className="max-h-40 overflow-y-auto">
                            {cart.map((item, index) => (
                                <div key={index} className="flex justify-between text-sm py-1 border-b dark:border-dark-800">
                                    <span>{item.quantity}x {item.title}</span>
                                    <div className="flex items-center gap-2">
                                        <span>${item.total_price.toFixed(2)}</span>
                                        <button onClick={() => removeFromCart(index)} className="text-red-500">
                                            <i className="pi pi-minus-circle"></i>
                                        </button>
                                    </div>
                                </div>
                            ))}
                        </div>
                        <div className="flex justify-between font-bold mt-2 pt-2 border-t dark:border-dark-700 text-lg">
                            <span>Total</span>
                            <span>${subtotal.toFixed(2)}</span>
                        </div>
                    </div>
                )}

                <div className="flex justify-end gap-2 mt-4">
                    <CustomButton label={t('Cancel')} onClick={onHide} className="p-button-text" />
                    <CustomButton
                        label={t('Place Order')}
                        onClick={handlePlaceOrder}
                        loading={isPlacing}
                        disabled={cart.length === 0}
                        className="bg-primary text-white"
                    />
                </div>
            </div>
        </Dialog>
    );
}
