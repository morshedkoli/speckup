import { db } from './firebase';
import { collection, getDocs, deleteDoc, doc, query, orderBy, DocumentData } from 'firebase/firestore';

export async function fetchCollection<T>(collectionName: string, orderByField: string = 'createdAt'): Promise<T[]> {
  try {
    const q = query(collection(db, collectionName), orderBy(orderByField, 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      ...doc.data(),
      id: doc.id, // ensure ID is set from doc id if not present in data
    })) as T[];
  } catch (error) {
    console.error(`Error fetching collection ${collectionName}:`, error);
    throw error;
  }
}

export async function deleteDocument(collectionName: string, docId: string): Promise<void> {
  try {
    await deleteDoc(doc(db, collectionName, docId));
  } catch (error) {
    console.error(`Error deleting doc ${docId} from ${collectionName}:`, error);
    throw error;
  }
}
