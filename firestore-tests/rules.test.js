// Security rule tests for firestore.rules, run against the Firestore emulator:
//   cd firestore-tests && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  setLogLevel,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

before(async () => {
  // Denied writes are expected here; keep the SDK from logging each one.
  setLogLevel('silent');
  env = await initializeTestEnvironment({
    projectId: 'demo-tokoku',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());

// Every test starts from the same data, written with rules turned off.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/alice'), { email: 'alice@example.com', displayName: 'Alice', role: 'customer' });
    await setDoc(doc(db, 'users/bob'), { email: 'bob@example.com', displayName: 'Bob', role: 'customer' });
    await setDoc(doc(db, 'users/admin'), { email: 'admin@example.com', displayName: 'Admin', role: 'admin' });
    await setDoc(doc(db, 'categories/beauty'), { slug: 'beauty', name: 'Beauty' });
    await setDoc(doc(db, 'products/p1'), {
      title: 'Lipstick',
      price: 10,
      stock: 5,
      rating: 4,
      reviews: [{ rating: 4 }, { rating: 4 }],
    });
    await setDoc(doc(db, 'orders/alicePending'), order('alice', 'pending'));
    await setDoc(doc(db, 'orders/aliceProcessing'), order('alice', 'processing'));
    await setDoc(doc(db, 'orders/aliceDelivered'), order('alice', 'delivered'));
    await setDoc(doc(db, 'orders/bobPending'), order('bob', 'pending'));
    await setDoc(doc(db, 'orders/bobDelivered'), order('bob', 'delivered'));
  });
});

function order(userId, status) {
  return { userId, status, items: [{ productId: 'p1', quantity: 2 }], total: 20 };
}

const guest = () => env.unauthenticatedContext().firestore();
const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const admin = () => env.authenticatedContext('admin').firestore();

describe('users', () => {
  test('a new user can create their own customer profile', async () => {
    await assertSucceeds(
      setDoc(doc(env.authenticatedContext('carol').firestore(), 'users/carol'), { displayName: 'Carol', role: 'customer' }),
    );
  });

  test('nobody can sign themselves up as an admin', async () => {
    await assertFails(
      setDoc(doc(env.authenticatedContext('carol').firestore(), 'users/carol'), { displayName: 'Carol', role: 'admin' }),
    );
  });

  test('users can read their own profile but not someone else’s', async () => {
    await assertSucceeds(getDoc(doc(alice(), 'users/alice')));
    await assertFails(getDoc(doc(alice(), 'users/bob')));
    await assertFails(getDoc(doc(guest(), 'users/alice')));
  });

  test('admins can read any profile', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'users/alice')));
  });

  test('users can edit their profile but not their role', async () => {
    await assertSucceeds(updateDoc(doc(alice(), 'users/alice'), { displayName: 'Alice B.' }));
    await assertFails(updateDoc(doc(alice(), 'users/alice'), { role: 'admin' }));
  });

  test('admins cannot change roles either, since the demo admin is public', async () => {
    await assertFails(updateDoc(doc(admin(), 'users/alice'), { role: 'admin' }));
    await assertFails(updateDoc(doc(admin(), 'users/admin'), { role: 'customer' }));
  });

  test('profiles cannot be deleted from the app', async () => {
    await assertFails(deleteDoc(doc(admin(), 'users/alice')));
  });
});

describe('private subcollections: cart, addresses and wishlist', () => {
  for (const collection of ['cartItems', 'addresses', 'wishlist']) {
    test(`${collection} belong to their owner only`, async () => {
      await assertSucceeds(setDoc(doc(alice(), `users/alice/${collection}/x`), { value: 1 }));
      await assertSucceeds(getDoc(doc(alice(), `users/alice/${collection}/x`)));
      await assertFails(getDoc(doc(bob(), `users/alice/${collection}/x`)));
      await assertFails(setDoc(doc(bob(), `users/alice/${collection}/y`), { value: 1 }));
      await assertFails(getDoc(doc(admin(), `users/alice/${collection}/x`)));
    });
  }
});

describe('catalog', () => {
  test('guests can browse products and categories', async () => {
    await assertSucceeds(getDoc(doc(guest(), 'products/p1')));
    await assertSucceeds(getDoc(doc(guest(), 'categories/beauty')));
  });

  test('only admins can add, edit or delete products and categories', async () => {
    await assertFails(setDoc(doc(alice(), 'products/p2'), { title: 'Fake', price: 1, stock: 1 }));
    await assertFails(updateDoc(doc(alice(), 'products/p1'), { price: 1 }));
    await assertFails(deleteDoc(doc(alice(), 'products/p1')));
    await assertFails(setDoc(doc(alice(), 'categories/toys'), { name: 'Toys' }));

    await assertSucceeds(setDoc(doc(admin(), 'products/p2'), { title: 'New', price: 5, stock: 3 }));
    await assertSucceeds(updateDoc(doc(admin(), 'products/p1'), { price: 12 }));
    await assertSucceeds(setDoc(doc(admin(), 'categories/toys'), { name: 'Toys' }));
    await assertSucceeds(deleteDoc(doc(admin(), 'products/p2')));
  });

  test('checkout can lower the stock, but never below zero or alongside other changes', async () => {
    await assertSucceeds(updateDoc(doc(alice(), 'products/p1'), { stock: 3 }));
    await assertFails(updateDoc(doc(alice(), 'products/p1'), { stock: -1 }));
    await assertFails(updateDoc(doc(alice(), 'products/p1'), { stock: 2, price: 1 }));
    await assertFails(updateDoc(doc(guest(), 'products/p1'), { stock: 2 }));
  });

  test('customers cannot raise the stock on their own', async () => {
    await assertFails(updateDoc(doc(alice(), 'products/p1'), { stock: 50 }));
    await assertFails(updateDoc(doc(alice(), 'products/p1'), { stock: 50, restockedByOrder: 'alicePending' }));
  });
});

describe('orders', () => {
  const newOrder = (userId, status = 'pending') => ({ userId, status, items: [{ productId: 'p1', quantity: 1 }] });

  test('signed-in customers can place their own pending orders', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'orders/new'), newOrder('alice')));
  });

  test('orders cannot be placed by guests, for someone else, already delivered or empty', async () => {
    await assertFails(setDoc(doc(guest(), 'orders/new'), newOrder('alice')));
    await assertFails(setDoc(doc(alice(), 'orders/new'), newOrder('bob')));
    await assertFails(setDoc(doc(alice(), 'orders/new'), newOrder('alice', 'delivered')));
    await assertFails(setDoc(doc(alice(), 'orders/new'), { userId: 'alice', status: 'pending', items: [] }));
  });

  test('customers see only their own orders; admins see all', async () => {
    await assertSucceeds(getDoc(doc(alice(), 'orders/alicePending')));
    await assertFails(getDoc(doc(alice(), 'orders/bobPending')));
    await assertFails(getDoc(doc(guest(), 'orders/alicePending')));
    await assertSucceeds(getDoc(doc(admin(), 'orders/bobPending')));
  });

  test('admins move orders through the status flow', async () => {
    await assertSucceeds(updateDoc(doc(admin(), 'orders/alicePending'), { status: 'processing' }));
  });

  test('customers cannot change their order status', async () => {
    await assertFails(updateDoc(doc(alice(), 'orders/alicePending'), { status: 'delivered' }));
    await assertFails(updateDoc(doc(alice(), 'orders/alicePending'), { total: 0 }));
  });

  test('orders cannot be deleted', async () => {
    await assertFails(deleteDoc(doc(admin(), 'orders/alicePending')));
  });
});

describe('customer cancellation', () => {
  // Mirrors OrderRepository.cancel for a customer.
  function cancelWithRestock(db, orderId, { restock = 2, cancelledBy = 'customer', status = 'cancelled' } = {}) {
    const batch = writeBatch(db);
    batch.update(doc(db, `orders/${orderId}`), {
      status,
      'statusUpdatedAt.cancelled': serverTimestamp(),
      cancelledBy,
      updatedAt: serverTimestamp(),
    });
    batch.update(doc(db, 'products/p1'), { stock: increment(restock), restockedByOrder: orderId });
    return batch.commit();
  }

  test('customers can cancel their own pending order and restock its items', async () => {
    await assertSucceeds(cancelWithRestock(alice(), 'alicePending'));
  });

  test('customers cannot cancel an order the store is already processing', async () => {
    await assertFails(cancelWithRestock(alice(), 'aliceProcessing'));
  });

  test('customers cannot cancel someone else’s order', async () => {
    await assertFails(cancelWithRestock(alice(), 'bobPending'));
  });

  test('cancelling must record the customer as the canceller', async () => {
    await assertFails(cancelWithRestock(alice(), 'alicePending', { cancelledBy: 'admin' }));
  });

  test('restocking needs the order to actually be cancelled in the same write', async () => {
    await assertFails(cancelWithRestock(alice(), 'alicePending', { status: 'pending' }));
  });

  test('cancelling cannot touch other order fields', async () => {
    await assertFails(
      updateDoc(doc(alice(), 'orders/alicePending'), { status: 'cancelled', cancelledBy: 'customer', total: 0 }),
    );
  });
});

describe('reviews', () => {
  // Mirrors ReviewRepository.submit: the review and the new average in one write.
  function postReview(db, uid, { orderId = 'aliceDelivered', rating = 5, reviewCount = 3, average = 4.33 } = {}) {
    const batch = writeBatch(db);
    batch.set(doc(db, `products/p1/reviews/${uid}`), {
      rating,
      comment: 'Great',
      reviewerName: 'Alice',
      orderId,
      createdAt: serverTimestamp(),
    });
    batch.update(doc(db, 'products/p1'), { rating: average, reviewCount });
    return batch.commit();
  }

  test('anyone can read reviews', async () => {
    await assertSucceeds(getDoc(doc(guest(), 'products/p1/reviews/alice')));
  });

  test('customers can review a product from their delivered order', async () => {
    await assertSucceeds(postReview(alice(), 'alice'));
  });

  test('reviews need a delivered order of the reviewer', async () => {
    await assertFails(postReview(alice(), 'alice', { orderId: 'alicePending' }));
    await assertFails(postReview(alice(), 'alice', { orderId: 'bobDelivered' }));
  });

  test('customers cannot review on someone else’s behalf', async () => {
    await assertFails(postReview(alice(), 'bob'));
  });

  test('ratings must be whole numbers from 1 to 5', async () => {
    await assertFails(postReview(alice(), 'alice', { rating: 6 }));
    await assertFails(postReview(alice(), 'alice', { rating: 0 }));
  });

  test('the average rating stays between 1 and 5 and the count goes up by exactly one', async () => {
    await assertFails(postReview(alice(), 'alice', { average: 9 }));
    await assertFails(postReview(alice(), 'alice', { reviewCount: 10 }));
  });

  test('reviews are final, and one per customer per product', async () => {
    await assertSucceeds(postReview(alice(), 'alice'));
    await assertFails(updateDoc(doc(alice(), 'products/p1/reviews/alice'), { rating: 1 }));
    await assertFails(postReview(alice(), 'alice', { reviewCount: 4 }));
  });

  test('the rating cannot be changed without posting a review', async () => {
    await assertFails(updateDoc(doc(alice(), 'products/p1'), { rating: 5, reviewCount: 3 }));
  });
});

describe('images', () => {
  const image = (ownerId, size = 1000) => ({ ownerId, contentType: 'image/jpeg', data: 'a'.repeat(size) });

  test('anyone can view images, so guests see product photos', async () => {
    await env.withSecurityRulesDisabled((context) => setDoc(doc(context.firestore(), 'images/i1'), image('admin')));
    await assertSucceeds(getDoc(doc(guest(), 'images/i1')));
  });

  test('signed-in users can upload images they own, under the size limit', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'images/i2'), image('alice')));
    await assertFails(setDoc(doc(alice(), 'images/i3'), image('bob')));
    await assertFails(setDoc(doc(guest(), 'images/i4'), image('alice')));
    await assertFails(setDoc(doc(alice(), 'images/i5'), image('alice', 900000)));
  });

  test('images cannot be edited, and only the owner or an admin can delete them', async () => {
    await env.withSecurityRulesDisabled((context) => setDoc(doc(context.firestore(), 'images/i1'), image('alice')));
    await assertFails(updateDoc(doc(alice(), 'images/i1'), { data: 'b' }));
    await assertFails(deleteDoc(doc(bob(), 'images/i1')));
    await assertSucceeds(deleteDoc(doc(admin(), 'images/i1')));
  });
});
