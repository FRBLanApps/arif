// 本地 aria2 引擎宿主（进程侧车；FFI 预留）。
// App 侧通常用 LocalEngineService；单测可注入 ProcessEngineHost。
export 'src/engine_host.dart';
export 'src/engine_paths.dart';
export 'src/engine_status.dart';
export 'src/local_engine_service.dart';
export 'src/port_utils.dart';
export 'src/process_engine_host.dart';
export 'src/rpc_ready.dart';
