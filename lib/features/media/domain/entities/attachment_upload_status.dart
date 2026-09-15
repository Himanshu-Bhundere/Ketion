enum AttachmentUploadStatus {
  pending('Pending'),
  compressing('Compressing'),
  uploading('Uploading'),
  uploaded('Uploaded'),
  failed('Failed'),
  cancelled('Cancelled');

  final String value;
  const AttachmentUploadStatus(this.value);

  static AttachmentUploadStatus fromString(String val) {
    return AttachmentUploadStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AttachmentUploadStatus.pending,
    );
  }
}
