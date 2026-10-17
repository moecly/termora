import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

/// Maps dartssh2 and dart:io exceptions to short, user-facing Chinese messages.
String describeSshError(Object error) {
  if (error is String) return error;
  if (error is ArgumentError) return '服务器地址或端口无效';
  if (error is SocketException) return '无法连接到服务器（网络不可达或端口未开放）';
  if (error is TimeoutException) return '连接超时，请检查网络或服务器地址';
  if (error is SSHHostkeyError) return '主机密钥校验未通过';
  if (error is SSHKeyDecodeError) return '私钥解析失败，请检查格式与口令';
  if (error is SSHAuthFailError) return '认证失败：用户名、密码或密钥不正确';
  if (error is SSHAuthAbortError) return '服务器中止了认证：${error.message}';
  if (error is SSHHandshakeError) return 'SSH 握手失败：${error.message}（可能是算法不兼容）';
  if (error is SSHDisconnectError) {
    return '连接被服务器断开（code ${error.reasonCode}）：${error.message}';
  }
  if (error is SSHChannelOpenError) return '无法创建终端会话（通道被拒绝）';
  if (error is SSHStateError) return 'SSH 协议错误，请重试';
  if (error is SSHInternalError) return 'SSH 协议错误，请重试';
  if (error is SSHPacketError) return 'SSH 协议错误，请重试';
  if (error is SSHSocketError) return '套接字错误，连接已中断';
  return '连接失败：$error';
}
