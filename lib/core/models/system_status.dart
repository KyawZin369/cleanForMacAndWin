class MemoryStatus {
  const MemoryStatus({
    required this.usedBytes,
    required this.totalBytes,
    required this.availableBytes,
    required this.usedPercent,
    required this.swapUsedBytes,
    required this.swapTotalBytes,
  });

  final int usedBytes;
  final int totalBytes;
  final int availableBytes;
  final double usedPercent;
  final int swapUsedBytes;
  final int swapTotalBytes;

  double get swapPercent =>
      swapTotalBytes > 0 ? (swapUsedBytes / swapTotalBytes) * 100 : 0;

  factory MemoryStatus.fromJson(Map<String, dynamic> json) {
    return MemoryStatus(
      usedBytes: json['used'] as int? ?? 0,
      totalBytes: json['total'] as int? ?? 0,
      availableBytes: json['available'] as int? ?? 0,
      usedPercent: (json['used_percent'] as num?)?.toDouble() ?? 0,
      swapUsedBytes: json['swap_used'] as int? ?? 0,
      swapTotalBytes: json['swap_total'] as int? ?? 0,
    );
  }
}

class DiskStatus {
  const DiskStatus({
    required this.mount,
    required this.device,
    required this.usedBytes,
    required this.totalBytes,
    required this.usedPercent,
    required this.isExternal,
    required this.label,
  });

  final String mount;
  final String device;
  final int usedBytes;
  final int totalBytes;
  final double usedPercent;
  final bool isExternal;
  final String label;

  int get freeBytes => (totalBytes - usedBytes).clamp(0, totalBytes);

  factory DiskStatus.fromJson(Map<String, dynamic> json, {required String label}) {
    return DiskStatus(
      mount: json['mount'] as String? ?? '',
      device: json['device'] as String? ?? '',
      usedBytes: json['used'] as int? ?? 0,
      totalBytes: json['total'] as int? ?? 0,
      usedPercent: (json['used_percent'] as num?)?.toDouble() ?? 0,
      isExternal: json['external'] as bool? ?? false,
      label: label,
    );
  }
}

class DiskIoStatus {
  const DiskIoStatus({
    required this.readRate,
    required this.writeRate,
  });

  final double readRate;
  final double writeRate;

  factory DiskIoStatus.fromJson(Map<String, dynamic>? json) {
    return DiskIoStatus(
      readRate: (json?['read_rate'] as num?)?.toDouble() ?? 0,
      writeRate: (json?['write_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProcessStatus {
  const ProcessStatus({
    required this.name,
    required this.command,
    required this.cpu,
    required this.memory,
  });

  final String name;
  final String command;
  final double cpu;
  final double memory;

  String get displayName {
    final cmd = command.trim();
    if (cmd.isNotEmpty && cmd != name) return cmd;
    return name;
  }

  factory ProcessStatus.fromJson(Map<String, dynamic> json) {
    return ProcessStatus(
      name: json['name'] as String? ?? '',
      command: json['command'] as String? ?? '',
      cpu: (json['cpu'] as num?)?.toDouble() ?? 0,
      memory: (json['memory'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NetworkStatus {
  const NetworkStatus({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.primaryIp,
  });

  final double downloadMbps;
  final double uploadMbps;
  final String primaryIp;

  factory NetworkStatus.fromInterfaces(List<dynamic> interfaces) {
    var download = 0.0;
    var upload = 0.0;
    String? ip;

    for (final item in interfaces) {
      final map = item as Map<String, dynamic>;
      download += (map['rx_rate_mbs'] as num?)?.toDouble() ?? 0;
      upload += (map['tx_rate_mbs'] as num?)?.toDouble() ?? 0;
      final candidate = map['ip'] as String? ?? '';
      if (ip == null && candidate.isNotEmpty) {
        ip = candidate;
      }
    }

    return NetworkStatus(
      downloadMbps: download,
      uploadMbps: upload,
      primaryIp: ip ?? '',
    );
  }
}

class ProxyStatus {
  const ProxyStatus({
    required this.enabled,
    required this.type,
    required this.host,
  });

  final bool enabled;
  final String type;
  final String host;

  factory ProxyStatus.fromJson(Map<String, dynamic>? json) {
    return ProxyStatus(
      enabled: json?['enabled'] as bool? ?? false,
      type: json?['type'] as String? ?? '',
      host: json?['host'] as String? ?? '',
    );
  }
}

class BatteryStatus {
  const BatteryStatus({
    required this.name,
    required this.chargePercent,
    required this.isCharging,
    required this.timeRemaining,
  });

  final String name;
  final int chargePercent;
  final bool isCharging;
  final String timeRemaining;

  factory BatteryStatus.fromJson(Map<String, dynamic> json) {
    return BatteryStatus(
      name: json['name'] as String? ?? 'Battery',
      chargePercent: json['charge_percent'] as int? ??
          json['percent'] as int? ??
          0,
      isCharging: json['charging'] as bool? ?? false,
      timeRemaining: json['time_remaining'] as String? ?? '',
    );
  }
}

class SystemStatus {
  const SystemStatus({
    required this.collectedAt,
    required this.host,
    required this.uptime,
    required this.healthScore,
    required this.healthScoreMessage,
    required this.cpuUsage,
    required this.memory,
    required this.disks,
    required this.trashBytes,
    required this.diskIo,
    required this.topProcesses,
    required this.network,
    required this.proxy,
    required this.batteries,
  });

  final DateTime? collectedAt;
  final String host;
  final String uptime;
  final int healthScore;
  final String healthScoreMessage;
  final double cpuUsage;
  final MemoryStatus memory;
  final List<DiskStatus> disks;
  final int trashBytes;
  final DiskIoStatus diskIo;
  final List<ProcessStatus> topProcesses;
  final NetworkStatus network;
  final ProxyStatus? proxy;
  final List<BatteryStatus> batteries;

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final disksJson = json['disks'] as List<dynamic>? ?? [];
    var externalIndex = 0;
    final disks = disksJson.map((item) {
      final map = item as Map<String, dynamic>;
      final isExternal = map['external'] as bool? ?? false;
      final label = isExternal
          ? 'EXTR${++externalIndex}'
          : 'INTR';
      return DiskStatus.fromJson(map, label: label);
    }).toList();

    final batteriesJson = json['batteries'];
    final batteries = batteriesJson is List
        ? batteriesJson
            .map((item) => BatteryStatus.fromJson(item as Map<String, dynamic>))
            .toList()
        : <BatteryStatus>[];

    final proxyJson = json['proxy'];
    final proxy = proxyJson is Map<String, dynamic>
        ? ProxyStatus.fromJson(proxyJson)
        : null;

    final collectedRaw = json['collected_at'] as String?;
    DateTime? collectedAt;
    if (collectedRaw != null) {
      collectedAt = DateTime.tryParse(collectedRaw);
    }

    final processes = (json['top_processes'] as List<dynamic>? ?? [])
        .map((item) => ProcessStatus.fromJson(item as Map<String, dynamic>))
        .toList();

    return SystemStatus(
      collectedAt: collectedAt,
      host: json['host'] as String? ?? '',
      uptime: json['uptime'] as String? ?? '',
      healthScore: json['health_score'] as int? ?? 0,
      healthScoreMessage: json['health_score_msg'] as String? ?? '',
      cpuUsage: (json['cpu']?['usage'] as num?)?.toDouble() ?? 0,
      memory: MemoryStatus.fromJson(
        json['memory'] as Map<String, dynamic>? ?? {},
      ),
      disks: disks,
      trashBytes: json['trash_size'] as int? ?? 0,
      diskIo: DiskIoStatus.fromJson(
        json['disk_io'] as Map<String, dynamic>?,
      ),
      topProcesses: processes,
      network: NetworkStatus.fromInterfaces(
        json['network'] as List<dynamic>? ?? [],
      ),
      proxy: proxy,
      batteries: batteries,
    );
  }
}
