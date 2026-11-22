enum IncomingShareType {
  file,
  link,
  text,
}

class IncomingShareItem {
  final IncomingShareType type;
  final String name;
  final String? localPath;
  final String? mimeType;
  final String? url;
  final String? text;
  final int? size;

  const IncomingShareItem({
    required this.type,
    required this.name,
    this.localPath,
    this.mimeType,
    this.url,
    this.text,
    this.size,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      if (localPath != null) 'localPath': localPath,
      if (mimeType != null) 'mimeType': mimeType,
      if (url != null) 'url': url,
      if (text != null) 'text': text,
      if (size != null) 'size': size,
    };
  }

  factory IncomingShareItem.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'file';
    final type = IncomingShareType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => IncomingShareType.file,
    );

    return IncomingShareItem(
      type: type,
      name: map['name'] as String? ?? 'Shared Item',
      localPath: map['localPath'] as String?,
      mimeType: map['mimeType'] as String?,
      url: map['url'] as String?,
      text: map['text'] as String?,
      size: (map['size'] as num?)?.toInt(),
    );
  }
}
