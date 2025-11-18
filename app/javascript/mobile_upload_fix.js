// 移动端上传兼容性修复
// 专门处理移动端浏览器的上传问题

(function() {
  'use strict';
  
  console.log('🚀 移动端上传兼容性修复已加载');
  
  // 移动端检测
  function isMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
           window.innerWidth <= 768;
  }
  
  // 网络状态检测
  function checkNetworkStatus() {
    if ('connection' in navigator) {
      const connection = navigator.connection;
      console.log('📡 网络状态检测:', {
        effectiveType: connection.effectiveType,
        downlink: connection.downlink,
        rtt: connection.rtt,
        saveData: connection.saveData
      });
      
      // 网络状态指示
      const networkStatus = document.createElement('div');
      networkStatus.className = 'network-status';
      networkStatus.id = 'network-status';
      
      let statusText = '';
      let statusClass = '';
      
      if (connection.effectiveType === '2g' || connection.saveData) {
        statusText = '慢网络';
        statusClass = 'slow';
      } else if (connection.effectiveType === '3g') {
        statusText = '3G网络';
      } else if (connection.effectiveType === '4g') {
        statusText = '4G网络';
      } else {
        statusText = 'WiFi';
      }
      
      if (statusClass) {
        networkStatus.classList.add(statusClass);
      }
      networkStatus.textContent = statusText;
      document.body.appendChild(networkStatus);
      
      // 显示网络状态
      setTimeout(() => {
        networkStatus.classList.add('show');
      }, 100);
      
      // 慢网络警告
      if (connection.effectiveType === '2g' || connection.saveData) {
        console.warn('⚠️ 检测到慢网络环境');
        if (window.showToast) {
          showToast('检测到慢网络，大文件上传可能需要更长时间', 'info', 5000);
        }
      }
    }
  }
  
  // 文件输入增强
  function enhanceFileInput() {
    const fileInput = document.getElementById('upload-file');
    if (!fileInput) {
      console.warn('文件输入元素未找到');
      return;
    }
    
    console.log('📁 文件输入增强已应用');
    
    // 移动端特殊配置
    if (isMobileDevice()) {
      console.log('📱 检测到移动设备，应用特殊配置');
      
      // 优化文件选择器
      fileInput.accept = '.pdf,application/pdf';
      fileInput.setAttribute('capture', 'environment'); // 优先使用相机扫描文档
      
      // 触摸目标大小优化
      fileInput.style.minHeight = '44px';
      fileInput.style.fontSize = '16px'; // 防止iOS自动缩放
      
      console.log('移动端文件输入配置:', {
        accept: fileInput.accept,
        capture: fileInput.getAttribute('capture'),
        minHeight: fileInput.style.minHeight,
        fontSize: fileInput.style.fontSize
      });
    }
    
    // 文件选择事件增强
    fileInput.addEventListener('change', function(e) {
      console.log('📄 文件选择事件触发:', e.target.files.length, '个文件');
      
      const file = e.target.files[0];
      if (!file) {
        console.log('未选择文件');
        return;
      }
      
      console.log('选择的文件详情:', {
        name: file.name,
        type: file.type,
        size: file.size,
        lastModified: new Date(file.lastModified).toLocaleString()
      });
      
      // 移动端特殊验证
      if (isMobileDevice()) {
        console.log('🔍 应用移动端文件验证');
        
        // 文件类型验证（移动端可能返回不同的MIME类型）
        const isPDF = file.type === 'application/pdf' || 
                     file.name.toLowerCase().endsWith('.pdf') ||
                     file.name.toLowerCase().endsWith('.PDF');
        
        if (!isPDF) {
          console.error('❌ 移动端文件类型验证失败:', {
            fileType: file.type,
            fileName: file.name,
            isPDF: isPDF
          });
          
          if (window.showToast) {
            showToast('请选择PDF格式的文件', 'error');
          }
          e.target.value = '';
          return;
        }
        
        // 文件大小验证
        const maxSize = 500 * 1024 * 1024; // 500MB
        if (file.size > maxSize) {
          console.error('❌ 移动端文件大小超限:', file.size, '>', maxSize);
          const sizeMB = (file.size / 1024 / 1024).toFixed(2);
          
          if (window.showToast) {
            showToast(`文件大小超过限制（最大500MB），当前：${sizeMB}MB`, 'error');
          }
          e.target.value = '';
          return;
        }
        
        console.log('✅ 移动端文件验证通过');
      }
    });
    
    // 触摸事件优化
    fileInput.addEventListener('touchstart', function(e) {
      console.log('👆 文件输入触摸开始');
      this.style.transform = 'scale(0.98)';
    });
    
    fileInput.addEventListener('touchend', function(e) {
      console.log('👆 文件输入触摸结束');
      this.style.transform = 'scale(1)';
    });
  }
  
  // XMLHttpRequest增强
  function enhanceXMLHttpRequest() {
    console.log('🔧 XMLHttpRequest增强已应用');
    
    // 保存原始的XMLHttpRequest
    const OriginalXMLHttpRequest = window.XMLHttpRequest;
    
    // 增强的XMLHttpRequest构造函数
    function EnhancedXMLHttpRequest() {
      const xhr = new OriginalXMLHttpRequest();
      
      // 保存原始方法
      const originalOpen = xhr.open;
      const originalSetRequestHeader = xhr.setRequestHeader;
      const originalSend = xhr.send;
      
      // 增强open方法
      xhr.open = function(method, url, async, user, password) {
        console.log('📡 XMLHttpRequest.open:', method, url);
        
        // 移动端特殊处理
        if (isMobileDevice() && method.toLowerCase() === 'post' && url.includes('upload')) {
          console.log('🎯 检测到移动端上传请求');
          
          // 确保异步
          if (async === undefined) async = true;
          
          // 设置更长的超时时间
          this.timeout = 300000; // 5分钟
          
          console.log('移动端上传请求配置:', {
            method: method,
            url: url,
            async: async,
            timeout: this.timeout
          });
        }
        
        return originalOpen.call(this, method, url, async, user, password);
      };
      
      // 增强setRequestHeader方法
      xhr.setRequestHeader = function(header, value) {
        console.log('📋 XMLHttpRequest.setRequestHeader:', header, value ? value.substring(0, 20) + '...' : value);
        
        // 移动端上传特殊头信息
        if (isMobileDevice() && this._url && this._url.includes('upload')) {
          if (header.toLowerCase() === 'accept') {
            // 确保接受JSON响应
            if (!value.includes('application/json')) {
              value = 'application/json, text/javascript, */*; q=0.01';
            }
          }
          
          if (header.toLowerCase() === 'x-requested-with') {
            value = 'XMLHttpRequest';
          }
        }
        
        return originalSetRequestHeader.call(this, header, value);
      };
      
      // 增强send方法
      xhr.send = function(data) {
        console.log('📤 XMLHttpRequest.send:', data ? (data instanceof FormData ? 'FormData' : typeof data) : 'null');
        
        if (isMobileDevice() && this._url && this._url.includes('upload')) {
          console.log('🚀 发送移动端上传请求');
          
          // 增强错误处理
          this.addEventListener('error', function(e) {
            console.error('❌ 移动端上传请求错误:', e);
            
            if (window.showToast) {
              let errorMessage = '上传失败';
              
              if (this.status === 0) {
                errorMessage = '网络连接失败，请检查网络设置';
              } else if (this.status === 408 || this.timeout) {
                errorMessage = '上传超时，请重试或选择较小的文件';
              } else if (this.status >= 500) {
                errorMessage = '服务器错误，请稍后重试';
              } else if (this.status >= 400) {
                errorMessage = '请求错误，请检查文件格式和大小';
              }
              
              showToast(errorMessage, 'error');
            }
          });
          
          // 增强超时处理
          this.addEventListener('timeout', function() {
            console.error('⏰ 移动端上传请求超时');
            if (window.showToast) {
              showToast('上传超时，请重试或选择较小的文件', 'error');
            }
          });
          
          // 增强进度事件
          this.addEventListener('progress', function(e) {
            if (e.lengthComputable) {
              const percentComplete = (e.loaded / e.total) * 100;
              console.log(`📊 移动端上传进度: ${Math.round(percentComplete)}%`);
            }
          });
        }
        
        return originalSend.call(this, data);
      };
      
      return xhr;
    }
    
    // 替换全局XMLHttpRequest
    window.XMLHttpRequest = EnhancedXMLHttpRequest;
    
    console.log('✅ XMLHttpRequest增强已全局应用');
  }
  
  // 全局错误处理
  function setupGlobalErrorHandling() {
    console.log('🛡️ 全局错误处理已设置');
    
    // 未捕获的错误
    window.addEventListener('error', function(e) {
      if (e.filename && e.filename.includes('upload')) {
        console.error('🚨 上传相关未捕获错误:', e.message, e.filename, e.lineno, e.colno);
        
        if (isMobileDevice() && window.showToast) {
          let userMessage = '操作失败，请重试';
          
          if (e.message.includes('File') || e.message.includes('file')) {
            userMessage = '文件处理失败，请选择正确的文件';
          } else if (e.message.includes('Network') || e.message.includes('network')) {
            userMessage = '网络连接失败，请检查网络设置';
          } else if (e.message.includes('Permission') || e.message.includes('permission')) {
            userMessage = '权限不足，请检查文件访问权限';
          } else if (e.message.includes('Timeout') || e.message.includes('timeout')) {
            userMessage = '操作超时，请重试';
          }
          
          showToast(userMessage, 'error');
        }
      }
    });
    
    // 未处理的Promise拒绝
    window.addEventListener('unhandledrejection', function(e) {
      console.error('🚨 未处理的Promise拒绝:', e.reason);
      
      if (isMobileDevice() && window.showToast) {
        showToast('操作失败，请重试', 'error');
      }
    });
  }
  
  // 网络状态监控
  function setupNetworkMonitoring() {
    console.log('📡 网络状态监控已设置');
    
    // 在线/离线事件
    window.addEventListener('online', function() {
      console.log('🌐 网络已连接');
      if (window.showToast) {
        showToast('网络已连接', 'success');
      }
    });
    
    window.addEventListener('offline', function() {
      console.log('📴 网络已断开');
      if (window.showToast) {
        showToast('网络已断开，请检查网络设置', 'error');
      }
    });
    
    // 网络类型变化
    if ('connection' in navigator) {
      navigator.connection.addEventListener('change', function() {
        console.log('🔄 网络状态变化:', navigator.connection.effectiveType);
        
        if (window.showToast) {
          showToast(`网络类型: ${navigator.connection.effectiveType}`, 'info');
        }
      });
    }
  }
  
  // 初始化
  function init() {
    console.log('🚀 移动端上传兼容性修复初始化');
    console.log('📱 设备类型:', isMobileDevice() ? '移动端' : '桌面端');
    console.log('🌐 用户代理:', navigator.userAgent);
    console.log('📊 屏幕尺寸:', `${window.innerWidth}x${window.innerHeight}`);
    
    // 检查网络状态
    checkNetworkStatus();
    
    // 增强文件输入
    enhanceFileInput();
    
    // 增强XMLHttpRequest
    enhanceXMLHttpRequest();
    
    // 设置全局错误处理
    setupGlobalErrorHandling();
    
    // 设置网络监控
    setupNetworkMonitoring();
    
    console.log('✅ 移动端上传兼容性修复初始化完成');
  }
  
  // 页面加载完成后初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
  
  // 暴露全局API
  window.MobileUploadFix = {
    isMobileDevice: isMobileDevice,
    checkNetworkStatus: checkNetworkStatus,
    version: '1.0.0'
  };
  
})();