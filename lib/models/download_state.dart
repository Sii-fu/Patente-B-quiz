/// Download state enum for content synchronization
enum DownloadState {
  /// Content has never been downloaded
  notStarted('not_started'),
  
  /// Download is currently in progress
  inProgress('in_progress'),
  
  /// Download completed successfully
  completed('completed'),
  
  /// Download failed with error
  failed('failed');

  const DownloadState(this.value);
  
  final String value;

  /// Convert string to enum
  static DownloadState fromString(String value) {
    return DownloadState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => DownloadState.notStarted,
    );
  }

  /// Check if content is available for offline use
  bool get isAvailableOffline => this == DownloadState.completed;

  /// Check if download is currently running
  bool get isDownloading => this == DownloadState.inProgress;

  /// Check if download needs retry
  bool get needsRetry => this == DownloadState.failed || this == DownloadState.notStarted;
}
