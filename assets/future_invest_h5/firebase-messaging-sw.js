/* eslint-disable no-undef */
/* eslint-disable no-restricted-globals */
/**
 * Firebase Cloud Messaging Service Worker
 * 处理后台推送通知
 */

// Firebase SDK 版本需要与项目中的版本一致
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js')
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js')

// Firebase 配置（需要与主应用保持一致）
const firebaseConfig = {
  apiKey: 'AIzaSyD09icCBkIcu6fLenAyTk4JHQTiaiWf3OA',
  authDomain: 'futren-a2d5e.firebaseapp.com',
  projectId: 'futren-a2d5e',
  storageBucket: 'futren-a2d5e.firebasestorage.app',
  messagingSenderId: '1084352260625',
  appId: '1:1084352260625:web:4ccb24888e9bda1b959fb0',
}

// 初始化 Firebase
firebase.initializeApp(firebaseConfig)

// 获取 Messaging 实例
const messaging = firebase.messaging()

// 子类型对应的通知标题和内容（后台通知使用）
const MESSAGE_CONFIG = {
  credited: {
    title: '🎁 体验金已到账',
    body: '免费体验真实交易，亏损由平台承担',
  },
  max_reward: {
    title: '💰 已获得最高现金奖励',
    body: '立即充值，将奖励划入真实账户',
  },
  exhausted: {
    title: '📊 体验金已用完，入金转战实盘',
    body: '现在入金继续交易，解锁真实收益',
  },
  expiring: {
    title: '⏰ 现金奖励即将失效',
    body: '体验金将在倒计时结束后收回，请尽快充值',
  },
}

/**
 * 解析 business_data 获取子类型
 */
function parseBusinessData(businessDataStr) {
  try {
    const data = JSON.parse(businessDataStr)
    return data.sub_type
  }
  catch {
    return null
  }
}

// 处理后台消息
messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {}
  const subType = parseBusinessData(data.business_data)
  const config = MESSAGE_CONFIG[subType]

  // 使用配置的标题和内容，或使用 payload 中的默认值
  const notificationTitle = config?.title || payload.notification?.title || '富腾汇'
  const notificationBody = config?.body || payload.notification?.body || '您有一条新消息'

  const notificationOptions = {
    body: notificationBody,
    icon: './pwa-192x192.png',
    badge: './pwa-192x192.png',
    tag: subType || 'default',
    data: {
      ...data,
      url: self.location.origin,
    },
    requireInteraction: true,
    vibrate: [200, 100, 200],
  }

  return self.registration.showNotification(notificationTitle, notificationOptions)
})

// 处理通知点击事件
self.addEventListener('notificationclick', (event) => {
  event.notification.close()

  const data = event.notification.data || {}
  const url = data.url || self.location.origin

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.startsWith(self.location.origin) && 'focus' in client) {
          client.postMessage({
            type: 'PUSH_NOTIFICATION_CLICK',
            data,
          })
          return client.focus()
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url)
      }
    }),
  )
})
