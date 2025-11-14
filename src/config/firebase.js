import { initializeApp } from "firebase/app";
import { getMessaging, getToken, onMessage } from "firebase/messaging";


const firebaseConfig = {
  apiKey: "AIzaSyBK3kuHma1itO0XGdh5Lovi-Rd4bzQuB-I",
  authDomain: "meup-bf64f.firebaseapp.com",
  projectId: "meup-bf64f",
  storageBucket: "meup-bf64f.firebasestorage.app",
  messagingSenderId: "116378588635",
  appId: "1:116378588635:web:26c74d2a4afadbdcde43fe",
  measurementId: "G-6M4RHT2EPJ"
};

// Khởi tạo app & messaging
const app = initializeApp(firebaseConfig);
export const messaging = getMessaging(app);

// Hàm lấy token
export const getFcmToken = async () => {
  try {
    const permission = await Notification.requestPermission();
    
    if (permission !== "granted") {
      console.warn("Notification permission denied");
      return null;
    }

    const token = await getToken(messaging, {
      vapidKey: "BCzIZ6MjDLIozYtspgUElR1bDseK-RT3o27cVbgE09O3y8yOPcqSNOAIQIFdtlohppCxdAFgbrkEF1H2eqiwE0k",
    });

    console.log("FCM Token:", token);
    return token;
  } catch (err) {
    console.error("Error getting FCM token:", err);
    return null;
  }
};

// Lắng nghe khi đang mở tab
onMessage(messaging, (payload) => {
  console.log("Message received:", payload);
});