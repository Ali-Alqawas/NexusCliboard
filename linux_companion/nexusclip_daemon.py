#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NexusClip - Linux Companion Daemon
برنامج المزامنة مع Linux

هذا السكريبت يتيح مزامنة الحافظة بين Android و Linux عبر الشبكة المحلية (LAN)
This script enables clipboard sync between Android and Linux over LAN

المتطلبات / Requirements:
    pip install pyperclip zeroconf

الاستخدام / Usage:
    python3 nexusclip_daemon.py
    
الإيقاف / Stop:
    Ctrl+C

المؤلف / Author: NexusClip Team
الإصدار / Version: 1.0.0
"""

import socket
import threading
import time
import base64
import json
import signal
import sys
import argparse
from typing import Optional, Dict, Set
from dataclasses import dataclass
from datetime import datetime

try:
    import pyperclip
except ImportError:
    print("❌ pyperclip غير مثبت / pyperclip not installed")
    print("   التثبيت / Install: pip install pyperclip")
    sys.exit(1)

try:
    from zeroconf import ServiceInfo, Zeroconf, ServiceBrowser, ServiceListener
except ImportError:
    print("⚠️ zeroconf غير مثبت / zeroconf not installed")
    print("   التثبيت / Install: pip install zeroconf")
    print("   سيتم استخدام البث المباشر فقط / Will use direct broadcast only")
    Zeroconf = None

# =====================================================
# ثوابت / Constants
# =====================================================

SYNC_PORT = 4040
BUFFER_SIZE = 65535
DISCOVERY_MESSAGE = "NEXUSCLIP_DISCOVER"
CLIPBOARD_PREFIX = "NEXUSCLIP_CLIP:"
ACK_PREFIX = "NEXUSCLIP_ACK:"
DEVICE_PREFIX = "NEXUSCLIP_DEVICE:"
HEARTBEAT_MESSAGE = "NEXUSCLIP_HEARTBEAT"
MDNS_TYPE = "_nexusclip._udp.local."

# ألوان الطرفية / Terminal Colors
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

# =====================================================
# نموذج الجهاز / Device Model
# =====================================================

@dataclass
class Device:
    """نموذج الجهاز المكتشف / Discovered Device Model"""
    address: str
    platform: str
    name: str
    last_seen: datetime
    
    def __str__(self):
        return f"{self.name} ({self.platform}) - {self.address}"

# =====================================================
# خدمة المزامنة / Sync Service
# =====================================================

class NexusClipDaemon:
    """
    NexusClip Linux Daemon
    
    يدير المزامنة عبر UDP مع أجهزة Android
    Manages UDP sync with Android devices
    """
    
    def __init__(self, port: int = SYNC_PORT, verbose: bool = False):
        self.port = port
        self.verbose = verbose
        self.running = False
        self.socket: Optional[socket.socket] = None
        self.discovered_devices: Dict[str, Device] = {}
        self.connected_device: Optional[Device] = None
        self.last_clipboard = ""
        self.clipboard_lock = threading.Lock()
        
        # Zeroconf (mDNS)
        self.zeroconf: Optional[Zeroconf] = None
        self.service_info: Optional[ServiceInfo] = None
        
    def start(self):
        """بدء الخدمة / Start service"""
        self.running = True
        
        # إنشاء UDP Socket
        self._create_socket()
        
        # تسجيل خدمة mDNS
        if Zeroconf:
            self._register_mdns()
        
        # بدء الخيوط / Start threads
        threads = [
            threading.Thread(target=self._listen_loop, daemon=True),
            threading.Thread(target=self._clipboard_monitor_loop, daemon=True),
            threading.Thread(target=self._heartbeat_loop, daemon=True),
        ]
        
        for thread in threads:
            thread.start()
        
        self._print_banner()
        
        # الحفاظ على التشغيل / Keep running
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()
    
    def stop(self):
        """إيقاف الخدمة / Stop service"""
        print(f"\n{Colors.WARNING}⏹ جاري الإيقاف... / Stopping...{Colors.END}")
        self.running = False
        
        if self.socket:
            self.socket.close()
        
        if self.zeroconf:
            self.zeroconf.unregister_service(self.service_info)
            self.zeroconf.close()
        
        print(f"{Colors.GREEN}✅ تم الإيقاف بنجاح / Stopped successfully{Colors.END}")
    
    def _create_socket(self):
        """إنشاء UDP Socket"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.socket.bind(('0.0.0.0', self.port))
        self.socket.settimeout(1.0)
    
    def _register_mdns(self):
        """تسجيل خدمة mDNS"""
        try:
            import socket as sock
            local_ip = sock.gethostbyname(sock.gethostname())
            
            self.zeroconf = Zeroconf()
            self.service_info = ServiceInfo(
                MDNS_TYPE,
                f"NexusClip-Linux.{MDNS_TYPE}",
                addresses=[sock.inet_aton(local_ip)],
                port=self.port,
                properties={'platform': 'Linux', 'version': '1.0'},
            )
            self.zeroconf.register_service(self.service_info)
            
            if self.verbose:
                print(f"{Colors.CYAN}📡 mDNS مسجل / mDNS registered{Colors.END}")
        except Exception as e:
            if self.verbose:
                print(f"{Colors.WARNING}⚠️ فشل تسجيل mDNS: {e}{Colors.END}")
    
    def _listen_loop(self):
        """حلقة الاستماع للرسائل / Message listening loop"""
        while self.running:
            try:
                data, addr = self.socket.recvfrom(BUFFER_SIZE)
                message = data.decode('utf-8')
                self._handle_message(message, addr[0])
            except socket.timeout:
                continue
            except Exception as e:
                if self.running and self.verbose:
                    print(f"{Colors.FAIL}❌ خطأ استماع: {e}{Colors.END}")
    
    def _handle_message(self, message: str, sender: str):
        """معالجة الرسائل الواردة / Handle incoming messages"""
        
        # طلب اكتشاف / Discovery request
        if message == DISCOVERY_MESSAGE:
            self._respond_to_discovery(sender)
            return
        
        # رد على الاكتشاف / Discovery response
        if message.startswith(DEVICE_PREFIX):
            self._handle_device_response(message, sender)
            return
        
        # محتوى حافظة / Clipboard content
        if message.startswith(CLIPBOARD_PREFIX):
            self._handle_clipboard(message, sender)
            return
        
        # تأكيد / Acknowledgment
        if message.startswith(ACK_PREFIX):
            self._handle_ack(message, sender)
            return
        
        # Heartbeat
        if message == HEARTBEAT_MESSAGE:
            self._handle_heartbeat(sender)
            return
    
    def _respond_to_discovery(self, sender: str):
        """الرد على طلب الاكتشاف / Respond to discovery request"""
        import platform
        device_name = platform.node() or "Linux"
        response = f"{DEVICE_PREFIX}Linux|{device_name}"
        self._send_to(response, sender)
        
        if self.verbose:
            print(f"{Colors.CYAN}📡 تم الرد على اكتشاف من / Responded to discovery from: {sender}{Colors.END}")
    
    def _handle_device_response(self, message: str, sender: str):
        """معالجة رد الجهاز / Handle device response"""
        try:
            parts = message[len(DEVICE_PREFIX):].split('|')
            if len(parts) >= 2:
                device = Device(
                    address=sender,
                    platform=parts[0],
                    name=parts[1],
                    last_seen=datetime.now()
                )
                self.discovered_devices[sender] = device
                print(f"{Colors.GREEN}📱 جهاز مكتشف / Device discovered: {device}{Colors.END}")
        except Exception as e:
            if self.verbose:
                print(f"{Colors.FAIL}❌ خطأ في تحليل الجهاز: {e}{Colors.END}")
    
    def _handle_clipboard(self, message: str, sender: str):
        """معالجة محتوى الحافظة / Handle clipboard content"""
        try:
            base64_content = message[len(CLIPBOARD_PREFIX):]
            content = base64.b64decode(base64_content).decode('utf-8')
            
            with self.clipboard_lock:
                if content != self.last_clipboard:
                    self.last_clipboard = content
                    pyperclip.copy(content)
                    
                    # إرسال تأكيد / Send ACK
                    self._send_to(f"{ACK_PREFIX}RECEIVED", sender)
                    
                    preview = content[:50] + "..." if len(content) > 50 else content
                    print(f"{Colors.GREEN}📋 تم استلام / Received: {preview}{Colors.END}")
        except Exception as e:
            if self.verbose:
                print(f"{Colors.FAIL}❌ خطأ في الحافظة: {e}{Colors.END}")
    
    def _handle_ack(self, message: str, sender: str):
        """معالجة التأكيد / Handle acknowledgment"""
        ack_type = message[len(ACK_PREFIX):]
        if self.verbose:
            print(f"{Colors.CYAN}✓ ACK من {sender}: {ack_type}{Colors.END}")
    
    def _handle_heartbeat(self, sender: str):
        """معالجة Heartbeat / Handle heartbeat"""
        if sender in self.discovered_devices:
            self.discovered_devices[sender].last_seen = datetime.now()
    
    def _clipboard_monitor_loop(self):
        """حلقة مراقبة الحافظة / Clipboard monitoring loop"""
        while self.running:
            try:
                current = pyperclip.paste()
                
                with self.clipboard_lock:
                    if current and current != self.last_clipboard:
                        self.last_clipboard = current
                        self._broadcast_clipboard(current)
                
                time.sleep(0.5)
            except Exception as e:
                if self.verbose:
                    print(f"{Colors.WARNING}⚠️ خطأ مراقبة الحافظة: {e}{Colors.END}")
                time.sleep(1)
    
    def _heartbeat_loop(self):
        """حلقة Heartbeat / Heartbeat loop"""
        while self.running:
            try:
                self._broadcast(HEARTBEAT_MESSAGE)
                self._cleanup_stale_devices()
                time.sleep(30)
            except Exception as e:
                if self.verbose:
                    print(f"{Colors.WARNING}⚠️ خطأ Heartbeat: {e}{Colors.END}")
    
    def _broadcast_clipboard(self, content: str):
        """بث الحافظة / Broadcast clipboard"""
        encoded = base64.b64encode(content.encode('utf-8')).decode('utf-8')
        message = f"{CLIPBOARD_PREFIX}{encoded}"
        self._broadcast(message)
        
        preview = content[:30] + "..." if len(content) > 30 else content
        print(f"{Colors.BLUE}📤 تم الإرسال / Sent: {preview}{Colors.END}")
    
    def _broadcast(self, message: str):
        """البث للشبكة / Broadcast to network"""
        try:
            data = message.encode('utf-8')
            self.socket.sendto(data, ('255.255.255.255', self.port))
        except Exception as e:
            if self.verbose:
                print(f"{Colors.FAIL}❌ خطأ بث: {e}{Colors.END}")
    
    def _send_to(self, message: str, address: str):
        """إرسال لعنوان محدد / Send to specific address"""
        try:
            data = message.encode('utf-8')
            self.socket.sendto(data, (address, self.port))
        except Exception as e:
            if self.verbose:
                print(f"{Colors.FAIL}❌ خطأ إرسال: {e}{Colors.END}")
    
    def _cleanup_stale_devices(self):
        """تنظيف الأجهزة القديمة / Cleanup stale devices"""
        now = datetime.now()
        stale_timeout = 120  # ثانية
        
        stale_devices = [
            addr for addr, device in self.discovered_devices.items()
            if (now - device.last_seen).total_seconds() > stale_timeout
        ]
        
        for addr in stale_devices:
            device = self.discovered_devices.pop(addr, None)
            if device:
                print(f"{Colors.WARNING}📵 جهاز غير متصل / Device disconnected: {device.name}{Colors.END}")
    
    def _print_banner(self):
        """طباعة البانر / Print banner"""
        banner = f"""
{Colors.HEADER}╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   {Colors.CYAN}███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗{Colors.HEADER}            ║
║   {Colors.CYAN}████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝{Colors.HEADER}            ║
║   {Colors.CYAN}██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗{Colors.HEADER}            ║
║   {Colors.CYAN}██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║{Colors.HEADER}            ║
║   {Colors.CYAN}██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║{Colors.HEADER}            ║
║   {Colors.CYAN}╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝{Colors.HEADER}            ║
║                                                          ║
║   {Colors.GREEN}NexusClip Linux Companion v1.0{Colors.HEADER}                        ║
║   {Colors.BLUE}نظام مزامنة الحافظة / Clipboard Sync System{Colors.HEADER}            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝{Colors.END}

{Colors.CYAN}📡 الاستماع على المنفذ / Listening on port: {self.port}{Colors.END}
{Colors.GREEN}✓ جاهز للمزامنة / Ready for sync{Colors.END}
{Colors.WARNING}⌨  اضغط Ctrl+C للإيقاف / Press Ctrl+C to stop{Colors.END}
"""
        print(banner)

# =====================================================
# نقطة الدخول / Entry Point
# =====================================================

def main():
    """نقطة الدخول الرئيسية / Main entry point"""
    parser = argparse.ArgumentParser(
        description='NexusClip Linux Companion - Clipboard Sync Daemon',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
أمثلة / Examples:
    python3 nexusclip_daemon.py
    python3 nexusclip_daemon.py -p 4040 -v
        """
    )
    parser.add_argument(
        '-p', '--port',
        type=int,
        default=SYNC_PORT,
        help=f'منفذ UDP (افتراضي: {SYNC_PORT}) / UDP port (default: {SYNC_PORT})'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='عرض رسائل مفصلة / Show verbose messages'
    )
    
    args = parser.parse_args()
    
    # معالجة إشارات الإيقاف / Handle stop signals
    daemon = NexusClipDaemon(port=args.port, verbose=args.verbose)
    
    def signal_handler(sig, frame):
        daemon.stop()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # بدء الخدمة / Start service
    daemon.start()

if __name__ == '__main__':
    main()
